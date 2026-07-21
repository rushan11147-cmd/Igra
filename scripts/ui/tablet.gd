extends Control
## Alex's work tablet — shift plan, factory map, documents.

@onready var _panel: PanelContainer = $Panel
@onready var _goal_label: Label = $Panel/Margin/VBox/GoalLabel
@onready var _money_label: Label = $Panel/Margin/VBox/MoneyLabel
@onready var _task_list: VBoxContainer = $Panel/Margin/VBox/TaskList
@onready var _area_list: VBoxContainer = $Panel/Margin/VBox/AreaList
@onready var _doc_list: VBoxContainer = $Panel/Margin/VBox/DocList

var _is_open: bool = false


func _ready() -> void:
	visible = false
	EventBus.tablet_toggle_requested.connect(_on_tablet_toggle)
	EventBus.goal_changed.connect(_on_goal_changed)
	EventBus.money_earned.connect(_on_money_earned)
	EventBus.task_added.connect(_on_task_added)
	EventBus.task_completed.connect(_on_task_completed)
	EventBus.area_unlocked.connect(_on_area_unlocked)
	EventBus.document_found.connect(_on_document_found)
	EventBus.shift_started.connect(_on_shift_started)
	EventBus.rule_announced.connect(_on_rule_announced)


func _on_tablet_toggle() -> void:
	if _is_open:
		_close()
	else:
		_open()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("tablet") and _is_open:
		_close()
		get_viewport().set_input_as_handled()


func _open() -> void:
	_is_open = true
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_refresh_all()


func _close() -> void:
	_is_open = false
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _refresh_all() -> void:
	_goal_label.text = "Цель: %s" % StoryManager.get_goal_description()
	_rules_section()
	_money_label.text = "Заработано: %d ₽ | Осталось смен: %d" % [
		StoryManager.money_earned,
		StoryManager.get_shifts_remaining(GameManager.current_night),
	]
	_refresh_areas()
	_refresh_documents()


func _refresh_areas() -> void:
	for child in _area_list.get_children():
		child.queue_free()
	for area_id in AreaManager.unlocked_areas:
		var label := Label.new()
		label.text = "✓ %s" % AreaManager.get_area_name(area_id)
		_area_list.add_child(label)


func _refresh_documents() -> void:
	for child in _doc_list.get_children():
		child.queue_free()
	for doc_id in StoryManager.documents_found:
		var label := Label.new()
		label.text = "📄 %s" % StoryManager.get_document_title(doc_id)
		_doc_list.add_child(label)


func _on_shift_started(_night: int) -> void:
	for child in _task_list.get_children():
		child.queue_free()
	_goal_label.text = "Цель: %s" % StoryManager.get_goal_description()
	_rules_section()


func _rules_section() -> void:
	var rules := FactoryRules.get_rules_text()
	if rules != "":
		if not _goal_label.text.contains("Правила смены"):
			_goal_label.text += "\n\nПравила смены:\n" + rules.replace("⚠ ", "• ")


func _on_rule_announced(_rule: Dictionary) -> void:
	_rules_section()


func _on_goal_changed(_goal: int, description: String) -> void:
	_goal_label.text = "Цель: %s" % description


func _on_money_earned(_amount: int, total: int) -> void:
	_money_label.text = "Заработано: %d ₽ | Осталось смен: %d" % [
		total,
		StoryManager.get_shifts_remaining(GameManager.current_night),
	]


func _on_task_added(task: Dictionary) -> void:
	var label := Label.new()
	label.text = "○ %s" % task.get("title", "")
	label.name = str(task.get("id", ""))
	_task_list.add_child(label)


func _on_task_completed(task_id: StringName) -> void:
	var node := _task_list.get_node_or_null(str(task_id))
	if node:
		node.text = "✓ " + node.text.substr(2)


func _on_area_unlocked(area_id: StringName) -> void:
	_refresh_areas()


func _on_document_found(_doc_id: StringName, _title: String) -> void:
	_refresh_documents()

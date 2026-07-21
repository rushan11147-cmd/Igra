extends Control
## In-game HUD with sanity, rules, radio, and corrupted tasks.

@onready var _night_label: Label = $Margin/VBox/TopBar/NightLabel
@onready var _time_label: Label = $Margin/VBox/TopBar/TimeLabel
@onready var _quota_label: Label = $Margin/VBox/TopBar/QuotaLabel
@onready var _goal_label: Label = $Margin/VBox/GoalBar/GoalLabel
@onready var _rules_label: Label = $Margin/VBox/RulesBar/RulesLabel
@onready var _threat_bar: ProgressBar = $Margin/VBox/BottomBar/ThreatBar
@onready var _sanity_bar: ProgressBar = $Margin/VBox/BottomBar/SanityBar
@onready var _threat_label: Label = $Margin/VBox/BottomBar/ThreatLabel
@onready var _noise_label: Label = $Margin/VBox/BottomBar/NoiseLabel
@onready var _creature_label: Label = $Margin/VBox/BottomBar/CreatureLabel
@onready var _interaction_label: Label = $Margin/VBox/Center/InteractionLabel
@onready var _task_list: VBoxContainer = $Margin/VBox/TaskPanel/TaskList
@onready var _event_label: Label = $Margin/VBox/EventFlash
@onready var _radio_label: Label = $Margin/VBox/RadioFlash

var _player: Node = null
var _event_flash_timer: float = 0.0
var _radio_flash_timer: float = 0.0


func _ready() -> void:
	EventBus.shift_started.connect(_on_shift_started)
	EventBus.time_updated.connect(_on_time_updated)
	EventBus.factory_time_updated.connect(_on_factory_time)
	EventBus.production_quota_changed.connect(_on_quota_changed)
	EventBus.threat_level_changed.connect(_on_threat_changed)
	EventBus.sanity_changed.connect(_on_sanity_changed)
	EventBus.goal_changed.connect(_on_goal_changed)
	EventBus.rule_announced.connect(_on_rule_announced)
	EventBus.task_added.connect(_on_task_added)
	EventBus.task_completed.connect(_on_task_completed)
	EventBus.task_display_corrupted.connect(_on_task_corrupted)
	EventBus.paranormal_event.connect(_on_paranormal_event)
	EventBus.player_noise_changed.connect(_on_noise_changed)
	EventBus.player_hiding_changed.connect(_on_hiding_changed)
	EventBus.radio_message.connect(_on_radio_message)
	EventBus.creature_type_changed.connect(_on_creature_changed)
	EventBus.hall8_event_started.connect(_on_hall8)
	_event_label.visible = false
	_radio_label.visible = false
	_on_goal_changed(StoryManager.current_goal, StoryManager.get_goal_description())


func set_player(player: Node) -> void:
	_player = player


func _process(_delta: float) -> void:
	if _player and _player.has_method("get_interaction_prompt"):
		var prompt: String = _player.get_interaction_prompt()
		_interaction_label.text = prompt
		_interaction_label.visible = not prompt.is_empty()

	if _event_flash_timer > 0.0:
		_event_flash_timer -= _delta
		if _event_flash_timer <= 0.0:
			_event_label.visible = false

	if _radio_flash_timer > 0.0:
		_radio_flash_timer -= _delta
		if _radio_flash_timer <= 0.0:
			_radio_label.visible = false


func _on_shift_started(night: int) -> void:
	_night_label.text = "Ночь %d / %d" % [night, GameManager.MAX_NIGHTS]
	_rules_label.text = ""
	_clear_tasks()


func _on_factory_time(hour: int, minute: int, _progress: float) -> void:
	_time_label.text = "%02d:%02d" % [hour, minute]


func _on_time_updated(minutes_left: float, _progress: float) -> void:
	var mins := int(minutes_left)
	var secs := int((minutes_left - mins) * 60.0)
	var clock := _time_label.text.split(" | ")[0] if " | " in _time_label.text else _time_label.text
	_time_label.text = "%s | до рассвета: %02d:%02d" % [clock, mins, secs]


func _on_quota_changed(current: int, target: int) -> void:
	_quota_label.text = "План: %d / %d" % [current, target]


func _on_goal_changed(_goal: int, description: String) -> void:
	_goal_label.text = description


func _on_rule_announced(rule: Dictionary) -> void:
	_rules_label.text = FactoryRules.get_rules_text()


func _on_threat_changed(level: float, phase: int) -> void:
	_threat_bar.value = level
	var phase_names := ["Спокойно", "Тревога", "Наблюдение", "Кошмар"]
	_threat_label.text = "Угроза: %s" % phase_names[mini(phase, 3)]


func _on_sanity_changed(value: float, _effects: Array) -> void:
	_sanity_bar.value = value


func _on_creature_changed(creature_type: StringName) -> void:
	var names: Dictionary = {
		&"observer": "Сущность: Наблюдатель",
		&"hunter": "Сущность: Охотник ⚠",
		&"crawler": "Сущность: Ползун (вентиляция)",
		&"shadow": "Сущность: Тень (темнота)",
	}
	_creature_label.text = names.get(creature_type, "")


func _on_noise_changed(level: float) -> void:
	if level < 0.5:
		_noise_label.text = "Шум: тихо"
	elif level < 2.0:
		_noise_label.text = "Шум: умеренный"
	else:
		_noise_label.text = "Шум: ГРОМКО — вас слышат"


func _on_hiding_changed(is_hiding: bool) -> void:
	_noise_label.text = "В укрытии — тихо" if is_hiding else "Шум: тихо"


func _on_radio_message(speaker: String, text: String, is_fake: bool) -> void:
	_radio_label.text = "📻 %s: %s" % [speaker, text]
	_radio_label.modulate = Color(1.0, 0.4, 0.4) if is_fake else Color(0.7, 0.9, 1.0)
	_radio_label.visible = true
	_radio_flash_timer = 6.0


func _on_hall8() -> void:
	_event_label.text = "⚠ Стук из цеха №8..."
	_event_label.visible = true
	_event_flash_timer = 5.0


func _on_task_added(task: Dictionary) -> void:
	var title: String = task.get("title", "")
	if SanitySystem.get_distortion() > 0.3:
		title = SanitySystem.corrupt_text(title)
	var label := Label.new()
	label.text = "○ %s" % title
	label.name = str(task.get("id", ""))
	_task_list.add_child(label)


func _on_task_corrupted(task_id: StringName, fake_text: String) -> void:
	var node := _task_list.get_node_or_null(str(task_id))
	if node:
		node.text = "○ %s (?)" % fake_text
		node.modulate = Color(1.0, 0.6, 0.6)


func _on_task_completed(task_id: StringName) -> void:
	var node := _task_list.get_node_or_null(str(task_id))
	if node:
		node.text = "✓ " + node.text.substr(2)


func _on_paranormal_event(event_id: StringName, data: Dictionary) -> void:
	var messages: Dictionary = {
		&"camera_glitch": "Камера дала сбой...",
		&"distant_footsteps": "Где-то слышны шаги...",
		&"item_moved": "Что-то переместилось...",
		&"lights_flicker": "Свет мерцает...",
		&"lights_cut": "Свет погас...",
		&"camera_figure": "На камере — фигура!",
		&"equipment_auto_start": "Оборудование включилось само!",
		&"equipment_sabotage": "Оборудование сломано...",
		&"power_outage": "Отключение электричества!",
		&"whispers": "Шёпот в темноте...",
		&"door_slams": "Дверь захлопнулась!",
		&"entity_glimpse": "Мелькнуло что-то...",
		&"entity_manifest": "Оно здесь...",
		&"hallucination": "Вам показалось...",
		&"hall8_knocking": "Стук из цеха №8...",
		&"hall8_voice": data.get("text", "Помоги... Я здесь..."),
		&"hide_spot_checked": "Кто-то проверил ваше укрытие...",
		&"phone_ring": "Звонит телефон...",
		&"alarm": "АВАРИЙНАЯ СИРЕНА!",
		&"reality_shift": "Реальность искажается...",
		&"mass_breach": "Чёрная масса прорывается!",
		&"factory_awakens": "Завод оживает...",
	}
	_event_label.text = messages.get(event_id, str(data.get("text", "...")))
	_event_label.visible = true
	_event_flash_timer = 3.0


func _clear_tasks() -> void:
	for child in _task_list.get_children():
		child.queue_free()

extends Control
## End-of-shift decision — money vs safety vs exploration.

@onready var _panel: PanelContainer = $Panel
@onready var _report_label: RichTextLabel = $Panel/Margin/VBox/ReportLabel
@onready var _btn_plan: Button = $Panel/Margin/VBox/Choices/BtnPlan
@onready var _btn_stop: Button = $Panel/Margin/VBox/Choices/BtnStop
@onready var _btn_explore: Button = $Panel/Margin/VBox/Choices/BtnExplore

var _report: Dictionary = {}


func _ready() -> void:
	visible = false
	_btn_plan.pressed.connect(func(): _choose(StoryManager.ShiftChoice.COMPLETE_PLAN))
	_btn_stop.pressed.connect(func(): _choose(StoryManager.ShiftChoice.STOP_PRODUCTION))
	_btn_explore.pressed.connect(func(): _choose(StoryManager.ShiftChoice.EXPLORE))
	EventBus.shift_choice_required.connect(_on_choice_required)


func _on_choice_required(report: Dictionary) -> void:
	_report = report
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	_report_label.text = """[b]Ночь %d завершена[/b]

Производство: %d / %d
Рассудок: %.0f%%
Заработано: %d ₽

[b]Правила смены:[/b]
%s

[b]Изменения завода:[/b]
%s

[b]Что делать дальше?[/b]""" % [
		report.get("night", 0),
		report.get("production", 0),
		report.get("production_target", 0),
		report.get("sanity", 100),
		report.get("money", 0),
		report.get("rules", ""),
		report.get("mutations", "—"),
	]

	_btn_plan.text = "✔ Выполнить план (+150₽ бонус)"
	_btn_stop.text = "⛔ Остановить производство (↓ угроза, -50₽)"
	_btn_explore.text = "🔍 Исследовать завод (шанс найти документ)"


func _choose(choice: StoryManager.ShiftChoice) -> void:
	visible = false
	StoryManager.apply_shift_choice(choice, _report.get("quota_met", false))
	EventBus.shift_choice_made.emit(StoryManager.get_choice_id(choice))

extends Control
## End-of-shift report and all endings.

@onready var _title: Label = $Panel/Margin/VBox/Title
@onready var _details: RichTextLabel = $Panel/Margin/VBox/Details
@onready var _continue_btn: Button = $Panel/Margin/VBox/ContinueBtn

signal continue_pressed

const ENDING_TEXTS: Dictionary = {
	&"bad": "Производство запущено. Чёрная масса выходит за пределы завода.",
	&"good": "Главный реактор уничтожен. Алекс спасается на рассвете.",
	&"secret": "«Протокол Синтез» раскрыт. Монстр — результат эксперимента, не мистика.",
	&"escape": "Алекс зарабатывает достаточно и уезжает из города. Завод продолжает работать.",
	&"save_workers": "Алекс спасает сотрудников из цеха 8. Не всех, но достаточно.",
	&"sell_secrets": "Алекс продаёт документы корпорации. Богат, но Factory 17 перестраивается.",
	&"become_subject": "Алекс остаётся на заводе. Становится частью эксперимента.",
}


func _ready() -> void:
	visible = false
	_continue_btn.pressed.connect(_on_continue)
	EventBus.shift_ended.connect(_on_shift_ended)
	EventBus.ending_triggered.connect(_on_ending)


func _on_shift_ended(success: bool, report: Dictionary) -> void:
	if StoryManager.ending != StoryManager.Ending.NONE:
		return

	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_title.text = "Смена завершена — %s" % StoryManager.PROTAGONIST_NAME if success else "Смена провалена"
	_title.modulate = Color(0.6, 1.0, 0.6) if success else Color(1.0, 0.4, 0.4)

	_details.text = """[b]Ночь %d / %d[/b] | Рассудок: %.0f%%

[b]Цель:[/b] %s

Производство: %d / %d | Задач: %d / %d
Заработано: %d ₽ | Осталось смен: %d
Брак: %d | Аварии: %d | Очки: %d""" % [
		report.get("night", 0), GameManager.MAX_NIGHTS,
		report.get("sanity", 100),
		report.get("goal", ""),
		report.get("production", 0), report.get("production_target", 0),
		report.get("tasks_completed", 0), report.get("tasks_total", 0),
		report.get("money", 0), report.get("shifts_remaining", 0),
		report.get("defects", 0), report.get("accidents", 0), report.get("score", 0),
	]


func _on_ending(ending_id: StringName) -> void:
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_title.text = "Концовка"
	_details.text = "[b]%s[/b]\n\n%s" % [ending_id, ENDING_TEXTS.get(ending_id, "...")]


func _on_continue() -> void:
	visible = false
	if StoryManager.ending != StoryManager.Ending.NONE:
		StoryManager.reset()
		GameManager.start_new_game()
		return
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	continue_pressed.emit()

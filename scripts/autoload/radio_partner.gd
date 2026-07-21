extends Node
## Radio partner — another night worker. Then silence. Then something else.

const PARTNER_NAME := "Дмитрий"

const DIALOGUE: Dictionary = {
	1: ["Приём. Первая смена? Не парься, тут всё просто.", "Главное — не опаздывай на обход."],
	3: ["Слышал, в цехе B странный запах. Наверное, фильтр.", "Если что — звони."],
	5: ["Тут был до тебя ещё один парень. Уволился внезапно.", "Не задавай лишних вопросов."],
	7: ["Камера 4 глючит. Не смотри в неё долго.", "Серьёзно."],
	9: ["Мне сегодня нехорошо. Может, смену закрою пораньше.", "Если не отвечу — не ищи."],
	11: ["Ты слышишь стук? В цехе 8?", "Не ходи туда. Никогда."],
}

const FAKE_DIALOGUE: Array[String] = [
	"Помоги мне... я в цехе 8...",
	"Открой дверь... я знаю, ты там...",
	"Они не отпускают... мы все здесь...",
	"Это Дмитрий. Я нашёл выход. Иди за мной.",
	"Не выключай свет. Оно любит темноту.",
]

var partner_alive: bool = true
var last_response_night: int = 0
var silence_nights: int = 0
var _message_timer: float = 0.0
var _fake_mode: bool = false


func reset() -> void:
	partner_alive = true
	last_response_night = 0
	silence_nights = 0
	_fake_mode = false
	_message_timer = 0.0


func setup_for_night(night: int) -> void:
	_fake_mode = night >= 14
	if night >= 12:
		silence_nights = night - 11

	_message_timer = randf_range(30.0, 90.0)


func _process(delta: float) -> void:
	if GameManager.game_state != GameManager.GameState.SHIFT:
		return

	_message_timer -= delta
	if _message_timer > 0.0:
		return

	_message_timer = randf_range(120.0, 300.0)
	_try_send_message()


func _try_send_message() -> void:
	var night := GameManager.current_night

	if _fake_mode:
		var line: String = FAKE_DIALOGUE[randi() % FAKE_DIALOGUE.size()]
		EventBus.radio_message.emit(PARTNER_NAME, line, true)
		return

	if night in DIALOGUE:
		var lines: Array = DIALOGUE[night]
		var line: String = lines[randi() % lines.size()]
		EventBus.radio_message.emit(PARTNER_NAME, line, false)
		last_response_night = night
	elif night > 11:
		EventBus.radio_silence.emit()
		silence_nights += 1


func player_responds() -> void:
	if _fake_mode:
		SanitySystem.add_stress(15.0, &"radio_fake")
		var line: String = FAKE_DIALOGUE[randi() % FAKE_DIALOGUE.size()]
		EventBus.radio_message.emit(PARTNER_NAME, line, true)
	elif silence_nights > 0:
		EventBus.radio_silence.emit()

class_name PumpMinigame
extends Interactable
## Pump repair minigame — toggle at right moment.

@export var machine_id: StringName = &"basement_pump"
@export var required_taps: int = 5

var _taps: int = 0
var _window_open: bool = false
var _window_timer: float = 0.0
var _is_done: bool = false


func _ready() -> void:
	super._ready()
	interaction_prompt = "Отремонтировать насос [E]"
	EventBus.minigame_started.emit(&"repair_pump")


func _process(delta: float) -> void:
	if _is_done:
		return
	_window_timer -= delta
	if _window_timer <= 0.0:
		_window_open = randf() < 0.3
		_window_timer = randf_range(0.5, 2.0)
		if _window_open:
			interaction_prompt = "⚡ Нажми [E] сейчас!"
		else:
			interaction_prompt = "Насос неисправен... жди момент"


func _on_interact(_player: Node3D) -> void:
	if _is_done:
		return
	if _window_open:
		_taps += 1
		_window_open = false
		interaction_prompt = "Прогресс: %d / %d" % [_taps, required_taps]
		if _taps >= required_taps:
			_complete()
	else:
		HorrorSystem.add_threat(3.0, &"pump_mistap")
		interaction_prompt = "Промах! Попробуй снова..."


func _complete() -> void:
	_is_done = true
	interaction_prompt = "Насос отремонтирован ✓"
	ShiftManager.complete_task(&"repair_pump")
	EventBus.minigame_completed.emit(&"repair_pump", true)

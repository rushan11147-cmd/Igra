class_name FilterMinigame
extends Interactable
## Replace filter minigame — hold interact to complete.

@export var machine_id: StringName = &"vent_filter"
@export var replace_duration: float = 3.0

var _progress: float = 0.0
var _is_replacing: bool = false
var _is_done: bool = false


func _ready() -> void:
	super._ready()
	interaction_prompt = "Заменить фильтр [E — удерживать]"


func _process(delta: float) -> void:
	if not _is_replacing or _is_done:
		return
	_progress += delta
	interaction_prompt = "Замена фильтра... %.0f%%" % (_progress / replace_duration * 100.0)
	if _progress >= replace_duration:
		_complete()


func _on_interact(_player: Node3D) -> void:
	if _is_done:
		return
	_is_replacing = true
	EventBus.minigame_started.emit(&"replace_filter")


func interact(player: Node3D) -> void:
	if _is_done:
		return
	_on_interact(player)


func _complete() -> void:
	_is_done = true
	_is_replacing = false
	interaction_prompt = "Фильтр заменён ✓"
	ShiftManager.complete_task(&"replace_filter")
	EventBus.minigame_completed.emit(&"replace_filter", true)


func _input_release() -> void:
	if not _is_done:
		_is_replacing = false
		_progress = 0.0

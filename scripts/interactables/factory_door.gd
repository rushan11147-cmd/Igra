class_name FactoryDoor
extends Interactable
## Doors that can be opened, closed, locked, and sabotaged by the entity.

@export var door_id: StringName = &"door_default"
@export var required_key: StringName = &""
@export var is_locked: bool = false
@export var open_angle: float = 90.0

var is_open: bool = false
var _pivot: Node3D = null


func _ready() -> void:
	super._ready()
	add_to_group("doors")
	_pivot = self
	_update_prompt()


func _on_interact(_player: Node3D) -> void:
	if is_locked:
		if required_key != &"" and InventoryManager.has_key(required_key):
			is_locked = false
			_update_prompt()
		else:
			return

	toggle()


func toggle() -> void:
	is_open = not is_open
	var target_angle := deg_to_rad(open_angle) if is_open else 0.0
	var tween := create_tween()
	tween.tween_property(_pivot, "rotation:y", target_angle, 0.5)
	EventBus.door_state_changed.emit(door_id, is_open)
	_update_prompt()


func sabotage() -> void:
	if is_open:
		toggle()  # Slam shut
	EventBus.paranormal_event.emit(&"door_slams", {"door_id": door_id})


func weld_shut() -> void:
	is_locked = true
	interaction_enabled = false
	interaction_prompt = "Дверь заварена"


func _update_prompt() -> void:
	if is_locked:
		interaction_prompt = "Заперто — нужен ключ [%s]" % required_key
	elif is_open:
		interaction_prompt = "Закрыть дверь [E]"
	else:
		interaction_prompt = "Открыть дверь [E]"

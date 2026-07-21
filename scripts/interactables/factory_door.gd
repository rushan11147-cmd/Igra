class_name FactoryDoor
extends Interactable
## Doors that can be opened, closed, locked, and sabotaged by the entity.

@export var door_id: StringName = &"door_default"
@export var required_key: StringName = &""
@export var is_locked: bool = false
@export var open_angle: float = 95.0

var is_open: bool = false
var _panel: Node3D = null
var _blocker: StaticBody3D = null
var _closed_rot_y: float = 0.0


func _ready() -> void:
	super._ready()
	add_to_group("doors")
	_panel = get_node_or_null("DoorPanel")
	_blocker = get_node_or_null("Blocker")
	if _panel:
		_closed_rot_y = _panel.rotation.y
	_update_prompt()
	_set_blocker_enabled(not is_open)


func _on_interact(_player: Node3D) -> void:
	if is_locked:
		if required_key != &"" and InventoryManager.has_key(required_key):
			is_locked = false
			_update_prompt()
		else:
			interaction_prompt = "Заперто"
			return
	toggle()


func toggle() -> void:
	is_open = not is_open
	var target := _closed_rot_y + (deg_to_rad(open_angle) if is_open else 0.0)
	if _panel:
		var tween := create_tween()
		tween.tween_property(_panel, "rotation:y", target, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_set_blocker_enabled(not is_open)
	EventBus.door_state_changed.emit(door_id, is_open)
	_update_prompt()
	_play_door_sound()


func sabotage() -> void:
	if is_open:
		toggle()
	EventBus.paranormal_event.emit(&"door_slams", {"door_id": door_id})


func weld_shut() -> void:
	is_locked = true
	interaction_enabled = false
	interaction_prompt = "Дверь заварена"
	_set_blocker_enabled(true)


func _set_blocker_enabled(enabled: bool) -> void:
	if _blocker == null:
		_blocker = get_node_or_null("Blocker") as StaticBody3D
	if _blocker == null:
		return
	# Надёжно выключаем коллизию (одного layer иногда недостаточно).
	_blocker.collision_layer = 1 if enabled else 0
	_blocker.collision_mask = 0
	for child in _blocker.get_children():
		if child is CollisionShape3D:
			(child as CollisionShape3D).disabled = not enabled


func _play_door_sound() -> void:
	if Engine.get_main_loop() == null:
		return
	var path := SoundLibrary.pick_random(SoundLibrary.DOOR_OPENS if is_open else SoundLibrary.DOOR_SLAMS)
	var stream := SoundLibrary.load_stream(path)
	if stream == null:
		return
	var player := AudioStreamPlayer3D.new()
	player.stream = stream
	player.volume_db = -4.0
	player.max_distance = 25.0
	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)


func _update_prompt() -> void:
	if is_locked:
		interaction_prompt = "Заперто — нужен ключ"
	elif is_open:
		interaction_prompt = "Закрыть дверь [E]"
	else:
		interaction_prompt = "Открыть дверь [E]"

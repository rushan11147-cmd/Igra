extends Node
## Handles paranormal event effects, ambient audio, and entity sabotage in the world.

@onready var _ambient: AudioStreamPlayer = $AmbientHum
@onready var _event_player: AudioStreamPlayer = $EventPlayer
@onready var _machine_player: AudioStreamPlayer = $MachinePlayer

var _lights: Array[Light3D] = []
var _cameras: Array[Node3D] = []
var _flicker_timer: float = 0.0
var _power_out: bool = false


func _ready() -> void:
	EventBus.paranormal_event.connect(_on_paranormal_event)
	EventBus.entity_sabotage.connect(_on_entity_sabotage)
	EventBus.threat_level_changed.connect(_on_threat_changed)
	EventBus.shift_started.connect(_on_shift_started)
	EventBus.entity_spawned.connect(_on_entity_spawned)
	EventBus.reactor_state_changed.connect(_on_reactor_state)
	_start_ambient()


func register_lights(lights: Array[Light3D]) -> void:
	_lights = lights


func register_cameras(cameras: Array[Node3D]) -> void:
	_cameras = cameras


func _process(delta: float) -> void:
	if _flicker_timer > 0.0:
		_flicker_timer -= delta
		var flicker := sin(_flicker_timer * 30.0) > 0.0
		for light in _lights:
			light.visible = flicker


func _start_ambient() -> void:
	var stream := SoundLibrary.load_stream(SoundLibrary.AMBIENT)
	if stream == null or _ambient == null:
		return
	if stream is AudioStreamOggVorbis:
		stream.loop = true
	_ambient.stream = stream
	_ambient.volume_db = -22.0
	_ambient.play()


func _on_shift_started(_night: int) -> void:
	_power_out = false
	for light in _lights:
		light.visible = true
	if _ambient and not _ambient.playing:
		_ambient.play()


func _on_threat_changed(level: float, _phase: int) -> void:
	if _ambient:
		_ambient.volume_db = lerpf(-24.0, -10.0, level / 100.0)


func _on_entity_spawned(_is_hallucination: bool, _creature_type: StringName) -> void:
	_play_event_sound(&"whispers", 0.0)
	await get_tree().create_timer(0.35).timeout
	_play_event_sound(&"footsteps", -6.0)


func _on_reactor_state(state: Dictionary) -> void:
	if not state.get("is_running", false):
		return
	if _machine_player and _machine_player.playing:
		return
	var path := SoundLibrary.pick_random(SoundLibrary.MACHINE)
	var stream := SoundLibrary.load_stream(path)
	if stream and _machine_player:
		_machine_player.stream = stream
		_machine_player.volume_db = -16.0
		_machine_player.play()


func _on_entity_sabotage(type: StringName, target: Node) -> void:
	if target and target.has_method("sabotage"):
		target.sabotage()
	else:
		_on_paranormal_event(type, {})


func _on_paranormal_event(event_id: StringName, data: Dictionary) -> void:
	match event_id:
		&"camera_glitch":
			_camera_glitch()
		&"distant_footsteps":
			_play_event_sound(&"footsteps", -4.0)
		&"item_moved":
			_item_moved()
			_play_event_sound(&"machine", -8.0)
		&"lights_flicker":
			_flicker_lights(2.0)
		&"lights_cut":
			_cut_lights(4.0)
		&"camera_figure":
			_camera_figure()
		&"equipment_auto_start", &"equipment_sabotage":
			_equipment_auto_start()
			_play_event_sound(&"machine", -6.0)
		&"power_outage":
			_power_outage(data)
		&"whispers":
			_play_event_sound(&"whispers", -2.0)
		&"door_slams":
			_door_slam()
			_play_event_sound(&"door_slam", 0.0)
		&"entity_glimpse", &"entity_manifest", &"hallucination":
			_play_event_sound(&"whispers", 2.0)
		&"reality_shift":
			_reality_shift()
		&"mass_breach":
			_mass_breach()
		&"factory_awakens":
			_factory_awakens()


func _flicker_lights(duration: float) -> void:
	_flicker_timer = duration


func _cut_lights(duration: float) -> void:
	for light in _lights:
		light.visible = false
	var timer := get_tree().create_timer(duration)
	timer.timeout.connect(_restore_lights)


func _restore_lights() -> void:
	for light in _lights:
		light.visible = true


func _door_slam() -> void:
	var doors := get_tree().get_nodes_in_group("doors")
	for door in doors:
		if door is FactoryDoor and door.is_open:
			door.sabotage()
			return


func _camera_glitch() -> void:
	for cam in _cameras:
		if cam.has_method("glitch"):
			cam.glitch(0.5)


func _camera_figure() -> void:
	for cam in _cameras:
		if cam.has_method("show_figure"):
			cam.show_figure()


func _power_outage(_data: Dictionary) -> void:
	_power_out = true
	_flicker_lights(5.0)
	_play_event_sound(&"machine", -4.0)
	await get_tree().create_timer(3.0).timeout
	_power_out = false
	for light in _lights:
		light.visible = true


func _equipment_auto_start() -> void:
	var reactors := get_tree().get_nodes_in_group("reactors")
	for reactor in reactors:
		if reactor is Reactor:
			if randf() < 0.5:
				reactor.is_running = not reactor.is_running
			else:
				reactor.break_equipment()


func _item_moved() -> void:
	var props := get_tree().get_nodes_in_group("movable_props")
	if props.is_empty():
		return
	var prop: Node3D = props[randi() % props.size()]
	prop.global_position += Vector3(randf_range(-2, 2), 0, randf_range(-2, 2))


func _reality_shift() -> void:
	Engine.time_scale = 0.5
	_play_event_sound(&"whispers", 4.0)
	await get_tree().create_timer(1.0).timeout
	Engine.time_scale = 1.0


func _mass_breach() -> void:
	HorrorSystem.add_threat(15.0, &"mass_breach")
	_play_event_sound(&"door_slam", 2.0)


func _factory_awakens() -> void:
	_flicker_lights(8.0)
	HorrorSystem.add_threat(10.0, &"factory_awakens")
	_play_event_sound(&"machine", 0.0)


func _play_event_sound(sound_id: StringName, volume_db: float = -6.0) -> void:
	if _event_player == null:
		return
	var path := ""
	match sound_id:
		&"footsteps":
			path = SoundLibrary.pick_random(SoundLibrary.FOOTSTEPS)
		&"whispers":
			path = SoundLibrary.pick_random(SoundLibrary.WHISPERS)
		&"door_slam":
			path = SoundLibrary.pick_random(SoundLibrary.DOOR_SLAMS)
		&"door_open":
			path = SoundLibrary.pick_random(SoundLibrary.DOOR_OPENS)
		&"machine":
			path = SoundLibrary.pick_random(SoundLibrary.MACHINE)
		_:
			return
	var stream := SoundLibrary.load_stream(path)
	if stream == null:
		return
	_event_player.stream = stream
	_event_player.volume_db = volume_db
	_event_player.play()

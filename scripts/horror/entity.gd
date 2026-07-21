extends CharacterBody3D
## Adaptive creature AI — Backrooms-style tall entity with sounds.

enum State { DORMANT, OBSERVING, HUNTING, CHECKING_HIDE, SABOTAGING, MANIFESTING, RETREATING }

const OBSERVE_SPEED := 2.2
const HUNT_SPEED := 4.2
const OBSERVE_DISTANCE := 12.0
const MANIFEST_DURATION := 4.0
const RETREAT_SPEED := 3.0
const NOISE_HUNT_THRESHOLD := 1.8
const FOOTSTEP_INTERVAL := 0.55

@export var patrol_points: Array[Node3D] = []

var _player: Node3D = null
var _state: State = State.DORMANT
var _patrol_index: int = 0
var _is_hallucination: bool = false
var _creature_type: StringName = &"observer"
var _manifest_timer: float = 0.0
var _observe_timer: float = 0.0
var _target_hide_spot: StringName = &""
var _sabotage_target: Node = null
var _footstep_timer: float = 0.0
var _ambient_timer: float = 0.0
var _scream_cooldown: float = 0.0
var _was_hunting: bool = false

@onready var _mesh: MeshInstance3D = $MeshInstance3D
@onready var _glow: OmniLight3D = $GlowLight
@onready var _sfx: AudioStreamPlayer3D = $MonsterSFX
@onready var _ambience: AudioStreamPlayer3D = $MonsterAmbience


func _ready() -> void:
	visible = false
	if _glow:
		_glow.visible = false
	_setup_visual()
	_setup_audio()
	add_to_group("entity")
	EventBus.entity_spawned.connect(_on_spawned)
	EventBus.entity_despawned.connect(_on_despawned)
	EventBus.entity_sabotage.connect(_on_sabotage_request)
	EventBus.player_hiding_changed.connect(_on_player_hiding)
	EventBus.player_noise_changed.connect(_on_player_noise)
	EventBus.flashlight_toggled.connect(_on_flashlight)
	EventBus.creature_type_changed.connect(_on_creature_type_changed)


func _setup_visual() -> void:
	if _mesh:
		_mesh.visible = false
	if has_node("MonsterVisual"):
		return
	var visual := Node3D.new()
	visual.name = "MonsterVisual"
	visual.set_script(load("res://scripts/horror/monster_visual.gd"))
	add_child(visual)


func _setup_audio() -> void:
	if _sfx == null:
		_sfx = AudioStreamPlayer3D.new()
		_sfx.name = "MonsterSFX"
		add_child(_sfx)
	_sfx.max_distance = 35.0
	_sfx.unit_size = 8.0
	_sfx.bus = &"Master"
	if _ambience == null:
		_ambience = AudioStreamPlayer3D.new()
		_ambience.name = "MonsterAmbience"
		add_child(_ambience)
	_ambience.max_distance = 28.0
	_ambience.unit_size = 10.0
	_ambience.volume_db = -8.0


func _physics_process(delta: float) -> void:
	if _state == State.DORMANT:
		return

	_find_player()
	_manifest_timer -= delta
	_observe_timer -= delta
	_scream_cooldown = maxf(0.0, _scream_cooldown - delta)
	_update_audio(delta)
	_face_player(delta)

	var hunting_now := _state == State.HUNTING
	if hunting_now and not _was_hunting:
		_scream()
	_was_hunting = hunting_now

	match _state:
		State.OBSERVING:
			_do_observe(delta)
		State.HUNTING:
			_do_hunt(delta)
		State.CHECKING_HIDE:
			_do_check_hide(delta)
		State.SABOTAGING:
			_do_sabotage(delta)
		State.MANIFESTING:
			_do_manifest(delta)
		State.RETREATING:
			_do_retreat(delta)


func _face_player(delta: float) -> void:
	if _player == null:
		return
	var target := _player.global_position
	target.y = global_position.y
	if global_position.distance_to(target) < 0.1:
		return
	var dir := (target - global_position).normalized()
	var target_basis := Basis.looking_at(dir, Vector3.UP)
	global_transform.basis = global_transform.basis.slerp(target_basis, clampf(6.0 * delta, 0.0, 1.0))


func _update_audio(delta: float) -> void:
	_footstep_timer -= delta
	_ambient_timer -= delta
	var moving := velocity.length() > 0.4
	if moving and _footstep_timer <= 0.0:
		_footstep_timer = FOOTSTEP_INTERVAL if _state != State.HUNTING else 0.35
		_play_sfx(SoundLibrary.pick_random(SoundLibrary.FOOTSTEPS), -2.0, 0.85 + randf() * 0.3)
	if _ambient_timer <= 0.0:
		_ambient_timer = randf_range(5.0, 10.0)
		if randf() < 0.45:
			_scream()
		else:
			_play_sfx(SoundLibrary.pick_random(SoundLibrary.WHISPERS), -6.0, 0.6 + randf() * 0.5)


func _play_sfx(path: String, volume_db: float = -4.0, pitch: float = 1.0) -> void:
	if _sfx == null:
		return
	var stream := SoundLibrary.load_stream(path)
	if stream == null:
		return
	_sfx.stream = stream
	_sfx.volume_db = volume_db
	_sfx.pitch_scale = pitch
	_sfx.play()


func _scream(force: bool = false) -> void:
	if not force and _scream_cooldown > 0.0:
		return
	_scream_cooldown = randf_range(4.0, 8.0)
	var path := SoundLibrary.pick_random(SoundLibrary.SCREAMS)
	# Slightly lower pitch = more inhuman
	_play_sfx(path, 2.0, 0.75 + randf() * 0.25)


func _play_ambience_loop() -> void:
	if _ambience == null:
		return
	var stream := SoundLibrary.load_stream(SoundLibrary.AMBIENT)
	if stream == null:
		return
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	_ambience.stream = stream
	_ambience.pitch_scale = 0.55
	_ambience.volume_db = -10.0
	_ambience.play()


func _stop_ambience() -> void:
	if _ambience and _ambience.playing:
		_ambience.stop()


func _on_creature_type_changed(creature_type: StringName) -> void:
	_creature_type = creature_type
	_update_appearance()


func _on_spawned(is_hallucination: bool, creature_type: StringName) -> void:
	_is_hallucination = is_hallucination
	_creature_type = creature_type
	visible = true
	if _glow:
		_glow.visible = true
	_manifest_timer = MANIFEST_DURATION
	_update_appearance()
	_play_ambience_loop()
	_scream(true)

	if is_hallucination:
		_state = State.MANIFESTING
		global_position = _get_glimpse_position()
	elif creature_type == &"hunter":
		_state = State.HUNTING
		global_position = MonsterMemory.get_noise_hotspot() if MonsterMemory.get_noise_hotspot() != Vector3.ZERO else _get_spawn_position()
	elif MonsterMemory.should_check_last_hiding_spot():
		_state = State.CHECKING_HIDE
		_target_hide_spot = MonsterMemory.last_hiding_spot
		global_position = _get_hiding_spot_position(_target_hide_spot)
	else:
		_state = State.OBSERVING
		global_position = _get_spawn_position()
		_observe_timer = randf_range(20.0, 50.0)

	# Avoid double scream on the first hunt frame after spawn
	_was_hunting = _state == State.HUNTING

	# Keep on floor
	global_position.y = 0.0


func _on_despawned() -> void:
	visible = false
	if _glow:
		_glow.visible = false
	_stop_ambience()
	_state = State.DORMANT
	_is_hallucination = false


func _on_sabotage_request(type: StringName, _target: Node) -> void:
	if _state == State.DORMANT:
		_state = State.SABOTAGING
		visible = true
		if _glow:
			_glow.visible = true
		_sabotage_target = _find_sabotage_target(type)
		global_position = _get_spawn_position()


func _on_player_hiding(is_hiding: bool) -> void:
	if is_hiding:
		if _state == State.OBSERVING or _state == State.HUNTING:
			if MonsterMemory.should_check_last_hiding_spot():
				_state = State.CHECKING_HIDE
				_target_hide_spot = MonsterMemory.last_hiding_spot
			else:
				_state = State.RETREATING


func _on_player_noise(level: float) -> void:
	if _state != State.DORMANT and _player:
		MonsterMemory.record_noise(_player.global_position, level)
	if CreatureManager.reacts_to_noise() and level >= NOISE_HUNT_THRESHOLD and _state == State.OBSERVING:
		_state = State.HUNTING
		_play_sfx(SoundLibrary.pick_random(SoundLibrary.DOOR_SLAMS), -4.0, 0.5)


func _on_flashlight(is_on: bool) -> void:
	if is_on and CreatureManager.reacts_to_light() and _state == State.OBSERVING:
		MonsterMemory.record_flashlight_sighting()
		if randf() < 0.45:
			_state = State.MANIFESTING
			global_position = _get_glimpse_position()
			_manifest_timer = 2.0
			_play_sfx(SoundLibrary.pick_random(SoundLibrary.WHISPERS), 2.0, 0.4)


func _do_observe(_delta: float) -> void:
	if not _player:
		_state = State.RETREATING
		return

	var dist := global_position.distance_to(_player.global_position)
	var away := (_player.global_position - global_position).normalized()
	var target_pos := _player.global_position - away * OBSERVE_DISTANCE * 0.65
	target_pos.y = 0.0

	if dist < OBSERVE_DISTANCE * 0.35:
		_state = State.HUNTING
		return

	velocity = (target_pos - global_position).normalized() * OBSERVE_SPEED
	move_and_slide()

	if _observe_timer <= 0.0:
		# Chance to hunt instead of leaving
		if randf() < 0.4:
			_state = State.HUNTING
			_observe_timer = 12.0
		else:
			_state = State.RETREATING


func _do_hunt(_delta: float) -> void:
	if not _player or _is_hallucination:
		_state = State.RETREATING
		return

	if _player.has_method("is_hiding") and _player.is_hiding():
		_state = State.CHECKING_HIDE
		return

	var direction := (_player.global_position - global_position)
	direction.y = 0.0
	if direction.length() > 0.01:
		velocity = direction.normalized() * HUNT_SPEED
	move_and_slide()

	if CreatureManager.should_attack() and global_position.distance_to(_player.global_position) < 2.2:
		if _player.has_method("take_damage"):
			_player.take_damage(20.0)
		_scream(true)
		_state = State.RETREATING


func _do_check_hide(_delta: float) -> void:
	var target_pos := _get_hiding_spot_position(_target_hide_spot)
	if target_pos == Vector3.ZERO:
		_state = State.RETREATING
		return

	velocity = (target_pos - global_position).normalized() * OBSERVE_SPEED
	move_and_slide()

	if global_position.distance_to(target_pos) < 2.0:
		EventBus.paranormal_event.emit(&"hide_spot_checked", {"spot_id": _target_hide_spot})
		if _player and _player.has_method("is_hiding") and _player.is_hiding():
			if CreatureManager.should_attack():
				if _player.has_method("take_damage"):
					_player.take_damage(30.0)
		_state = State.RETREATING


func _do_sabotage(_delta: float) -> void:
	if _sabotage_target and is_instance_valid(_sabotage_target):
		velocity = (_sabotage_target.global_position - global_position).normalized() * OBSERVE_SPEED
		move_and_slide()
		if global_position.distance_to(_sabotage_target.global_position) < 2.0:
			if _sabotage_target.has_method("sabotage"):
				_sabotage_target.sabotage()
			_state = State.RETREATING
	else:
		_state = State.RETREATING


func _do_manifest(_delta: float) -> void:
	velocity = Vector3.ZERO
	if _manifest_timer <= 0.0:
		if _is_hallucination:
			_state = State.RETREATING
		else:
			_state = State.OBSERVING
			_observe_timer = randf_range(10.0, 25.0)


func _do_retreat(_delta: float) -> void:
	if patrol_points.is_empty():
		_finish()
		return
	var target: Vector3 = patrol_points[_patrol_index % patrol_points.size()].global_position
	velocity = (target - global_position).normalized() * RETREAT_SPEED
	move_and_slide()
	if global_position.distance_to(target) < 2.0:
		_finish()


func _finish() -> void:
	visible = false
	if _glow:
		_glow.visible = false
	_stop_ambience()
	_state = State.DORMANT
	HorrorSystem.end_manifestation()


func _find_player() -> void:
	if _player and is_instance_valid(_player):
		return
	var players := get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		_player = players[0]


func _get_spawn_position() -> Vector3:
	var ambush := MonsterMemory.get_ambush_position()
	if ambush != Vector3.ZERO:
		ambush.y = 0.0
		return ambush
	if not patrol_points.is_empty():
		var p: Vector3 = patrol_points[randi() % patrol_points.size()].global_position
		p.y = 0.0
		return p
	if _player:
		var behind := _player.global_position - _player.global_basis.z * 8.0
		behind.y = 0.0
		return behind
	return Vector3(0, 0, -8)


func _get_glimpse_position() -> Vector3:
	if not _player:
		return _get_spawn_position()
	var offset := _player.global_basis.x * randf_range(-4.0, 4.0)
	var pos := _player.global_position + offset + _player.global_basis.z * randf_range(-9.0, -5.0)
	pos.y = 0.0
	return pos


func _get_hiding_spot_position(spot_id: StringName) -> Vector3:
	for spot in get_tree().get_nodes_in_group("hiding_spots"):
		if spot.get("spot_id") == spot_id:
			return spot.global_position
	return Vector3.ZERO


func _find_sabotage_target(type: StringName) -> Node:
	match type:
		&"lights_cut", &"lights_flicker":
			var lights := get_tree().get_nodes_in_group("factory_lights")
			if not lights.is_empty():
				return lights[randi() % lights.size()]
		&"door_slams":
			var doors := get_tree().get_nodes_in_group("doors")
			if not doors.is_empty():
				return doors[randi() % doors.size()]
		&"equipment_sabotage":
			var machines := get_tree().get_nodes_in_group("reactors")
			if not machines.is_empty():
				return machines[randi() % machines.size()]
	return null


func _update_appearance() -> void:
	if _glow:
		_glow.light_color = Color(0.7, 0.15, 0.1)
		_glow.light_energy = 2.0 if _creature_type == &"hunter" else 1.5
		_glow.omni_range = 5.5
		_glow.position = Vector3(0, 2.4, 0.25)

	var visual := get_node_or_null("MonsterVisual")
	if visual and _creature_type == &"crawler":
		visual.scale = Vector3(1.1, 0.55, 1.3)
		visual.position.y = 0.0
	elif visual and _creature_type == &"shadow":
		visual.scale = Vector3(0.85, 1.35, 0.85)
	elif visual:
		visual.scale = Vector3.ONE

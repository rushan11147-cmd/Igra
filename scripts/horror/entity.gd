extends CharacterBody3D
## Adaptive creature AI — behavior depends on type and monster memory.

enum State { DORMANT, OBSERVING, HUNTING, CHECKING_HIDE, SABOTAGING, MANIFESTING, RETREATING }

const OBSERVE_SPEED := 1.5
const HUNT_SPEED := 5.0
const OBSERVE_DISTANCE := 14.0
const MANIFEST_DURATION := 2.5
const RETREAT_SPEED := 3.5
const NOISE_HUNT_THRESHOLD := 2.5

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

@onready var _mesh: MeshInstance3D = $MeshInstance3D
@onready var _glow: OmniLight3D = $GlowLight


func _ready() -> void:
	visible = false
	if _glow:
		_glow.visible = false
	add_to_group("entity")
	EventBus.entity_spawned.connect(_on_spawned)
	EventBus.entity_despawned.connect(_on_despawned)
	EventBus.entity_sabotage.connect(_on_sabotage_request)
	EventBus.player_hiding_changed.connect(_on_player_hiding)
	EventBus.player_noise_changed.connect(_on_player_noise)
	EventBus.flashlight_toggled.connect(_on_flashlight)
	EventBus.creature_type_changed.connect(_on_creature_type_changed)


func _physics_process(delta: float) -> void:
	if _state == State.DORMANT:
		return

	_find_player()
	_manifest_timer -= delta
	_observe_timer -= delta

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
		_observe_timer = randf_range(15.0, 40.0)


func _on_despawned() -> void:
	visible = false
	if _glow:
		_glow.visible = false
	_state = State.DORMANT
	_is_hallucination = false


func _on_sabotage_request(type: StringName, _target: Node) -> void:
	if _state == State.DORMANT:
		_state = State.SABOTAGING
		_sabotage_target = _find_sabotage_target(type)


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


func _on_flashlight(is_on: bool) -> void:
	if is_on and CreatureManager.reacts_to_light() and _state == State.OBSERVING:
		MonsterMemory.record_flashlight_sighting()
		if randf() < 0.3:
			_state = State.MANIFESTING
			global_position = _get_glimpse_position()
			_manifest_timer = 1.0


func _do_observe(_delta: float) -> void:
	if not _player:
		_state = State.RETREATING
		return

	var dist := global_position.distance_to(_player.global_position)
	var target_pos := _player.global_position + (_player.global_position - global_position).normalized() * OBSERVE_DISTANCE

	if dist < OBSERVE_DISTANCE * 0.4:
		_state = State.RETREATING
		return

	velocity = (target_pos - global_position).normalized() * OBSERVE_SPEED
	move_and_slide()

	if _observe_timer <= 0.0:
		_state = State.RETREATING


func _do_hunt(_delta: float) -> void:
	if not _player or _is_hallucination:
		_state = State.RETREATING
		return

	if _player.has_method("is_hiding") and _player.is_hiding():
		_state = State.CHECKING_HIDE
		return

	var direction := (_player.global_position - global_position).normalized()
	velocity = direction * HUNT_SPEED
	move_and_slide()

	if CreatureManager.should_attack() and global_position.distance_to(_player.global_position) < 2.0:
		if _player.has_method("take_damage"):
			_player.take_damage(20.0)
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
		_state = State.RETREATING


func _do_retreat(_delta: float) -> void:
	if patrol_points.is_empty():
		_finish()
		return
	var target: Vector3 = patrol_points[_patrol_index].global_position
	velocity = (target - global_position).normalized() * RETREAT_SPEED
	move_and_slide()
	if global_position.distance_to(target) < 1.5:
		_finish()


func _finish() -> void:
	visible = false
	if _glow:
		_glow.visible = false
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
		return ambush
	if not patrol_points.is_empty():
		return patrol_points[randi() % patrol_points.size()].global_position
	return global_position


func _get_glimpse_position() -> Vector3:
	if not _player:
		return _get_spawn_position()
	var offset := _player.global_basis.x * randf_range(-5.0, 5.0)
	return _player.global_position + offset + _player.global_basis.z * randf_range(-10.0, -6.0)


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
	if not _mesh:
		return
	var colors: Dictionary = {
		&"observer": Color(0.35, 0.35, 0.55),
		&"hunter": Color(0.75, 0.08, 0.08),
		&"crawler": Color(0.15, 0.55, 0.2),
		&"shadow": Color(0.25, 0.05, 0.35),
	}
	var emissions: Dictionary = {
		&"observer": Color(0.5, 0.55, 0.95),
		&"hunter": Color(1.0, 0.15, 0.1),
		&"crawler": Color(0.2, 0.95, 0.35),
		&"shadow": Color(0.55, 0.1, 0.85),
	}
	var mat := _mesh.get_active_material(0)
	if mat is StandardMaterial3D:
		var std := mat as StandardMaterial3D
		std.albedo_color = colors.get(_creature_type, Color(0.2, 0.05, 0.08))
		std.emission = emissions.get(_creature_type, Color(0.9, 0.15, 0.25))
		std.emission_energy_multiplier = 7.0 if _is_hallucination else 5.5
	if _glow:
		_glow.light_color = emissions.get(_creature_type, Color(0.9, 0.15, 0.25))
		_glow.light_energy = 5.0 if _creature_type == &"hunter" else 3.5

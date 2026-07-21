extends CharacterBody3D
## First-person controller: Alex, night shift operator at Factory 17.

const WALK_SPEED := 4.0
const SPRINT_SPEED := 7.0
const CROUCH_SPEED := 2.0
const JUMP_VELOCITY := 4.5
const MOUSE_SENSITIVITY := 0.002
const INTERACTION_RANGE := 3.0
const STAND_HEIGHT := 1.6
const CROUCH_HEIGHT := 0.9
const PEEK_OFFSET := 0.35

# Noise levels — monster hears values above ~1.5
const NOISE_WALK := 1.0
const NOISE_SPRINT := 3.5
const NOISE_CROUCH := 0.25
const NOISE_JUMP := 5.0
const NOISE_IDLE := 0.0

@export var head: Node3D
@export var camera: Camera3D
@export var collision_shape: CollisionShape3D
@export var flashlight: SpotLight3D

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _current_interactable: Interactable = null
var _health: float = 100.0
var _is_crouching: bool = false
var _is_hiding: bool = false
var _peek_offset: float = 0.0
var _noise_level: float = 0.0
var _hiding_spot: HidingSpot = null


func _ready() -> void:
	add_to_group("player")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if not head:
		head = $Head
	if not camera:
		camera = $Head/Camera3D
	if not collision_shape:
		collision_shape = $CollisionShape3D
	if not flashlight:
		flashlight = $Head/Camera3D/Flashlight


func _unhandled_input(event: InputEvent) -> void:
	if _is_hiding:
		if event.is_action_pressed("interact"):
			_exit_hiding()
		return

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		head.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		head.rotation.x = clampf(head.rotation.x, deg_to_rad(-89.0), deg_to_rad(89.0))

	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	if event.is_action_pressed("tablet"):
		EventBus.tablet_toggle_requested.emit()

	if event.is_action_pressed("radio"):
		RadioPartner.player_responds()

	if event.is_action_pressed("hall8_choice_1"):
		_try_hall8_choice(&"open")
	if event.is_action_pressed("hall8_choice_2"):
		_try_hall8_choice(&"leave")
	if event.is_action_pressed("hall8_choice_3"):
		_try_hall8_choice(&"cut_power")
	if event.is_action_pressed("hall8_choice_4"):
		_try_hall8_choice(&"peek")

	if event.is_action_pressed("flashlight"):
		InventoryManager.toggle_flashlight()
		if flashlight:
			flashlight.visible = InventoryManager.flashlight_on
		EventBus.flashlight_toggled.emit(InventoryManager.flashlight_on)

	if event.is_action_pressed("interact") and _current_interactable:
		_current_interactable.interact(self)

	if _current_interactable is ChemicalMixer:
		if event.is_action_pressed("adjust_ratio_up"):
			(_current_interactable as ChemicalMixer).adjust_ratio(0.05)
		if event.is_action_pressed("adjust_ratio_down"):
			(_current_interactable as ChemicalMixer).adjust_ratio(-0.05)


func _physics_process(delta: float) -> void:
	if _is_hiding:
		return

	_update_crouch(delta)
	_update_peek(delta)
	_update_noise()

	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_action_just_pressed("jump") and is_on_floor() and not _is_crouching:
		velocity.y = JUMP_VELOCITY
		_emit_noise(NOISE_JUMP)

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()

	var speed := WALK_SPEED
	if _is_crouching:
		speed = CROUCH_SPEED
	elif Input.is_action_pressed("sprint"):
		speed = SPRINT_SPEED

	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		MonsterMemory.record_noise(global_position, _noise_level)
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed)
		velocity.z = move_toward(velocity.z, 0.0, speed)

	move_and_slide()
	_scan_interactables()

	if flashlight:
		flashlight.visible = InventoryManager.flashlight_on and InventoryManager.flashlight_battery > 0.0


func _update_crouch(_delta: float) -> void:
	var want_crouch := Input.is_action_pressed("crouch")
	if want_crouch != _is_crouching:
		_is_crouching = want_crouch
		var target_y := CROUCH_HEIGHT if _is_crouching else STAND_HEIGHT
		head.position.y = target_y
		if collision_shape and collision_shape.shape is CapsuleShape3D:
			(collision_shape.shape as CapsuleShape3D).height = 1.8 if not _is_crouching else 1.0


func _update_peek(_delta: float) -> void:
	var target_peek := 0.0
	if Input.is_action_pressed("peek_left"):
		target_peek = -PEEK_OFFSET
	elif Input.is_action_pressed("peek_right"):
		target_peek = PEEK_OFFSET

	_peek_offset = move_toward(_peek_offset, target_peek, PEEK_OFFSET * 8.0 * _delta)
	head.position.x = _peek_offset
	EventBus.player_peek_changed.emit(_peek_offset)


func _update_noise() -> void:
	var noise := NOISE_IDLE
	if velocity.length() > 0.5:
		if _is_crouching:
			noise = NOISE_CROUCH
		elif Input.is_action_pressed("sprint"):
			noise = NOISE_SPRINT
		else:
			noise = NOISE_WALK
	_emit_noise(noise)


func _emit_noise(level: float) -> void:
	if not is_equal_approx(_noise_level, level):
		_noise_level = level
		EventBus.player_noise_changed.emit(level)


func enter_hiding(spot: HidingSpot) -> void:
	_is_hiding = true
	_hiding_spot = spot
	visible = false
	set_collision_layer_value(2, false)
	EventBus.player_hiding_changed.emit(true)


func _exit_hiding() -> void:
	if _hiding_spot:
		_hiding_spot.release_player()
	_hiding_spot = null
	_is_hiding = false
	visible = true
	set_collision_layer_value(2, true)
	EventBus.player_hiding_changed.emit(false)


func _scan_interactables() -> void:
	var space := get_world_3d().direct_space_state
	var from := camera.global_position
	var to := from - camera.global_basis.z * INTERACTION_RANGE
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 4
	query.collide_with_areas = true

	var result := space.intersect_ray(query)
	var found: Interactable = null

	if result:
		var collider: Object = result.collider
		if collider is Interactable:
			found = collider
		elif collider.get_parent() is Interactable:
			found = collider.get_parent()

	_current_interactable = found


func get_interaction_prompt() -> String:
	return _current_interactable.get_prompt() if _current_interactable else ""


func get_noise_level() -> float:
	return _noise_level if not _is_hiding else NOISE_IDLE


func is_hiding() -> bool:
	return _is_hiding


func take_damage(amount: float) -> void:
	_health -= amount
	EventBus.player_damaged.emit(amount)
	if _health <= 0.0:
		EventBus.player_died.emit()


func _try_hall8_choice(choice: StringName) -> void:
	if FactoryRules.hall8_state != &"voice":
		return
	FactoryRules.make_hall8_choice(choice)

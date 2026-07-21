extends Node3D
## Root scene controller — wires factory, player, HUD, and shift lifecycle.

@onready var _player: CharacterBody3D = $Player
@onready var _hud: Control = $HUD
@onready var _shift_report: Control = $ShiftReport
@onready var _paranormal: Node = $ParanormalHandler
@onready var _entity: CharacterBody3D = $Entity


func _ready() -> void:
	_hud.set_player(_player)
	_shift_report.continue_pressed.connect(_on_continue_shift)

	_register_factory_nodes()
	call_deferred("_begin_game")


func _begin_game() -> void:
	GameManager.start_new_game()


func _register_factory_nodes() -> void:
	var lights: Array[Light3D] = []
	for node in get_tree().get_nodes_in_group("factory_lights"):
		if node is Light3D:
			lights.append(node)

	# Auto-register all omni lights in factory
	for child in $Factory.get_children():
		if child is OmniLight3D:
			child.add_to_group("factory_lights")
			lights.append(child)
	_register_interior_lights(lights)

	var cameras: Array[Node3D] = []
	for node in get_tree().get_nodes_in_group("security_cameras"):
		cameras.append(node)

	_paranormal.register_lights(lights)
	_paranormal.register_cameras(cameras)

	# Wire entity patrol points
	var points: Array[Node3D] = []
	for child in $PatrolPoints.get_children():
		points.append(child)
	_entity.patrol_points = points


func _register_interior_lights(lights: Array[Light3D]) -> void:
	var interior := $Factory.get_node_or_null("FactoryInterior")
	if interior == null:
		return
	for node in interior.get_children():
		if node is OmniLight3D:
			node.add_to_group("factory_lights")
			lights.append(node)


func _on_continue_shift() -> void:
	if GameManager.current_night > GameManager.MAX_NIGHTS:
		# Game complete — restart for now
		GameManager.start_new_game()
	else:
		GameManager.start_shift()

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
	GameManager.consume_boot_action()


func _register_factory_nodes() -> void:
	var lights: Array[Light3D] = []
	for node in get_tree().get_nodes_in_group("factory_lights"):
		if node is Light3D:
			lights.append(node)

	for child in $Factory.get_children():
		if child is OmniLight3D:
			child.add_to_group("factory_lights")
			lights.append(child)

	var cameras: Array[Node3D] = []
	for node in get_tree().get_nodes_in_group("security_cameras"):
		cameras.append(node)

	_paranormal.register_lights(lights)
	_paranormal.register_cameras(cameras)

	var points: Array[Node3D] = []
	for child in $PatrolPoints.get_children():
		points.append(child)
	_entity.patrol_points = points

	call_deferred("_snap_patrol_to_markers")


func _snap_patrol_to_markers() -> void:
	var fmap := $Factory.get_node_or_null("FactoryMap")
	if fmap == null or not fmap.has_method("find_marker"):
		return
	var mapping := {
		"Patrol1": "Patrol1",
		"Patrol2": "Patrol2",
		"Patrol3": "Patrol3",
		"Patrol4": "Patrol4",
	}
	for child in $PatrolPoints.get_children():
		var key := String(child.name)
		if not mapping.has(key):
			continue
		var marker: Marker3D = fmap.find_marker(mapping[key])
		if marker:
			child.global_position = marker.global_position


func _on_continue_shift() -> void:
	if GameManager.current_night > GameManager.MAX_NIGHTS:
		# Game complete — restart for now
		GameManager.start_new_game()
	else:
		GameManager.start_shift()

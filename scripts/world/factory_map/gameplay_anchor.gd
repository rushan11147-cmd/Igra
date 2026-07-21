extends Node3D
## Moves this node (or a target) onto a named GameplayMarker from FactoryMap.

@export var marker_name: String = ""
@export var target_path: NodePath = NodePath("..")
@export var height_offset: float = 0.35


func _ready() -> void:
	call_deferred("_snap")


func _snap() -> void:
	if marker_name.is_empty():
		return
	# Wait until FactoryMap geometry is in the physics world.
	await get_tree().physics_frame
	await get_tree().physics_frame

	var factory_map := _find_factory_map()
	if factory_map == null:
		return
	var marker: Marker3D = null
	if factory_map.has_method("find_marker"):
		marker = factory_map.find_marker(marker_name)
	if marker == null:
		marker = get_tree().root.find_child(marker_name, true, false) as Marker3D
	if marker == null:
		return

	var target := get_node_or_null(target_path) as Node3D
	if target == null:
		target = get_parent() as Node3D
	if target == null:
		return

	var pos := marker.global_position
	pos.y += height_offset
	target.global_position = pos
	if target is CharacterBody3D:
		var body := target as CharacterBody3D
		body.velocity = Vector3.ZERO
		body.floor_snap_length = 0.4
		# Force a grounded check after teleport.
		body.move_and_slide()


func _find_factory_map() -> Node:
	var n: Node = self
	while n:
		if n.is_in_group("factory_map") or n.name == "FactoryMap":
			return n
		var scr: Script = n.get_script() as Script
		if scr != null and scr.resource_path.ends_with("factory_map.gd"):
			return n
		n = n.get_parent()
	return get_tree().get_first_node_in_group("factory_map")

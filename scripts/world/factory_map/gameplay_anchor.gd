extends Node3D
## Moves this node (or a target) onto a named GameplayMarker from FactoryMap.

@export var marker_name: String = ""
@export var target_path: NodePath = NodePath("..")


func _ready() -> void:
	call_deferred("_snap")


func _snap() -> void:
	if marker_name.is_empty():
		return
	var factory_map := _find_factory_map()
	if factory_map == null:
		return
	var marker: Marker3D = null
	if factory_map.has_method("find_marker"):
		marker = factory_map.find_marker(marker_name)
	if marker == null:
		return
	var target := get_node_or_null(target_path) as Node3D
	if target == null:
		target = get_parent() as Node3D
	if target == null:
		return
	target.global_position = marker.global_position


func _find_factory_map() -> Node:
	var n: Node = self
	while n:
		if n.name == "FactoryMap":
			return n
		var scr: Script = n.get_script() as Script
		if scr != null and scr.resource_path.ends_with("factory_map.gd"):
			return n
		n = n.get_parent()
	return get_tree().get_first_node_in_group("factory_map")

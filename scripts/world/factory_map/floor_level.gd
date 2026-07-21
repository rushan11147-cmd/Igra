extends Node3D
## Builds one factory level from layout data.

const IndustrialPaletteScript = preload("res://scripts/world/factory_map/industrial_palette.gd")
const RoomBuilderScript = preload("res://scripts/world/factory_map/room_builder.gd")
const PropKitScript = preload("res://scripts/world/factory_map/prop_kit.gd")
const LayoutDataScript = preload("res://scripts/world/factory_map/layout_data.gd")

@export var level_id: StringName = &"floor_01"

var _palette
var _builder
var _props
var _markers_root: Node3D


func _ready() -> void:
	_palette = IndustrialPaletteScript.new()
	_builder = RoomBuilderScript.new()
	_props = PropKitScript.new(_palette, _builder)
	_markers_root = Node3D.new()
	_markers_root.name = "GameplayMarkers"
	add_child(_markers_root)
	_build_level()


func _build_level() -> void:
	var layout: Dictionary = LayoutDataScript.get_layout(level_id)
	var y := 0.0
	var build_ceiling: bool = bool(layout.get("build_ceiling", true))
	var rooms: Array = layout.get("rooms", [])
	var world_openings: Array = _builder.collect_world_openings(rooms)

	# Open vertical shafts: no footprint collision through stairwells / elevators.
	var shaft_holes: Array = []
	var shaft_edges: Dictionary = {}
	for room_data in rooms:
		var role: StringName = room_data["role"]
		if role != &"stairwell" and role != &"elevator":
			continue
		var r: Rect2 = room_data["rect"]
		shaft_holes.append(r)
		shaft_edges["x:%.3f" % r.position.x] = true
		shaft_edges["x:%.3f" % (r.position.x + r.size.x)] = true
		shaft_edges["z:%.3f" % r.position.y] = true
		shaft_edges["z:%.3f" % (r.position.y + r.size.y)] = true

	# Collision only — visible floor comes from room slabs (no z-fight flicker).
	if shaft_holes.is_empty():
		_builder.add_floor_collision(self, LayoutDataScript.FOOTPRINT, y)
	else:
		_builder.add_floor_collision_with_holes(self, LayoutDataScript.FOOTPRINT, y, shaft_holes)

	for room_data in rooms:
		var rect: Rect2 = room_data["rect"]
		var role: StringName = room_data["role"]
		var openings: Array = room_data.get("openings", [])
		var wall_mat = _palette.wall_for_role(role)
		var floor_mat = _palette.floor_for_role(role)
		var is_shaft := role == &"stairwell" or role == &"elevator"
		var room_root := Node3D.new()
		room_root.name = String(room_data.get("id", "room"))
		add_child(room_root)

		if is_shaft:
			# No floor, ceiling, or walls — shaft is empty. Stairs come from VerticalLinks.
			_props.fill_room(room_root, rect, y, role)
		else:
			var fixed_openings := _mark_shaft_border_openings(rect, openings, shaft_edges)
			_builder.add_room_shell(
				room_root,
				rect,
				y,
				wall_mat,
				floor_mat,
				_palette.concrete_dark,
				fixed_openings,
				build_ceiling and role != &"roof",
				world_openings,
				true
			)
			_props.fill_room(room_root, rect, y, role)
			if role == &"glass_bridge":
				_add_glass_panels(room_root, rect, y)

	var markers: Dictionary = layout.get("markers", {})
	for marker_name in markers:
		var m := Marker3D.new()
		m.name = String(marker_name)
		m.position = markers[marker_name]
		_markers_root.add_child(m)


## Openings on walls shared with a stair/elevator shaft must be full-height
## (otherwise door headers form horizontal partitions across the shaft).
func _mark_shaft_border_openings(rect: Rect2, openings: Array, shaft_edges: Dictionary) -> Array:
	var x0 := rect.position.x
	var z0 := rect.position.y
	var x1 := x0 + rect.size.x
	var z1 := z0 + rect.size.y
	var result: Array = []
	for item in openings:
		var copy: Dictionary = item.duplicate()
		var wall: StringName = StringName(copy.get("wall", &""))
		var on_shaft := false
		match wall:
			&"w":
				on_shaft = shaft_edges.has("x:%.3f" % x0)
			&"e":
				on_shaft = shaft_edges.has("x:%.3f" % x1)
			&"s":
				on_shaft = shaft_edges.has("z:%.3f" % z0)
			&"n":
				on_shaft = shaft_edges.has("z:%.3f" % z1)
		if on_shaft:
			copy["full_height"] = true
			copy["w"] = maxf(float(copy.get("w", 2.8)), 3.2)
		result.append(copy)
	return result


func _add_glass_panels(parent: Node3D, rect: Rect2, y: float) -> void:
	var cx := rect.position.x + rect.size.x * 0.5
	var cz := rect.position.y + rect.size.y * 0.5
	_builder.add_box(
		parent,
		Vector3(cx, y + 1.6, cz - rect.size.y * 0.48),
		Vector3(rect.size.x * 0.9, 2.8, 0.08),
		_palette.glass,
		false
	)
	_builder.add_box(
		parent,
		Vector3(cx, y + 1.6, cz + rect.size.y * 0.48),
		Vector3(rect.size.x * 0.9, 2.8, 0.08),
		_palette.glass,
		false
	)


func get_marker(marker_name: String) -> Marker3D:
	return _markers_root.get_node_or_null(marker_name) as Marker3D

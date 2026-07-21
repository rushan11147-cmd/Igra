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
	var shaft_holes: Array = []

	for room_data in rooms:
		var role: StringName = room_data["role"]
		# Footprint collision must not seal stair/elevator shafts.
		if role == &"elevator" or role == &"stairwell":
			shaft_holes.append(room_data["rect"])

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
		var is_elevator := role == &"elevator"
		var is_stairwell := role == &"stairwell"
		var room_root := Node3D.new()
		room_root.name = String(room_data.get("id", "room"))
		add_child(room_root)
		_builder.add_room_shell(
			room_root,
			rect,
			y,
			wall_mat,
			floor_mat,
			_palette.concrete_dark,
			openings,
			build_ceiling and role != &"roof" and not is_elevator and not is_stairwell,
			world_openings,
			not is_elevator and not is_stairwell
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

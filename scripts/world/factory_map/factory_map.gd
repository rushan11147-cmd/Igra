extends Node3D
## Root factory map: loads all floor scenes, vertical links, vents, navigation.

const IndustrialPaletteScript = preload("res://scripts/world/factory_map/industrial_palette.gd")
const RoomBuilderScript = preload("res://scripts/world/factory_map/room_builder.gd")
const LayoutDataScript = preload("res://scripts/world/factory_map/layout_data.gd")
const VerticalLinksScript = preload("res://scripts/world/factory_map/vertical_links.gd")
const VentNetworkScript = preload("res://scripts/world/factory_map/vent_network.gd")
const FactoryAreaScript = preload("res://scripts/world/factory_area.gd")

const LEVEL_SCENES: Array[StringName] = [
	&"basement_02",
	&"basement_01",
	&"floor_01",
	&"floor_02",
	&"floor_03",
	&"floor_04",
	&"roof",
]

var _palette
var _builder
var _levels: Dictionary = {}


func _ready() -> void:
	_palette = IndustrialPaletteScript.new()
	_builder = RoomBuilderScript.new()
	_load_levels()
	VerticalLinksScript.build(self, _palette, _builder)
	VentNetworkScript.build(self, _palette, _builder)
	_build_navigation()
	_register_area_nodes()


func _load_levels() -> void:
	var container := Node3D.new()
	container.name = "Levels"
	add_child(container)
	for level_id in LEVEL_SCENES:
		var path: String = LayoutDataScript.scene_path(level_id)
		if not ResourceLoader.exists(path):
			push_error("Missing floor scene: %s" % path)
			continue
		var packed: PackedScene = load(path)
		var level: Node3D = packed.instantiate() as Node3D
		level.name = String(level_id)
		level.position = Vector3(0, LayoutDataScript.level_y(level_id), 0)
		container.add_child(level)
		_levels[level_id] = level


func get_level(level_id: StringName) -> Node3D:
	return _levels.get(level_id) as Node3D


func find_marker(marker_name: String) -> Marker3D:
	var floor01: Node = _levels.get(&"floor_01")
	if floor01 and floor01.has_method("get_marker"):
		return floor01.get_marker(marker_name)
	if floor01:
		return floor01.find_child(marker_name, true, false) as Marker3D
	return null


func _build_navigation() -> void:
	var region := NavigationRegion3D.new()
	region.name = "NavigationRegion3D"
	var mesh := NavigationMesh.new()
	mesh.cell_size = 0.25
	mesh.cell_height = 0.25
	mesh.agent_height = 1.8
	mesh.agent_radius = 0.4
	mesh.agent_max_climb = 0.4
	mesh.agent_max_slope = 45.0
	region.navigation_mesh = mesh
	add_child(region)
	call_deferred("_bake_navigation", region)


func _bake_navigation(region: NavigationRegion3D) -> void:
	if region == null or region.navigation_mesh == null:
		return
	region.bake_navigation_mesh(false)


func _register_area_nodes() -> void:
	var area_map := {
		&"hall_a": Vector3(0, 0, -20),
		&"hall_b": Vector3(-4, 0, -24),
		&"warehouse": Vector3(28, 0, 0),
		&"ventilation": Vector3(-44, 0, 20),
		&"basement": Vector3(0, -8, 0),
		&"basement_1": Vector3(0, -8, -10),
		&"basement_2": Vector3(0, -16, 0),
		&"floor2": Vector3(0, 5, 0),
		&"floor3": Vector3(0, 10, 0),
		&"floor4": Vector3(0, 15, 0),
		&"roof": Vector3(0, 20, 0),
		&"director_office": Vector3(-30, 10, -20),
	}
	for area_id in area_map:
		var node := Node3D.new()
		node.name = "Area_%s" % String(area_id)
		node.position = area_map[area_id]
		node.set_script(FactoryAreaScript)
		node.set("area_id", area_id)
		node.set("locked_visible", true)
		add_child(node)

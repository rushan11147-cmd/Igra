extends Node3D
## Multi-room factory interior: walls, ceilings, doors, room lights.
## Rooms: Entrance, Production, Warehouse, Office, Utility, Hall8.

const WALL_H := 4.5
const WALL_T := 0.3
const CEIL_T := 0.2
const DOOR_W := 1.6
const DOOR_H := 2.4

var _wall_mat: StandardMaterial3D
var _wall_alt_mat: StandardMaterial3D
var _floor_mat: StandardMaterial3D
var _ceil_mat: StandardMaterial3D
var _door_mat: StandardMaterial3D


func _ready() -> void:
	_build_materials()
	_build_rooms()
	_build_doors()
	_build_lights()


func _build_materials() -> void:
	_wall_mat = _make_pbr(WarehouseCatalog.MAT_WALL, Color(0.25, 0.25, 0.28), 4.0)
	_wall_alt_mat = _make_pbr(WarehouseCatalog.MAT_WALL_ALT, Color(0.2, 0.22, 0.24), 3.0)
	_floor_mat = _make_pbr(WarehouseCatalog.MAT_FLOOR, Color(0.18, 0.17, 0.16), 6.0)
	_ceil_mat = _make_pbr(WarehouseCatalog.MAT_DIRTY, Color(0.1, 0.1, 0.11), 2.0)
	_door_mat = StandardMaterial3D.new()
	_door_mat.albedo_color = Color(0.22, 0.18, 0.14)
	_door_mat.metallic = 0.65
	_door_mat.roughness = 0.4
	_door_mat.emission_enabled = true
	_door_mat.emission = Color(0.15, 0.05, 0.02)
	_door_mat.emission_energy_multiplier = 0.4


func _make_pbr(asset_id: String, fallback: Color, uv_scale: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = fallback
	mat.roughness = 0.85
	mat.uv1_scale = Vector3(uv_scale, uv_scale, uv_scale)
	var albedo := WarehouseCatalog.basecolor_path(asset_id)
	if albedo != "":
		mat.albedo_texture = load(albedo)
		mat.albedo_color = Color.WHITE
	var normal := WarehouseCatalog.normal_path(asset_id)
	if normal != "":
		mat.normal_enabled = true
		mat.normal_texture = load(normal)
		mat.normal_scale = 1.0
	var rough := WarehouseCatalog.roughness_path(asset_id)
	if rough != "":
		mat.roughness_texture = load(rough)
	return mat


func _build_rooms() -> void:
	# Outer shell — large factory footprint
	_rect_room(Rect2(-20, -16, 40, 32), true)

	# Internal partitions (with door gaps handled by door builder)
	# Production | Warehouse (x = 10)
	_wall_segment(Vector3(10, WALL_H * 0.5, -8), Vector3(WALL_T, WALL_H, 8), _wall_mat)  # north of door
	_wall_segment(Vector3(10, WALL_H * 0.5, 8), Vector3(WALL_T, WALL_H, 8), _wall_mat)   # south of door
	# gap at z≈0 between them for door

	# Production | Office (x = -10)
	_wall_segment(Vector3(-10, WALL_H * 0.5, -8), Vector3(WALL_T, WALL_H, 8), _wall_alt_mat)
	_wall_segment(Vector3(-10, WALL_H * 0.5, 8), Vector3(WALL_T, WALL_H, 8), _wall_alt_mat)

	# Production | Utility (z = -6) — north wall with gap
	_wall_segment(Vector3(-5, WALL_H * 0.5, -6), Vector3(8, WALL_H, WALL_T), _wall_mat)
	_wall_segment(Vector3(5, WALL_H * 0.5, -6), Vector3(8, WALL_H, WALL_T), _wall_mat)

	# Hall 8 enclosure (NW corner) — gaps for locked door
	_wall_with_gap(Vector3(-15, WALL_H * 0.5, -6), Vector3(8, WALL_H, WALL_T), DOOR_W + 0.4, true, _wall_alt_mat)
	_wall_with_gap(Vector3(-10, WALL_H * 0.5, -11), Vector3(WALL_T, WALL_H, 8), DOOR_W + 0.4, false, _wall_alt_mat)

	# Floor patches per room (visual distinction)
	_floor_patch(Vector3(0, 0.01, 2), Vector3(18, 0.05, 14), _floor_mat)       # production
	_floor_patch(Vector3(15, 0.01, 0), Vector3(8, 0.05, 20), _floor_mat)       # warehouse
	_floor_patch(Vector3(-15, 0.01, 2), Vector3(8, 0.05, 12), _wall_alt_mat)  # office
	_floor_patch(Vector3(0, 0.01, -11), Vector3(18, 0.05, 8), _floor_mat)     # utility
	_floor_patch(Vector3(-15, 0.01, -11), Vector3(8, 0.05, 8), _ceil_mat)     # hall8 dirty

	# Ceilings
	_wall_segment(Vector3(0, WALL_H, 0), Vector3(40, CEIL_T, 32), _ceil_mat)


func _rect_room(rect: Rect2, with_outer: bool) -> void:
	if not with_outer:
		return
	var cx := rect.position.x + rect.size.x * 0.5
	var cz := rect.position.y + rect.size.y * 0.5
	var w := rect.size.x
	var d := rect.size.y
	# North / South walls with entrance gaps
	_wall_with_gap(Vector3(cx, WALL_H * 0.5, cz - d * 0.5), Vector3(w, WALL_H, WALL_T), DOOR_W * 1.5, true, _wall_mat)
	_wall_with_gap(Vector3(cx, WALL_H * 0.5, cz + d * 0.5), Vector3(w, WALL_H, WALL_T), DOOR_W * 1.8, true, _wall_mat)
	# East / West solid
	_wall_segment(Vector3(cx + w * 0.5, WALL_H * 0.5, cz), Vector3(WALL_T, WALL_H, d), _wall_mat)
	_wall_segment(Vector3(cx - w * 0.5, WALL_H * 0.5, cz), Vector3(WALL_T, WALL_H, d), _wall_mat)


func _wall_with_gap(pos: Vector3, size: Vector3, gap: float, gap_on_x: bool, mat: StandardMaterial3D) -> void:
	var axis_len: float = size.x if gap_on_x else size.z
	var segment := (axis_len - gap) * 0.5
	if segment < 0.4:
		_wall_segment(pos, size, mat)
		return
	if gap_on_x:
		var offset := (segment + gap) * 0.5
		_wall_segment(pos + Vector3(-offset, 0, 0), Vector3(segment, size.y, size.z), mat)
		_wall_segment(pos + Vector3(offset, 0, 0), Vector3(segment, size.y, size.z), mat)
	else:
		var z_off := (segment + gap) * 0.5
		_wall_segment(pos + Vector3(0, 0, -z_off), Vector3(size.x, size.y, segment), mat)
		_wall_segment(pos + Vector3(0, 0, z_off), Vector3(size.x, size.y, segment), mat)


func _wall_segment(pos: Vector3, size: Vector3, mat: StandardMaterial3D) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	var mesh_inst := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh_inst.mesh = box
	mesh_inst.material_override = mat
	body.add_child(mesh_inst)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	add_child(body)


func _floor_patch(pos: Vector3, size: Vector3, mat: StandardMaterial3D) -> void:
	var mesh_inst := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh_inst.mesh = box
	mesh_inst.material_override = mat
	mesh_inst.position = pos
	add_child(mesh_inst)


func _build_doors() -> void:
	# Door: Entrance (south outer) — already open gap, add decorative door frame pair
	_spawn_door(&"door_entrance", Vector3(0, 0, 15.85), 0.0, false)
	# Production <-> Warehouse
	_spawn_door(&"door_warehouse", Vector3(10, 0, 0), PI * 0.5, false)
	# Production <-> Office
	_spawn_door(&"door_office", Vector3(-10, 0, 0), -PI * 0.5, false)
	# Production <-> Utility
	_spawn_door(&"door_utility", Vector3(0, 0, -6), 0.0, false)
	# Office <-> Hall 8 (locked)
	_spawn_door(&"door_hall8", Vector3(-15, 0, -6), 0.0, true)
	# North utility exit toward outer
	_spawn_door(&"door_north", Vector3(0, 0, -15.85), PI, false)


func _spawn_door(door_id: StringName, pos: Vector3, rot_y: float, locked: bool) -> void:
	var packed: PackedScene = load("res://scenes/interactables/factory_door.tscn")
	var door: FactoryDoor = packed.instantiate() as FactoryDoor
	door.name = String(door_id)
	door.door_id = door_id
	door.is_locked = locked
	if locked:
		door.required_key = &"key_hall8"
	door.position = pos
	door.rotation.y = rot_y

	# Visual panel
	var panel := MeshInstance3D.new()
	panel.name = "DoorPanel"
	var box := BoxMesh.new()
	box.size = Vector3(DOOR_W, DOOR_H, 0.12)
	panel.mesh = box
	panel.position = Vector3(0, DOOR_H * 0.5, 0)
	panel.material_override = _door_mat
	door.add_child(panel)

	# Frame
	for offset_x in [-DOOR_W * 0.5 - 0.1, DOOR_W * 0.5 + 0.1]:
		var frame := MeshInstance3D.new()
		var fbox := BoxMesh.new()
		fbox.size = Vector3(0.2, DOOR_H + 0.2, 0.25)
		frame.mesh = fbox
		frame.position = Vector3(offset_x, DOOR_H * 0.5, 0)
		frame.material_override = _wall_mat
		door.add_child(frame)
	var lintel := MeshInstance3D.new()
	var lbox := BoxMesh.new()
	lbox.size = Vector3(DOOR_W + 0.4, 0.2, 0.25)
	lintel.mesh = lbox
	lintel.position = Vector3(0, DOOR_H + 0.1, 0)
	lintel.material_override = _wall_mat
	door.add_child(lintel)

	# Interaction collider
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(DOOR_W + 0.4, DOOR_H, 0.8)
	col.shape = shape
	col.position = Vector3(0, DOOR_H * 0.5, 0)
	door.add_child(col)

	# Physical blocker when closed
	var blocker := StaticBody3D.new()
	blocker.name = "Blocker"
	var bcol := CollisionShape3D.new()
	var bshape := BoxShape3D.new()
	bshape.size = Vector3(DOOR_W, DOOR_H, 0.15)
	bcol.shape = bshape
	bcol.position = Vector3(0, DOOR_H * 0.5, 0)
	blocker.add_child(bcol)
	door.add_child(blocker)

	add_child(door)


func _build_lights() -> void:
	_room_light(Vector3(0, 3.8, 2), Color(1.0, 0.78, 0.5), 2.2, 16.0)      # production
	_room_light(Vector3(-6, 3.8, 4), Color(1.0, 0.7, 0.4), 1.6, 12.0)
	_room_light(Vector3(6, 3.8, 4), Color(1.0, 0.7, 0.4), 1.6, 12.0)
	_room_light(Vector3(15, 3.8, 0), Color(0.85, 0.9, 1.0), 1.8, 14.0)    # warehouse cool
	_room_light(Vector3(-15, 3.8, 2), Color(1.0, 0.85, 0.6), 1.5, 12.0)   # office
	_room_light(Vector3(0, 3.8, -11), Color(0.7, 0.85, 1.0), 1.4, 12.0)   # utility
	_room_light(Vector3(-15, 3.5, -11), Color(1.0, 0.15, 0.08), 1.8, 10.0) # hall8 red


func _room_light(at: Vector3, color: Color, energy: float, range_m: float) -> void:
	var light := OmniLight3D.new()
	light.position = at
	light.light_color = color
	light.light_energy = energy
	light.omni_range = range_m
	light.shadow_enabled = true
	light.add_to_group("factory_lights")
	add_child(light)

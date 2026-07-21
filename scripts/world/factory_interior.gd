@tool
extends Node3D
## Multi-room factory interior: walls, ceilings, doors, room lights.
## Rooms: Entrance, Production, Warehouse, Office, Utility, Hall8.
## @tool — геометрия видна в редакторе (как в игре).

const WALL_H := 4.5
const WALL_T := 0.35
const CEIL_T := 0.2
const DOOR_W := 1.8
const DOOR_H := 2.4
## Ширина проёма — с запасом под капсулу игрока (radius 0.4).
const OPEN_W := 2.2

## В Inspector: включи галку → стены пересоберутся в редакторе.
@export var refresh_editor_preview: bool = false:
	set(value):
		if value and Engine.is_editor_hint():
			call_deferred("_rebuild")
		refresh_editor_preview = false

var _wall_mat: StandardMaterial3D
var _wall_alt_mat: StandardMaterial3D
var _floor_mat: StandardMaterial3D
var _ceil_mat: StandardMaterial3D
var _door_mat: StandardMaterial3D


func _ready() -> void:
	_rebuild()


func _rebuild() -> void:
	_clear_generated()
	_build_materials()
	_build_rooms()
	# В редакторе двери/свет тоже рисуем; звуки/EventBus при клике не обязательны
	_build_doors()
	_build_lights()


func _clear_generated() -> void:
	var kids := get_children()
	for child in kids:
		remove_child(child)
		child.free()


func _build_materials() -> void:
	# Простые цвета без текстур.
	_wall_mat = _make_flat(Color(0.55, 0.52, 0.48), 0.9, 0.02)
	_wall_alt_mat = _make_flat(Color(0.42, 0.43, 0.45), 0.7, 0.35)
	_floor_mat = _make_flat(Color(0.48, 0.45, 0.4), 0.95, 0.0)
	_ceil_mat = _make_flat(Color(0.28, 0.27, 0.26), 0.9, 0.05)
	_door_mat = _make_flat(Color(0.28, 0.24, 0.2), 0.45, 0.55)


func _make_flat(color: Color, roughness: float, metallic: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	mat.metallic = metallic
	return mat


func _make_surface(color: Color, roughness: float, metallic: float, _noise_scale: float) -> StandardMaterial3D:
	return _make_flat(color, roughness, metallic)


func _make_pbr(_asset_id: String, fallback: Color, _uv_scale: float) -> StandardMaterial3D:
	return _make_flat(fallback, 0.85, 0.05)


func _build_rooms() -> void:
	# Outer shell — large factory footprint
	_rect_room(Rect2(-20, -16, 40, 32), true)

	# Внутренние перегородки с аккуратным дверным проёмом (не на всю высоту!)
	# Production | Warehouse (x = 10)
	_partition_along_z(10.0, -16.0, 16.0, 0.0, _wall_mat)
	# Production | Office (x = -10)
	_partition_along_z(-10.0, -16.0, 16.0, 0.0, _wall_alt_mat)
	# Production | Utility (z = -6)
	_partition_along_x(-10.0, 10.0, -6.0, 0.0, _wall_mat)
	# Hall 8 enclosure
	_partition_along_x(-19.0, -11.0, -6.0, -15.0, _wall_alt_mat)
	_partition_along_z(-10.0, -15.0, -7.0, -11.0, _wall_alt_mat)

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
	var x0 := rect.position.x
	var x1 := rect.position.x + rect.size.x
	var z0 := rect.position.y
	var z1 := rect.position.y + rect.size.y
	# North / South — проём под дверь + перемычка сверху
	_partition_along_x(x0, x1, z0, cx, _wall_mat)
	_partition_along_x(x0, x1, z1, cx, _wall_mat)
	# East / West — сплошные
	_wall_segment(Vector3(cx + w * 0.5, WALL_H * 0.5, cz), Vector3(WALL_T, WALL_H, d), _wall_mat)
	_wall_segment(Vector3(cx - w * 0.5, WALL_H * 0.5, cz), Vector3(WALL_T, WALL_H, d), _wall_mat)


## Стена вдоль Z (фиксированный X), дверной проём около door_z.
func _partition_along_z(x: float, z_min: float, z_max: float, door_z: float, mat: StandardMaterial3D) -> void:
	var half := OPEN_W * 0.5
	var z_left_end := door_z - half
	var z_right_start := door_z + half
	# Южный кусок
	if z_left_end - z_min > 0.05:
		var len_s := z_left_end - z_min
		_wall_segment(Vector3(x, WALL_H * 0.5, z_min + len_s * 0.5), Vector3(WALL_T, WALL_H, len_s), mat)
	# Северный кусок
	if z_max - z_right_start > 0.05:
		var len_n := z_max - z_right_start
		_wall_segment(Vector3(x, WALL_H * 0.5, z_right_start + len_n * 0.5), Vector3(WALL_T, WALL_H, len_n), mat)
	# Перемычка над дверью — закрывает просвет до потолка
	_add_door_header(Vector3(x, 0, door_z), true, mat)


## Стена вдоль X (фиксированный Z), дверной проём около door_x.
func _partition_along_x(x_min: float, x_max: float, z: float, door_x: float, mat: StandardMaterial3D) -> void:
	var half := OPEN_W * 0.5
	var x_left_end := door_x - half
	var x_right_start := door_x + half
	if x_left_end - x_min > 0.05:
		var len_l := x_left_end - x_min
		_wall_segment(Vector3(x_min + len_l * 0.5, WALL_H * 0.5, z), Vector3(len_l, WALL_H, WALL_T), mat)
	if x_max - x_right_start > 0.05:
		var len_r := x_max - x_right_start
		_wall_segment(Vector3(x_right_start + len_r * 0.5, WALL_H * 0.5, z), Vector3(len_r, WALL_H, WALL_T), mat)
	_add_door_header(Vector3(door_x, 0, z), false, mat)


func _add_door_header(center: Vector3, wall_is_yz: bool, mat: StandardMaterial3D) -> void:
	var header_h := WALL_H - DOOR_H
	if header_h <= 0.05:
		return
	var y := DOOR_H + header_h * 0.5
	if wall_is_yz:
		# стена в плоскости YZ (нормаль по X)
		_wall_segment(Vector3(center.x, y, center.z), Vector3(WALL_T, header_h, OPEN_W + 0.08), mat)
	else:
		# стена в плоскости XY (нормаль по Z)
		_wall_segment(Vector3(center.x, y, center.z), Vector3(OPEN_W + 0.08, header_h, WALL_T), mat)


func _wall_with_gap(pos: Vector3, size: Vector3, gap: float, gap_on_x: bool, mat: StandardMaterial3D) -> void:
	# Совместимость: полный проём + перемычка
	var axis_len: float = size.x if gap_on_x else size.z
	var segment := (axis_len - gap) * 0.5
	if segment < 0.4:
		_wall_segment(pos, size, mat)
		return
	if gap_on_x:
		var offset := (segment + gap) * 0.5
		_wall_segment(pos + Vector3(-offset, 0, 0), Vector3(segment, size.y, size.z), mat)
		_wall_segment(pos + Vector3(offset, 0, 0), Vector3(segment, size.y, size.z), mat)
		_add_door_header(Vector3(pos.x, 0, pos.z), false, mat)
	else:
		var z_off := (segment + gap) * 0.5
		_wall_segment(pos + Vector3(0, 0, -z_off), Vector3(size.x, size.y, segment), mat)
		_wall_segment(pos + Vector3(0, 0, z_off), Vector3(size.x, size.y, segment), mat)
		_add_door_header(Vector3(pos.x, 0, pos.z), true, mat)


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
	_spawn_door(&"door_entrance", Vector3(0, 0, 16.0), 0.0, false)
	_spawn_door(&"door_warehouse", Vector3(10, 0, 0), PI * 0.5, false)
	_spawn_door(&"door_office", Vector3(-10, 0, 0), -PI * 0.5, false)
	_spawn_door(&"door_utility", Vector3(0, 0, -6), 0.0, false)
	_spawn_door(&"door_hall8", Vector3(-15, 0, -6), 0.0, true)
	_spawn_door(&"door_north", Vector3(0, 0, -16.0), PI, false)


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

	var frame_mat := _wall_alt_mat
	var jamb_w := 0.14
	var frame_depth := WALL_T + 0.08
	var panel_w := DOOR_W - 0.04
	var panel_h := DOOR_H - 0.06

	# Полотно двери — почти вплотную к проёму
	var panel := MeshInstance3D.new()
	panel.name = "DoorPanel"
	var box := BoxMesh.new()
	box.size = Vector3(panel_w, panel_h, 0.1)
	panel.mesh = box
	panel.position = Vector3(0, panel_h * 0.5 + 0.03, 0)
	panel.material_override = _door_mat
	door.add_child(panel)

	# Боковые стойки — перекрывают шов со стеной
	for side in [-1.0, 1.0]:
		var jamb := MeshInstance3D.new()
		var jbox := BoxMesh.new()
		jbox.size = Vector3(jamb_w, DOOR_H + 0.08, frame_depth)
		jamb.mesh = jbox
		jamb.position = Vector3(side * (DOOR_W * 0.5 + jamb_w * 0.35), DOOR_H * 0.5, 0)
		jamb.material_override = frame_mat
		door.add_child(jamb)

	# Верхняя перекладина рамы (стык с каменной перемычкой стены)
	var lintel := MeshInstance3D.new()
	var lbox := BoxMesh.new()
	lbox.size = Vector3(DOOR_W + jamb_w * 2.2, 0.18, frame_depth)
	lintel.mesh = lbox
	lintel.position = Vector3(0, DOOR_H + 0.02, 0)
	lintel.material_override = frame_mat
	door.add_child(lintel)

	# Порог — убирает нижний просвет
	var sill := MeshInstance3D.new()
	var sbox := BoxMesh.new()
	sbox.size = Vector3(DOOR_W + jamb_w * 2.0, 0.06, frame_depth + 0.04)
	sill.mesh = sbox
	sill.position = Vector3(0, 0.03, 0)
	sill.material_override = frame_mat
	door.add_child(sill)

	# Interaction collider
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(DOOR_W + 0.5, DOOR_H, 0.9)
	col.shape = shape
	col.position = Vector3(0, DOOR_H * 0.5, 0)
	door.add_child(col)

	# Physical blocker when closed — тонкий, только полотно (не вся толщина стены).
	var blocker := StaticBody3D.new()
	blocker.name = "Blocker"
	blocker.collision_layer = 1
	blocker.collision_mask = 0
	var bcol := CollisionShape3D.new()
	var bshape := BoxShape3D.new()
	bshape.size = Vector3(panel_w, panel_h, 0.12)
	bcol.shape = bshape
	bcol.position = Vector3(0, panel_h * 0.5 + 0.03, 0)
	blocker.add_child(bcol)
	door.add_child(blocker)

	add_child(door)


func _build_lights() -> void:
	# Основные зоны; склад дополнительно подсвечивает WarehouseShowcaseLight.
	_room_light(Vector3(0, 3.9, 2), Color(1.0, 0.9, 0.72), 2.0, 14.0)
	_room_light(Vector3(-5, 3.9, 5), Color(1.0, 0.88, 0.7), 1.6, 11.0)
	_room_light(Vector3(5, 3.9, 5), Color(1.0, 0.88, 0.7), 1.6, 11.0)
	_room_light(Vector3(15.5, 3.9, 2), Color(1.0, 0.94, 0.82), 1.2, 10.0)
	_room_light(Vector3(-15, 3.8, 2), Color(1.0, 0.9, 0.75), 1.8, 11.0)
	_room_light(Vector3(0, 3.8, -11), Color(0.85, 0.9, 1.0), 1.6, 11.0)
	_room_light(Vector3(-15, 3.5, -11), Color(1.0, 0.2, 0.1), 1.2, 9.0)


func _room_light(at: Vector3, color: Color, energy: float, range_m: float) -> void:
	var light := OmniLight3D.new()
	light.position = at
	light.light_color = color
	light.light_energy = energy
	light.omni_range = range_m
	light.shadow_enabled = true
	light.add_to_group("factory_lights")
	add_child(light)

extends Node3D
## Enclosed production hall — walls and ceiling for the interior shift area.

const WALL_HEIGHT := 5.0
const WALL_THICKNESS := 0.35
const HALL_CENTER := Vector3(0.0, 0.0, 4.0)
const HALL_SIZE := Vector2(32.0, 22.0)  # width (x), depth (z)
const DOOR_WIDTH := 4.0

var _wall_mat: StandardMaterial3D
var _ceiling_mat: StandardMaterial3D


func _ready() -> void:
	_setup_materials()
	_build_hall()


func _setup_materials() -> void:
	_wall_mat = StandardMaterial3D.new()
	_wall_mat.albedo_color = Color(0.12, 0.12, 0.14)
	_wall_mat.roughness = 0.92
	_wall_mat.metallic = 0.05
	_ceiling_mat = StandardMaterial3D.new()
	_ceiling_mat.albedo_color = Color(0.08, 0.08, 0.1)
	_ceiling_mat.roughness = 0.95


func _build_hall() -> void:
	var half_x := HALL_SIZE.x * 0.5
	var half_z := HALL_SIZE.y * 0.5
	var cx := HALL_CENTER.x
	var cz := HALL_CENTER.z

	# North wall (z min) — opening toward courtyard / hall 8 side
	_add_wall_with_gap(
		Vector3(cx, WALL_HEIGHT * 0.5, cz - half_z),
		Vector3(HALL_SIZE.x, WALL_HEIGHT, WALL_THICKNESS),
		DOOR_WIDTH,
		true,
	)
	# South wall — main entrance from spawn
	_add_wall_with_gap(
		Vector3(cx, WALL_HEIGHT * 0.5, cz + half_z),
		Vector3(HALL_SIZE.x, WALL_HEIGHT, WALL_THICKNESS),
		DOOR_WIDTH,
		true,
	)
	# East wall
	_add_solid_wall(
		Vector3(cx + half_x, WALL_HEIGHT * 0.5, cz),
		Vector3(WALL_THICKNESS, WALL_HEIGHT, HALL_SIZE.y),
	)
	# West wall — side corridor gap
	_add_wall_with_gap(
		Vector3(cx - half_x, WALL_HEIGHT * 0.5, cz),
		Vector3(WALL_THICKNESS, WALL_HEIGHT, HALL_SIZE.y),
		3.0,
		false,
	)
	# Ceiling slab
	_add_solid_wall(
		Vector3(cx, WALL_HEIGHT, cz),
		Vector3(HALL_SIZE.x, 0.25, HALL_SIZE.y),
		_ceiling_mat,
	)
	# Interior strip lights along the hall
	_add_interior_light(Vector3(-6, 4.2, 2), Color(1.0, 0.75, 0.45))
	_add_interior_light(Vector3(4, 4.2, 2), Color(1.0, 0.75, 0.45))
	_add_interior_light(Vector3(0, 4.2, 8), Color(1.0, 0.7, 0.4))


func _add_solid_wall(pos: Vector3, size: Vector3, material: StandardMaterial3D = null) -> void:
	if material == null:
		material = _wall_mat
	var body := StaticBody3D.new()
	body.position = pos
	var mesh_inst := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_inst.mesh = mesh
	mesh_inst.material_override = material
	body.add_child(mesh_inst)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	add_child(body)


func _add_wall_with_gap(
	pos: Vector3,
	size: Vector3,
	gap: float,
	gap_on_x: bool,
) -> void:
	var axis_len: float = size.x if gap_on_x else size.z
	var segment := (axis_len - gap) * 0.5
	if segment <= 0.5:
		_add_solid_wall(pos, size)
		return

	if gap_on_x:
		var left_size := Vector3(segment, size.y, size.z)
		var right_size := Vector3(segment, size.y, size.z)
		var offset := (segment + gap) * 0.5
		_add_solid_wall(pos + Vector3(-offset, 0, 0), left_size)
		_add_solid_wall(pos + Vector3(offset, 0, 0), right_size)
	else:
		var front_size := Vector3(size.x, size.y, segment)
		var back_size := Vector3(size.x, size.y, segment)
		var z_offset := (segment + gap) * 0.5
		_add_solid_wall(pos + Vector3(0, 0, -z_offset), front_size)
		_add_solid_wall(pos + Vector3(0, 0, z_offset), back_size)


func _add_interior_light(at: Vector3, color: Color) -> void:
	var light := OmniLight3D.new()
	light.position = at
	light.light_color = color
	light.light_energy = 1.8
	light.omni_range = 14.0
	light.shadow_enabled = true
	light.add_to_group("factory_lights")
	add_child(light)

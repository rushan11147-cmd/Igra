extends RefCounted
## Procedural industrial props with collision where needed.

var palette
var builder


func _init(p_palette, p_builder) -> void:
	palette = p_palette
	builder = p_builder


func fill_room(parent: Node3D, rect: Rect2, y: float, role: StringName) -> void:
	# Keep props inward so doorways stay clear.
	var margin := 1.6
	var x0 := rect.position.x + margin
	var z0 := rect.position.y + margin
	var x1 := rect.position.x + rect.size.x - margin
	var z1 := rect.position.y + rect.size.y - margin
	if x1 <= x0 or z1 <= z0:
		x0 = rect.position.x + rect.size.x * 0.35
		x1 = rect.position.x + rect.size.x * 0.65
		z0 = rect.position.y + rect.size.y * 0.35
		z1 = rect.position.y + rect.size.y * 0.65
	var cx := (x0 + x1) * 0.5
	var cz := (z0 + z1) * 0.5
	var props := Node3D.new()
	props.name = "Props_%s" % String(role)
	parent.add_child(props)

	match role:
		&"lobby", &"checkpoint", &"security":
			_desk(props, Vector3(cx, y, cz), palette.metal)
			_cabinet(props, Vector3(cx + 2.5, y, cz - 2.0), palette.metal)
			_camera(props, Vector3(cx - 3.0, y + 3.2, cz + 2.5))
			_extinguisher(props, Vector3(cx - rect.size.x * 0.4, y, cz))
		&"locker", &"shower", &"breakroom", &"canteen":
			for i in 4:
				_cabinet(props, Vector3(cx - 3.0 + i * 1.6, y, cz - rect.size.y * 0.35), palette.metal)
			_bench(props, Vector3(cx, y, cz + 1.5), palette.metal)
			_lamp(props, Vector3(cx, y + 3.6, cz))
		&"medbay":
			_cabinet(props, Vector3(cx - 2.0, y, cz), palette.tile_clean)
			_cabinet(props, Vector3(cx + 2.0, y, cz), palette.tile_clean)
			_extinguisher(props, Vector3(cx + rect.size.x * 0.35, y, cz))
			_lamp(props, Vector3(cx, y + 3.6, cz), Color(0.85, 0.95, 1.0))
		&"warehouse", &"loading":
			for i in 6:
				_pallet(props, Vector3(cx - 4.0 + (i % 3) * 3.0, y, cz - 3.0 + int(i / 3) * 4.0))
				_barrel(props, Vector3(cx - 5.0 + i * 1.4, y, cz + 4.0), palette.hazard if i % 2 == 0 else palette.metal_rust)
			_pipe_run(props, Vector3(cx, y + 3.2, cz - rect.size.y * 0.4), rect.size.x * 0.7, true)
			_forklift(props, Vector3(cx + 5.0, y, cz))
			_container(props, Vector3(cx - 6.0, y, cz + 2.0))
		&"production", &"line", &"reactor_bay":
			_tank(props, Vector3(cx - 4.0, y, cz), 2.4)
			_tank(props, Vector3(cx + 4.0, y, cz - 2.0), 1.8)
			_conveyor(props, Vector3(cx, y, cz + 3.0), 8.0)
			_pipe_run(props, Vector3(cx, y + 3.0, cz), rect.size.x * 0.6, true)
			_pipe_run(props, Vector3(cx - 2.0, y + 2.2, cz), rect.size.y * 0.5, false)
			_beam(props, Vector3(cx, y + 3.8, cz), rect.size.x * 0.8)
			_railing(props, Vector3(cx, y + 2.0, cz - 1.5), 6.0)
		&"control", &"pulpit", &"electrical", &"pump":
			_cabinet(props, Vector3(cx - 2.5, y, cz), palette.metal)
			_cabinet(props, Vector3(cx, y, cz), palette.warning_red)
			_cabinet(props, Vector3(cx + 2.5, y, cz), palette.metal)
			_pump(props, Vector3(cx + 1.0, y, cz + 2.5))
			_cable_tray(props, Vector3(cx, y + 3.5, cz), rect.size.x * 0.7)
			_lamp(props, Vector3(cx, y + 3.6, cz), Color(1.0, 0.85, 0.55))
		&"lab", &"test_hall", &"archive", &"office", &"server", &"cctv":
			_desk(props, Vector3(cx, y, cz), palette.paint_blue)
			_cabinet(props, Vector3(cx - 3.0, y, cz - 2.0), palette.metal)
			_cabinet(props, Vector3(cx + 3.0, y, cz - 2.0), palette.metal)
			_camera(props, Vector3(cx, y + 3.3, cz + rect.size.y * 0.35))
			_lamp(props, Vector3(cx, y + 3.6, cz), Color(0.8, 0.9, 1.0))
			if role == &"server":
				for i in 5:
					_cabinet(props, Vector3(cx - 4.0 + i * 2.0, y, cz + 1.5), palette.metal)
		&"glass_bridge":
			_railing(props, Vector3(cx, y + 1.0, cz - 1.2), rect.size.x * 0.8)
			_railing(props, Vector3(cx, y + 1.0, cz + 1.2), rect.size.x * 0.8)
			_lamp(props, Vector3(cx, y + 3.4, cz))
		&"secret_lab", &"reactor_hall", &"computer", &"docs", &"emergency_cc":
			_tank(props, Vector3(cx, y, cz), 3.2)
			_cabinet(props, Vector3(cx - 5.0, y, cz), palette.warning_red)
			_cabinet(props, Vector3(cx + 5.0, y, cz), palette.metal)
			_beam(props, Vector3(cx, y + 3.9, cz), rect.size.x * 0.85)
			_pipe_run(props, Vector3(cx, y + 3.1, cz - 2.0), rect.size.x * 0.75, true)
			_lamp(props, Vector3(cx, y + 3.6, cz), Color(0.7, 1.0, 0.75), 1.4)
		&"tunnel", &"boiler", &"water", &"generator", &"sewer", &"locked_tech":
			_pipe_run(props, Vector3(cx, y + 1.2, cz), rect.size.x * 0.8, true)
			_pipe_run(props, Vector3(cx - 2.0, y + 2.4, cz), rect.size.y * 0.7, false)
			_pump(props, Vector3(cx + 2.0, y, cz))
			_tank(props, Vector3(cx - 3.0, y, cz + 1.0), 2.0)
			_lamp(props, Vector3(cx, y + 3.4, cz), Color(1.0, 0.55, 0.25), 0.9)
			_barrel(props, Vector3(cx + 4.0, y, cz - 1.5), palette.metal_rust)
		&"horror_lab", &"experiment", &"morgue", &"cage", &"waste", &"ruin", &"secret_tunnel":
			_cabinet(props, Vector3(cx - 2.0, y, cz), palette.metal_rust)
			_barrel(props, Vector3(cx + 2.5, y, cz), palette.warning_red)
			_barrel(props, Vector3(cx + 3.5, y, cz + 1.2), palette.metal_rust)
			builder.add_box(props, Vector3(cx, y + 0.02, cz + 2.0), Vector3(2.5, 0.04, 1.2), palette.blood_stain, false)
			_cage(props, Vector3(cx - 4.0, y, cz))
			_lamp(props, Vector3(cx, y + 3.3, cz), Color(1.0, 0.25, 0.15), 0.7)
			_pipe_run(props, Vector3(cx, y + 3.0, cz), rect.size.x * 0.5, true)
		&"corridor", &"service":
			_cable_tray(props, Vector3(cx, y + 3.5, cz), maxf(rect.size.x, rect.size.y) * 0.7)
			_extinguisher(props, Vector3(cx - rect.size.x * 0.35, y, cz))
			_lamp(props, Vector3(cx, y + 3.5, cz), Color(1.0, 0.9, 0.7), 1.1)
			_pipe_run(props, Vector3(cx, y + 3.8, cz), maxf(rect.size.x, rect.size.y) * 0.6, rect.size.x >= rect.size.y)
		&"roof":
			_fan(props, Vector3(cx - 4.0, y + 1.5, cz))
			_fan(props, Vector3(cx + 4.0, y + 1.5, cz))
			_cooling_tower(props, Vector3(cx, y, cz - 6.0))
			_tank(props, Vector3(cx + 8.0, y, cz + 4.0), 2.8)
			_railing(props, Vector3(cx, y + 1.0, cz + rect.size.y * 0.4), rect.size.x * 0.7)
			_pipe_run(props, Vector3(cx, y + 0.6, cz), rect.size.x * 0.8, true)
		&"stairwell", &"elevator":
			_railing(props, Vector3(cx + 1.2, y + 1.0, cz), 3.0)
			_lamp(props, Vector3(cx, y + 3.5, cz), Color(1.0, 0.85, 0.5), 1.0)
		_:
			_barrel(props, Vector3(cx, y, cz), palette.metal)
			_lamp(props, Vector3(cx, y + 3.5, cz))


func _mesh_box(parent: Node3D, pos: Vector3, size: Vector3, mat: Material, collide: bool = true) -> void:
	builder.add_box(parent, pos, size, mat, collide, false)


func _barrel(parent: Node3D, pos: Vector3, mat: Material) -> void:
	var body := StaticBody3D.new()
	body.position = pos + Vector3(0, 0.55, 0)
	var mesh := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.35
	cyl.bottom_radius = 0.38
	cyl.height = 1.1
	mesh.mesh = cyl
	mesh.material_override = mat
	body.add_child(mesh)
	var col := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 0.38
	shape.height = 1.1
	col.shape = shape
	body.add_child(col)
	parent.add_child(body)


func _pallet(parent: Node3D, pos: Vector3) -> void:
	_mesh_box(parent, pos + Vector3(0, 0.08, 0), Vector3(1.2, 0.16, 1.0), palette.wood_crate)
	_mesh_box(parent, pos + Vector3(0, 0.55, 0), Vector3(1.0, 0.8, 0.8), palette.wood_crate)


func _cabinet(parent: Node3D, pos: Vector3, mat: Material) -> void:
	_mesh_box(parent, pos + Vector3(0, 1.0, 0), Vector3(0.9, 2.0, 0.55), mat)


func _desk(parent: Node3D, pos: Vector3, mat: Material) -> void:
	_mesh_box(parent, pos + Vector3(0, 0.75, 0), Vector3(1.8, 0.08, 0.9), mat)
	_mesh_box(parent, pos + Vector3(-0.75, 0.35, 0.35), Vector3(0.1, 0.7, 0.1), mat)
	_mesh_box(parent, pos + Vector3(0.75, 0.35, 0.35), Vector3(0.1, 0.7, 0.1), mat)
	_mesh_box(parent, pos + Vector3(-0.75, 0.35, -0.35), Vector3(0.1, 0.7, 0.1), mat)
	_mesh_box(parent, pos + Vector3(0.75, 0.35, -0.35), Vector3(0.1, 0.7, 0.1), mat)


func _bench(parent: Node3D, pos: Vector3, mat: Material) -> void:
	_mesh_box(parent, pos + Vector3(0, 0.45, 0), Vector3(2.4, 0.1, 0.5), mat)


func _tank(parent: Node3D, pos: Vector3, height: float) -> void:
	var body := StaticBody3D.new()
	body.position = pos + Vector3(0, height * 0.5, 0)
	var mesh := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 1.1
	cyl.bottom_radius = 1.2
	cyl.height = height
	mesh.mesh = cyl
	mesh.material_override = palette.metal
	body.add_child(mesh)
	var col := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 1.2
	shape.height = height
	col.shape = shape
	body.add_child(col)
	parent.add_child(body)


func _pump(parent: Node3D, pos: Vector3) -> void:
	_mesh_box(parent, pos + Vector3(0, 0.4, 0), Vector3(1.0, 0.8, 0.7), palette.metal)
	_mesh_box(parent, pos + Vector3(0, 1.0, 0), Vector3(0.5, 0.5, 0.5), palette.pipe_steel)


func _pipe_run(parent: Node3D, pos: Vector3, length: float, along_x: bool) -> void:
	var size := Vector3(length, 0.22, 0.22) if along_x else Vector3(0.22, 0.22, length)
	_mesh_box(parent, pos, size, palette.pipe_steel, false)
	var valve_pos := pos + (Vector3(length * 0.25, 0, 0) if along_x else Vector3(0, 0, length * 0.25))
	_mesh_box(parent, valve_pos, Vector3(0.35, 0.35, 0.35), palette.hazard, false)


func _cable_tray(parent: Node3D, pos: Vector3, length: float) -> void:
	_mesh_box(parent, pos, Vector3(length, 0.08, 0.4), palette.metal, false)


func _beam(parent: Node3D, pos: Vector3, length: float) -> void:
	_mesh_box(parent, pos, Vector3(length, 0.25, 0.25), palette.metal_rust, false)


func _railing(parent: Node3D, pos: Vector3, length: float) -> void:
	_mesh_box(parent, pos + Vector3(0, 0.5, 0), Vector3(length, 0.08, 0.08), palette.metal, false)
	_mesh_box(parent, pos + Vector3(0, 1.0, 0), Vector3(length, 0.08, 0.08), palette.metal, false)
	for i in 5:
		var x := -length * 0.4 + i * (length * 0.2)
		_mesh_box(parent, pos + Vector3(x, 0.5, 0), Vector3(0.06, 1.0, 0.06), palette.metal, false)


func _conveyor(parent: Node3D, pos: Vector3, length: float) -> void:
	_mesh_box(parent, pos + Vector3(0, 0.45, 0), Vector3(length, 0.35, 1.1), palette.metal)
	for i in 3:
		_mesh_box(parent, pos + Vector3(-length * 0.3 + i * length * 0.3, 0.2, 0), Vector3(0.2, 0.2, 1.2), palette.metal_rust)


func _forklift(parent: Node3D, pos: Vector3) -> void:
	_mesh_box(parent, pos + Vector3(0, 0.6, 0), Vector3(1.4, 1.2, 2.2), palette.hazard)
	_mesh_box(parent, pos + Vector3(0, 0.3, 1.4), Vector3(0.15, 0.15, 1.2), palette.metal)


func _container(parent: Node3D, pos: Vector3) -> void:
	_mesh_box(parent, pos + Vector3(0, 1.3, 0), Vector3(2.4, 2.6, 6.0), palette.paint_blue)


func _cage(parent: Node3D, pos: Vector3) -> void:
	_mesh_box(parent, pos + Vector3(0, 1.1, 0), Vector3(2.0, 2.2, 2.0), palette.metal_rust, false)
	_mesh_box(parent, pos + Vector3(0, 1.1, 0), Vector3(1.7, 2.0, 1.7), palette.concrete_dark)


func _fan(parent: Node3D, pos: Vector3) -> void:
	var mesh := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 1.6
	cyl.bottom_radius = 1.6
	cyl.height = 0.35
	mesh.mesh = cyl
	mesh.material_override = palette.vent
	mesh.position = pos
	mesh.rotation.x = PI * 0.5
	parent.add_child(mesh)
	_mesh_box(parent, pos + Vector3(0, -0.8, 0), Vector3(0.4, 1.6, 0.4), palette.metal)


func _cooling_tower(parent: Node3D, pos: Vector3) -> void:
	var body := StaticBody3D.new()
	body.position = pos + Vector3(0, 2.5, 0)
	var mesh := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 1.2
	cyl.bottom_radius = 2.2
	cyl.height = 5.0
	mesh.mesh = cyl
	mesh.material_override = palette.concrete
	body.add_child(mesh)
	var col := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 2.2
	shape.height = 5.0
	col.shape = shape
	body.add_child(col)
	parent.add_child(body)


func _extinguisher(parent: Node3D, pos: Vector3) -> void:
	_mesh_box(parent, pos + Vector3(0, 0.7, 0), Vector3(0.25, 0.7, 0.25), palette.warning_red, false)


func _camera(parent: Node3D, pos: Vector3) -> void:
	_mesh_box(parent, pos, Vector3(0.25, 0.2, 0.35), palette.metal, false)


func _lamp(parent: Node3D, pos: Vector3, color: Color = Color(1.0, 0.92, 0.75), energy: float = 1.2) -> void:
	_mesh_box(parent, pos, Vector3(1.2, 0.12, 0.35), palette.metal, false)
	var light := OmniLight3D.new()
	light.position = pos + Vector3(0, -0.2, 0)
	light.light_color = color
	light.light_energy = energy
	light.omni_range = 10.0
	light.shadow_enabled = false
	light.add_to_group("factory_lights")
	parent.add_child(light)

extends Node3D
## Складской интерьер из Megascans: плотная «витринная» раскладка под Forward+.
## Текстуры навешиваются явно — FBX Quixel без автоматериалов.

const TARGET_HEIGHT := 2.2


func _ready() -> void:
	_place_production_props()
	_place_warehouse_showcase()
	_place_office_props()
	_place_utility_props()
	_place_hall8_props()
	_place_floor_markings()


func _place_production_props() -> void:
	# Не ставим пропы в дверные проёмы (x=±10, z=0 и z=-6).
	_spawn("wbslaikga", Vector3(-6, 0, 3), 0.35, 3.2)
	_spawn("wbuidixga", Vector3(5, 0, 4), -0.5, 3.0)
	_spawn("vgyiedcaw", Vector3(1, 0, -3), 1.1, 2.2)
	_spawn("villceo", Vector3(-3, 0, 7), 0.15, 1.8)
	_spawn("vhtmaifaw", Vector3(3, 0, 7), PI, 1.6)
	_spawn("tewscfuda", Vector3(-4, 0, 9), 0.0, 1.4)
	_spawn("virqcfw", Vector3(6, 0, -3), PI * 0.5, 2.2)
	_spawn("vgyidebaw", Vector3(-1, 0, 5), 0.2, 1.0)
	_spawn("vgyide1aw", Vector3(0.4, 0, 5.3), -0.4, 1.0)
	_spawn("vidrear", Vector3(2, 0, 9), 0.6, 1.1)


func _place_warehouse_showcase() -> void:
	# Три ряда стеллажей, с свободным проходом к двери склада (x≈10, z≈0).
	var shelf_ids: Array[String] = [
		"vh3lbfy", "vhtibbe", "vgyiciqaw", "vijnbi3",
		"vijnbhf", "virvfjk", "vizqehw", "vijnbjz",
	]

	# Ряд A — отодвинут от двери (не ближе x=13), пропускаем z около 0
	for i in 7:
		var z := -9.0 + i * 2.55
		if absf(z) < 2.2:
			continue
		var id: String = shelf_ids[i % shelf_ids.size()]
		_spawn(id, Vector3(13.2, 0, z), PI * 0.5, 3.6)

	# Ряд B
	for i in 7:
		var z := -9.0 + i * 2.55
		if absf(z) < 1.6:
			continue
		var id: String = shelf_ids[(i + 2) % shelf_ids.size()]
		_spawn(id, Vector3(16.2, 0, z), -PI * 0.5 if i % 2 == 0 else PI * 0.5, 3.7)

	# Ряд C
	for i in 7:
		var z := -9.0 + i * 2.55
		var id: String = shelf_ids[(i + 4) % shelf_ids.size()]
		_spawn(id, Vector3(19.2, 0, z), -PI * 0.5, 3.5)

	# Коробки — не в коридоре к двери
	var box_ids: Array[String] = WarehouseCatalog.BOXES
	for i in 18:
		var id: String = box_ids[i % box_ids.size()]
		var lane := i % 2
		var x := 14.2 + lane * 3.2 + randf_range(-0.1, 0.1)
		var z := -8.0 + int(i / 2) * 1.7 + randf_range(-0.1, 0.1)
		if absf(z) < 2.0 and x < 15.0:
			continue
		_spawn(id, Vector3(x, 0, z), randf_range(-0.25, 0.25), randf_range(0.75, 1.15))

	# Акценты подальше от дверного проёма
	_spawn("vgyidebaw", Vector3(15.5, 0, 5.5), 0.2, 1.05)
	_spawn("vgyide1aw", Vector3(16.2, 0, 5.8), -0.5, 1.0)
	_spawn("vh1icei", Vector3(17.0, 0, 3.0), 0.55, 2.5)
	_spawn("vhtmaifaw", Vector3(14.5, 0, 8.5), -0.2, 1.6)
	_spawn("vizqehw", Vector3(17.5, 0, 10.5), 0.1, 2.9)
	_spawn("vijnbjz", Vector3(14.5, 0, 10.2), 0.2, 2.7)
	_spawn("vh3lbfy", Vector3(19.0, 0, 9.5), PI * 0.9, 3.2)
	_spawn("vidrear", Vector3(15.5, 0, -6.5), 0.8, 1.15)
	_spawn("tewscfuda", Vector3(18.5, 0, -3.5), PI * 0.25, 1.5)


func _place_office_props() -> void:
	_spawn("ukknbeyaw", Vector3(-14, 0, 2), 0.0, 1.2)
	_spawn("ukwteiiaw", Vector3(-16, 0, 4), PI * 0.5, 1.1)
	_spawn("vh1jegi", Vector3(-13, 0, 5), -0.4, 1.0)
	_spawn("vhskccxaw", Vector3(-15, 0, 0), PI, 1.4)
	_spawn("ui1maewga", Vector3(-12, 0, 3), 0.2, 0.9)
	_spawn("ujyqaelga", Vector3(-17, 0, 2), 0.0, 0.8)


func _place_utility_props() -> void:
	_spawn("vh1icei", Vector3(-2, 0, -10), 0.0, 2.0)
	_spawn("vh1jeck", Vector3(2, 0, -11), PI * 0.25, 2.0)
	_spawn("wdkmabe", Vector3(0, 0, -8), 0.0, 1.5)
	_spawn("teraccgda", Vector3(4, 0, -9), PI * 0.5, 1.6)
	_spawn("teufceuda", Vector3(-5, 0, -9), -PI * 0.5, 1.6)
	_spawn("vgyidebaw", Vector3(6, 0, -10), 0.5, 1.1)
	_spawn("vidrear", Vector3(-7, 0, -8), 1.0, 1.2)


func _place_hall8_props() -> void:
	_spawn("wdqqeae", Vector3(-14, 0, -10), 0.8, 1.8)
	_spawn("wcwsfjbdw", Vector3(-16, 0, -12), PI, 1.2)
	_spawn("vjhledeaw", Vector3(-12, 0, -13), 0.0, 2.0)
	_spawn("vgyidbkaw", Vector3(-18, 0, -9), -0.3, 1.0)


func _place_floor_markings() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.93, 0.93, 0.9)
	mat.roughness = 0.85
	mat.emission_enabled = true
	mat.emission = Color(0.35, 0.35, 0.32)
	mat.emission_energy_multiplier = 0.15
	_marking_line(Vector3(14.2, 0.03, 0.5), Vector3(0.14, 0.02, 20), mat)
	_marking_line(Vector3(17.6, 0.03, 0.5), Vector3(0.14, 0.02, 20), mat)
	_marking_line(Vector3(15.9, 0.03, -9.5), Vector3(8.5, 0.02, 0.14), mat)
	_marking_line(Vector3(15.9, 0.03, 10.8), Vector3(8.5, 0.02, 0.14), mat)


func _marking_line(pos: Vector3, size: Vector3, mat: Material) -> void:
	var mesh_inst := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh_inst.mesh = box
	mesh_inst.position = pos
	mesh_inst.material_override = mat
	add_child(mesh_inst)


func _spawn(asset_id: String, pos: Vector3, rot_y: float, target_height: float = TARGET_HEIGHT) -> void:
	var path := WarehouseCatalog.fbx_path(asset_id)
	if not ResourceLoader.exists(path):
		push_warning("Missing warehouse asset: %s" % path)
		return
	var scene: PackedScene = load(path)
	if scene == null:
		return
	var instance := scene.instantiate() as Node3D
	if instance == null:
		return
	instance.name = asset_id
	instance.position = pos
	instance.rotation.y = rot_y
	add_child(instance)
	WarehouseCatalog.apply_materials(instance, asset_id)
	call_deferred("_normalize_and_collide", instance, target_height)


func _combined_aabb(node: Node3D) -> AABB:
	var result := AABB()
	var first := true
	var stack: Array[Node] = [node]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for child in n.get_children():
			stack.append(child)
		if n is MeshInstance3D:
			var mesh_inst := n as MeshInstance3D
			if mesh_inst.mesh == null:
				continue
			var local := mesh_inst.get_aabb()
			var xf := mesh_inst.global_transform
			var pts: Array[Vector3] = [
				xf * local.position,
				xf * (local.position + Vector3(local.size.x, 0, 0)),
				xf * (local.position + Vector3(0, local.size.y, 0)),
				xf * (local.position + Vector3(0, 0, local.size.z)),
				xf * (local.position + Vector3(local.size.x, local.size.y, 0)),
				xf * (local.position + Vector3(local.size.x, 0, local.size.z)),
				xf * (local.position + Vector3(0, local.size.y, local.size.z)),
				xf * (local.position + local.size),
			]
			for c in pts:
				if first:
					result = AABB(c, Vector3.ZERO)
					first = false
				else:
					result = result.expand(c)
	return result


func _normalize_and_collide(root: Node3D, target_height: float) -> void:
	var aabb := _combined_aabb(root)
	if aabb.size.y > 0.01:
		var scale_factor := target_height / aabb.size.y
		scale_factor = clampf(scale_factor, 0.005, 5.0)
		root.scale = Vector3.ONE * scale_factor
		var after := _combined_aabb(root)
		root.position.y -= after.position.y
	call_deferred("_add_collision", root)


func _add_collision(root: Node3D) -> void:
	_add_collision_recursive(root, root)


func _add_collision_recursive(node: Node, root: Node3D) -> void:
	if node is MeshInstance3D:
		var mesh_inst := node as MeshInstance3D
		if mesh_inst.mesh:
			var shape := mesh_inst.mesh.create_trimesh_shape()
			if shape:
				var body := StaticBody3D.new()
				var col := CollisionShape3D.new()
				col.shape = shape
				body.add_child(col)
				body.transform = root.global_transform.affine_inverse() * mesh_inst.global_transform
				root.add_child(body)
	for child in node.get_children():
		_add_collision_recursive(child, root)

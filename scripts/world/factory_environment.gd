extends Node3D
## Складской интерьер из Megascans: стеллажи, коробки, бочки, оборудование.
## Текстуры навешиваются явно — FBX Quixel без автоматериалов.

const TARGET_HEIGHT := 2.2


func _ready() -> void:
	_place_production_props()
	_place_warehouse_aisles()
	_place_office_props()
	_place_utility_props()
	_place_hall8_props()
	_place_floor_markings()


func _place_production_props() -> void:
	# Крупное оборудование без «игрушечных» цилиндров
	_spawn("wbslaikga", Vector3(-7, 0, 1), 0.35, 3.2)
	_spawn("wbuidixga", Vector3(7, 0, 0), -0.5, 3.0)
	_spawn("vgyiedcaw", Vector3(1, 0, -3), 1.1, 2.2)
	_spawn("villceo", Vector3(-2, 0, 6), 0.15, 1.8)
	_spawn("vhtmaifaw", Vector3(4, 0, 6), PI, 1.6)
	_spawn("tewscfuda", Vector3(-4, 0, 8), 0.0, 1.4)
	_spawn("virqcfw", Vector3(8, 0, -4), PI * 0.5, 2.2)

	# Бочки / канистры у прохода
	_spawn("vgyidebaw", Vector3(-1, 0, 4), 0.2, 1.0)
	_spawn("vgyide1aw", Vector3(0.4, 0, 4.3), -0.4, 1.0)
	_spawn("vidrear", Vector3(2, 0, 8), 0.6, 1.1)


func _place_warehouse_aisles() -> void:
	# Два ряда стеллажей — как на референсе склада
	var shelf_ids: Array[String] = [
		"vh3lbfy", "vhtibbe", "vgyiciqaw", "vijnbi3",
		"vijnbhf", "virvfjk", "vizqehw", "vijnbjz",
	]

	# Левый ряд (восток)
	for i in 6:
		var id: String = shelf_ids[i % shelf_ids.size()]
		var z := -8.0 + i * 2.6
		_spawn(id, Vector3(13.5, 0, z), PI * 0.5, 3.4)

	# Правый ряд
	for i in 6:
		var id: String = shelf_ids[(i + 3) % shelf_ids.size()]
		var z := -8.0 + i * 2.6
		_spawn(id, Vector3(18.2, 0, z), -PI * 0.5, 3.4)

	# Коробки на полу между рядами и у торцов
	var box_ids: Array[String] = WarehouseCatalog.BOXES
	for i in 14:
		var id: String = box_ids[i % box_ids.size()]
		var x := 14.5 + (i % 3) * 1.35
		var z := -7.5 + int(i / 3) * 2.0 + randf_range(-0.2, 0.2)
		_spawn(id, Vector3(x, 0, z), randf_range(-0.3, 0.3), randf_range(0.7, 1.15))

	# Палеты / доп. стеллажи у южной стены склада
	_spawn("vizqehw", Vector3(16, 0, 10), 0.2, 2.8)
	_spawn("vijnbjz", Vector3(12.5, 0, 10), PI * 0.15, 2.6)
	_spawn("vh3lbfy", Vector3(19, 0, 8), PI, 3.0)

	# Лестница / тележка / бочка в проходе
	_spawn("vh1icei", Vector3(15.5, 0, 2), 0.4, 2.4)
	_spawn("vgyidebaw", Vector3(16.2, 0, -1), 0.1, 1.05)
	_spawn("vhtmaifaw", Vector3(11.8, 0, -2), -0.3, 1.5)


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
	# Белые разметки проходов на складе
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.92, 0.92, 0.9)
	mat.roughness = 0.9
	_marking_line(Vector3(15.8, 0.03, 0), Vector3(0.12, 0.02, 18), mat)
	_marking_line(Vector3(12.2, 0.03, 0), Vector3(0.12, 0.02, 18), mat)
	_marking_line(Vector3(16, 0.03, -9.2), Vector3(8, 0.02, 0.12), mat)


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

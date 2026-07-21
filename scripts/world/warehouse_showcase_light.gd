extends Node3D
## Кинематографичный свет и «витринный» склад (Forward+).
## Вешается на Factory рядом с FactoryEnvironment.

func _ready() -> void:
	_build_sun()
	_build_warehouse_ceiling_lamps()
	_build_skylight_beams()
	_build_fill_lights()


func _build_sun() -> void:
	# Жёсткий «солнечный» луч в проход склада — главный вау-эффект референса.
	var sun := DirectionalLight3D.new()
	sun.name = "WarehouseSun"
	sun.light_color = Color(1.0, 0.92, 0.78)
	sun.light_energy = 2.4
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	sun.light_angular_distance = 0.4
	# Луч падает вдоль прохода склада (примерно с юго-запада сверху).
	sun.rotation_degrees = Vector3(-42, 55, 0)
	add_child(sun)


func _build_warehouse_ceiling_lamps() -> void:
	var lamp_mat := StandardMaterial3D.new()
	lamp_mat.albedo_color = Color(0.15, 0.15, 0.16)
	lamp_mat.metallic = 0.7
	lamp_mat.roughness = 0.4
	lamp_mat.emission_enabled = true
	lamp_mat.emission = Color(1.0, 0.92, 0.75)
	lamp_mat.emission_energy_multiplier = 2.5

	var positions: Array[Vector3] = [
		Vector3(14.0, 4.15, 6.0),
		Vector3(17.5, 4.15, 6.0),
		Vector3(14.0, 4.15, 1.0),
		Vector3(17.5, 4.15, 1.0),
		Vector3(14.0, 4.15, -4.0),
		Vector3(17.5, 4.15, -4.0),
		Vector3(14.0, 4.15, -8.5),
		Vector3(17.5, 4.15, -8.5),
		Vector3(15.5, 4.15, 10.0),
	]

	for i in positions.size():
		var pivot := Node3D.new()
		pivot.name = "Lamp_%d" % i
		pivot.position = positions[i]
		add_child(pivot)

		# Корпус лампы
		var housing := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.55, 0.12, 0.55)
		housing.mesh = box
		housing.material_override = lamp_mat
		pivot.add_child(housing)

		# Spot вниз
		var spot := SpotLight3D.new()
		spot.light_color = Color(1.0, 0.94, 0.82)
		spot.light_energy = 5.5
		spot.spot_range = 14.0
		spot.spot_angle = 38.0
		spot.shadow_enabled = true
		spot.spot_angle_attenuation = 0.6
		spot.rotation_degrees = Vector3(-90, 0, 0)
		spot.position = Vector3(0, -0.08, 0)
		spot.add_to_group("factory_lights")
		pivot.add_child(spot)


func _build_skylight_beams() -> void:
	# Яркие «проёмы в крыше» — имитация дневного света.
	var beams: Array[Dictionary] = [
		{"pos": Vector3(15.8, 4.3, 3.0), "energy": 8.0, "angle": 28.0},
		{"pos": Vector3(15.8, 4.3, -2.5), "energy": 7.0, "angle": 26.0},
		{"pos": Vector3(12.5, 4.3, 8.0), "energy": 6.0, "angle": 32.0},
	]
	for i in beams.size():
		var data: Dictionary = beams[i]
		var spot := SpotLight3D.new()
		spot.name = "Skylight_%d" % i
		spot.position = data["pos"]
		spot.light_color = Color(1.0, 0.96, 0.88)
		spot.light_energy = data["energy"]
		spot.spot_range = 16.0
		spot.spot_angle = data["angle"]
		spot.shadow_enabled = true
		spot.rotation_degrees = Vector3(-78, 15, 0)
		spot.add_to_group("factory_lights")
		add_child(spot)


func _build_fill_lights() -> void:
	# Мягкая заливка теней в проходе, чтобы не было чёрных пятен.
	var fill := OmniLight3D.new()
	fill.name = "WarehouseFill"
	fill.position = Vector3(15.5, 2.4, 2.0)
	fill.light_color = Color(0.85, 0.88, 0.95)
	fill.light_energy = 1.1
	fill.omni_range = 12.0
	fill.shadow_enabled = false
	fill.add_to_group("factory_lights")
	add_child(fill)

	var warm := OmniLight3D.new()
	warm.name = "WarehouseWarm"
	warm.position = Vector3(12.0, 2.2, 8.0)
	warm.light_color = Color(1.0, 0.85, 0.65)
	warm.light_energy = 1.4
	warm.omni_range = 9.0
	warm.shadow_enabled = false
	add_child(warm)

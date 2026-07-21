extends Node3D
## Процедурная ночная площадка завода для главного меню.
## Здания (Kenney Industrial), мигающие лампы, вентиляторы, дым.

signal lights_ready(lights: Array)

const GLB_DIR := "res://assets/models/industrial/glb/"

## Компактный силуэт завода перед камерой.
const LAYOUT: Array[Dictionary] = [
	{"file": "building-a.glb", "pos": Vector3(0, 0, -8), "rot": 0.15, "scale": 1.1},
	{"file": "building-e.glb", "pos": Vector3(-18, 0, -4), "rot": 0.4, "scale": 1.0},
	{"file": "building-b.glb", "pos": Vector3(16, 0, -10), "rot": -0.35, "scale": 1.0},
	{"file": "building-c.glb", "pos": Vector3(-8, 0, 6), "rot": PI * 0.5, "scale": 0.95},
	{"file": "building-g.glb", "pos": Vector3(10, 0, 4), "rot": -PI * 0.4, "scale": 0.9},
	{"file": "chimney-large.glb", "pos": Vector3(-4, 0, -14), "rot": 0.0, "scale": 1.2},
	{"file": "chimney-medium.glb", "pos": Vector3(8, 0, -16), "rot": 0.0, "scale": 1.0},
	{"file": "chimney-small.glb", "pos": Vector3(20, 0, -6), "rot": 0.0, "scale": 1.1},
	{"file": "detail-tank.glb", "pos": Vector3(-14, 0, 2), "rot": 0.2, "scale": 1.3},
	{"file": "building-h.glb", "pos": Vector3(24, 0, 2), "rot": PI, "scale": 0.85},
]

var factory_lights: Array[Light3D] = []
var emergency_lights: Array[Light3D] = []
var fans: Array[Node3D] = []
var conveyor: Node3D
var silhouette: MeshInstance3D

var _fan_speeds: Array[float] = []


func _ready() -> void:
	_build_ground()
	_build_buildings()
	_build_lights()
	_build_fans()
	_build_smoke()
	_build_conveyor()
	_build_silhouette()
	lights_ready.emit(factory_lights)


func _process(delta: float) -> void:
	# Вращение вентиляторов.
	for i in fans.size():
		var speed: float = _fan_speeds[i] if i < _fan_speeds.size() else 2.5
		fans[i].rotate_z(speed * delta)

	# Медленное «дыхание» дымовых частиц уже в GPUParticles.
	if conveyor and conveyor.visible:
		conveyor.position.x = fmod(conveyor.position.x + delta * 1.8, 12.0) - 6.0


func _build_ground() -> void:
	var ground := MeshInstance3D.new()
	ground.name = "Ground"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(120, 0.4, 120)
	ground.mesh = mesh
	ground.position = Vector3(0, -0.2, 0)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.08, 0.08, 0.09)
	mat.roughness = 0.95
	mat.metallic = 0.15
	ground.material_override = mat
	add_child(ground)


func _build_buildings() -> void:
	var root := Node3D.new()
	root.name = "Buildings"
	add_child(root)

	for entry in LAYOUT:
		var path: String = GLB_DIR + str(entry["file"])
		if not ResourceLoader.exists(path):
			continue
		var packed: PackedScene = load(path)
		if packed == null:
			continue
		var instance := packed.instantiate() as Node3D
		if instance == null:
			continue
		instance.position = entry["pos"]
		instance.rotation.y = entry["rot"]
		var s: float = entry["scale"]
		instance.scale = Vector3(s, s, s)
		root.add_child(instance)
		_darken_meshes(instance)


func _darken_meshes(node: Node) -> void:
	# Холодный индустриальный оттенок поверх исходных материалов.
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.22, 0.23, 0.25)
		mat.metallic = 0.55
		mat.roughness = 0.72
		mi.material_override = mat
	for child in node.get_children():
		_darken_meshes(child)


func _build_lights() -> void:
	var lights_root := Node3D.new()
	lights_root.name = "FactoryLights"
	add_child(lights_root)

	var positions: Array[Vector3] = [
		Vector3(-10, 8, 2),
		Vector3(6, 9, -2),
		Vector3(0, 12, -10),
		Vector3(14, 7, 4),
		Vector3(-16, 6, -6),
		Vector3(4, 5, 8),
	]

	for i in positions.size():
		var light := OmniLight3D.new()
		light.name = "Lamp_%d" % i
		light.position = positions[i]
		light.light_color = Color(0.72, 0.82, 0.95) # холодный белый
		light.light_energy = 2.4
		light.omni_range = 18.0
		light.shadow_enabled = false
		lights_root.add_child(light)
		factory_lights.append(light)

		# Аварийные жёлтые прожекторы.
		if i % 2 == 0:
			var emergency := SpotLight3D.new()
			emergency.name = "Emergency_%d" % i
			emergency.position = positions[i] + Vector3(0, -1, 0)
			emergency.rotation_degrees = Vector3(-55, i * 40.0, 0)
			emergency.light_color = Color(1.0, 0.72, 0.18)
			emergency.light_energy = 3.5
			emergency.spot_range = 22.0
			emergency.spot_angle = 35.0
			lights_root.add_child(emergency)
			emergency_lights.append(emergency)
			factory_lights.append(emergency)


func _build_fans() -> void:
	var fans_root := Node3D.new()
	fans_root.name = "Fans"
	add_child(fans_root)

	var spots: Array[Vector3] = [
		Vector3(-12, 6, 3),
		Vector3(8, 7, -5),
		Vector3(2, 9, -12),
	]

	for i in spots.size():
		var pivot := Node3D.new()
		pivot.position = spots[i]
		pivot.rotation_degrees = Vector3(0, 25 * i, 0)
		fans_root.add_child(pivot)

		var blade := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(2.4, 0.08, 0.35)
		blade.mesh = box
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.35, 0.35, 0.38)
		mat.metallic = 0.8
		mat.roughness = 0.4
		blade.material_override = mat
		pivot.add_child(blade)

		var blade2 := blade.duplicate() as MeshInstance3D
		blade2.rotation_degrees = Vector3(0, 0, 90)
		pivot.add_child(blade2)

		fans.append(pivot)
		_fan_speeds.append(1.8 + i * 0.7)


func _build_smoke() -> void:
	var smoke := GPUParticles3D.new()
	smoke.name = "Smoke"
	smoke.position = Vector3(-4, 14, -14)
	smoke.amount = 24
	smoke.lifetime = 6.0
	smoke.visibility_aabb = AABB(Vector3(-8, -2, -8), Vector3(16, 20, 16))

	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0.1, 1.0, 0.05)
	mat.spread = 12.0
	mat.initial_velocity_min = 0.4
	mat.initial_velocity_max = 1.1
	mat.gravity = Vector3(0.15, 0.2, 0.0)
	mat.scale_min = 1.2
	mat.scale_max = 2.8
	mat.color = Color(0.25, 0.25, 0.28, 0.35)
	smoke.process_material = mat

	var draw := SphereMesh.new()
	draw.radius = 0.6
	draw.height = 1.2
	var draw_mat := StandardMaterial3D.new()
	draw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	draw_mat.albedo_color = Color(0.3, 0.3, 0.32, 0.25)
	draw_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	draw.material = draw_mat
	smoke.draw_pass_1 = draw

	add_child(smoke)


func _build_conveyor() -> void:
	conveyor = Node3D.new()
	conveyor.name = "Conveyor"
	conveyor.position = Vector3(-6, 0.6, 8)
	conveyor.visible = false
	add_child(conveyor)

	var belt := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(10, 0.15, 1.2)
	belt.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.12, 0.12, 0.13)
	mat.metallic = 0.4
	belt.material_override = mat
	conveyor.add_child(belt)

	for i in 4:
		var crate := MeshInstance3D.new()
		var cmesh := BoxMesh.new()
		cmesh.size = Vector3(0.7, 0.5, 0.7)
		crate.mesh = cmesh
		crate.position = Vector3(-3.5 + i * 2.2, 0.4, 0)
		var cmat := StandardMaterial3D.new()
		cmat.albedo_color = Color(0.4, 0.28, 0.12)
		crate.material_override = cmat
		conveyor.add_child(crate)


func _build_silhouette() -> void:
	silhouette = MeshInstance3D.new()
	silhouette.name = "DarkSilhouette"
	var mesh := CapsuleMesh.new()
	mesh.radius = 0.45
	mesh.height = 2.1
	silhouette.mesh = mesh
	silhouette.position = Vector3(4, 1.05, -2)
	silhouette.visible = false

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.02, 0.02, 0.025)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	silhouette.material_override = mat
	add_child(silhouette)


## Публичные хуки для ambient-событий.
func flicker_lights(duration: float = 0.8) -> void:
	for light in factory_lights:
		if not is_instance_valid(light):
			continue
		var original := light.light_energy
		var tween := create_tween()
		tween.tween_property(light, "light_energy", 0.05, 0.05)
		tween.tween_property(light, "light_energy", original * 0.4, 0.07)
		tween.tween_property(light, "light_energy", 0.1, 0.05)
		tween.tween_property(light, "light_energy", original, duration * 0.4)


func blackout_partial(duration: float = 3.0) -> void:
	var targets: Array[Light3D] = []
	for i in factory_lights.size():
		if i % 2 == 0:
			targets.append(factory_lights[i])

	for light in targets:
		if not is_instance_valid(light):
			continue
		var original := light.light_energy
		var tween := create_tween()
		tween.tween_property(light, "light_energy", 0.0, 0.3)
		tween.tween_interval(duration)
		tween.tween_property(light, "light_energy", original, 0.8)


func show_silhouette(duration: float = 2.5) -> void:
	if silhouette == null:
		return
	silhouette.visible = true
	# Прозрачность через материал (у MeshInstance3D нет modulate).
	var mat := silhouette.material_override as StandardMaterial3D
	if mat:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color.a = 0.0
		var tween := create_tween()
		tween.tween_property(mat, "albedo_color:a", 1.0, 0.6)
		tween.tween_interval(duration)
		tween.tween_property(mat, "albedo_color:a", 0.0, 0.8)
		tween.tween_callback(func() -> void: silhouette.visible = false)


func run_conveyor(duration: float = 5.0) -> void:
	if conveyor == null:
		return
	conveyor.visible = true
	await get_tree().create_timer(duration).timeout
	if is_instance_valid(conveyor):
		conveyor.visible = false

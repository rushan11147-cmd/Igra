extends Node3D
## Skinless humanoid Backrooms entity — exposed muscle, bone, no skin.


func _ready() -> void:
	_build()


func _build() -> void:
	var flesh := _mat(Color(0.55, 0.12, 0.1), Color(0.35, 0.02, 0.02), 0.6)
	var muscle := _mat(Color(0.72, 0.18, 0.14), Color(0.4, 0.05, 0.03), 0.45)
	var bone := _mat(Color(0.85, 0.8, 0.7), Color(0.15, 0.12, 0.08), 0.15)
	var wet := _mat(Color(0.35, 0.05, 0.05), Color(0.5, 0.0, 0.0), 1.8)
	var void_eye := _mat(Color(0.02, 0.01, 0.01), Color(0.6, 0.0, 0.05), 3.5)

	# Pelvis / hips
	_box(Vector3(0, 0.95, 0), Vector3(0.38, 0.22, 0.24), flesh)
	# Exposed torso (ribcage shape)
	_box(Vector3(0, 1.45, 0), Vector3(0.42, 0.75, 0.26), muscle)
	# Ribs
	for i in 5:
		var y := 1.2 + i * 0.12
		_box(Vector3(-0.2, y, 0.12), Vector3(0.08, 0.04, 0.18), bone)
		_box(Vector3(0.2, y, 0.12), Vector3(0.08, 0.04, 0.18), bone)
	# Spine
	_box(Vector3(0, 1.5, -0.12), Vector3(0.08, 0.85, 0.08), bone)
	# Exposed guts bulge
	_box(Vector3(0, 1.15, 0.1), Vector3(0.28, 0.28, 0.16), wet)

	# Shoulders
	_box(Vector3(-0.28, 1.9, 0), Vector3(0.2, 0.16, 0.18), flesh)
	_box(Vector3(0.28, 1.9, 0), Vector3(0.2, 0.16, 0.18), flesh)
	# Neck (sinew)
	_cyl(Vector3(0, 2.15, 0), 0.09, 0.28, muscle)
	# Skull (no skin — bone head)
	_box(Vector3(0, 2.48, 0.02), Vector3(0.28, 0.32, 0.3), bone)
	_box(Vector3(0, 2.38, 0.12), Vector3(0.22, 0.12, 0.14), bone)  # jaw
	# Eye sockets
	_box(Vector3(-0.08, 2.52, 0.14), Vector3(0.07, 0.06, 0.06), void_eye)
	_box(Vector3(0.08, 2.52, 0.14), Vector3(0.07, 0.06, 0.06), void_eye)
	# Open scream mouth
	_box(Vector3(0, 2.34, 0.16), Vector3(0.14, 0.1, 0.08), void_eye)
	# Teeth
	for i in 4:
		_box(Vector3(-0.06 + i * 0.04, 2.38, 0.2), Vector3(0.025, 0.04, 0.03), bone)

	# Arms — muscle strips, elongated slightly
	_arm(-1.0, flesh, muscle, bone)
	_arm(1.0, flesh, muscle, bone)

	# Legs
	_leg(-1.0, flesh, muscle, bone)
	_leg(1.0, flesh, muscle, bone)


func _arm(side: float, flesh: Material, muscle: Material, bone: Material) -> void:
	# Upper arm
	_cyl(Vector3(side * 0.42, 1.55, 0), 0.07, 0.55, muscle)
	# Elbow bone knob
	_box(Vector3(side * 0.48, 1.25, 0), Vector3(0.08, 0.08, 0.08), bone)
	# Forearm
	_cyl(Vector3(side * 0.52, 0.95, 0.05), 0.055, 0.5, flesh)
	# Hand / claws
	_box(Vector3(side * 0.55, 0.68, 0.12), Vector3(0.1, 0.08, 0.16), flesh)
	for f in 3:
		_box(Vector3(side * 0.55, 0.62, 0.18 + f * 0.04), Vector3(0.03, 0.12, 0.03), bone)


func _leg(side: float, flesh: Material, muscle: Material, bone: Material) -> void:
	_cyl(Vector3(side * 0.14, 0.55, 0), 0.085, 0.55, muscle)
	_box(Vector3(side * 0.14, 0.28, 0), Vector3(0.1, 0.08, 0.1), bone)
	_cyl(Vector3(side * 0.14, 0.12, 0.02), 0.07, 0.35, flesh)
	_box(Vector3(side * 0.14, 0.04, 0.1), Vector3(0.12, 0.06, 0.26), bone)


func _mat(albedo: Color, emission: Color, emission_energy: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = albedo
	mat.roughness = 0.55
	mat.metallic = 0.05
	mat.emission_enabled = true
	mat.emission = emission
	mat.emission_energy_multiplier = emission_energy
	return mat


func _box(pos: Vector3, size: Vector3, mat: Material) -> void:
	var mesh_inst := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh_inst.mesh = box
	mesh_inst.position = pos
	mesh_inst.material_override = mat
	add_child(mesh_inst)


func _cyl(pos: Vector3, radius: float, height: float, mat: Material) -> void:
	var mesh_inst := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = radius
	cyl.bottom_radius = radius * 0.92
	cyl.height = height
	mesh_inst.mesh = cyl
	mesh_inst.position = pos
	mesh_inst.material_override = mat
	add_child(mesh_inst)

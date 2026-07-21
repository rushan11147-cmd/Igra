extends Node3D
## Procedural Backrooms-style entity: tall, thin, pale, wrong proportions.


func _ready() -> void:
	_build()


func _build() -> void:
	var skin := StandardMaterial3D.new()
	skin.albedo_color = Color(0.82, 0.8, 0.76)
	skin.roughness = 0.95
	skin.metallic = 0.0
	skin.emission_enabled = true
	skin.emission = Color(0.15, 0.12, 0.1)
	skin.emission_energy_multiplier = 0.35

	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.05, 0.05, 0.06)
	dark.roughness = 0.8
	dark.emission_enabled = true
	dark.emission = Color(0.4, 0.02, 0.05)
	dark.emission_energy_multiplier = 2.5

	_part(Vector3(0, 1.55, 0), Vector3(0.45, 1.4, 0.28), skin)
	_part(Vector3(0, 2.45, 0), Vector3(0.18, 0.55, 0.18), skin)
	_part(Vector3(0, 2.95, 0.05), Vector3(0.42, 0.5, 0.4), skin)
	_part(Vector3(-0.1, 3.0, 0.22), Vector3(0.08, 0.06, 0.06), dark)
	_part(Vector3(0.1, 3.0, 0.22), Vector3(0.08, 0.06, 0.06), dark)
	_part(Vector3(0, 2.82, 0.24), Vector3(0.22, 0.03, 0.04), dark)

	_limb_box(Vector3(-0.45, 1.45, 0), Vector3(0.1, 1.3, 0.1), skin)
	_limb_box(Vector3(0.45, 1.45, 0), Vector3(0.1, 1.3, 0.1), skin)
	_part(Vector3(-0.55, 0.75, 0.1), Vector3(0.14, 0.4, 0.1), skin)
	_part(Vector3(0.55, 0.75, 0.1), Vector3(0.14, 0.4, 0.1), skin)

	_limb_box(Vector3(-0.14, 0.45, 0), Vector3(0.12, 0.9, 0.12), skin)
	_limb_box(Vector3(0.14, 0.45, 0), Vector3(0.12, 0.9, 0.12), skin)
	_part(Vector3(-0.16, 0.06, 0.1), Vector3(0.14, 0.08, 0.3), skin)
	_part(Vector3(0.16, 0.06, 0.1), Vector3(0.14, 0.08, 0.3), skin)

	for i in 4:
		_part(Vector3(0, 1.2 + i * 0.28, -0.18), Vector3(0.06, 0.12, 0.1), dark)


func _part(pos: Vector3, size: Vector3, mat: Material) -> void:
	var mesh_inst := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh_inst.mesh = box
	mesh_inst.position = pos
	mesh_inst.material_override = mat
	add_child(mesh_inst)


func _limb_box(pos: Vector3, size: Vector3, mat: Material) -> void:
	_part(pos, size, mat)

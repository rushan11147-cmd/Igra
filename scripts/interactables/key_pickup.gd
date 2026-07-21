extends Interactable
## Picks up a key into inventory.

@export var key_id: StringName = &"key_hall8"
@export var label: String = "Ключ от цеха №8"


func _ready() -> void:
	super._ready()
	interaction_prompt = "Взять: %s [E]" % label
	_build_visual()


func _build_visual() -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.25, 0.08, 0.5)
	mesh.mesh = box
	mesh.position = Vector3(0, 1.0, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.85, 0.7, 0.2)
	mat.metallic = 0.9
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.8, 0.2)
	mat.emission_energy_multiplier = 2.0
	mesh.material_override = mat
	add_child(mesh)


func _on_interact(_player: Node3D) -> void:
	InventoryManager.add_key(key_id)
	interaction_enabled = false
	visible = false
	queue_free()

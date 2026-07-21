@tool
extends Node3D
## Procedural layout of Kenney City Kit Industrial GLB models (CC0).
## @tool — модели видны в редакторе.

const GLB_DIR := "res://assets/models/industrial/glb/"

const LAYOUT: Array[Dictionary] = [
	{"file": "building-a.glb", "pos": Vector3(0, 0, 0), "rot": 0.0, "scale": 1.0},
	{"file": "building-b.glb", "pos": Vector3(22, 0, 0), "rot": PI, "scale": 1.0},
	{"file": "building-c.glb", "pos": Vector3(-20, 0, 14), "rot": PI * 0.5, "scale": 1.0},
	{"file": "building-d.glb", "pos": Vector3(20, 0, -16), "rot": -PI * 0.5, "scale": 1.0},
	{"file": "building-e.glb", "pos": Vector3(0, 0, -22), "rot": PI, "scale": 1.0},
	{"file": "building-f.glb", "pos": Vector3(-22, 0, -10), "rot": 0.0, "scale": 1.0},
	{"file": "building-g.glb", "pos": Vector3(22, 0, 16), "rot": PI * 0.5, "scale": 1.0},
	{"file": "building-h.glb", "pos": Vector3(-28, 0, 2), "rot": PI * 0.5, "scale": 1.0},
	{"file": "building-i.glb", "pos": Vector3(28, 0, -4), "rot": -PI * 0.5, "scale": 1.0},
	{"file": "building-j.glb", "pos": Vector3(-10, 0, 22), "rot": 0.0, "scale": 1.0},
	{"file": "building-k.glb", "pos": Vector3(12, 0, 22), "rot": PI, "scale": 1.0},
	{"file": "chimney-large.glb", "pos": Vector3(-6, 0, -8), "rot": 0.0, "scale": 1.0},
	{"file": "chimney-medium.glb", "pos": Vector3(10, 0, -10), "rot": 0.0, "scale": 1.0},
	{"file": "chimney-small.glb", "pos": Vector3(16, 0, 6), "rot": 0.0, "scale": 1.0},
	{"file": "chimney-basic.glb", "pos": Vector3(-16, 0, -6), "rot": 0.0, "scale": 1.0},
	{"file": "building-l.glb", "pos": Vector3(-14, 0, -20), "rot": 0.2, "scale": 0.9},
	{"file": "building-m.glb", "pos": Vector3(14, 0, -24), "rot": -0.3, "scale": 0.9},
]

@export var refresh_editor_preview: bool = false:
	set(value):
		if value and Engine.is_editor_hint():
			call_deferred("_rebuild")
		refresh_editor_preview = false


func _ready() -> void:
	_rebuild()


func _rebuild() -> void:
	var kids := get_children()
	for child in kids:
		remove_child(child)
		child.free()
	_build_layout()


func _build_layout() -> void:
	for entry in LAYOUT:
		_spawn_glb(entry)


func _spawn_glb(entry: Dictionary) -> void:
	var file_name: String = str(entry.get("file", ""))
	var path: String = GLB_DIR + file_name
	if not ResourceLoader.exists(path):
		push_warning("Missing GLB: %s" % path)
		return

	var scene: PackedScene = load(path)
	if scene == null:
		return

	var instance := scene.instantiate() as Node3D
	if instance == null:
		return

	instance.position = entry.get("pos", Vector3.ZERO)
	instance.rotation.y = entry.get("rot", 0.0)
	var s: float = entry.get("scale", 1.0)
	instance.scale = Vector3(s, s, s)
	instance.name = file_name.get_basename()

	add_child(instance)
	call_deferred("_add_collision", instance)


func _add_collision(root: Node3D) -> void:
	_add_collision_recursive(root, root)


func _add_collision_recursive(node: Node, root: Node3D) -> void:
	if node is MeshInstance3D:
		var mesh_inst := node as MeshInstance3D
		if mesh_inst.mesh:
			var body := StaticBody3D.new()
			var col := CollisionShape3D.new()
			col.shape = mesh_inst.mesh.create_trimesh_shape()
			body.add_child(col)
			var local_transform: Transform3D = (
				root.global_transform.affine_inverse() * mesh_inst.global_transform
			)
			body.transform = local_transform
			root.add_child(body)
	for child in node.get_children():
		_add_collision_recursive(child, root)

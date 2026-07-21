extends Node3D
## Визуал станков: только Megascans props + статусный индикатор.
## Без оранжевых цилиндров/торусов-плейсхолдеров.

enum Kind { REACTOR, MIXER, CONVEYOR }

@export var kind: Kind = Kind.REACTOR
@export var accent_color: Color = Color(1.0, 0.55, 0.15)

var _status_light: OmniLight3D
var _indicator: MeshInstance3D
var _running: bool = false
var _broken: bool = false


func _ready() -> void:
	_build_mesh()
	_status_light = OmniLight3D.new()
	_status_light.position = Vector3(0, 2.8, 0)
	_status_light.omni_range = 6.0
	_status_light.light_energy = 1.2
	_status_light.shadow_enabled = false
	add_child(_status_light)
	_apply_status(false, false)
	_connect_machine()


func _process(_delta: float) -> void:
	var parent := get_parent()
	if parent == null:
		return
	if "is_running" in parent:
		var running: bool = parent.is_running
		var broken: bool = parent.get("is_broken") if "is_broken" in parent else false
		if running != _running or broken != _broken:
			_apply_status(running, broken)


func _connect_machine() -> void:
	if kind == Kind.REACTOR:
		EventBus.reactor_state_changed.connect(_on_reactor_state)


func _on_reactor_state(state: Dictionary) -> void:
	if get_parent() and state.get("machine_id") != get_parent().machine_id:
		return
	_apply_status(state.get("is_running", false), state.get("is_broken", false))


func _build_mesh() -> void:
	match kind:
		Kind.REACTOR:
			_spawn_prop(["wbuidixga", "villceo", "vgyiedcaw", "wbslaikga"], 3.0, 0.3)
		Kind.MIXER:
			_spawn_prop(["vgyiedcaw", "vhtmaifaw", "tewscfuda"], 2.2, -0.4)
		Kind.CONVEYOR:
			_spawn_prop(["virqcfw", "vh1jeck", "wdkmabe"], 1.4, PI * 0.5)
	_build_status_indicator()


func _spawn_prop(candidates: Array, target_height: float, rot_y: float) -> void:
	for asset_id in candidates:
		var path := WarehouseCatalog.fbx_path(String(asset_id))
		if not ResourceLoader.exists(path):
			continue
		var scene: PackedScene = load(path)
		if scene == null:
			continue
		var prop := scene.instantiate() as Node3D
		if prop == null:
			continue
		prop.rotation.y = rot_y
		add_child(prop)
		WarehouseCatalog.apply_materials(prop, String(asset_id))
		call_deferred("_normalize_height", prop, target_height)
		return

	# Фоллбек только если Megascans недоступен
	var tank_path := "res://assets/models/industrial/glb/detail-tank.glb"
	if ResourceLoader.exists(tank_path):
		var scene2: PackedScene = load(tank_path)
		if scene2:
			var tank2 := scene2.instantiate() as Node3D
			tank2.scale = Vector3(1.2, 1.2, 1.2)
			add_child(tank2)


func _normalize_height(root: Node3D, target_height: float) -> void:
	var aabb := _combined_aabb(root)
	if aabb.size.y <= 0.01:
		return
	var scale_factor := clampf(target_height / aabb.size.y, 0.005, 5.0)
	root.scale = Vector3.ONE * scale_factor
	var after := _combined_aabb(root)
	root.position.y -= after.position.y


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
			for ox in [0.0, local.size.x]:
				for oy in [0.0, local.size.y]:
					for oz in [0.0, local.size.z]:
						var c: Vector3 = xf * (local.position + Vector3(ox, oy, oz))
						if first:
							result = AABB(c, Vector3.ZERO)
							first = false
						else:
							result = result.expand(c)
	return result


func _build_status_indicator() -> void:
	# Небольшой индустриальный индикатор вместо neon-тора
	_indicator = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.18, 0.12, 0.08)
	_indicator.mesh = box
	_indicator.position = Vector3(0.9, 2.1, 0.7)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.2, 0.22)
	mat.emission_enabled = true
	mat.emission = accent_color
	mat.emission_energy_multiplier = 1.5
	_indicator.material_override = mat
	add_child(_indicator)


func _apply_status(running: bool, broken: bool) -> void:
	_running = running
	_broken = broken
	if _status_light == null or _indicator == null:
		return

	var mat := _indicator.material_override as StandardMaterial3D
	if broken:
		_status_light.light_color = Color(1.0, 0.12, 0.06)
		_status_light.light_energy = 2.4
		if mat:
			mat.emission = Color(1.0, 0.1, 0.05)
			mat.emission_energy_multiplier = 4.0
	elif running:
		_status_light.light_color = accent_color
		_status_light.light_energy = 1.8
		if mat:
			mat.emission = accent_color
			mat.emission_energy_multiplier = 3.0
	else:
		_status_light.light_color = Color(0.55, 0.58, 0.62)
		_status_light.light_energy = 0.7
		if mat:
			mat.emission = Color(0.35, 0.38, 0.4)
			mat.emission_energy_multiplier = 0.8

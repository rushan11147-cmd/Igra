extends Node3D
## Visible production equipment mesh + status light.

enum Kind { REACTOR, MIXER, CONVEYOR }

@export var kind: Kind = Kind.REACTOR
@export var accent_color: Color = Color(1.0, 0.45, 0.1)

var _status_light: OmniLight3D
var _emissive_mesh: MeshInstance3D
var _base_emission: Color = Color(0.6, 0.25, 0.05)
var _running: bool = false
var _broken: bool = false


func _ready() -> void:
	_build_mesh()
	_status_light = OmniLight3D.new()
	_status_light.position = Vector3(0, 2.5, 0)
	_status_light.omni_range = 8.0
	_status_light.light_energy = 2.5
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
			_build_reactor()
		Kind.MIXER:
			_build_mixer()
		Kind.CONVEYOR:
			_build_conveyor()


func _build_reactor() -> void:
	# Prefer Megascans large industrial hardware over Kenney tank
	var tank_ids := ["wbuidixga", "villceo", "vgyiedcaw"]
	var placed := false
	for asset_id in tank_ids:
		var path := WarehouseCatalog.fbx_path(asset_id)
		if ResourceLoader.exists(path):
			var scene: PackedScene = load(path)
			if scene:
				var tank := scene.instantiate() as Node3D
				tank.scale = Vector3(0.015, 0.015, 0.015)
				tank.rotation.y = 0.4
				add_child(tank)
				placed = true
				break
	if not placed:
		var tank_path := "res://assets/models/industrial/glb/detail-tank.glb"
		if ResourceLoader.exists(tank_path):
			var scene2: PackedScene = load(tank_path)
			if scene2:
				var tank2 := scene2.instantiate() as Node3D
				tank2.scale = Vector3(1.4, 1.4, 1.4)
				add_child(tank2)

	var core := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 1.1
	cyl.bottom_radius = 1.3
	cyl.height = 2.8
	core.mesh = cyl
	core.position = Vector3(0, 1.4, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.25, 0.22, 0.2)
	mat.metallic = 0.7
	mat.roughness = 0.35
	mat.emission_enabled = true
	mat.emission = _base_emission
	mat.emission_energy_multiplier = 2.0
	core.material_override = mat
	add_child(core)
	_emissive_mesh = core

	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 1.15
	torus.outer_radius = 1.35
	ring.mesh = torus
	ring.position = Vector3(0, 2.6, 0)
	var ring_mat := StandardMaterial3D.new()
	ring_mat.albedo_color = Color(0.9, 0.35, 0.05)
	ring_mat.emission_enabled = true
	ring_mat.emission = Color(1.0, 0.4, 0.05)
	ring_mat.emission_energy_multiplier = 4.0
	ring.material_override = ring_mat
	add_child(ring)


func _build_mixer() -> void:
	var body := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(2.2, 2.0, 2.2)
	body.mesh = box
	body.position = Vector3(0, 1.0, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.18, 0.28, 0.22)
	mat.metallic = 0.55
	mat.roughness = 0.4
	mat.emission_enabled = true
	mat.emission = Color(0.05, 0.35, 0.15)
	mat.emission_energy_multiplier = 2.5
	body.material_override = mat
	add_child(body)
	_emissive_mesh = body

	var funnel := MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.2
	cone.bottom_radius = 0.7
	cone.height = 1.0
	funnel.mesh = cone
	funnel.position = Vector3(0, 2.5, 0)
	add_child(funnel)


func _build_conveyor() -> void:
	var belt := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(5.0, 0.6, 1.8)
	belt.mesh = box
	belt.position = Vector3(0, 0.5, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.15, 0.15, 0.17)
	mat.metallic = 0.4
	mat.emission_enabled = true
	mat.emission = Color(0.15, 0.12, 0.05)
	mat.emission_energy_multiplier = 1.5
	belt.material_override = mat
	add_child(belt)
	_emissive_mesh = belt

	for i in 3:
		var roller := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.25
		cyl.bottom_radius = 0.25
		cyl.height = 1.9
		roller.mesh = cyl
		roller.position = Vector3(-1.8 + i * 1.8, 0.25, 0)
		roller.rotation.z = PI * 0.5
		add_child(roller)


func _apply_status(running: bool, broken: bool) -> void:
	_running = running
	_broken = broken
	if _status_light == null:
		return

	if broken:
		_status_light.light_color = Color(1.0, 0.1, 0.05)
		_status_light.light_energy = 3.5
		if _emissive_mesh and _emissive_mesh.material_override is StandardMaterial3D:
			(_emissive_mesh.material_override as StandardMaterial3D).emission = Color(0.8, 0.05, 0.02)
	elif running:
		_status_light.light_color = accent_color
		_status_light.light_energy = 3.0
		if _emissive_mesh and _emissive_mesh.material_override is StandardMaterial3D:
			(_emissive_mesh.material_override as StandardMaterial3D).emission = accent_color * 0.7
	else:
		_status_light.light_color = Color(0.35, 0.35, 0.4)
		_status_light.light_energy = 1.2
		if _emissive_mesh and _emissive_mesh.material_override is StandardMaterial3D:
			(_emissive_mesh.material_override as StandardMaterial3D).emission = _base_emission * 0.3

extends RefCounted
## Shared industrial materials for the modular factory map.

var concrete: StandardMaterial3D
var concrete_dark: StandardMaterial3D
var metal: StandardMaterial3D
var metal_rust: StandardMaterial3D
var hazard: StandardMaterial3D
var tile_clean: StandardMaterial3D
var tile_dirty: StandardMaterial3D
var paint_green: StandardMaterial3D
var paint_blue: StandardMaterial3D
var glass: StandardMaterial3D
var door_metal: StandardMaterial3D
var vent: StandardMaterial3D
var blood_stain: StandardMaterial3D
var warning_red: StandardMaterial3D
var pipe_copper: StandardMaterial3D
var pipe_steel: StandardMaterial3D
var wood_crate: StandardMaterial3D


func _init() -> void:
	concrete = _mat(Color(0.42, 0.4, 0.36), 0.92, 0.05)
	concrete_dark = _mat(Color(0.22, 0.21, 0.2), 0.95, 0.02)
	metal = _mat(Color(0.35, 0.38, 0.42), 0.35, 0.75)
	metal_rust = _mat(Color(0.45, 0.28, 0.16), 0.7, 0.55)
	hazard = _mat(Color(0.85, 0.7, 0.12), 0.55, 0.2)
	tile_clean = _mat(Color(0.55, 0.58, 0.6), 0.45, 0.15)
	tile_dirty = _mat(Color(0.32, 0.34, 0.3), 0.85, 0.08)
	paint_green = _mat(Color(0.22, 0.38, 0.28), 0.7, 0.1)
	paint_blue = _mat(Color(0.2, 0.28, 0.42), 0.65, 0.12)
	glass = _mat(Color(0.45, 0.65, 0.75, 0.35), 0.1, 0.05)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	door_metal = _mat(Color(0.25, 0.22, 0.18), 0.4, 0.65)
	vent = _mat(Color(0.3, 0.32, 0.34), 0.5, 0.6)
	blood_stain = _mat(Color(0.35, 0.05, 0.05), 0.9, 0.0)
	warning_red = _mat(Color(0.7, 0.12, 0.08), 0.55, 0.15)
	pipe_copper = _mat(Color(0.55, 0.32, 0.18), 0.4, 0.7)
	pipe_steel = _mat(Color(0.4, 0.42, 0.45), 0.3, 0.8)
	wood_crate = _mat(Color(0.4, 0.28, 0.16), 0.85, 0.05)


func wall_for_role(role: StringName) -> StandardMaterial3D:
	match role:
		&"lab", &"medbay", &"shower":
			return tile_clean
		&"office", &"archive", &"cctv", &"server":
			return paint_blue
		&"boiler", &"generator", &"tunnel", &"pump":
			return concrete_dark
		&"horror_lab", &"morgue", &"cage", &"waste":
			return metal_rust
		&"reactor_hall", &"secret_lab", &"control":
			return paint_green
		&"roof":
			return concrete
		_:
			return concrete


func floor_for_role(role: StringName) -> StandardMaterial3D:
	match role:
		&"lab", &"medbay", &"shower", &"canteen":
			return tile_clean
		&"warehouse", &"loading", &"production":
			return concrete
		&"horror_lab", &"morgue", &"waste", &"tunnel":
			return tile_dirty
		&"roof":
			return concrete_dark
		_:
			return concrete_dark


static func _mat(color: Color, roughness: float, metallic: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	m.metallic = metallic
	return m

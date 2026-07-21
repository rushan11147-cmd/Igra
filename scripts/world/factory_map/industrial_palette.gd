extends RefCounted
## Shared industrial materials for the modular factory map.

const FLOOR_TEX := "res://assets/textures/floors/concrete_floor.png"
const FLOOR_TEX_WORN := "res://assets/textures/floors/concrete_floor_worn.png"
const WALL_TEX := "res://assets/textures/walls/rebar_concrete.png"

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
var floor_concrete: StandardMaterial3D
var floor_concrete_worn: StandardMaterial3D
var floor_concrete_horror: StandardMaterial3D
var floor_marble: StandardMaterial3D
var floor_marble_worn: StandardMaterial3D
var floor_marble_horror: StandardMaterial3D


func _init() -> void:
	# Walls use the rebar concrete albedo; tint shifts room mood without losing detail.
	concrete = _wall_tex(Color(1.0, 1.0, 1.0), 0.9, 0.0, 0.55)
	concrete_dark = _wall_tex(Color(0.55, 0.52, 0.5), 0.94, 0.0, 0.55)
	tile_clean = _wall_tex(Color(0.85, 0.88, 0.9), 0.55, 0.05, 0.7)
	tile_dirty = _wall_tex(Color(0.55, 0.58, 0.52), 0.88, 0.04, 0.6)
	paint_green = _wall_tex(Color(0.45, 0.7, 0.5), 0.75, 0.04, 0.55)
	paint_blue = _wall_tex(Color(0.45, 0.55, 0.75), 0.72, 0.05, 0.55)
	metal_rust = _wall_tex(Color(0.85, 0.55, 0.35), 0.78, 0.2, 0.5)

	metal = _mat(Color(0.42, 0.44, 0.48), 0.4, 0.7)
	hazard = _mat(Color(0.85, 0.7, 0.12), 0.55, 0.2)
	glass = _mat(Color(0.45, 0.65, 0.75, 0.35), 0.1, 0.05)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	door_metal = _mat(Color(0.3, 0.28, 0.24), 0.45, 0.6)
	vent = _mat(Color(0.34, 0.36, 0.38), 0.55, 0.55)
	blood_stain = _mat(Color(0.35, 0.05, 0.05), 0.9, 0.0)
	warning_red = _mat(Color(0.7, 0.12, 0.08), 0.55, 0.15)
	pipe_copper = _mat(Color(0.55, 0.32, 0.18), 0.4, 0.7)
	pipe_steel = _mat(Color(0.4, 0.42, 0.45), 0.3, 0.8)
	wood_crate = _mat(Color(0.4, 0.28, 0.16), 0.85, 0.05)

	floor_concrete = _triplanar_tex(FLOOR_TEX, Color(1, 1, 1), 0.88, 0.0, 0.45)
	floor_concrete_worn = _triplanar_tex(FLOOR_TEX_WORN, Color(0.95, 0.93, 0.9), 0.92, 0.0, 0.5)
	floor_concrete_horror = _triplanar_tex(FLOOR_TEX_WORN, Color(0.7, 0.52, 0.5), 0.9, 0.0, 0.55)
	floor_marble = floor_concrete
	floor_marble_worn = floor_concrete_worn
	floor_marble_horror = floor_concrete_horror


func wall_for_role(role: StringName) -> StandardMaterial3D:
	match role:
		&"lab", &"medbay", &"shower":
			return tile_clean
		&"office", &"archive", &"cctv", &"server":
			return paint_blue
		&"boiler", &"generator", &"tunnel", &"pump", &"stairwell", &"elevator":
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
		&"roof":
			return concrete_dark
		&"horror_lab", &"morgue", &"waste", &"cage", &"ruin", &"secret_tunnel", &"experiment":
			return floor_concrete_horror
		&"warehouse", &"loading", &"production", &"line", &"reactor_bay", &"boiler", &"generator", &"tunnel", &"sewer", &"pump", &"stairwell":
			return floor_concrete_worn
		_:
			return floor_concrete


static func _mat(color: Color, roughness: float, metallic: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	m.metallic = metallic
	return m


static func _wall_tex(tint: Color, roughness: float, metallic: float, world_scale: float) -> StandardMaterial3D:
	return _triplanar_tex(WALL_TEX, tint, roughness, metallic, world_scale)


static func _triplanar_tex(
	path: String,
	tint: Color,
	roughness: float,
	metallic: float,
	world_scale: float
) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = tint
	m.roughness = roughness
	m.metallic = metallic
	if ResourceLoader.exists(path):
		var tex: Texture2D = load(path)
		m.albedo_texture = tex
		m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_triplanar_sharpness = 1.0
	m.uv1_scale = Vector3(world_scale, world_scale, world_scale)
	return m

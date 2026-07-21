extends Node
## Catalog of Megascans warehouse_mid props by gameplay role (autoload).

const ROOT := "res://assets/warehouse_mid/"

const LARGE_MACHINES: Array[String] = [
	"wbslaikga",
	"wbuidixga",
	"vgyiedcaw",
	"villceo",
]

const STORAGE: Array[String] = [
	"vh3lbfy",
	"vhtibbe",
	"vgyiciqaw",
	"vijnbi3",
	"vijnbhf",
	"vijnbjz",
	"virvfjk",
	"vizqehw",
]

const BOXES: Array[String] = [
	"tlbjdbova",
	"uewlfg2va",
	"tkwmdexva",
	"vifpcdyaw",
	"vifpceyaw",
	"vifpcfpaw",
]

const FURNITURE: Array[String] = [
	"ukknbeyaw",
	"ukwteiiaw",
	"vh1jegi",
	"vhskccxaw",
]

const CONSTRUCTION: Array[String] = [
	"vh1icei",
	"vh1jeck",
	"virqcfw",
	"wdkmabe",
	"tewscfuda",
	"teraccgda",
	"teufceuda",
]

const PROPS: Array[String] = [
	"vgyidebaw",
	"vhtmaifaw",
	"vidrear",
	"vgyidfpaw",
	"vgyide1aw",
	"vgyiea1aw",
	"vh1hehj",
	"vimrdhl",
	"vjvraja",
	"vjvrbbb",
	"vjwtbd1",
	"vicifcy",
	"vieldbo",
	"vigvahd",
	"vktifj1ga",
	"vgyidauaw",
	"vgyidbkaw",
	"vh2jfg1s",
	"vh2jfjes",
	"ui1maewga",
	"uizhacnga",
	"ujyqaelga",
	"uiohbdnfa",
	"vjhledeaw",
	"wcwsfjbdw",
	"wdqqeae",
]

const MAT_WALL := "shhnouh"
const MAT_WALL_ALT := "smtmsan"
const MAT_FLOOR := "ugcmfivcw"
const MAT_FLOOR_ALT := "vd3kcjs"
const MAT_DIRTY := "smsqo0n"


func fbx_path(asset_id: String) -> String:
	return ROOT + asset_id + "/" + asset_id + ".fbx"


func basecolor_path(asset_id: String) -> String:
	return _first_existing(asset_id, [
		"_2K_Basecolor.JPG", "_2K_Basecolor.jpg",
		"_2K_BaseColor.JPG", "_2K_BaseColor.jpg",
		"_2K_Diffuse.JPG", "_2K_Diffuse.jpg",
	])


func normal_path(asset_id: String) -> String:
	return _first_existing(asset_id, ["_2K_Normal.JPG", "_2K_Normal.jpg"])


func roughness_path(asset_id: String) -> String:
	return _first_existing(asset_id, ["_2K_Roughness.JPG", "_2K_Roughness.jpg"])


func metalness_path(asset_id: String) -> String:
	return _first_existing(asset_id, ["_2K_Metalness.JPG", "_2K_Metalness.jpg"])


func ao_path(asset_id: String) -> String:
	return _first_existing(asset_id, ["_2K_AO.JPG", "_2K_AO.jpg"])


func _first_existing(asset_id: String, suffixes: Array) -> String:
	var folder: String = ROOT + asset_id + "/"
	for suffix in suffixes:
		var p: String = folder + asset_id + String(suffix)
		if ResourceLoader.exists(p):
			return p
	return ""


## Собирает PBR-материал Megascans для ассета.
func make_material(asset_id: String, fallback: Color = Color(0.55, 0.55, 0.55)) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = fallback
	mat.roughness = 0.75
	mat.metallic = 0.05

	var albedo := basecolor_path(asset_id)
	if albedo != "":
		mat.albedo_texture = load(albedo)
		mat.albedo_color = Color.WHITE

	var normal := normal_path(asset_id)
	if normal != "":
		mat.normal_enabled = true
		mat.normal_texture = load(normal)
		mat.normal_scale = 1.0

	var rough := roughness_path(asset_id)
	if rough != "":
		mat.roughness_texture = load(rough)

	var metal := metalness_path(asset_id)
	if metal != "":
		mat.metallic_texture = load(metal)
		mat.metallic = 1.0

	var ao := ao_path(asset_id)
	if ao != "":
		mat.ao_enabled = true
		mat.ao_texture = load(ao)

	return mat


## Навешивает текстуры Megascans на все MeshInstance3D внутри.
func apply_materials(root: Node, asset_id: String) -> void:
	var mat := make_material(asset_id)
	_apply_material_recursive(root, mat)


func _apply_material_recursive(node: Node, mat: Material) -> void:
	if node is MeshInstance3D:
		(node as MeshInstance3D).material_override = mat
	for child in node.get_children():
		_apply_material_recursive(child, mat)

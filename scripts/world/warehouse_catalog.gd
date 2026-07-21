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
	var folder: String = ROOT + asset_id + "/"
	for name in [
		asset_id + "_2K_Basecolor.JPG",
		asset_id + "_2K_Basecolor.jpg",
		asset_id + "_2K_BaseColor.JPG",
		asset_id + "_2K_BaseColor.jpg",
	]:
		var p: String = folder + name
		if ResourceLoader.exists(p):
			return p
	return ""


func normal_path(asset_id: String) -> String:
	var folder: String = ROOT + asset_id + "/"
	for name in [
		asset_id + "_2K_Normal.JPG",
		asset_id + "_2K_Normal.jpg",
	]:
		var p: String = folder + name
		if ResourceLoader.exists(p):
			return p
	return ""


func roughness_path(asset_id: String) -> String:
	var folder: String = ROOT + asset_id + "/"
	for name in [
		asset_id + "_2K_Roughness.JPG",
		asset_id + "_2K_Roughness.jpg",
	]:
		var p: String = folder + name
		if ResourceLoader.exists(p):
			return p
	return ""

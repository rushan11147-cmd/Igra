extends Node3D
## Reusable crawlable vent duct segment.

const IndustrialPaletteScript = preload("res://scripts/world/factory_map/industrial_palette.gd")
const RoomBuilderScript = preload("res://scripts/world/factory_map/room_builder.gd")

@export var length: float = 8.0
@export var along_x: bool = true


func _ready() -> void:
	var palette = IndustrialPaletteScript.new()
	var builder = RoomBuilderScript.new()
	var h := 1.1
	var w := 1.2
	if along_x:
		builder.add_box(self, Vector3(0, h, 0), Vector3(length, 0.08, w), palette.vent, true, false)
		builder.add_box(self, Vector3(0, h * 0.5, -w * 0.5), Vector3(length, h, 0.08), palette.vent, true, false)
		builder.add_box(self, Vector3(0, h * 0.5, w * 0.5), Vector3(length, h, 0.08), palette.vent, true, false)
		builder.add_box(self, Vector3(0, 0.04, 0), Vector3(length, 0.08, w * 0.7), palette.metal, true, false)
	else:
		builder.add_box(self, Vector3(0, h, 0), Vector3(w, 0.08, length), palette.vent, true, false)
		builder.add_box(self, Vector3(-w * 0.5, h * 0.5, 0), Vector3(0.08, h, length), palette.vent, true, false)
		builder.add_box(self, Vector3(w * 0.5, h * 0.5, 0), Vector3(0.08, h, length), palette.vent, true, false)
		builder.add_box(self, Vector3(0, 0.04, 0), Vector3(w * 0.7, 0.08, length), palette.metal, true, false)

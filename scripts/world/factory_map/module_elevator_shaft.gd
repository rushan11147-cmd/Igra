extends Node3D
## Reusable elevator shaft module with framed opening.

const IndustrialPaletteScript = preload("res://scripts/world/factory_map/industrial_palette.gd")
const RoomBuilderScript = preload("res://scripts/world/factory_map/room_builder.gd")

@export var shaft_height: float = 5.0
@export var shaft_size: Vector3 = Vector3(3.0, 5.0, 3.0)


func _ready() -> void:
	var palette = IndustrialPaletteScript.new()
	var builder = RoomBuilderScript.new()
	var h := shaft_height
	var w := shaft_size.x
	var d := shaft_size.z
	builder.add_box(self, Vector3(-w * 0.5, h * 0.5, 0), Vector3(0.2, h, d), palette.metal, true, true)
	builder.add_box(self, Vector3(w * 0.5, h * 0.5, 0), Vector3(0.2, h, d), palette.metal, true, true)
	builder.add_box(self, Vector3(0, h * 0.5, -d * 0.5), Vector3(w, h, 0.2), palette.metal, true, true)
	builder.add_box(self, Vector3(0, h - 0.2, d * 0.5), Vector3(w, 0.4, 0.2), palette.metal, true, false)
	builder.add_box(self, Vector3(0, 0.05, 0), Vector3(w - 0.4, 0.1, d - 0.4), palette.hazard, true, false)

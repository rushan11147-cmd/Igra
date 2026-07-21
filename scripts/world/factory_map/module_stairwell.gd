extends Node3D
## Reusable stairwell module: local flight of industrial stairs.

const IndustrialPaletteScript = preload("res://scripts/world/factory_map/industrial_palette.gd")
const RoomBuilderScript = preload("res://scripts/world/factory_map/room_builder.gd")

@export var flight_height: float = 5.0
@export var step_run: float = 0.32
@export var width: float = 2.4


func _ready() -> void:
	var palette = IndustrialPaletteScript.new()
	var builder = RoomBuilderScript.new()
	var steps := maxi(int(flight_height / 0.25), 8)
	var step_h := flight_height / float(steps)
	for i in steps:
		var pos := Vector3(0, step_h * (float(i) + 0.5), step_run * float(i))
		builder.add_box(self, pos, Vector3(width, absf(step_h), step_run), palette.metal, true, false)
	builder.add_box(
		self,
		Vector3(-width * 0.5 - 0.05, flight_height * 0.5, step_run * float(steps) * 0.5),
		Vector3(0.08, flight_height, step_run * float(steps)),
		palette.metal,
		false
	)
	builder.add_box(
		self,
		Vector3(width * 0.5 + 0.05, flight_height * 0.5, step_run * float(steps) * 0.5),
		Vector3(0.08, flight_height, step_run * float(steps)),
		palette.metal,
		false
	)

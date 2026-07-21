extends RefCounted
## Stairs between floors and elevator teleport pads.

const ElevatorPadScript = preload("res://scripts/world/factory_map/elevator_pad.gd")
const LayoutDataScript = preload("res://scripts/world/factory_map/layout_data.gd")

const STAIR_A := Vector3(-47, 0, 45)
const STAIR_B := Vector3(47, 0, 45)
const ELEV_CARGO := Vector3(-47, 0, -43)
const ELEV_TECH := Vector3(47, 0, -43)


static func build(root: Node3D, palette, builder) -> void:
	var levels: Array = LayoutDataScript.level_ids()
	for i in levels.size() - 1:
		var id_a: StringName = levels[i]
		var id_b: StringName = levels[i + 1]
		var y0: float = LayoutDataScript.level_y(id_a)
		var y1: float = LayoutDataScript.level_y(id_b)
		_stair_flight(root, STAIR_A, y0, y1, palette, builder)
		_stair_flight(root, STAIR_B, y0, y1, palette, builder)

	_make_elevator_bank(root, ELEV_CARGO, &"cargo", palette, builder)
	_make_elevator_bank(root, ELEV_TECH, &"tech", palette, builder)


static func _stair_flight(root: Node3D, base_xz: Vector3, y0: float, y1: float, palette, builder) -> void:
	var dy := y1 - y0
	var steps := int(absf(dy) / 0.25)
	steps = maxi(steps, 8)
	var step_h := dy / float(steps)
	var run := 0.32
	for i in steps:
		var t := float(i)
		var pos := Vector3(base_xz.x, y0 + step_h * (t + 0.5), base_xz.z + run * t)
		builder.add_box(root, pos, Vector3(2.4, absf(step_h), run), palette.metal, true, false)
	builder.add_box(
		root,
		Vector3(base_xz.x - 1.35, (y0 + y1) * 0.5, base_xz.z + run * float(steps) * 0.5),
		Vector3(0.08, absf(dy), run * float(steps)),
		palette.metal,
		false
	)
	builder.add_box(
		root,
		Vector3(base_xz.x + 1.35, (y0 + y1) * 0.5, base_xz.z + run * float(steps) * 0.5),
		Vector3(0.08, absf(dy), run * float(steps)),
		palette.metal,
		false
	)


static func _make_elevator_bank(root: Node3D, xz: Vector3, bank_id: StringName, palette, builder) -> void:
	var levels: Array = LayoutDataScript.level_ids()
	for level_id in levels:
		var y: float = LayoutDataScript.level_y(level_id)
		builder.add_box(root, Vector3(xz.x, y + 2.2, xz.z), Vector3(3.2, 4.4, 0.2), palette.metal, true, false)
		var pad := Area3D.new()
		pad.name = "Elevator_%s_%s" % [String(bank_id), String(level_id)]
		pad.position = Vector3(xz.x, y + 1.0, xz.z)
		pad.collision_layer = 0
		pad.collision_mask = 2
		pad.monitoring = true
		pad.monitorable = false
		var col := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(2.4, 2.0, 2.4)
		col.shape = shape
		pad.add_child(col)
		pad.set_script(ElevatorPadScript)
		pad.set("bank_id", bank_id)
		pad.set("level_id", level_id)
		root.add_child(pad)
		builder.add_box(root, Vector3(xz.x + 1.4, y + 1.4, xz.z), Vector3(0.12, 0.8, 0.4), palette.hazard, false)

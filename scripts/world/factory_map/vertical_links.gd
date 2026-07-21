extends RefCounted
## Stairs between floors and elevator teleport pads.

const ElevatorPadScript = preload("res://scripts/world/factory_map/elevator_pad.gd")
const LayoutDataScript = preload("res://scripts/world/factory_map/layout_data.gd")

const STAIR_A := Vector3(-47, 0, 45)
const STAIR_B := Vector3(47, 0, 45)
const ELEV_CARGO := Vector3(-47, 0, -43)
const ELEV_TECH := Vector3(47, 0, -43)

const STEP_WIDTH := 2.2
const SPAN := 8.0
const ROOM_HALF := 5.0


static func build(root: Node3D, palette, builder) -> void:
	var levels: Array = LayoutDataScript.level_ids()
	for i in levels.size() - 1:
		var id_a: StringName = levels[i]
		var id_b: StringName = levels[i + 1]
		var y0: float = LayoutDataScript.level_y(id_a)
		var y1: float = LayoutDataScript.level_y(id_b)
		_stair_flight(root, STAIR_A, y0, y1, palette, builder)
		_stair_flight(root, STAIR_B, y0, y1, palette, builder)

	# Small door pads only (not full-length decks that read as partitions).
	for level_id in levels:
		var y: float = LayoutDataScript.level_y(level_id)
		_door_pad(root, STAIR_A, y, 1.0, palette, builder)
		_door_pad(root, STAIR_B, y, -1.0, palette, builder)

	_make_elevator_bank(root, ELEV_CARGO, &"cargo", +1.0, palette, builder)
	_make_elevator_bank(root, ELEV_TECH, &"tech", -1.0, palette, builder)


static func _stair_flight(
	root: Node3D,
	base_xz: Vector3,
	y0: float,
	y1: float,
	palette,
	builder
) -> void:
	var dy := y1 - y0
	var steps := maxi(int(absf(dy) / 0.22), 10)
	var step_h := dy / float(steps)
	var run := SPAN / float(steps)
	var z_start := base_xz.z - SPAN * 0.5
	for i in steps:
		var t := float(i)
		var pos := Vector3(base_xz.x, y0 + step_h * (t + 0.5), z_start + run * (t + 0.5))
		builder.add_box(root, pos, Vector3(STEP_WIDTH, absf(step_h), run * 0.98), palette.metal, true, false)

	# Visual rails only — no collision.
	var rail_z := z_start + SPAN * 0.5
	builder.add_box(
		root,
		Vector3(base_xz.x - STEP_WIDTH * 0.5 - 0.06, (y0 + y1) * 0.5, rail_z),
		Vector3(0.08, absf(dy), SPAN),
		palette.metal,
		false
	)
	builder.add_box(
		root,
		Vector3(base_xz.x + STEP_WIDTH * 0.5 + 0.06, (y0 + y1) * 0.5, rail_z),
		Vector3(0.08, absf(dy), SPAN),
		palette.metal,
		false
	)


static func _door_pad(
	root: Node3D,
	base_xz: Vector3,
	y: float,
	entrance_sign: float,
	palette,
	builder
) -> void:
	# Compact pad from doorway to stair edge — does not cover the stair column.
	var stair_edge := base_xz.x + entrance_sign * (STEP_WIDTH * 0.5)
	var wall_x := base_xz.x + entrance_sign * ROOM_HALF
	var gap := 0.05
	var inner := stair_edge + entrance_sign * gap
	var walk_w := absf(wall_x - inner)
	if walk_w < 0.4:
		return
	var cx := (inner + wall_x) * 0.5
	builder.add_box(
		root,
		Vector3(cx, y, base_xz.z),
		Vector3(walk_w, 0.16, 3.2),
		palette.metal,
		true,
		false
	)


static func _make_elevator_bank(
	root: Node3D,
	xz: Vector3,
	bank_id: StringName,
	door_x_dir: float,
	palette,
	builder
) -> void:
	var levels: Array = LayoutDataScript.level_ids()
	for level_id in levels:
		var y: float = LayoutDataScript.level_y(level_id)
		builder.add_box(
			root,
			Vector3(xz.x, y + 0.05, xz.z),
			Vector3(2.2, 0.12, 2.2),
			palette.hazard,
			true,
			false
		)
		builder.add_box(
			root,
			Vector3(xz.x + door_x_dir * 1.5, y + 1.4, xz.z),
			Vector3(0.1, 0.7, 0.35),
			palette.hazard,
			false
		)
		var pad := Area3D.new()
		pad.name = "Elevator_%s_%s" % [String(bank_id), String(level_id)]
		pad.position = Vector3(xz.x, y + 1.0, xz.z)
		pad.collision_layer = 0
		pad.collision_mask = 2
		pad.monitoring = true
		pad.monitorable = false
		var col := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(1.8, 2.0, 1.8)
		col.shape = shape
		pad.add_child(col)
		pad.set_script(ElevatorPadScript)
		pad.bank_id = bank_id
		pad.level_id = level_id
		root.add_child(pad)

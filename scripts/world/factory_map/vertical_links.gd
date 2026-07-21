extends RefCounted
## Solid stair towers + elevator pads between factory levels.

const ElevatorPadScript = preload("res://scripts/world/factory_map/elevator_pad.gd")
const LayoutDataScript = preload("res://scripts/world/factory_map/layout_data.gd")

const STAIR_A := Vector3(-47, 0, 45)
const STAIR_B := Vector3(47, 0, 45)
const ELEV_CARGO := Vector3(-47, 0, -43)
const ELEV_TECH := Vector3(47, 0, -43)

## Inner clear size of the 10×10 stair room.
const WELL := 9.0
const FLIGHT_W := 2.2
const STEP_H := 0.22
const STEP_RUN := 0.3
const DECK_T := 0.2


static func build(root: Node3D, palette, builder) -> void:
	var levels: Array = LayoutDataScript.level_ids()
	_build_stair_tower(root, STAIR_A, levels, +1.0, palette, builder)
	_build_stair_tower(root, STAIR_B, levels, -1.0, palette, builder)
	_make_elevator_bank(root, ELEV_CARGO, &"cargo", +1.0, palette, builder)
	_make_elevator_bank(root, ELEV_TECH, &"tech", -1.0, palette, builder)


static func _build_stair_tower(
	root: Node3D,
	center: Vector3,
	levels: Array,
	door_x_dir: float,
	palette,
	builder
) -> void:
	var tower := Node3D.new()
	tower.name = "StairTower_%d_%d" % [int(center.x), int(center.z)]
	root.add_child(tower)

	for i in levels.size():
		var y: float = LayoutDataScript.level_y(levels[i])
		var is_bottom := i == 0
		_deck(tower, center, y, door_x_dir, is_bottom, palette, builder)
		if i < levels.size() - 1:
			var y1: float = LayoutDataScript.level_y(levels[i + 1])
			_story_stairs(tower, center, y, y1, door_x_dir, palette, builder)


static func _deck(
	root: Node3D,
	center: Vector3,
	y: float,
	door_x_dir: float,
	is_bottom: bool,
	palette,
	builder
) -> void:
	# Full solid deck. Upper floors keep a tight stair hatch so the shaft is not see-through.
	var half := WELL * 0.5
	if is_bottom:
		builder.add_box(
			root,
			Vector3(center.x, y - DECK_T * 0.5, center.z),
			Vector3(WELL, DECK_T, WELL),
			palette.concrete,
			true,
			false
		)
		return

	# Hatch over the ascending flight (door-side half kept solid for entry).
	var hatch_w := FLIGHT_W + 0.35
	var hatch_d := 4.6
	var hatch_x := center.x - door_x_dir * 1.35
	var hatch_z := center.z
	var pieces: Array = _subtract_rect(
		Rect2(center.x - half, center.z - half, WELL, WELL),
		Rect2(hatch_x - hatch_w * 0.5, hatch_z - hatch_d * 0.5, hatch_w, hatch_d)
	)
	for piece_variant in pieces:
		var piece: Rect2 = piece_variant
		if piece.size.x < 0.15 or piece.size.y < 0.15:
			continue
		builder.add_box(
			root,
			Vector3(piece.position.x + piece.size.x * 0.5, y - DECK_T * 0.5, piece.position.y + piece.size.y * 0.5),
			Vector3(piece.size.x, DECK_T, piece.size.y),
			palette.concrete,
			true,
			false
		)
	# Rail around hatch
	builder.add_box(
		root,
		Vector3(hatch_x + door_x_dir * hatch_w * 0.5, y + 0.55, hatch_z),
		Vector3(0.06, 1.1, hatch_d),
		palette.metal,
		false
	)


static func _story_stairs(
	root: Node3D,
	center: Vector3,
	y0: float,
	y1: float,
	door_x_dir: float,
	palette,
	builder
) -> void:
	var dy := y1 - y0
	if absf(dy) < 0.4:
		return
	var mid_y := y0 + dy * 0.5
	# Lower flight: away from door, going +Z
	var x_left := center.x - door_x_dir * 1.35
	_flight(root, x_left, center.z - 1.8, y0, mid_y, +1.0, palette, builder)
	# Mid landing
	builder.add_box(
		root,
		Vector3(center.x, mid_y - DECK_T * 0.5, center.z + 2.6),
		Vector3(FLIGHT_W * 2.2, DECK_T, 1.8),
		palette.concrete,
		true,
		false
	)
	# Upper flight: toward door side, going -Z up to next deck
	var x_right := center.x + door_x_dir * 1.35
	_flight(root, x_right, center.z + 1.8, mid_y, y1, -1.0, palette, builder)


static func _flight(
	root: Node3D,
	x: float,
	z_start: float,
	y0: float,
	y1: float,
	z_dir: float,
	palette,
	builder
) -> void:
	var dy := y1 - y0
	var steps := maxi(int(ceil(absf(dy) / STEP_H)), 8)
	var step_h := dy / float(steps)
	# Overlap steps so there are no see-through gaps.
	var run := STEP_RUN
	for i in steps:
		var t := float(i)
		var pos := Vector3(
			x,
			y0 + step_h * (t + 0.5),
			z_start + z_dir * run * t
		)
		builder.add_box(
			root,
			pos,
			Vector3(FLIGHT_W, maxf(absf(step_h) + 0.04, 0.12), run + 0.04),
			palette.concrete,
			true,
			false
		)
	# Side stringer (closes the side view)
	var depth := run * float(steps)
	builder.add_box(
		root,
		Vector3(x - FLIGHT_W * 0.55, (y0 + y1) * 0.5, z_start + z_dir * depth * 0.5),
		Vector3(0.1, absf(dy) + 0.15, depth + 0.1),
		palette.concrete_dark,
		true,
		false
	)
	builder.add_box(
		root,
		Vector3(x + FLIGHT_W * 0.55, (y0 + y1) * 0.5, z_start + z_dir * depth * 0.5),
		Vector3(0.1, absf(dy) + 0.15, depth + 0.1),
		palette.concrete_dark,
		true,
		false
	)
	# Handrail
	builder.add_box(
		root,
		Vector3(x + FLIGHT_W * 0.5, (y0 + y1) * 0.5 + 0.5, z_start + z_dir * depth * 0.5),
		Vector3(0.05, 0.06, depth),
		palette.metal,
		false
	)


static func _subtract_rect(base: Rect2, hole: Rect2) -> Array:
	var cut := base.intersection(hole)
	if cut.size.x <= 0.01 or cut.size.y <= 0.01:
		return [base]
	var out: Array = []
	var left := cut.position.x - base.position.x
	if left > 0.05:
		out.append(Rect2(base.position.x, base.position.y, left, base.size.y))
	var right := (base.position.x + base.size.x) - (cut.position.x + cut.size.x)
	if right > 0.05:
		out.append(Rect2(cut.position.x + cut.size.x, base.position.y, right, base.size.y))
	var mid_x := cut.position.x
	var mid_w := cut.size.x
	var bottom := cut.position.y - base.position.y
	if bottom > 0.05:
		out.append(Rect2(mid_x, base.position.y, mid_w, bottom))
	var top := (base.position.y + base.size.y) - (cut.position.y + cut.size.y)
	if top > 0.05:
		out.append(Rect2(mid_x, cut.position.y + cut.size.y, mid_w, top))
	return out


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

extends RefCounted
## Builds floors, walls with door openings, ceilings, and occluders.

const WALL_H := 4.4
const WALL_T := 0.3
const CEIL_T := 0.18
const DOOR_W := 2.8
const DOOR_H := 2.7
const FLOOR_T := 0.2
const OPENING_MATCH_EPS := 0.35


func add_box(
	parent: Node3D,
	pos: Vector3,
	size: Vector3,
	mat: Material,
	with_collision: bool = true,
	occlude: bool = false
) -> MeshInstance3D:
	var mesh_inst := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh_inst.mesh = box
	mesh_inst.material_override = mat
	mesh_inst.position = pos
	if with_collision:
		var body := StaticBody3D.new()
		body.position = pos
		var col := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		col.shape = shape
		var visual := MeshInstance3D.new()
		visual.mesh = box
		visual.material_override = mat
		body.add_child(visual)
		body.add_child(col)
		if occlude and size.x * size.y * size.z > 8.0:
			var occ := OccluderInstance3D.new()
			var occ_shape := BoxOccluder3D.new()
			occ_shape.size = size
			occ.occluder = occ_shape
			body.add_child(occ)
		parent.add_child(body)
		return visual
	parent.add_child(mesh_inst)
	return mesh_inst


func add_floor_slab(parent: Node3D, rect: Rect2, y: float, mat: Material) -> void:
	var cx := rect.position.x + rect.size.x * 0.5
	var cz := rect.position.y + rect.size.y * 0.5
	add_box(parent, Vector3(cx, y - FLOOR_T * 0.5, cz), Vector3(rect.size.x, FLOOR_T, rect.size.y), mat, true, false)


func add_ceiling(parent: Node3D, rect: Rect2, y: float, mat: Material) -> void:
	var cx := rect.position.x + rect.size.x * 0.5
	var cz := rect.position.y + rect.size.y * 0.5
	add_box(parent, Vector3(cx, y + WALL_H + CEIL_T * 0.5, cz), Vector3(rect.size.x, CEIL_T, rect.size.y), mat, true, true)


## Opening dict: { "along_x": bool, "fixed": float, "mid": float, "width": float }
func collect_world_openings(rooms: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for room_data in rooms:
		var rect: Rect2 = room_data["rect"]
		var openings: Array = room_data.get("openings", [])
		var x0 := rect.position.x
		var z0 := rect.position.y
		var x1 := x0 + rect.size.x
		var z1 := z0 + rect.size.y
		for item in openings:
			var wall: StringName = StringName(item.get("wall", &""))
			var t: float = float(item.get("t", 0.5))
			var w: float = float(item.get("w", DOOR_W))
			match wall:
				&"s":
					result.append({"along_x": true, "fixed": z0, "mid": lerpf(x0, x1, t), "width": w})
				&"n":
					result.append({"along_x": true, "fixed": z1, "mid": lerpf(x0, x1, t), "width": w})
				&"w":
					result.append({"along_x": false, "fixed": x0, "mid": lerpf(z0, z1, t), "width": w})
				&"e":
					result.append({"along_x": false, "fixed": x1, "mid": lerpf(z0, z1, t), "width": w})
	return result


func add_room_shell(
	parent: Node3D,
	rect: Rect2,
	y: float,
	wall_mat: Material,
	floor_mat: Material,
	ceil_mat: Material,
	openings: Array,
	build_ceiling: bool = true,
	world_openings: Array = []
) -> void:
	add_floor_slab(parent, rect, y, floor_mat)
	if build_ceiling:
		add_ceiling(parent, rect, y, ceil_mat)

	var x0 := rect.position.x
	var z0 := rect.position.y
	var x1 := x0 + rect.size.x
	var z1 := z0 + rect.size.y

	_wall_with_openings(parent, true, z0, x0, x1, y, wall_mat, openings, &"s", world_openings)
	_wall_with_openings(parent, true, z1, x0, x1, y, wall_mat, openings, &"n", world_openings)
	_wall_with_openings(parent, false, x0, z0, z1, y, wall_mat, openings, &"w", world_openings)
	_wall_with_openings(parent, false, x1, z0, z1, y, wall_mat, openings, &"e", world_openings)


func _wall_with_openings(
	parent: Node3D,
	along_x: bool,
	fixed: float,
	a0: float,
	a1: float,
	y: float,
	mat: Material,
	openings: Array,
	side: StringName,
	world_openings: Array = []
) -> void:
	var gaps: Array[Dictionary] = []

	for item in openings:
		if StringName(item.get("wall", &"")) != side:
			continue
		var t: float = float(item.get("t", 0.5))
		var w: float = float(item.get("w", DOOR_W))
		var mid := lerpf(a0, a1, t)
		gaps.append({"mid": mid, "half": w * 0.5})

	# Also cut holes for openings declared by neighboring rooms on this same wall plane.
	for wo in world_openings:
		if bool(wo.get("along_x", false)) != along_x:
			continue
		if absf(float(wo.get("fixed", 0.0)) - fixed) > OPENING_MATCH_EPS:
			continue
		var mid2: float = float(wo.get("mid", 0.0))
		if mid2 < a0 - 0.05 or mid2 > a1 + 0.05:
			continue
		var half2: float = float(wo.get("width", DOOR_W)) * 0.5
		gaps.append({"mid": mid2, "half": half2})

	if gaps.is_empty():
		_solid_wall_segment(parent, along_x, fixed, a0, a1, y, mat)
		return

	gaps.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["mid"]) < float(b["mid"]))
	gaps = _merge_overlapping_gaps(gaps)

	var cursor := a0
	for g in gaps:
		var left := float(g["mid"]) - float(g["half"])
		var right := float(g["mid"]) + float(g["half"])
		left = clampf(left, a0, a1)
		right = clampf(right, a0, a1)
		if left > cursor + 0.05:
			_solid_wall_segment(parent, along_x, fixed, cursor, left, y, mat)
		if right > left + 0.05:
			_door_header(parent, along_x, fixed, (left + right) * 0.5, right - left, y, mat)
		cursor = maxf(cursor, right)
	if a1 > cursor + 0.05:
		_solid_wall_segment(parent, along_x, fixed, cursor, a1, y, mat)


func _merge_overlapping_gaps(gaps: Array[Dictionary]) -> Array[Dictionary]:
	if gaps.is_empty():
		return gaps
	var merged: Array[Dictionary] = []
	var cur := gaps[0].duplicate()
	for i in range(1, gaps.size()):
		var g: Dictionary = gaps[i]
		var cur_left := float(cur["mid"]) - float(cur["half"])
		var cur_right := float(cur["mid"]) + float(cur["half"])
		var g_left := float(g["mid"]) - float(g["half"])
		var g_right := float(g["mid"]) + float(g["half"])
		if g_left <= cur_right + 0.15:
			var new_left := minf(cur_left, g_left)
			var new_right := maxf(cur_right, g_right)
			cur["mid"] = (new_left + new_right) * 0.5
			cur["half"] = (new_right - new_left) * 0.5
		else:
			merged.append(cur)
			cur = g.duplicate()
	merged.append(cur)
	return merged


func _solid_wall_segment(
	parent: Node3D, along_x: bool, fixed: float, a0: float, a1: float, y: float, mat: Material
) -> void:
	var length := a1 - a0
	if length < 0.05:
		return
	var mid := (a0 + a1) * 0.5
	if along_x:
		add_box(
			parent,
			Vector3(mid, y + WALL_H * 0.5, fixed),
			Vector3(length, WALL_H, WALL_T),
			mat,
			true,
			true
		)
	else:
		add_box(
			parent,
			Vector3(fixed, y + WALL_H * 0.5, mid),
			Vector3(WALL_T, WALL_H, length),
			mat,
			true,
			true
		)


func _door_header(
	parent: Node3D, along_x: bool, fixed: float, mid: float, width: float, y: float, mat: Material
) -> void:
	var header_h := WALL_H - DOOR_H
	if header_h <= 0.05:
		return
	var hy := y + DOOR_H + header_h * 0.5
	# Header only — no collision below door height. Slightly thinner than wall so jambs feel open.
	if along_x:
		add_box(parent, Vector3(mid, hy, fixed), Vector3(width, header_h, WALL_T * 0.85), mat, true, false)
	else:
		add_box(parent, Vector3(fixed, hy, mid), Vector3(WALL_T * 0.85, header_h, width), mat, true, false)


func add_column(parent: Node3D, pos: Vector3, mat: Material) -> void:
	add_box(parent, pos + Vector3(0, WALL_H * 0.5, 0), Vector3(0.45, WALL_H, 0.45), mat, true, false)

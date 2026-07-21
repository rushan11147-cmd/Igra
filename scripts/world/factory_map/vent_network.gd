extends RefCounted
## Crawlable ventilation ducts connecting floors and key rooms.

const LayoutDataScript = preload("res://scripts/world/factory_map/layout_data.gd")

const DUCT_H := 1.1
const DUCT_W := 1.2


static func build(root: Node3D, palette, builder) -> void:
	var vents := Node3D.new()
	vents.name = "VentNetwork"
	root.add_child(vents)

	_vertical_shaft(vents, Vector3(-44, 0, 20), palette, builder)
	_vertical_shaft(vents, Vector3(44, 0, -20), palette, builder)

	for level_id in LayoutDataScript.level_ids():
		if level_id == &"roof":
			continue
		var y: float = LayoutDataScript.level_y(level_id) + 3.6
		_duct_box(vents, Vector3(0, y, 20), Vector3(80, DUCT_H, DUCT_W), palette, builder, true)
		_duct_box(vents, Vector3(0, y, -20), Vector3(80, DUCT_H, DUCT_W), palette, builder, true)
		_duct_box(vents, Vector3(-20, y, 0), Vector3(DUCT_W, DUCT_H, 40), palette, builder, true)
		_duct_box(vents, Vector3(20, y, 0), Vector3(DUCT_W, DUCT_H, 40), palette, builder, true)
		_hatch(vents, Vector3(-20, LayoutDataScript.level_y(level_id) + 2.6, 8), palette, builder)
		_hatch(vents, Vector3(20, LayoutDataScript.level_y(level_id) + 2.6, -8), palette, builder)


static func _vertical_shaft(parent: Node3D, xz: Vector3, palette, builder) -> void:
	var y0: float = LayoutDataScript.level_y(&"basement_02")
	var y1: float = LayoutDataScript.level_y(&"roof")
	var height := y1 - y0 + 2.0
	builder.add_box(parent, Vector3(xz.x - 0.7, y0 + height * 0.5, xz.z), Vector3(0.12, height, 1.4), palette.vent, true)
	builder.add_box(parent, Vector3(xz.x + 0.7, y0 + height * 0.5, xz.z), Vector3(0.12, height, 1.4), palette.vent, true)
	builder.add_box(parent, Vector3(xz.x, y0 + height * 0.5, xz.z - 0.7), Vector3(1.4, height, 0.12), palette.vent, true)
	builder.add_box(parent, Vector3(xz.x, y0 + height * 0.5, xz.z + 0.7), Vector3(1.4, height, 0.12), palette.vent, true)
	for level_id in LayoutDataScript.level_ids():
		var y: float = LayoutDataScript.level_y(level_id)
		builder.add_box(parent, Vector3(xz.x, y + 0.15, xz.z), Vector3(1.0, 0.2, 1.0), palette.metal, true)


static func _duct_box(parent: Node3D, pos: Vector3, size: Vector3, palette, builder, crawlable: bool) -> void:
	if size.x >= size.z:
		builder.add_box(parent, pos + Vector3(0, size.y * 0.5, -size.z * 0.5), Vector3(size.x, size.y, 0.08), palette.vent, true)
		builder.add_box(parent, pos + Vector3(0, size.y * 0.5, size.z * 0.5), Vector3(size.x, size.y, 0.08), palette.vent, true)
		builder.add_box(parent, pos + Vector3(0, size.y, 0), Vector3(size.x, 0.08, size.z), palette.vent, true)
		if crawlable:
			builder.add_box(parent, pos + Vector3(0, 0.04, 0), Vector3(size.x, 0.08, size.z * 0.7), palette.metal, true)
	else:
		builder.add_box(parent, pos + Vector3(-size.x * 0.5, size.y * 0.5, 0), Vector3(0.08, size.y, size.z), palette.vent, true)
		builder.add_box(parent, pos + Vector3(size.x * 0.5, size.y * 0.5, 0), Vector3(0.08, size.y, size.z), palette.vent, true)
		builder.add_box(parent, pos + Vector3(0, size.y, 0), Vector3(size.x, 0.08, size.z), palette.vent, true)
		if crawlable:
			builder.add_box(parent, pos + Vector3(0, 0.04, 0), Vector3(size.x * 0.7, 0.08, size.z), palette.metal, true)


static func _hatch(parent: Node3D, pos: Vector3, palette, builder) -> void:
	builder.add_box(parent, pos, Vector3(1.0, 0.1, 1.0), palette.hazard, false)
	builder.add_box(parent, pos + Vector3(0, 0.6, 0), Vector3(0.08, 1.0, 1.0), palette.vent, true)
	builder.add_box(parent, pos + Vector3(0.5, 0.6, 0), Vector3(0.08, 1.0, 1.0), palette.vent, true)

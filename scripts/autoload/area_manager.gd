extends Node
## Controls which factory areas are accessible. New areas unlock after tasks.

const AREAS: Dictionary = {
	&"hall_a": {
		"name": "Цех A — Производственная линия",
		"unlocked_by_default": true,
		"unlock_task": &"",
	},
	&"hall_b": {
		"name": "Цех B — Реакторный блок",
		"unlocked_by_default": false,
		"unlock_task": &"check_pressure",
	},
	&"warehouse": {
		"name": "Склад",
		"unlocked_by_default": false,
		"unlock_task": &"check_warehouse",
	},
	&"ventilation": {
		"name": "Вентиляционные шахты",
		"unlocked_by_default": false,
		"unlock_task": &"replace_filter",
	},
	&"basement": {
		"name": "Технический подвал",
		"unlocked_by_default": false,
		"unlock_task": &"repair_pump",
	},
	&"basement_1": {
		"name": "Подвал 1 — Инженерные системы",
		"unlocked_by_default": false,
		"unlock_task": &"repair_pump",
	},
	&"basement_2": {
		"name": "Подвал 2 — Заброшенный блок",
		"unlocked_by_default": false,
		"unlock_task": &"repair_pump",
	},
	&"floor2": {
		"name": "Этаж 2 — Производство",
		"unlocked_by_default": true,
		"unlock_task": &"",
	},
	&"floor3": {
		"name": "Этаж 3 — Лаборатории",
		"unlocked_by_default": true,
		"unlock_task": &"",
	},
	&"floor4": {
		"name": "Этаж 4 — Секретный блок",
		"unlocked_by_default": false,
		"unlock_task": &"clean_reactor",
	},
	&"roof": {
		"name": "Крыша — Техническая площадка",
		"unlocked_by_default": true,
		"unlock_task": &"",
	},
	&"director_office": {
		"name": "Кабинет директора",
		"unlocked_by_default": false,
		"unlock_task": &"clean_reactor",
	},
}

var unlocked_areas: Array[StringName] = []


func reset() -> void:
	unlocked_areas.clear()
	for area_id: StringName in AREAS:
		if AREAS[area_id].get("unlocked_by_default", false):
			_unlock(area_id)


func is_unlocked(area_id: StringName) -> bool:
	return area_id in unlocked_areas


func get_area_name(area_id: StringName) -> String:
	return AREAS.get(area_id, {}).get("name", str(area_id))


func on_task_completed(task_id: StringName) -> void:
	for area_id: StringName in AREAS:
		if AREAS[area_id].get("unlock_task", &"") == task_id:
			_unlock(area_id)


func unlock_area(area_id: StringName) -> void:
	_unlock(area_id)


func _unlock(area_id: StringName) -> void:
	if area_id in unlocked_areas:
		return
	unlocked_areas.append(area_id)
	EventBus.area_unlocked.emit(area_id)


func apply_to_scene(root: Node) -> void:
	if root == null:
		return
	for node in root.get_tree().get_nodes_in_group("factory_areas"):
		var area_id: StringName = node.get("area_id") if "area_id" in node else &""
		if area_id == &"":
			continue
		var unlocked := is_unlocked(area_id)
		node.visible = unlocked or node.get("locked_visible") if "locked_visible" in node else unlocked
		_set_collision_enabled(node, unlocked)


func _set_collision_enabled(node: Node, enabled: bool) -> void:
	if node is CollisionObject3D:
		node.set_collision_layer_value(1, enabled)
		node.set_collision_mask_value(1, enabled)
	for child in node.get_children():
		_set_collision_enabled(child, enabled)

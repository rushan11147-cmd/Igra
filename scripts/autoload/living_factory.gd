extends Node
## Factory layout mutates between nights — player can't trust the map.

const MUTATION_POOL: Array[Dictionary] = [
	{"id": &"door_welded", "description": "Дверь в цех B заварена.", "min_night": 3},
	{"id": &"new_corridor", "description": "Появился новый коридор.", "min_night": 5},
	{"id": &"wrong_elevator", "description": "Лифт привозит не на тот этаж.", "min_night": 7},
	{"id": &"moved_closet", "description": "Шкаф для укрытия переехал.", "min_night": 4},
	{"id": &"new_hall", "description": "Открылся новый цех.", "min_night": 8},
	{"id": &"blocked_vent", "description": "Вентиляция частично заблокирована.", "min_night": 10},
	{"id": &"reversed_signs", "description": "Указатели показывают не туда.", "min_night": 6},
]

var active_mutations: Array[Dictionary] = []
var _applied_ids: Array[StringName] = []


func reset() -> void:
	active_mutations.clear()
	# Mutations persist across nights within a playthrough


func generate_for_night(night: int) -> void:
	var available: Array[Dictionary] = []
	for mut in MUTATION_POOL:
		if mut.get("min_night", 1) <= night and mut["id"] not in _applied_ids:
			available.append(mut)

	if available.is_empty():
		return

	# 0-2 new mutations per night after night 3
	var count := 0 if night < 3 else randi_range(0, mini(2, 1 + night / 8))
	for i in count:
		if available.is_empty():
			break
		var pick: Dictionary = available[randi() % available.size()]
		available.erase(pick)
		active_mutations.append(pick)
		_applied_ids.append(pick["id"])

	if not active_mutations.is_empty():
		EventBus.factory_mutated.emit(active_mutations.duplicate())


func apply_to_scene(root: Node) -> void:
	if root == null:
		return
	for mut in active_mutations:
		_apply_mutation(root, mut)


func get_mutation_descriptions() -> String:
	var lines: PackedStringArray = []
	for mut in active_mutations:
		lines.append("• %s" % mut.get("description", ""))
	return "\n".join(lines) if not lines.is_empty() else "Завод без изменений."


func _apply_mutation(root: Node, mut: Dictionary) -> void:
	match mut.get("id"):
		&"door_welded":
			var door := root.get_tree().get_first_node_in_group("door_hall_b")
			if door and door.has_method("weld_shut"):
				door.weld_shut()
		&"moved_closet":
			var closet := root.get_tree().get_first_node_in_group("hiding_spots")
			if closet:
				closet.global_position += Vector3(randf_range(-5, 5), 0, randf_range(-5, 5))
		&"new_hall":
			AreaManager.unlock_area(&"basement")
		&"wrong_elevator":
			pass  # Elevator script will read this flag
		&"blocked_vent":
			pass  # Ventilation areas get disabled


func has_mutation(mut_id: StringName) -> bool:
	for mut in active_mutations:
		if mut.get("id") == mut_id:
			return true
	return false

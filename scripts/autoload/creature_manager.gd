extends Node
## Manages creature types — each behaves differently.

enum CreatureType { OBSERVER, HUNTER, CRAWLER, SHADOW }

const CREATURE_DATA: Dictionary = {
	CreatureType.OBSERVER: {
		"id": &"observer",
		"name": "Наблюдатель",
		"attacks": true,
		"reacts_to_noise": true,
		"reacts_to_light": true,
		"vent_only": false,
		"darkness_only": false,
	},
	CreatureType.HUNTER: {
		"id": &"hunter",
		"name": "Охотник",
		"attacks": true,
		"reacts_to_noise": true,
		"reacts_to_light": false,
		"vent_only": false,
		"darkness_only": false,
	},
	CreatureType.CRAWLER: {
		"id": &"crawler",
		"name": "Ползун",
		"attacks": true,
		"reacts_to_noise": true,
		"reacts_to_light": false,
		"vent_only": true,
		"darkness_only": false,
	},
	CreatureType.SHADOW: {
		"id": &"shadow",
		"name": "Тень",
		"attacks": true,
		"reacts_to_noise": false,
		"reacts_to_light": true,
		"vent_only": false,
		"darkness_only": true,
	},
}

var active_type: CreatureType = CreatureType.OBSERVER
var active_types_tonight: Array[CreatureType] = []


func setup_for_night(night: int) -> void:
	active_types_tonight.clear()

	if night < 3:
		active_type = CreatureType.OBSERVER
	elif night < 8:
		active_type = [CreatureType.OBSERVER, CreatureType.HUNTER].pick_random()
	elif night < 15:
		active_type = [CreatureType.HUNTER, CreatureType.CRAWLER].pick_random()
	else:
		active_type = CreatureType.values().pick_random()

	active_types_tonight.append(active_type)
	if night >= 15 and randf() < 0.4:
		var secondary: CreatureType = CreatureType.values().pick_random()
		if secondary != active_type:
			active_types_tonight.append(secondary)

	EventBus.creature_type_changed.emit(get_active_id())


func get_active_id() -> StringName:
	return CREATURE_DATA[active_type].get("id", &"observer")


func get_active_data() -> Dictionary:
	return CREATURE_DATA[active_type]


func should_attack() -> bool:
	return CREATURE_DATA[active_type].get("attacks", false)


func reacts_to_noise() -> bool:
	return CREATURE_DATA[active_type].get("reacts_to_noise", false)


func reacts_to_light() -> bool:
	return CREATURE_DATA[active_type].get("reacts_to_light", false)


func is_vent_only() -> bool:
	return CREATURE_DATA[active_type].get("vent_only", false)


func is_darkness_only() -> bool:
	return CREATURE_DATA[active_type].get("darkness_only", false)


func force_spawn(type_id: StringName) -> void:
	for type_enum in CreatureType.values():
		if CREATURE_DATA[type_enum].get("id") == type_id:
			active_type = type_enum
			EventBus.creature_type_changed.emit(type_id)
			HorrorSystem.start_manifestation(false)
			return

extends Node
## Sanity system — player can't trust senses, instruments, or task list.

const MAX_SANITY := 100.0
const RECOVER_RATE := 0.3

var sanity: float = 100.0
var active_effects: Array[StringName] = []

const STRESS_SOURCES: Dictionary = {
	&"paranormal": 3.0,
	&"rule_violation": 20.0,
	&"entity_sighting": 8.0,
	&"hallucination": 5.0,
	&"night_event": 6.0,
	&"radio_fake": 12.0,
	&"hall8_opened": 25.0,
	&"hall8_ignored": 10.0,
	&"hall8_power_cut": 15.0,
	&"hall8_peek": 30.0,
}


func _ready() -> void:
	EventBus.paranormal_event.connect(_on_paranormal)
	EventBus.entity_spawned.connect(_on_entity_spawned)
	EventBus.night_event_started.connect(_on_night_event)
	EventBus.radio_message.connect(_on_radio_message)
	EventBus.sanity_effect.connect(_on_sanity_effect)


func _process(delta: float) -> void:
	if sanity < MAX_SANITY:
		sanity = minf(MAX_SANITY, sanity + RECOVER_RATE * delta)
		_update_effects()
		_emit()


func reset() -> void:
	sanity = MAX_SANITY
	active_effects.clear()
	_emit()


func add_stress(amount: float, _source: StringName = &"") -> void:
	sanity = maxf(0.0, sanity - amount)
	_update_effects()
	_emit()


func get_distortion() -> float:
	return 1.0 - (sanity / MAX_SANITY)


func should_hallucinate() -> bool:
	return sanity < 50.0 and randf() < get_distortion() * 0.5


func corrupt_text(original: String) -> String:
	if sanity > 60.0:
		return original
	if randf() > get_distortion() * 0.4:
		return original

	var corruptions: Array[String] = [
		original.replace("Проверить", "Игнорировать"),
		original.replace("Запустить", "Остановить"),
		original + " (?)",
		"Не " + original.to_lower(),
		"..." + original,
	]
	return corruptions[randi() % corruptions.size()]


func distort_reading(actual: float) -> float:
	if sanity > 70.0:
		return actual
	var offset := get_distortion() * randf_range(-20.0, 20.0)
	return actual + offset


func _update_effects() -> void:
	active_effects.clear()
	if sanity < 80.0:
		active_effects.append(&"mild_anxiety")
	if sanity < 60.0:
		active_effects.append(&"whispers")
	if sanity < 40.0:
		active_effects.append(&"false_entities")
	if sanity < 25.0:
		active_effects.append(&"wrong_readings")
	if sanity < 15.0:
		active_effects.append(&"corrupted_tasks")


func _emit() -> void:
	EventBus.sanity_changed.emit(sanity, active_effects.duplicate())


func _on_paranormal(_id: StringName, _data: Dictionary) -> void:
	add_stress(STRESS_SOURCES.get(&"paranormal", 3.0), &"paranormal")


func _on_entity_spawned(is_hallucination: bool, _type: StringName) -> void:
	if is_hallucination:
		add_stress(STRESS_SOURCES.get(&"hallucination", 5.0), &"hallucination")
	else:
		add_stress(STRESS_SOURCES.get(&"entity_sighting", 8.0), &"entity_sighting")


func _on_night_event(_id: StringName, _desc: String) -> void:
	add_stress(STRESS_SOURCES.get(&"night_event", 6.0), &"night_event")


func _on_radio_message(_speaker: String, _text: String, is_fake: bool) -> void:
	if is_fake:
		add_stress(STRESS_SOURCES.get(&"radio_fake", 12.0), &"radio_fake")


func _on_sanity_effect(effect_id: StringName) -> void:
	if effect_id not in active_effects:
		active_effects.append(effect_id)

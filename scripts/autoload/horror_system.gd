extends Node
## Threat escalation driven by player mistakes. Entity studies, not chases.

const THREAT_DECAY_RATE := 0.015
const MAX_THREAT := 100.0

const WEIGHT_OVERHEAT := 8.0
const WEIGHT_DEFECT := 5.0
const WEIGHT_ACCIDENT := 12.0
const WEIGHT_BLACK_MASS := 3.0
const WEIGHT_NOISE := 2.0

var threat_level: float = 0.0
var black_mass_amount: float = 0.0
var entity_active: bool = false
var entity_observing: bool = false
var _night: int = 1
var _phase: int = 0
var _event_cooldown: float = 0.0
var _sabotage_cooldown: float = 0.0

const PHASE_EVENTS: Dictionary = {
	0: [],
	1: [&"camera_glitch", &"distant_footsteps", &"item_moved", &"lights_flicker", &"entity_glimpse", &"whispers"],
	2: [&"camera_figure", &"equipment_auto_start", &"power_outage", &"whispers",
		&"door_slams", &"entity_glimpse", &"hallucination"],
	3: [&"entity_manifest", &"reality_shift", &"mass_breach", &"factory_awakens",
		&"lights_cut", &"equipment_sabotage"],
}

const SABOTAGE_EVENTS: Array[StringName] = [
	&"lights_cut", &"door_slams", &"equipment_sabotage", &"item_moved",
]


func _ready() -> void:
	EventBus.reactor_state_changed.connect(_on_reactor_state)
	EventBus.defect_produced.connect(_on_defect)
	EventBus.emergency_triggered.connect(_on_emergency)
	EventBus.mixer_ratio_changed.connect(_on_mixer_ratio)
	EventBus.player_noise_changed.connect(_on_player_noise)


func _process(delta: float) -> void:
	if threat_level > 0.0:
		threat_level = maxf(0.0, threat_level - THREAT_DECAY_RATE * delta)
		_emit_threat()

	_event_cooldown -= delta
	_sabotage_cooldown -= delta

	if _event_cooldown <= 0.0 and _phase >= 1:
		_try_paranormal_event()

	if _sabotage_cooldown <= 0.0 and entity_active and _phase >= 2:
		_try_sabotage()


func reset_for_night(night: int) -> void:
	_night = night
	_phase = GameManager.get_horror_phase()
	threat_level = 18.0 + _phase * 8.0
	black_mass_amount = maxf(0.0, black_mass_amount - 8.0)
	entity_active = false
	entity_observing = false
	_event_cooldown = 12.0
	_sabotage_cooldown = 35.0
	_emit_threat()
	# Первое появление сущности через короткое время после старта смены
	var first_spawn := get_tree().create_timer(18.0 + randf() * 12.0)
	first_spawn.timeout.connect(_force_early_spawn)


func _force_early_spawn() -> void:
	if entity_active:
		return
	if _phase < 1:
		return
	add_threat(25.0, &"early_presence")
	if not entity_active:
		start_manifestation(false)


func add_threat(amount: float, reason: StringName = &"") -> void:
	threat_level = clampf(threat_level + amount, 0.0, MAX_THREAT)
	_emit_threat()

	if threat_level >= 25.0 and not entity_observing and _phase >= 1:
		_start_observing()

	if threat_level >= 35.0 and not entity_active and _phase >= 1:
		_activate_entity()


func start_manifestation(hallucination: bool = false) -> void:
	entity_active = true
	var creature_type := CreatureManager.get_active_id()
	if hallucination or SanitySystem.should_hallucinate():
		hallucination = true
	EventBus.entity_spawned.emit(hallucination, creature_type)


func end_manifestation() -> void:
	entity_active = false
	EventBus.entity_despawned.emit()


func trigger_sabotage(type: StringName) -> void:
	EventBus.entity_sabotage.emit(type, null)
	EventBus.paranormal_event.emit(type, {"threat": threat_level, "night": _night})


func _emit_threat() -> void:
	EventBus.threat_level_changed.emit(threat_level, _phase)


func _start_observing() -> void:
	entity_observing = true


func _activate_entity() -> void:
	entity_active = true
	EventBus.entity_spawned.emit(false, CreatureManager.get_active_id())


func _on_reactor_state(state: Dictionary) -> void:
	var temp: float = state.get("temperature", 0.0)
	var pressure: float = state.get("pressure", 0.0)
	if temp > state.get("max_temp", 100.0) * 0.9:
		add_threat(WEIGHT_OVERHEAT * 0.1, &"reactor_overheat")
	if pressure > state.get("max_pressure", 50.0) * 0.9:
		add_threat(WEIGHT_OVERHEAT * 0.08, &"reactor_overpressure")


func _on_defect(amount: int) -> void:
	add_threat(WEIGHT_DEFECT * amount, &"defect_produced")
	GameManager.total_defects += amount


func _on_emergency(type: StringName) -> void:
	add_threat(WEIGHT_ACCIDENT, type)
	GameManager.total_accidents += 1


func _on_player_noise(level: float) -> void:
	if level > 2.0 and entity_observing:
		add_threat(WEIGHT_NOISE * level * 0.05, &"player_noise")


func _on_mixer_ratio(ratio_a: float, ratio_b: float) -> void:
	var deviation := absf(ratio_a - 0.6) + absf(ratio_b - 0.4)
	if deviation > 0.15:
		var growth := deviation * WEIGHT_BLACK_MASS
		black_mass_amount += growth
		add_threat(growth * 0.5, &"wrong_mix_ratio")
		EventBus.black_mass_growth.emit(growth, black_mass_amount)


func _try_paranormal_event() -> void:
	var available: Array = PHASE_EVENTS.get(_phase, [])
	if available.is_empty():
		return

	var interval := lerpf(45.0, 12.0, threat_level / MAX_THREAT)
	_event_cooldown = interval + randf_range(-5.0, 8.0)

	if randf() > threat_level / MAX_THREAT * 0.55 + 0.25:
		return

	var event_id: StringName = available[randi() % available.size()]

	# Hallucinations: entity appears but isn't real
	if event_id == &"hallucination" or event_id == &"entity_glimpse" or event_id == &"entity_manifest":
		var is_hallucination := event_id != &"entity_manifest" and randf() < 0.35
		start_manifestation(is_hallucination)
		if is_hallucination:
			var timer := get_tree().create_timer(randf_range(2.5, 5.0))
			timer.timeout.connect(end_manifestation)

	EventBus.paranormal_event.emit(event_id, {
		"threat": threat_level,
		"night": _night,
		"phase": _phase,
		"black_mass": black_mass_amount,
	})


func _try_sabotage() -> void:
	_sabotage_cooldown = randf_range(45.0, 90.0)
	var sabotage: StringName = SABOTAGE_EVENTS[randi() % SABOTAGE_EVENTS.size()]
	trigger_sabotage(sabotage)

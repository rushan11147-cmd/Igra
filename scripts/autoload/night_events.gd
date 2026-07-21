extends Node
## Random events that make each night unique.

const NIGHT_EVENTS: Array[Dictionary] = [
	{"id": &"fire", "title": "Пожар в цехе A", "min_night": 3, "weight": 10},
	{"id": &"gas_leak", "title": "Утечка газа", "min_night": 4, "weight": 12},
	{"id": &"power_outage", "title": "Отключение света", "min_night": 2, "weight": 15},
	{"id": &"reactor_fault", "title": "Авария реактора", "min_night": 3, "weight": 10},
	{"id": &"phone_ring", "title": "Звонок по внутреннему телефону", "min_night": 5, "weight": 8},
	{"id": &"alarm", "title": "Аварийная сирена", "min_night": 2, "weight": 12},
	{"id": &"pipe_burst", "title": "Прорыв трубопровода", "min_night": 6, "weight": 8},
	{"id": &"elevator_stuck", "title": "Лифт застрял", "min_night": 7, "weight": 6},
]

var tonight_events: Array[Dictionary] = []
var _event_index: int = 0
var _event_timer: float = 0.0


func setup_for_night(night: int) -> void:
	tonight_events.clear()
	_event_index = 0
	_event_timer = randf_range(60.0, 120.0)

	var available: Array[Dictionary] = []
	for ev in NIGHT_EVENTS:
		if ev.get("min_night", 1) <= night:
			available.append(ev)

	available.shuffle()
	var count := mini(1 + night / 10, 3)
	for i in count:
		if available.is_empty():
			break
		tonight_events.append(available.pop_front())


func _process(delta: float) -> void:
	if GameManager.game_state != GameManager.GameState.SHIFT:
		return
	if _event_index >= tonight_events.size():
		return

	_event_timer -= delta
	if _event_timer <= 0.0:
		_trigger_next()


func _trigger_next() -> void:
	if _event_index >= tonight_events.size():
		return

	var ev: Dictionary = tonight_events[_event_index]
	_event_index += 1
	_event_timer = randf_range(90.0, 180.0)

	EventBus.night_event_started.emit(ev["id"], ev.get("title", ""))
	_execute_event(ev["id"])


func _execute_event(event_id: StringName) -> void:
	match event_id:
		&"fire":
			EventBus.emergency_triggered.emit(&"fire")
			HorrorSystem.add_threat(10.0, &"fire")
		&"gas_leak":
			EventBus.emergency_triggered.emit(&"gas_leak")
			EventBus.paranormal_event.emit(&"whispers", {})
		&"power_outage":
			HorrorSystem.trigger_sabotage(&"lights_cut")
		&"reactor_fault":
			for r in get_tree().get_nodes_in_group("reactors"):
				if r.has_method("break_equipment"):
					r.break_equipment()
		&"phone_ring":
			EventBus.paranormal_event.emit(&"phone_ring", {})
			if FactoryRules.has_rule(&"no_phone"):
				# Player must not answer — handled by phone interactable
				pass
		&"alarm":
			EventBus.paranormal_event.emit(&"alarm", {})
			EventBus.emergency_triggered.emit(&"alarm")
		&"pipe_burst":
			EventBus.emergency_triggered.emit(&"pipe_burst")
		&"elevator_stuck":
			EventBus.paranormal_event.emit(&"elevator_stuck", {})

	EventBus.night_event_resolved.emit(event_id)

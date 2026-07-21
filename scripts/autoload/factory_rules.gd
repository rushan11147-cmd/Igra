extends Node
## Nightly factory rules — the viral hook. Players fear breaking new rules each shift.

const RULE_POOL: Array[Dictionary] = [
	{
		"id": &"hall8_door",
		"text": "Главное правило завода: никогда не открывай дверь цеха №8 после 03:00.",
		"min_night": 1,
		"priority": 100,
	},
	{
		"id": &"camera_4",
		"text": "Не смотри в камеру №4 дольше 10 секунд.",
		"min_night": 4,
		"priority": 50,
	},
	{
		"id": &"no_phone",
		"text": "Не отвечай на телефон после 02:17.",
		"min_night": 6,
		"priority": 60,
	},
	{
		"id": &"whistle_lights",
		"text": "Если услышишь свист — немедленно выключи свет.",
		"min_night": 8,
		"priority": 70,
	},
	{
		"id": &"no_mirror",
		"text": "Не смотри в зеркала в туалете цеха B.",
		"min_night": 10,
		"priority": 40,
	},
	{
		"id": &"elevator_alone",
		"text": "Не езжай на лифте в одиночестве после 04:00.",
		"min_night": 12,
		"priority": 55,
	},
]

const HALL8_TRIGGER_PROGRESS := 0.625  # 03:00 при смене 22:00–06:00
const HALL8_MIN_NIGHT := 4

var active_rules: Array[Dictionary] = []
var violations: Array[StringName] = []
var hall8_state: StringName = &"dormant"  # dormant, knocking, voice, resolved
var hall8_choice: StringName = &""
var _hall8_triggered: bool = false
var _camera4_watch_time: float = 0.0


func reset_for_night(night: int) -> void:
	active_rules.clear()
	violations.clear()
	hall8_state = &"dormant"
	hall8_choice = &""
	_hall8_triggered = false
	_camera4_watch_time = 0.0

	var available: Array[Dictionary] = []
	for rule in RULE_POOL:
		if rule.get("min_night", 1) <= night:
			available.append(rule)

	available.sort_custom(func(a, b): return a.get("priority", 0) > b.get("priority", 0))

	# Always include hall8 rule from night 1, add 1-2 more rules as nights progress
	for rule in available:
		if rule["id"] == &"hall8_door" or active_rules.size() < mini(1 + night / 5, 3):
			active_rules.append(rule)
			EventBus.rule_announced.emit(rule)


func on_factory_time(progress: float, hour: int, _minute: int) -> void:
	if not _hall8_triggered and progress >= HALL8_TRIGGER_PROGRESS:
		if GameManager.current_night >= HALL8_MIN_NIGHT:
			_trigger_hall8_event()
		_hall8_triggered = true


func on_camera_watch(camera_id: StringName, delta: float) -> void:
	if camera_id != &"camera_4":
		_camera4_watch_time = 0.0
		return
	_camera4_watch_time += delta
	if _camera4_watch_time > 10.0 and has_rule(&"camera_4"):
		violate_rule(&"camera_4")


func violate_rule(rule_id: StringName) -> void:
	if rule_id in violations:
		return
	violations.append(rule_id)
	EventBus.rule_violated.emit(rule_id)
	HorrorSystem.add_threat(15.0, rule_id)
	SanitySystem.add_stress(20.0, &"rule_violation")


func has_rule(rule_id: StringName) -> bool:
	for rule in active_rules:
		if rule.get("id") == rule_id:
			return true
	return false


func get_rules_text() -> String:
	var lines: PackedStringArray = []
	for rule in active_rules:
		lines.append("⚠ %s" % rule.get("text", ""))
	return "\n".join(lines)


func make_hall8_choice(choice: StringName) -> void:
	hall8_choice = choice
	hall8_state = &"resolved"

	var consequence := ""
	match choice:
		&"open":
			consequence = "Дверь открылась. Внутри — пустота. Но что-то уже вышло."
			HorrorSystem.add_threat(30.0, &"hall8_opened")
			SanitySystem.add_stress(25.0, &"hall8_opened")
			CreatureManager.force_spawn(&"hunter")
		&"leave":
			consequence = "Вы ушли. Стук не прекращался до рассвета."
			SanitySystem.add_stress(10.0, &"hall8_ignored")
		&"cut_power":
			consequence = "Свет погас. Стук прекратился. На секунду — детский смех."
			HorrorSystem.trigger_sabotage(&"lights_cut")
			SanitySystem.add_stress(15.0, &"hall8_power_cut")
		&"peek":
			consequence = "В окне — лицо. Ваше. Оно улыбается."
			SanitySystem.add_stress(30.0, &"hall8_peek")
			EventBus.sanity_effect.emit(&"false_reflection")

	EventBus.hall8_choice_made.emit(choice, consequence)


func _trigger_hall8_event() -> void:
	hall8_state = &"knocking"
	EventBus.hall8_event_started.emit()
	EventBus.paranormal_event.emit(&"hall8_knocking", {})

	var timer := get_tree().create_timer(8.0)
	timer.timeout.connect(_hall8_voice)


func _hall8_voice() -> void:
	if hall8_state != &"knocking":
		return
	hall8_state = &"voice"
	EventBus.paranormal_event.emit(&"hall8_voice", {
		"text": "Помоги... Я здесь...",
	})

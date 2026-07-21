class_name Reactor
extends Interactable
## Core production machine — temperature and pressure must stay in safe range.

@export var machine_id: StringName = &"reactor_main"
@export var max_temperature: float = 120.0
@export var max_pressure: float = 60.0
@export var optimal_temp: float = 80.0

var temperature: float = 25.0
var pressure: float = 10.0
var is_running: bool = false
var is_broken: bool = false

@onready var _cooling_rate: float = 2.0
@onready var _heating_rate: float = 5.0


func _ready() -> void:
	super._ready()
	interaction_prompt = "Управление реактором [E]"


func _process(delta: float) -> void:
	if not is_running or is_broken:
		temperature = move_toward(temperature, 25.0, _cooling_rate * delta)
		pressure = move_toward(pressure, 10.0, _cooling_rate * 0.5 * delta)
	else:
		temperature += _heating_rate * delta
		pressure += _heating_rate * 0.3 * delta

	_emit_state()

	if temperature > max_temperature * 0.95:
		EventBus.emergency_triggered.emit(&"reactor_meltdown")


func _on_interact(_player: Node3D) -> void:
	if is_broken:
		_repair()
	else:
		is_running = not is_running
		interaction_prompt = "Остановить реактор [E]" if is_running else "Запустить реактор [E]"
		ShiftManager.complete_task(&"check_pressure")


func cool_down(amount: float) -> void:
	temperature = maxf(25.0, temperature - amount)
	pressure = maxf(10.0, pressure - amount * 0.3)


func break_equipment() -> void:
	is_broken = true
	is_running = false
	interaction_prompt = "Починить реактор [E]"
	EventBus.equipment_broken.emit(machine_id)


func sabotage() -> void:
	break_equipment()
	EventBus.paranormal_event.emit(&"equipment_sabotage", {"machine_id": machine_id})


func _repair() -> void:
	is_broken = false
	interaction_prompt = "Запустить реактор [E]"
	EventBus.equipment_repaired.emit(machine_id)
	ShiftManager.complete_task(&"fix_equipment")


func _emit_state() -> void:
	var display_temp := SanitySystem.distort_reading(temperature)
	var display_pressure := SanitySystem.distort_reading(pressure)
	EventBus.reactor_state_changed.emit({
		"machine_id": machine_id,
		"temperature": display_temp,
		"pressure": display_pressure,
		"actual_temperature": temperature,
		"actual_pressure": pressure,
		"max_temp": max_temperature,
		"max_pressure": max_pressure,
		"is_running": is_running,
		"is_broken": is_broken,
		"overheat": temperature > max_temperature * 0.9,
		"distorted": SanitySystem.get_distortion() > 0.3,
	})

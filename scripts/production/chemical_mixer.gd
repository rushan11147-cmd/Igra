class_name ChemicalMixer
extends Interactable
## Mixes two chemical components. Wrong ratios spawn black mass.

const IDEAL_RATIO_A := 0.6
const IDEAL_RATIO_B := 0.4

@export var machine_id: StringName = &"mixer_main"
@export var flow_rate: float = 1.0

var component_a: float = 0.5
var component_b: float = 0.5
var is_active: bool = false
var _produced_units: float = 0.0


func _ready() -> void:
	super._ready()
	interaction_prompt = "Настроить смеситель [E]"


func get_prompt() -> String:
	if not interaction_enabled:
		return ""
	if is_active:
		return "%s | Q/R — пропорции A:%.0f%% B:%.0f%%" % [
			interaction_prompt,
			component_a * 100,
			component_b * 100,
		]
	return interaction_prompt


func _process(delta: float) -> void:
	if not is_active:
		return

	_produced_units += flow_rate * delta
	_emit_ratio()

	if _produced_units >= 1.0:
		_produced_units -= 1.0
		_produce_unit()


func _on_interact(_player: Node3D) -> void:
	is_active = not is_active
	interaction_prompt = "Остановить смеситель [E]" if is_active else "Запустить смеситель [E]"
	if is_active:
		ShiftManager.complete_task(&"mix_batch")


func adjust_ratio(delta_a: float) -> void:
	component_a = clampf(component_a + delta_a, 0.0, 1.0)
	component_b = 1.0 - component_a
	_emit_ratio()


func _produce_unit() -> void:
	var deviation := absf(component_a - IDEAL_RATIO_A) + absf(component_b - IDEAL_RATIO_B)
	if deviation > 0.15:
		EventBus.defect_produced.emit(1)
	else:
		ShiftManager.add_production(1)


func _emit_ratio() -> void:
	EventBus.mixer_ratio_changed.emit(component_a, component_b)

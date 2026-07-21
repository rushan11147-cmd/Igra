class_name Hall8Door
extends Interactable
## The viral moment — Factory Hall 8. Knocking at 03:00.

@export var peek_window: bool = true

var _knocking: bool = false


func _ready() -> void:
	super._ready()
	add_to_group("hall8_door")
	interaction_prompt = "Цех №8 — закрыто"
	interaction_enabled = false
	EventBus.hall8_event_started.connect(_on_hall8_started)
	EventBus.shift_started.connect(_on_shift_started)


func _on_shift_started(night: int) -> void:
	interaction_enabled = night >= FactoryRules.HALL8_MIN_NIGHT
	interaction_prompt = "Цех №8 — закрыто" if not interaction_enabled else interaction_prompt


func _on_hall8_started() -> void:
	_knocking = true
	interaction_enabled = true
	interaction_prompt = "Цех №8 — кто-то стучит... [E]"


func _on_interact(_player: Node3D) -> void:
	if FactoryRules.hall8_state == &"resolved":
		return

	if FactoryRules.hall8_state == &"voice":
		_show_choices()
	elif _knocking:
		interaction_prompt = "Стук усиливается... Подождите..."
	else:
		FactoryRules.violate_rule(&"hall8_door")
		FactoryRules.make_hall8_choice(&"open")


func _show_choices() -> void:
	# In full UI this would be a modal; for prototype use sequential prompts via EventBus
	EventBus.paranormal_event.emit(&"hall8_choices", {
		"options": ["open", "leave", "cut_power", "peek"],
	})
	# Default: player must interact again with different keys — handled by hall8_choice input
	interaction_prompt = "[1] Открыть | [2] Уйти | [3] Отключить питание | [4] Заглянуть"


func make_choice(choice: StringName) -> void:
	FactoryRules.make_hall8_choice(choice)
	_knocking = false
	interaction_enabled = false
	interaction_prompt = "Цех №8 — пусто"

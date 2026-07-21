extends Node
## Player inventory: keys, tools, flashlight state.

var keys: Array[StringName] = []
var tools: Array[StringName] = [&"flashlight", &"radio", &"wrench"]
var flashlight_on: bool = true
var flashlight_battery: float = 100.0
var radio_active: bool = false

const BATTERY_DRAIN_RATE := 0.5  # per second when on
const LOW_BATTERY_THRESHOLD := 15.0


func reset() -> void:
	keys.clear()
	tools = [&"flashlight", &"radio", &"wrench"]
	flashlight_on = true
	flashlight_battery = 100.0
	radio_active = false


func _process(delta: float) -> void:
	if flashlight_on and flashlight_battery > 0.0:
		flashlight_battery = maxf(0.0, flashlight_battery - BATTERY_DRAIN_RATE * delta)
		if flashlight_battery <= 0.0:
			flashlight_on = false


func has_key(key_id: StringName) -> bool:
	return key_id in keys


func add_key(key_id: StringName) -> void:
	if key_id in keys:
		return
	keys.append(key_id)
	EventBus.key_acquired.emit(key_id)


func has_tool(tool_id: StringName) -> bool:
	return tool_id in tools


func toggle_flashlight() -> void:
	if flashlight_battery > 0.0:
		flashlight_on = not flashlight_on


func toggle_radio() -> void:
	radio_active = not radio_active

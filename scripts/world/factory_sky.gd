extends Node
## Keeps Sky3D night sky aligned with Factory 17 shift clock (22:00–06:00).

var _sky3d: Sky3D


func _ready() -> void:
	_sky3d = get_parent() as Sky3D
	if EventBus.has_signal("factory_time_updated"):
		EventBus.factory_time_updated.connect(_on_factory_time)
	if EventBus.has_signal("shift_started"):
		EventBus.shift_started.connect(_on_shift_started)
	_set_hour(23.25)


func _on_shift_started(_night: int) -> void:
	_set_hour(22.0)


func _on_factory_time(hour: int, minute: int, _progress: float) -> void:
	_set_hour(float(hour) + float(minute) / 60.0)


func _set_hour(hour: float) -> void:
	if _sky3d == null:
		_sky3d = get_parent() as Sky3D
	if _sky3d == null or _sky3d.tod == null:
		return
	_sky3d.tod.current_time = hour

extends Button
## Минималистичная кнопка меню с hover-свечением и клик-анимацией.

signal fx_hover
signal fx_press

@export var hover_scale: float = 1.06
@export var press_scale: float = 0.96
@export var hover_modulate: Color = Color(1.0, 0.35, 0.28, 1.0)
@export var normal_modulate: Color = Color(0.92, 0.92, 0.94, 1.0)

var _base_scale: Vector2 = Vector2.ONE
var _hovering: bool = false
var _tween: Tween


func _ready() -> void:
	_base_scale = scale
	modulate = normal_modulate
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)
	focus_entered.connect(_on_mouse_entered)
	focus_exited.connect(_on_mouse_exited)
	resized.connect(_update_pivot)
	call_deferred("_update_pivot")


func _update_pivot() -> void:
	pivot_offset = size * 0.5


func _on_mouse_entered() -> void:
	_hovering = true
	_animate_to(Vector2.ONE * hover_scale, hover_modulate, 0.18)
	fx_hover.emit()


func _on_mouse_exited() -> void:
	_hovering = false
	_animate_to(_base_scale, normal_modulate, 0.2)


func _on_button_down() -> void:
	_animate_to(Vector2.ONE * press_scale, hover_modulate.lightened(0.1), 0.08)
	fx_press.emit()


func _on_button_up() -> void:
	if _hovering:
		_animate_to(Vector2.ONE * hover_scale, hover_modulate, 0.1)
	else:
		_animate_to(_base_scale, normal_modulate, 0.12)


func _animate_to(target_scale: Vector2, target_modulate: Color, duration: float) -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_property(self, "scale", target_scale, duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "modulate", target_modulate, duration).set_trans(Tween.TRANS_SINE)

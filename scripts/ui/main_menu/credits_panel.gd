extends Control
## Экран титров / credits для главного меню.

signal closed

@onready var _panel: PanelContainer = $Panel
@onready var _close_button: Button = %CloseButton


func _ready() -> void:
	visible = false
	_close_button.pressed.connect(hide_panel)
	set_process_unhandled_input(false)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		hide_panel()
		get_viewport().set_input_as_handled()


func show_panel() -> void:
	visible = true
	set_process_unhandled_input(true)
	_panel.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(_panel, "modulate:a", 1.0, 0.25)
	_close_button.grab_focus()


func hide_panel() -> void:
	visible = false
	set_process_unhandled_input(false)
	closed.emit()

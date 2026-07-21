extends Node
## Global display settings — fullscreen works from anywhere in the game.


func _ready() -> void:
	call_deferred("_apply_default_fullscreen")


func _apply_default_fullscreen() -> void:
	var window: Window = get_tree().root
	if window == null:
		return
	if window.mode == Window.MODE_WINDOWED:
		window.mode = Window.MODE_EXCLUSIVE_FULLSCREEN


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_fullscreen"):
		toggle_fullscreen()
		get_viewport().set_input_as_handled()


func toggle_fullscreen() -> void:
	var window: Window = get_tree().root
	if window == null:
		return

	var is_fullscreen := window.mode in [
		Window.MODE_FULLSCREEN,
		Window.MODE_EXCLUSIVE_FULLSCREEN,
	]

	if is_fullscreen:
		window.mode = Window.MODE_WINDOWED
		window.borderless = false
	else:
		window.mode = Window.MODE_EXCLUSIVE_FULLSCREEN

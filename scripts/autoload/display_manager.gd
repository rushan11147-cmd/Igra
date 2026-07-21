extends Node
## Global display settings — fullscreen works from anywhere in the game.
## Делегирует постоянное состояние в SettingsManager.


func _ready() -> void:
	# SettingsManager применяет fullscreen при старте.
	pass


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_fullscreen"):
		toggle_fullscreen()
		get_viewport().set_input_as_handled()


func toggle_fullscreen() -> void:
	SettingsManager.set_fullscreen(not SettingsManager.fullscreen)

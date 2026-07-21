extends CanvasLayer
## Игровое меню паузы. Открывается по ESC во время смены.

signal opened
signal closed

const SETTINGS_SCENE := preload("res://scenes/ui/main_menu/settings_panel.tscn")

@onready var _root: Control = $Root
@onready var _panel: PanelContainer = $Root/Panel
@onready var _resume_button: Button = %ResumeButton
@onready var _settings_button: Button = %SettingsButton
@onready var _menu_button: Button = %MainMenuButton
@onready var _quit_button: Button = %QuitButton

var _settings: Control
var _is_open: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 90
	visible = true
	_root.visible = false

	_resume_button.pressed.connect(close_menu)
	_settings_button.pressed.connect(_on_settings_pressed)
	_menu_button.pressed.connect(_on_main_menu_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)

	_settings = SETTINGS_SCENE.instantiate()
	_settings.process_mode = Node.PROCESS_MODE_ALWAYS
	_root.add_child(_settings)
	_settings.closed.connect(_on_settings_closed)


func _input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return

	# Сначала закрываем окно настроек, если оно открыто.
	if _settings and _settings.visible:
		_settings.hide_panel()
		get_viewport().set_input_as_handled()
		return

	if _is_open:
		close_menu()
		get_viewport().set_input_as_handled()
		return

	if _can_open():
		open_menu()
		get_viewport().set_input_as_handled()


func _can_open() -> bool:
	# Пауза только во время активной смены / брифинга.
	return GameManager.game_state in [
		GameManager.GameState.SHIFT,
		GameManager.GameState.BRIEFING,
	]


func open_menu() -> void:
	if _is_open:
		return

	_is_open = true
	_root.visible = true
	GameManager.pause_shift()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	_panel.modulate.a = 0.0
	_panel.scale = Vector2(0.96, 0.96)
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_parallel(true)
	tween.tween_property(_panel, "modulate:a", 1.0, 0.18)
	tween.tween_property(_panel, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	_resume_button.grab_focus()
	opened.emit()


func close_menu() -> void:
	if not _is_open:
		return

	if _settings and _settings.visible:
		_settings.hide_panel()

	_is_open = false
	_root.visible = false
	GameManager.resume_shift()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	closed.emit()


func _on_settings_pressed() -> void:
	_panel.visible = false
	_settings.show_panel()


func _on_settings_closed() -> void:
	_panel.visible = true
	_resume_button.grab_focus()


func _on_main_menu_pressed() -> void:
	_is_open = false
	_root.visible = false
	get_tree().paused = false
	GameManager.game_state = GameManager.GameState.MENU
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	GameManager.save_progress()
	SceneLoader.go_to_menu(0.9)


func _on_quit_pressed() -> void:
	get_tree().paused = false
	get_tree().quit()

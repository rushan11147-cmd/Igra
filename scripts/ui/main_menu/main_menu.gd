extends Node3D
## Главное меню Horror Factory.
## Управляет UI, атмосферой, переходом в игру и оверлеями настроек/титров.

const GAME_SCENE := "res://scenes/world/main.tscn"

@onready var _camera: Camera3D = $CameraPivot/Camera3D
@onready var _camera_pivot: Node3D = $CameraPivot
@onready var _background: Node3D = $Background3D
@onready var _animation_player: AnimationPlayer = $AnimationPlayer
@onready var _ambient_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var _sfx_player: AudioStreamPlayer = $SfxPlayer
@onready var _world_env: WorldEnvironment = $WorldEnvironment

@onready var _logo_title: Label = $CanvasLayer/Logo/Title
@onready var _logo_subtitle: Label = $CanvasLayer/Logo/Subtitle
@onready var _menu_box: VBoxContainer = $CanvasLayer/VBoxContainer
@onready var _continue_button: Button = $CanvasLayer/VBoxContainer/ContinueButton
@onready var _new_game_button: Button = $CanvasLayer/VBoxContainer/NewGameButton
@onready var _settings_button: Button = $CanvasLayer/VBoxContainer/SettingsButton
@onready var _credits_button: Button = $CanvasLayer/VBoxContainer/CreditsButton
@onready var _exit_button: Button = $CanvasLayer/VBoxContainer/ExitButton
@onready var _settings_panel: Control = $CanvasLayer/SettingsPanel
@onready var _credits_panel: Control = $CanvasLayer/CreditsPanel
@onready var _intro_label: Label = $CanvasLayer/IntroLabel

var _busy: bool = false
var _camera_time: float = 0.0
var _camera_look_at: Vector3 = Vector3(0, 5, -6)


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	GameManager.game_state = GameManager.GameState.MENU

	_setup_environment()
	_setup_logo_style()
	_setup_buttons()
	_setup_ambient_audio()
	_setup_camera_animation()
	_refresh_continue_visibility()
	_play_intro_fade()

	SettingsManager.settings_changed.connect(_on_settings_changed)
	SettingsManager.apply_brightness()
	_camera.fov = SettingsManager.fov
	call_deferred("_focus_default_button")


func _process(delta: float) -> void:
	# Лёгкое «дыхание» камеры поверх медленного дрейфа пивота.
	_camera_time += delta
	var sway := Vector3(
		sin(_camera_time * 0.15) * 0.25,
		cos(_camera_time * 0.12) * 0.12,
		0.0
	)
	_camera.position = sway
	_camera.look_at(_camera_look_at, Vector3.UP)


func _setup_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.02, 0.025, 0.035)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.12, 0.14, 0.18)
	env.ambient_light_energy = 0.35
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.adjustment_enabled = true
	env.adjustment_brightness = SettingsManager.brightness
	env.fog_enabled = true
	env.fog_light_color = Color(0.08, 0.09, 0.11)
	env.fog_density = 0.012
	env.glow_enabled = true
	env.glow_intensity = 0.4
	env.glow_bloom = 0.15
	_world_env.environment = env


func _setup_logo_style() -> void:
	# «Изношенный металл»: холодный белый + лёгкая тень через theme override.
	_logo_title.add_theme_font_size_override("font_size", 64)
	_logo_title.add_theme_color_override("font_color", Color(0.92, 0.93, 0.95))
	_logo_title.add_theme_color_override("font_shadow_color", Color(0.15, 0.02, 0.02, 0.85))
	_logo_title.add_theme_constant_override("shadow_offset_x", 3)
	_logo_title.add_theme_constant_override("shadow_offset_y", 4)
	_logo_title.add_theme_constant_override("outline_size", 2)
	_logo_title.add_theme_color_override("font_outline_color", Color(0.25, 0.25, 0.28, 0.55))

	_logo_subtitle.add_theme_font_size_override("font_size", 18)
	_logo_subtitle.add_theme_color_override("font_color", Color(0.75, 0.22, 0.18))
	_logo_subtitle.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	_logo_subtitle.add_theme_constant_override("shadow_offset_x", 1)
	_logo_subtitle.add_theme_constant_override("shadow_offset_y", 2)


func _setup_buttons() -> void:
	_wire_menu_button(_continue_button, _on_continue_pressed)
	_wire_menu_button(_new_game_button, _on_new_game_pressed)
	_wire_menu_button(_settings_button, _on_settings_pressed)
	_wire_menu_button(_credits_button, _on_credits_pressed)
	_wire_menu_button(_exit_button, _on_exit_pressed)

	_settings_panel.closed.connect(_on_overlay_closed)
	_credits_panel.closed.connect(_on_overlay_closed)


func _wire_menu_button(button: Button, handler: Callable) -> void:
	button.pressed.connect(handler)
	if button.has_signal("fx_hover"):
		button.fx_hover.connect(_play_switch_hover)
	if button.has_signal("fx_press"):
		button.fx_press.connect(_play_switch_press)


func _setup_ambient_audio() -> void:
	var ambient := SoundLibrary.load_stream(SoundLibrary.AMBIENT)
	if ambient:
		# Зацикливаем гул завода.
		if ambient is AudioStreamOggVorbis:
			(ambient as AudioStreamOggVorbis).loop = true
		_ambient_player.stream = ambient
		_ambient_player.volume_db = -8.0
		_ambient_player.play()

	# Фоновые металлические/капельные слои через таймер редких SFX.
	var drip_timer := Timer.new()
	drip_timer.wait_time = 7.0
	drip_timer.autostart = true
	drip_timer.timeout.connect(_play_ambient_layer)
	add_child(drip_timer)


func _setup_camera_animation() -> void:
	# AnimationPlayer двигает пивот; локальный sway — у самой Camera3D.
	_camera_pivot.position = Vector3(28, 11, 26)

	var anim := Animation.new()
	anim.length = 40.0
	anim.loop_mode = Animation.LOOP_LINEAR

	var track := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(track, NodePath("CameraPivot:position"))
	anim.track_insert_key(track, 0.0, Vector3(28, 11, 26))
	anim.track_insert_key(track, 20.0, Vector3(24, 10.5, 22))
	anim.track_insert_key(track, 40.0, Vector3(28, 11, 26))

	var lib := AnimationLibrary.new()
	lib.add_animation("camera_drift", anim)
	if _animation_player.has_animation_library(""):
		_animation_player.remove_animation_library("")
	_animation_player.add_animation_library("", lib)
	_animation_player.play("camera_drift")


func _play_intro_fade() -> void:
	_intro_label.visible = false
	_menu_box.modulate.a = 0.0
	$CanvasLayer/Logo.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property($CanvasLayer/Logo, "modulate:a", 1.0, 1.4)
	tween.tween_property(_menu_box, "modulate:a", 1.0, 1.0)


func _focus_default_button() -> void:
	if _continue_button.visible and _continue_button.disabled == false:
		_continue_button.grab_focus()
	else:
		_new_game_button.grab_focus()


func _refresh_continue_visibility() -> void:
	var has_save := GameManager.has_save()
	_continue_button.visible = has_save
	_continue_button.disabled = not has_save


func _on_continue_pressed() -> void:
	if _busy:
		return
	_start_game_flow(&"continue")


func _on_new_game_pressed() -> void:
	if _busy:
		return
	_start_game_flow(&"new_game")


func _on_settings_pressed() -> void:
	_set_menu_interactive(false)
	_settings_panel.show_panel()


func _on_credits_pressed() -> void:
	_set_menu_interactive(false)
	_credits_panel.show_panel()


func _on_exit_pressed() -> void:
	get_tree().quit()


func _on_overlay_closed() -> void:
	_set_menu_interactive(true)
	_focus_default_button()


func _set_menu_interactive(enabled: bool) -> void:
	_menu_box.visible = enabled
	$CanvasLayer/Logo.visible = enabled


func _start_game_flow(action: StringName) -> void:
	_busy = true
	_set_menu_interactive(false)

	# Короткая «intro»-заставка перед загрузкой смены.
	_intro_label.visible = true
	_intro_label.modulate.a = 0.0
	_intro_label.text = "НОЧНАЯ СМЕНА НАЧИНАЕТСЯ..."
	var tween := create_tween()
	tween.tween_property(_intro_label, "modulate:a", 1.0, 0.8)
	tween.tween_interval(0.9)
	tween.tween_property(_intro_label, "modulate:a", 0.0, 0.6)
	await tween.finished

	match action:
		&"continue":
			GameManager.request_continue()
		_:
			GameManager.request_new_game()

	await SceneLoader.go_to_game(1.4)


func _play_switch_hover() -> void:
	_play_ui_sfx(SoundLibrary.DOOR_OPENS, -14.0, 1.35)


func _play_switch_press() -> void:
	_play_ui_sfx(SoundLibrary.MACHINE, -10.0, 0.85)


func _play_ambient_layer() -> void:
	if _busy:
		return
	# Случайный слой: капли / металл / электрический щелчок.
	var pools: Array = [SoundLibrary.WHISPERS, SoundLibrary.DOOR_SLAMS, SoundLibrary.MACHINE]
	_play_ui_sfx(pools[randi() % pools.size()], -18.0, randf_range(0.7, 1.2))


func _play_ui_sfx(pool: Array, volume_db: float, pitch: float) -> void:
	var stream := SoundLibrary.load_stream(SoundLibrary.pick_random(pool))
	if stream == null:
		return
	_sfx_player.stream = stream
	_sfx_player.volume_db = volume_db
	_sfx_player.pitch_scale = pitch
	_sfx_player.play()


func _on_settings_changed() -> void:
	if _world_env and _world_env.environment:
		_world_env.environment.adjustment_brightness = SettingsManager.brightness
	if _camera:
		_camera.fov = SettingsManager.fov

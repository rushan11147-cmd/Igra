extends Node
## Глобальные настройки игры. Автосохранение в user://settings.cfg.

signal settings_changed

const SAVE_PATH := "user://settings.cfg"

enum GraphicsQuality { LOW, MEDIUM, HIGH, ULTRA }

## Громкость master-шины (0.0 … 1.0).
var master_volume: float = 0.8
## Чувствительность мыши для FPS-камеры.
var mouse_sensitivity: float = 0.002
## Полноэкранный режим.
var fullscreen: bool = true
## Пресет качества графики.
var graphics_quality: GraphicsQuality = GraphicsQuality.HIGH
## Яркость сцены (0.5 … 1.5).
var brightness: float = 1.0
## Поле зрения камеры игрока.
var fov: float = 75.0

var _applying: bool = false


func _ready() -> void:
	load_settings()
	call_deferred("apply_all")


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return

	master_volume = float(cfg.get_value("audio", "master_volume", master_volume))
	mouse_sensitivity = float(cfg.get_value("controls", "mouse_sensitivity", mouse_sensitivity))
	fullscreen = bool(cfg.get_value("video", "fullscreen", fullscreen))
	graphics_quality = int(cfg.get_value("video", "graphics_quality", graphics_quality)) as GraphicsQuality
	brightness = float(cfg.get_value("video", "brightness", brightness))
	fov = float(cfg.get_value("video", "fov", fov))


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "master_volume", master_volume)
	cfg.set_value("controls", "mouse_sensitivity", mouse_sensitivity)
	cfg.set_value("video", "fullscreen", fullscreen)
	cfg.set_value("video", "graphics_quality", graphics_quality)
	cfg.set_value("video", "brightness", brightness)
	cfg.set_value("video", "fov", fov)
	cfg.save(SAVE_PATH)


func apply_all() -> void:
	_applying = true
	apply_volume()
	apply_fullscreen()
	apply_graphics_quality()
	apply_brightness()
	apply_fov()
	_applying = false
	settings_changed.emit()


func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	apply_volume()
	_autosave()


func set_mouse_sensitivity(value: float) -> void:
	mouse_sensitivity = clampf(value, 0.0005, 0.01)
	_autosave()
	settings_changed.emit()


func set_fullscreen(enabled: bool) -> void:
	fullscreen = enabled
	apply_fullscreen()
	_autosave()


func set_graphics_quality(quality: GraphicsQuality) -> void:
	graphics_quality = quality
	apply_graphics_quality()
	_autosave()


func set_brightness(value: float) -> void:
	brightness = clampf(value, 0.5, 1.5)
	apply_brightness()
	_autosave()


func set_fov(value: float) -> void:
	fov = clampf(value, 60.0, 110.0)
	apply_fov()
	_autosave()


func apply_volume() -> void:
	var bus := AudioServer.get_bus_index("Master")
	if bus < 0:
		return
	# Линейная громкость → дБ. 0 = -80 дБ (тишина).
	var db := linear_to_db(maxf(master_volume, 0.0001))
	if master_volume <= 0.001:
		db = -80.0
	AudioServer.set_bus_volume_db(bus, db)
	AudioServer.set_bus_mute(bus, master_volume <= 0.001)


func apply_fullscreen() -> void:
	var window := get_tree().root
	if window == null:
		return
	if fullscreen:
		window.mode = Window.MODE_EXCLUSIVE_FULLSCREEN
	else:
		window.mode = Window.MODE_WINDOWED
		window.borderless = false


func apply_graphics_quality() -> void:
	var vp := get_viewport()
	if vp == null:
		return

	match graphics_quality:
		GraphicsQuality.LOW:
			vp.msaa_3d = Viewport.MSAA_DISABLED
			vp.scaling_3d_scale = 0.75
		GraphicsQuality.MEDIUM:
			vp.msaa_3d = Viewport.MSAA_2X
			vp.scaling_3d_scale = 0.9
		GraphicsQuality.HIGH:
			vp.msaa_3d = Viewport.MSAA_4X
			vp.scaling_3d_scale = 1.0
		GraphicsQuality.ULTRA:
			vp.msaa_3d = Viewport.MSAA_8X
			vp.scaling_3d_scale = 1.0


func apply_brightness() -> void:
	# Яркость через Environment у текущей сцены / WorldEnvironment.
	var scene := get_tree().current_scene
	if scene == null:
		return
	_apply_brightness_recursive(scene)


func apply_fov() -> void:
	for camera in get_tree().get_nodes_in_group("player_camera"):
		if camera is Camera3D:
			(camera as Camera3D).fov = fov


func _apply_brightness_recursive(node: Node) -> void:
	if node is WorldEnvironment:
		var we := node as WorldEnvironment
		if we.environment == null:
			we.environment = Environment.new()
		var env := we.environment
		env.adjustment_enabled = true
		env.adjustment_brightness = brightness
	for child in node.get_children():
		_apply_brightness_recursive(child)


func _autosave() -> void:
	if _applying:
		return
	save_settings()
	settings_changed.emit()


func graphics_quality_label(quality: GraphicsQuality) -> String:
	match quality:
		GraphicsQuality.LOW:
			return "Низкое"
		GraphicsQuality.MEDIUM:
			return "Среднее"
		GraphicsQuality.HIGH:
			return "Высокое"
		GraphicsQuality.ULTRA:
			return "Ультра"
	return "Высокое"

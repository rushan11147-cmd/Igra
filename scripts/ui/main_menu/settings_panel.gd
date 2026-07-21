extends Control
## Окно настроек главного меню. Все изменения пишутся через SettingsManager.

signal closed

@onready var _panel: PanelContainer = $Panel
@onready var _volume: HSlider = %VolumeSlider
@onready var _sensitivity: HSlider = %SensitivitySlider
@onready var _fullscreen: CheckButton = %FullscreenCheck
@onready var _quality: OptionButton = %QualityOption
@onready var _brightness: HSlider = %BrightnessSlider
@onready var _fov: HSlider = %FovSlider
@onready var _volume_value: Label = %VolumeValue
@onready var _sensitivity_value: Label = %SensitivityValue
@onready var _brightness_value: Label = %BrightnessValue
@onready var _fov_value: Label = %FovValue
@onready var _close_button: Button = %CloseButton


func _ready() -> void:
	visible = false
	_quality.clear()
	_quality.add_item(SettingsManager.graphics_quality_label(SettingsManager.GraphicsQuality.LOW), SettingsManager.GraphicsQuality.LOW)
	_quality.add_item(SettingsManager.graphics_quality_label(SettingsManager.GraphicsQuality.MEDIUM), SettingsManager.GraphicsQuality.MEDIUM)
	_quality.add_item(SettingsManager.graphics_quality_label(SettingsManager.GraphicsQuality.HIGH), SettingsManager.GraphicsQuality.HIGH)
	_quality.add_item(SettingsManager.graphics_quality_label(SettingsManager.GraphicsQuality.ULTRA), SettingsManager.GraphicsQuality.ULTRA)

	_volume.value_changed.connect(_on_volume_changed)
	_sensitivity.value_changed.connect(_on_sensitivity_changed)
	_fullscreen.toggled.connect(_on_fullscreen_toggled)
	_quality.item_selected.connect(_on_quality_selected)
	_brightness.value_changed.connect(_on_brightness_changed)
	_fov.value_changed.connect(_on_fov_changed)
	_close_button.pressed.connect(hide_panel)

	# Закрытие по Esc, пока окно открыто.
	set_process_unhandled_input(false)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		hide_panel()
		get_viewport().set_input_as_handled()


func show_panel() -> void:
	_sync_from_settings()
	visible = true
	set_process_unhandled_input(true)
	_animate_in()
	_close_button.grab_focus()


func hide_panel() -> void:
	visible = false
	set_process_unhandled_input(false)
	closed.emit()


func _sync_from_settings() -> void:
	_volume.value = SettingsManager.master_volume * 100.0
	_sensitivity.value = SettingsManager.mouse_sensitivity * 1000.0
	_fullscreen.button_pressed = SettingsManager.fullscreen
	_quality.select(int(SettingsManager.graphics_quality))
	_brightness.value = SettingsManager.brightness
	_fov.value = SettingsManager.fov
	_refresh_labels()


func _refresh_labels() -> void:
	_volume_value.text = "%d%%" % int(_volume.value)
	_sensitivity_value.text = "%.1f" % _sensitivity.value
	_brightness_value.text = "%.2f" % _brightness.value
	_fov_value.text = "%d°" % int(_fov.value)


func _on_volume_changed(value: float) -> void:
	SettingsManager.set_master_volume(value / 100.0)
	_refresh_labels()


func _on_sensitivity_changed(value: float) -> void:
	SettingsManager.set_mouse_sensitivity(value / 1000.0)
	_refresh_labels()


func _on_fullscreen_toggled(pressed: bool) -> void:
	SettingsManager.set_fullscreen(pressed)


func _on_quality_selected(index: int) -> void:
	var id := _quality.get_item_id(index)
	SettingsManager.set_graphics_quality(id as SettingsManager.GraphicsQuality)


func _on_brightness_changed(value: float) -> void:
	SettingsManager.set_brightness(value)
	_refresh_labels()


func _on_fov_changed(value: float) -> void:
	SettingsManager.set_fov(value)
	_refresh_labels()


func _animate_in() -> void:
	_panel.modulate.a = 0.0
	_panel.scale = Vector2(0.96, 0.96)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_panel, "modulate:a", 1.0, 0.25)
	tween.tween_property(_panel, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

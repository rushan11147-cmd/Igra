extends CanvasLayer
## Асинхронная смена сцен с плавным затемнением.
## Автозагрузка: всегда поверх UI (layer 100).

signal transition_started(path: String)
signal transition_finished(path: String)

const DEFAULT_FADE := 1.2
const GAME_SCENE := "res://scenes/world/main.tscn"
const MENU_SCENE := "res://scenes/ui/main_menu/MainMenu.tscn"

var _fade: ColorRect
var _busy: bool = false
var _pending_path: String = ""


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_fade_overlay()


func _build_fade_overlay() -> void:
	_fade = ColorRect.new()
	_fade.name = "FadeOverlay"
	_fade.color = Color(0, 0, 0, 0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_fade)


func is_busy() -> bool:
	return _busy


## Плавный переход на сцену с потоковой загрузкой.
func change_scene_async(path: String, fade_out: float = DEFAULT_FADE, fade_in: float = 0.8) -> void:
	if _busy:
		return
	if path.is_empty() or not ResourceLoader.exists(path):
		push_error("SceneLoader: сцена не найдена: %s" % path)
		return

	_busy = true
	_pending_path = path
	transition_started.emit(path)
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP

	await _tween_fade(1.0, fade_out)
	await _load_and_switch(path)
	await _tween_fade(0.0, fade_in)

	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_busy = false
	transition_finished.emit(path)


func go_to_game(fade_out: float = DEFAULT_FADE) -> void:
	await change_scene_async(GAME_SCENE, fade_out)


func go_to_menu(fade_out: float = DEFAULT_FADE) -> void:
	await change_scene_async(MENU_SCENE, fade_out)


func _tween_fade(target_alpha: float, duration: float) -> void:
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(_fade, "color:a", target_alpha, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished


func _load_and_switch(path: String) -> void:
	# Потоковая загрузка — не блокирует кадр на тяжёлых сценах.
	var err := ResourceLoader.load_threaded_request(path, "", true)
	if err != OK:
		# Фоллбек на синхронную загрузку.
		get_tree().change_scene_to_file(path)
		return

	while true:
		var status := ResourceLoader.load_threaded_get_status(path)
		match status:
			ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				await get_tree().process_frame
			ResourceLoader.THREAD_LOAD_LOADED:
				var packed := ResourceLoader.load_threaded_get(path) as PackedScene
				if packed:
					get_tree().change_scene_to_packed(packed)
				else:
					get_tree().change_scene_to_file(path)
				return
			_:
				push_error("SceneLoader: ошибка загрузки %s" % path)
				get_tree().change_scene_to_file(path)
				return

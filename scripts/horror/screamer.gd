extends CanvasLayer
## Fullscreen jumpscare — image + scream, 20s after game start.

const IMAGE_PATH := "res://assets/models/monster/8Khs595hThSHSFiemYxp2qBWyDo8zxUJ.jpeg.jpg"
const DELAY_SEC := 20.0
const SHOW_SEC := 1.8

var _fired: bool = false
var _scheduled: bool = false
var _hide_left: float = 0.0

@onready var _root: Control = $Root
@onready var _face: TextureRect = $Root/Face
@onready var _sfx: AudioStreamPlayer = $ScreamSFX


func _ready() -> void:
	layer = 128
	visible = false
	_root.visible = false
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_load_face()
	EventBus.shift_started.connect(_on_shift_started)


func _process(delta: float) -> void:
	if _hide_left <= 0.0:
		return
	_hide_left -= delta
	_face.position = Vector2(randf_range(-12.0, 12.0), randf_range(-8.0, 8.0))
	if _hide_left <= 0.0:
		_end_screamer()


func _on_shift_started(night: int) -> void:
	# TODO: временно отключено для отладки лестниц
	return
	# New run — allow screamer again
	if night == 1:
		_fired = false
		_scheduled = false
	if _fired or _scheduled:
		return
	_scheduled = true
	get_tree().create_timer(DELAY_SEC).timeout.connect(_trigger, CONNECT_ONE_SHOT)


func _load_face() -> void:
	if ResourceLoader.exists(IMAGE_PATH):
		_face.texture = load(IMAGE_PATH) as Texture2D
		return
	if FileAccess.file_exists(IMAGE_PATH):
		var img := Image.load_from_file(ProjectSettings.globalize_path(IMAGE_PATH))
		if img:
			_face.texture = ImageTexture.create_from_image(img)


func _trigger() -> void:
	if _fired:
		return
	_fired = true
	visible = true
	_root.visible = true
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_face.modulate = Color.WHITE
	_hide_left = SHOW_SEC
	_play_scream()
	SanitySystem.add_stress(18.0, &"screamer")


func _play_scream() -> void:
	var path := SoundLibrary.pick_random(SoundLibrary.SCREAMS)
	var stream := SoundLibrary.load_stream(path)
	if stream == null:
		return
	_sfx.stream = stream
	_sfx.volume_db = 6.0
	_sfx.pitch_scale = 0.85 + randf() * 0.2
	_sfx.play()


func _end_screamer() -> void:
	_root.visible = false
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_face.position = Vector2.ZERO
	if _sfx.playing:
		_sfx.stop()

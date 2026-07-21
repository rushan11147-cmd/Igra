extends Node
## Случайные ambient-события главного меню каждые 20–40 секунд.

enum EventKind { FLICKER, IMPACT, SILHOUETTE, BLACKOUT, CONVEYOR }

@export var atmosphere_path: NodePath
@export var sfx_player_path: NodePath
@export var min_interval: float = 20.0
@export var max_interval: float = 40.0

var _atmosphere: Node3D
var _sfx: AudioStreamPlayer
var _timer: float = 0.0
var _next_in: float = 25.0


func _ready() -> void:
	_atmosphere = get_node_or_null(atmosphere_path) as Node3D
	_sfx = get_node_or_null(sfx_player_path) as AudioStreamPlayer
	_schedule_next()


func _process(delta: float) -> void:
	_timer += delta
	if _timer >= _next_in:
		_timer = 0.0
		_trigger_random_event()
		_schedule_next()


func _schedule_next() -> void:
	_next_in = randf_range(min_interval, max_interval)


func _trigger_random_event() -> void:
	if _atmosphere == null:
		return

	var kind: EventKind = (randi() % EventKind.size()) as EventKind
	match kind:
		EventKind.FLICKER:
			_atmosphere.flicker_lights(0.9)
			_play_sfx(SoundLibrary.MACHINE)
		EventKind.IMPACT:
			_play_sfx(SoundLibrary.DOOR_SLAMS, 0.85)
		EventKind.SILHOUETTE:
			_atmosphere.show_silhouette(2.8)
			_play_sfx(SoundLibrary.WHISPERS, 0.55)
		EventKind.BLACKOUT:
			_atmosphere.blackout_partial(3.5)
			_play_sfx(SoundLibrary.DOOR_OPENS, 0.5)
		EventKind.CONVEYOR:
			_atmosphere.run_conveyor(5.0)
			_play_sfx(SoundLibrary.MACHINE, 0.7)


func _play_sfx(pool: Array, volume_db: float = 0.0) -> void:
	if _sfx == null:
		return
	var stream := SoundLibrary.load_stream(SoundLibrary.pick_random(pool))
	if stream == null:
		return
	_sfx.stream = stream
	_sfx.volume_db = volume_db
	_sfx.pitch_scale = randf_range(0.9, 1.1)
	_sfx.play()

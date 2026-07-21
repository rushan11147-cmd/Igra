extends Node
## Kenney CC0 sound paths — RPG Audio pack.

const AUDIO_DIR := "res://assets/audio/"

const AMBIENT := AUDIO_DIR + "cloth4.ogg"
const FOOTSTEPS: Array[String] = [
	AUDIO_DIR + "footstep00.ogg",
	AUDIO_DIR + "footstep01.ogg",
	AUDIO_DIR + "footstep02.ogg",
	AUDIO_DIR + "footstep03.ogg",
	AUDIO_DIR + "footstep04.ogg",
]
const WHISPERS: Array[String] = [
	AUDIO_DIR + "cloth1.ogg",
	AUDIO_DIR + "cloth2.ogg",
	AUDIO_DIR + "cloth3.ogg",
	AUDIO_DIR + "handleSmallLeather.ogg",
]
const DOOR_SLAMS: Array[String] = [
	AUDIO_DIR + "doorClose_1.ogg",
	AUDIO_DIR + "doorClose_2.ogg",
	AUDIO_DIR + "doorClose_3.ogg",
	AUDIO_DIR + "doorClose_4.ogg",
]
const DOOR_OPENS: Array[String] = [
	AUDIO_DIR + "doorOpen_1.ogg",
	AUDIO_DIR + "doorOpen_2.ogg",
]
const MACHINE: Array[String] = [
	AUDIO_DIR + "handleCoins.ogg",
	AUDIO_DIR + "bookFlip1.ogg",
	AUDIO_DIR + "bookFlip2.ogg",
]
const SCREAMS: Array[String] = [
	AUDIO_DIR + "monster_scream_1.wav",
	AUDIO_DIR + "monster_scream_2.wav",
	AUDIO_DIR + "monster_scream_3.wav",
]


func pick_random(paths: Array) -> String:
	if paths.is_empty():
		return ""
	return paths[randi() % paths.size()]


func load_stream(path: String) -> AudioStream:
	if path.is_empty():
		return null
	if ResourceLoader.exists(path):
		return load(path) as AudioStream
	# Fallback for newly-added WAV before Godot generates .import
	if path.ends_with(".wav") and FileAccess.file_exists(path):
		return _load_wav(path)
	return null


func _load_wav(path: String) -> AudioStreamWAV:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var bytes := file.get_buffer(file.get_length())
	file.close()
	if bytes.size() < 44:
		return null

	var mix_rate := 22050
	var channels := 1
	var bits := 16
	var data_offset := -1
	var data_size := 0
	var i := 12
	while i + 8 <= bytes.size():
		var chunk_id := String.chr(bytes[i]) + String.chr(bytes[i + 1]) + String.chr(bytes[i + 2]) + String.chr(bytes[i + 3])
		var chunk_size := bytes.decode_u32(i + 4)
		var payload := i + 8
		if chunk_id == "fmt " and payload + 16 <= bytes.size():
			channels = bytes.decode_u16(payload + 2)
			mix_rate = bytes.decode_u32(payload + 4)
			bits = bytes.decode_u16(payload + 14)
		elif chunk_id == "data":
			data_offset = payload
			data_size = chunk_size
			break
		i = payload + chunk_size
		if chunk_size % 2 == 1:
			i += 1

	if data_offset < 0:
		return null

	var wav := AudioStreamWAV.new()
	if bits == 8:
		wav.format = AudioStreamWAV.FORMAT_8_BITS
	else:
		wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = mix_rate
	wav.stereo = channels > 1
	wav.data = bytes.slice(data_offset, data_offset + data_size)
	return wav

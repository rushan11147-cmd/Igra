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


func pick_random(paths: Array) -> String:
	if paths.is_empty():
		return ""
	return paths[randi() % paths.size()]


func load_stream(path: String) -> AudioStream:
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return load(path) as AudioStream

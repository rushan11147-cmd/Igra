extends Node
## Smart monster memory — each playthrough learns player habits.

const MAX_MEMORY_ENTRIES := 20
const CHECK_THRESHOLD := 3  # Times hidden before monster checks spot

var hiding_spot_counts: Dictionary = {}  # spot_id -> usage count
var noise_hotspots: Array[Dictionary] = []  # {position, intensity, count}
var frequent_routes: Array[Vector3] = []
var flashlight_attract_count: int = 0
var last_hiding_spot: StringName = &""
var player_death_locations: Array[Vector3] = []


func reset() -> void:
	hiding_spot_counts.clear()
	noise_hotspots.clear()
	frequent_routes.clear()
	flashlight_attract_count = 0
	last_hiding_spot = &""
	# death_locations persist across resets for "living factory" feel


func record_hiding(spot_id: StringName, position: Vector3) -> void:
	if spot_id == &"":
		return
	hiding_spot_counts[spot_id] = hiding_spot_counts.get(spot_id, 0) + 1
	last_hiding_spot = spot_id
	_record_position(frequent_routes, position)
	_emit_update()


func record_noise(position: Vector3, intensity: float) -> void:
	if intensity < 1.5:
		return

	for entry in noise_hotspots:
		if entry["position"].distance_to(position) < 5.0:
			entry["count"] += 1
			entry["intensity"] = maxf(entry["intensity"], intensity)
			_emit_update()
			return

	noise_hotspots.append({"position": position, "intensity": intensity, "count": 1})
	if noise_hotspots.size() > MAX_MEMORY_ENTRIES:
		noise_hotspots.pop_front()
	_record_position(frequent_routes, position)
	_emit_update()


func record_flashlight_sighting() -> void:
	flashlight_attract_count += 1
	_emit_update()


func get_spots_to_check() -> Array[StringName]:
	var result: Array[StringName] = []
	for spot_id: StringName in hiding_spot_counts:
		if hiding_spot_counts[spot_id] >= CHECK_THRESHOLD:
			result.append(spot_id)
	result.sort_custom(func(a, b): return hiding_spot_counts[a] > hiding_spot_counts[b])
	return result


func get_noise_hotspot() -> Vector3:
	if noise_hotspots.is_empty():
		return Vector3.ZERO
	var best: Dictionary = noise_hotspots[0]
	for entry in noise_hotspots:
		if entry["count"] > best["count"]:
			best = entry
	return best["position"]


func get_ambush_position() -> Vector3:
	if not frequent_routes.is_empty():
		return frequent_routes[randi() % frequent_routes.size()]
	return Vector3.ZERO


func should_check_last_hiding_spot() -> bool:
	return last_hiding_spot != &"" and hiding_spot_counts.get(last_hiding_spot, 0) >= 2


func _record_position(route: Array[Vector3], pos: Vector3) -> void:
	route.append(pos)
	if route.size() > MAX_MEMORY_ENTRIES:
		route.pop_front()


func _emit_update() -> void:
	EventBus.monster_memory_updated.emit({
		"hiding_spots": hiding_spot_counts.duplicate(),
		"noise_hotspots": noise_hotspots.size(),
		"flashlight_sightings": flashlight_attract_count,
	})

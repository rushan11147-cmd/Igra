extends RefCounted
## Room layouts for every factory level. Coordinates in meters (XZ plane).

const FOOTPRINT := Rect2(-60, -60, 120, 120)


static func level_ids() -> Array[StringName]:
	return [
		&"basement_02",
		&"basement_01",
		&"floor_01",
		&"floor_02",
		&"floor_03",
		&"floor_04",
		&"roof",
	]


static func level_y(level_id: StringName) -> float:
	match level_id:
		&"basement_02":
			return -16.0
		&"basement_01":
			return -8.0
		&"floor_01":
			return 0.0
		&"floor_02":
			return 5.0
		&"floor_03":
			return 10.0
		&"floor_04":
			return 15.0
		&"roof":
			return 20.0
		_:
			return 0.0


static func scene_path(level_id: StringName) -> String:
	return "res://scenes/world/factory_map/floors/%s.tscn" % String(level_id)


static func get_layout(level_id: StringName) -> Dictionary:
	match level_id:
		&"floor_01":
			return _floor_01()
		&"floor_02":
			return _floor_02()
		&"floor_03":
			return _floor_03()
		&"floor_04":
			return _floor_04()
		&"basement_01":
			return _basement_01()
		&"basement_02":
			return _basement_02()
		&"roof":
			return _roof()
		_:
			return {"rooms": [], "markers": {}, "build_ceiling": true}


static func _room(
	id: String,
	x: float,
	z: float,
	w: float,
	d: float,
	role: StringName,
	openings: Array = []
) -> Dictionary:
	return {
		"id": id,
		"rect": Rect2(x, z, w, d),
		"role": role,
		"openings": openings,
	}


static func _op(wall: StringName, t: float = 0.5, w: float = 2.8) -> Dictionary:
	return {"wall": wall, "t": t, "w": w}


static func _floor_01() -> Dictionary:
	var rooms: Array = [
		_room("lobby", -12, 40, 24, 16, &"lobby", [_op(&"s", 0.5), _op(&"n", 0.5)]),
		_room("checkpoint", -8, 30, 16, 10, &"checkpoint", [_op(&"s", 0.5), _op(&"n", 0.5)]),
		_room("security", 8, 30, 12, 10, &"security", [_op(&"w", 0.5), _op(&"s", 0.4)]),
		_room("locker", -28, 18, 16, 14, &"locker", [_op(&"e", 0.5), _op(&"s", 0.5)]),
		_room("shower", -28, 6, 16, 12, &"shower", [_op(&"n", 0.5), _op(&"e", 0.5)]),
		_room("canteen", -28, -12, 18, 16, &"canteen", [_op(&"n", 0.5), _op(&"e", 0.5)]),
		_room("medbay", -8, 18, 12, 10, &"medbay", [_op(&"s", 0.5), _op(&"w", 0.5)]),
		_room("breakroom", 4, 18, 12, 10, &"breakroom", [_op(&"s", 0.5), _op(&"e", 0.5)]),
		_room("corridor_main", -10, -2, 20, 16, &"corridor", [
			_op(&"n", 0.3), _op(&"n", 0.7), _op(&"s", 0.5), _op(&"e", 0.5), _op(&"w", 0.5),
		]),
		_room("production", -8, -30, 24, 22, &"production", [_op(&"n", 0.5), _op(&"e", 0.4), _op(&"w", 0.5)]),
		_room("warehouse", 18, -8, 28, 36, &"warehouse", [_op(&"w", 0.35), _op(&"w", 0.65), _op(&"s", 0.5)]),
		_room("loading", 22, -48, 24, 16, &"loading", [_op(&"n", 0.5), _op(&"s", 0.5, 6.0)]),
		_room("hall8", -48, -30, 18, 18, &"locked_tech", [_op(&"e", 0.5)]),
		_room("stair_a", -52, 40, 10, 10, &"stairwell", [_op(&"e", 0.5), _op(&"s", 0.5)]),
		_room("stair_b", 42, 40, 10, 10, &"stairwell", [_op(&"w", 0.5), _op(&"s", 0.5)]),
		_room("elev_cargo", -52, -48, 10, 10, &"elevator", [_op(&"e", 0.5)]),
		_room("elev_tech", 42, -48, 10, 10, &"elevator", [_op(&"w", 0.5)]),
		_room("service_w", -52, 8, 10, 28, &"service", [_op(&"n", 0.5), _op(&"s", 0.5), _op(&"e", 0.3), _op(&"e", 0.7)]),
		_room("service_e", 42, 8, 10, 28, &"service", [_op(&"n", 0.5), _op(&"s", 0.5), _op(&"w", 0.3), _op(&"w", 0.7)]),
		_room("corridor_n", -42, 40, 30, 8, &"corridor", [_op(&"w", 0.5), _op(&"e", 0.5), _op(&"s", 0.4)]),
		_room("corridor_s", -42, -52, 64, 8, &"corridor", [_op(&"w", 0.2), _op(&"e", 0.8), _op(&"n", 0.3), _op(&"n", 0.7)]),
	]
	return {
		"rooms": rooms,
		"build_ceiling": true,
		"markers": {
			"PlayerSpawn": Vector3(0, 0, 44),
			"Reactor": Vector3(-4, 0, -24),
			"Mixer": Vector3(4, 0, -22),
			"ConveyorA": Vector3(2, 0, -28),
			"ConveyorB": Vector3(6, 0, -32),
			"HidingCloset": Vector3(28, 0, 0),
			"DocumentLog": Vector3(-20, 0, 20),
			"Hall8Key": Vector3(-22, 0, 12),
			"Hall8Door": Vector3(-38, 0, -22),
			"Patrol1": Vector3(-4, 0, -24),
			"Patrol2": Vector3(28, 0, -8),
			"Patrol3": Vector3(0, 0, -40),
			"Patrol4": Vector3(-22, 0, 10),
		},
	}


static func _floor_02() -> Dictionary:
	return {
		"build_ceiling": true,
		"markers": {},
		"rooms": [
			_room("line_a", -40, -20, 36, 28, &"line", [_op(&"e", 0.5), _op(&"n", 0.5)]),
			_room("line_b", 4, -20, 36, 28, &"line", [_op(&"w", 0.5), _op(&"n", 0.5)]),
			_room("reactor_bay", -20, 16, 40, 24, &"reactor_bay", [_op(&"s", 0.5), _op(&"e", 0.5), _op(&"w", 0.5)]),
			_room("tanks", 24, 16, 20, 24, &"reactor_bay", [_op(&"w", 0.5)]),
			_room("pulpit", -12, 44, 24, 12, &"pulpit", [_op(&"s", 0.5)]),
			_room("electrical", -40, 44, 16, 12, &"electrical", [_op(&"e", 0.5), _op(&"s", 0.5)]),
			_room("pump", 20, 44, 16, 12, &"pump", [_op(&"w", 0.5), _op(&"s", 0.5)]),
			_room("bridge_a", -8, 4, 16, 8, &"glass_bridge", [_op(&"n", 0.5), _op(&"s", 0.5)]),
			_room("corridor", -8, -40, 16, 12, &"corridor", [_op(&"n", 0.3), _op(&"n", 0.7), _op(&"s", 0.5)]),
			_room("stair_a", -52, 40, 10, 10, &"stairwell", [_op(&"e", 0.5)]),
			_room("stair_b", 42, 40, 10, 10, &"stairwell", [_op(&"w", 0.5)]),
			_room("elev_cargo", -52, -48, 10, 10, &"elevator", [_op(&"e", 0.5)]),
			_room("elev_tech", 42, -48, 10, 10, &"elevator", [_op(&"w", 0.5)]),
			_room("service_w", -52, 0, 10, 32, &"service", [_op(&"n", 0.5), _op(&"s", 0.5), _op(&"e", 0.5)]),
			_room("service_e", 42, 0, 10, 32, &"service", [_op(&"n", 0.5), _op(&"s", 0.5), _op(&"w", 0.5)]),
		],
	}


static func _floor_03() -> Dictionary:
	return {
		"build_ceiling": true,
		"markers": {},
		"rooms": [
			_room("lab", -40, 8, 28, 28, &"lab", [_op(&"e", 0.5), _op(&"s", 0.5)]),
			_room("test_hall", -4, 8, 28, 28, &"test_hall", [_op(&"w", 0.5), _op(&"e", 0.5), _op(&"s", 0.5)]),
			_room("archive", 32, 8, 16, 28, &"archive", [_op(&"w", 0.5)]),
			_room("office_a", -40, -28, 18, 16, &"office", [_op(&"n", 0.5), _op(&"e", 0.5)]),
			_room("office_b", -18, -28, 18, 16, &"office", [_op(&"n", 0.5), _op(&"w", 0.5), _op(&"e", 0.5)]),
			_room("server", 4, -28, 16, 16, &"server", [_op(&"w", 0.5), _op(&"e", 0.5)]),
			_room("cctv", 24, -28, 16, 16, &"cctv", [_op(&"w", 0.5)]),
			_room("glass_a", -10, 40, 28, 8, &"glass_bridge", [_op(&"s", 0.5), _op(&"w", 0.5), _op(&"e", 0.5)]),
			_room("glass_b", -10, -48, 28, 8, &"glass_bridge", [_op(&"n", 0.5)]),
			_room("corridor", -8, -8, 16, 12, &"corridor", [_op(&"n", 0.5), _op(&"s", 0.5), _op(&"e", 0.5), _op(&"w", 0.5)]),
			_room("stair_a", -52, 40, 10, 10, &"stairwell", [_op(&"e", 0.5)]),
			_room("stair_b", 42, 40, 10, 10, &"stairwell", [_op(&"w", 0.5)]),
			_room("elev_cargo", -52, -48, 10, 10, &"elevator", [_op(&"e", 0.5)]),
			_room("elev_tech", 42, -48, 10, 10, &"elevator", [_op(&"w", 0.5)]),
			_room("service_w", -52, 0, 10, 32, &"service", [_op(&"n", 0.5), _op(&"s", 0.5), _op(&"e", 0.5)]),
			_room("service_e", 42, 0, 10, 32, &"service", [_op(&"n", 0.5), _op(&"s", 0.5), _op(&"w", 0.5)]),
		],
	}


static func _floor_04() -> Dictionary:
	return {
		"build_ceiling": true,
		"markers": {},
		"rooms": [
			_room("secret_lab", -36, 8, 24, 24, &"secret_lab", [_op(&"e", 0.5)]),
			_room("reactor_hall", -8, -8, 32, 40, &"reactor_hall", [_op(&"w", 0.5), _op(&"e", 0.5), _op(&"n", 0.5), _op(&"s", 0.5)]),
			_room("computer", 28, 8, 20, 24, &"computer", [_op(&"w", 0.5)]),
			_room("docs", -36, -28, 24, 16, &"docs", [_op(&"n", 0.5), _op(&"e", 0.5)]),
			_room("emergency_cc", 28, -28, 20, 16, &"emergency_cc", [_op(&"n", 0.5), _op(&"w", 0.5)]),
			_room("corridor_n", -8, 36, 16, 10, &"corridor", [_op(&"s", 0.5), _op(&"w", 0.5), _op(&"e", 0.5)]),
			_room("corridor_s", -8, -48, 16, 10, &"corridor", [_op(&"n", 0.5)]),
			_room("stair_a", -52, 40, 10, 10, &"stairwell", [_op(&"e", 0.5)]),
			_room("stair_b", 42, 40, 10, 10, &"stairwell", [_op(&"w", 0.5)]),
			_room("elev_cargo", -52, -48, 10, 10, &"elevator", [_op(&"e", 0.5)]),
			_room("elev_tech", 42, -48, 10, 10, &"elevator", [_op(&"w", 0.5)]),
			_room("service_w", -52, 0, 10, 32, &"service", [_op(&"n", 0.5), _op(&"s", 0.5), _op(&"e", 0.5)]),
			_room("service_e", 42, 0, 10, 32, &"service", [_op(&"n", 0.5), _op(&"s", 0.5), _op(&"w", 0.5)]),
		],
	}


static func _basement_01() -> Dictionary:
	return {
		"build_ceiling": true,
		"markers": {},
		"rooms": [
			_room("tunnel_n", -40, 20, 80, 12, &"tunnel", [_op(&"s", 0.25), _op(&"s", 0.75), _op(&"w", 0.5), _op(&"e", 0.5)]),
			_room("tunnel_s", -40, -40, 80, 12, &"tunnel", [_op(&"n", 0.25), _op(&"n", 0.75), _op(&"w", 0.5), _op(&"e", 0.5)]),
			_room("boiler", -40, -20, 24, 28, &"boiler", [_op(&"n", 0.5), _op(&"s", 0.5), _op(&"e", 0.5)]),
			_room("water", -8, -20, 24, 28, &"water", [_op(&"w", 0.5), _op(&"e", 0.5), _op(&"n", 0.5)]),
			_room("generator", 24, -20, 24, 28, &"generator", [_op(&"w", 0.5), _op(&"n", 0.5), _op(&"s", 0.5)]),
			_room("sewer", -20, 40, 40, 14, &"sewer", [_op(&"s", 0.5)]),
			_room("locked_a", -48, -20, 12, 12, &"locked_tech", [_op(&"e", 0.5)]),
			_room("locked_b", 40, -20, 12, 12, &"locked_tech", [_op(&"w", 0.5)]),
			_room("stair_a", -52, 40, 10, 10, &"stairwell", [_op(&"e", 0.5)]),
			_room("stair_b", 42, 40, 10, 10, &"stairwell", [_op(&"w", 0.5)]),
			_room("elev_cargo", -52, -48, 10, 10, &"elevator", [_op(&"e", 0.5)]),
			_room("elev_tech", 42, -48, 10, 10, &"elevator", [_op(&"w", 0.5)]),
		],
	}


static func _basement_02() -> Dictionary:
	return {
		"build_ceiling": true,
		"markers": {},
		"rooms": [
			_room("horror_lab", -40, 8, 28, 24, &"horror_lab", [_op(&"e", 0.5), _op(&"s", 0.5)]),
			_room("experiment", -4, 8, 24, 24, &"experiment", [_op(&"w", 0.5), _op(&"e", 0.5), _op(&"s", 0.5)]),
			_room("morgue", 28, 8, 20, 24, &"morgue", [_op(&"w", 0.5)]),
			_room("cage", -40, -28, 24, 20, &"cage", [_op(&"n", 0.5), _op(&"e", 0.5)]),
			_room("waste", -8, -28, 24, 20, &"waste", [_op(&"w", 0.5), _op(&"e", 0.5), _op(&"n", 0.5)]),
			_room("ruin", 24, -28, 24, 20, &"ruin", [_op(&"w", 0.5), _op(&"n", 0.5)]),
			_room("secret_tunnel", -12, -52, 24, 10, &"secret_tunnel", [_op(&"n", 0.5)]),
			_room("corridor", -8, -4, 16, 10, &"corridor", [_op(&"n", 0.5), _op(&"s", 0.5), _op(&"e", 0.5), _op(&"w", 0.5)]),
			_room("stair_a", -52, 40, 10, 10, &"stairwell", [_op(&"e", 0.5)]),
			_room("stair_b", 42, 40, 10, 10, &"stairwell", [_op(&"w", 0.5)]),
			_room("elev_cargo", -52, -48, 10, 10, &"elevator", [_op(&"e", 0.5)]),
			_room("elev_tech", 42, -48, 10, 10, &"elevator", [_op(&"w", 0.5)]),
		],
	}


static func _roof() -> Dictionary:
	return {
		"build_ceiling": false,
		"markers": {},
		"rooms": [
			_room("roof_deck", -50, -50, 100, 100, &"roof", []),
			_room("stair_a", -52, 40, 10, 10, &"stairwell", [_op(&"e", 0.5)]),
			_room("stair_b", 42, 40, 10, 10, &"stairwell", [_op(&"w", 0.5)]),
			_room("elev_cargo", -52, -48, 10, 10, &"elevator", [_op(&"e", 0.5)]),
			_room("elev_tech", 42, -48, 10, 10, &"elevator", [_op(&"w", 0.5)]),
		],
	}

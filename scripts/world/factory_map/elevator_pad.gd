extends Area3D
## Elevator pad: stand inside and press Interact to travel up one level (wraps).

const LayoutDataScript = preload("res://scripts/world/factory_map/layout_data.gd")

@export var bank_id: StringName = &"cargo"
@export var level_id: StringName = &"floor_01"

var _player_inside: Node3D = null


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _unhandled_input(event: InputEvent) -> void:
	if _player_inside == null:
		return
	if event.is_action_pressed("interact"):
		_travel()


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		_player_inside = body


func _on_body_exited(body: Node3D) -> void:
	if body == _player_inside:
		_player_inside = null


func _travel() -> void:
	if _player_inside == null:
		return
	var levels: Array = LayoutDataScript.level_ids()
	var idx := levels.find(level_id)
	if idx < 0:
		return
	var next_idx := (idx + 1) % levels.size()
	var next_id: StringName = levels[next_idx]
	var next_y: float = LayoutDataScript.level_y(next_id)
	var dest := global_position
	dest.y = next_y + 0.1
	_player_inside.global_position = dest

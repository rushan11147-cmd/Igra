class_name ConveyorBelt
extends Interactable
## Production line conveyor — must be running for shift tasks.

@export var machine_id: StringName = &"conveyor_a"
@export var belt_speed: float = 1.0

var is_running: bool = false
var units_transported: int = 0

static var _running_count: int = 0
static var _total_count: int = 0


func _ready() -> void:
	super._ready()
	interaction_prompt = "Запустить конвейер [E]"
	_total_count += 1


func _exit_tree() -> void:
	_total_count -= 1
	if is_running:
		_running_count -= 1


func _process(delta: float) -> void:
	if is_running:
		if randf() < belt_speed * delta * 0.1:
			units_transported += 1


func _on_interact(_player: Node3D) -> void:
	is_running = not is_running
	if is_running:
		_running_count += 1
	else:
		_running_count = maxi(0, _running_count - 1)

	interaction_prompt = "Остановить конвейер [E]" if is_running else "Запустить конвейер [E]"
	_check_all_lines()


func _check_all_lines() -> void:
	if _running_count >= _total_count and _total_count > 0:
		ShiftManager.complete_task(&"start_line_3")

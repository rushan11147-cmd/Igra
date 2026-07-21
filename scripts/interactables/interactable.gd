class_name Interactable
extends Area3D
## Base class for all player-interactable objects in the factory.

@export var interaction_prompt: String = "Взаимодействовать"
@export var interaction_enabled: bool = true

signal interacted(player: Node3D)


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	collision_layer = 4  # interactable layer
	collision_mask = 0


func get_prompt() -> String:
	return interaction_prompt if interaction_enabled else ""


func interact(player: Node3D) -> void:
	if not interaction_enabled:
		return
	interacted.emit(player)
	_on_interact(player)
	EventBus.player_interacted.emit(self)


func _on_interact(_player: Node3D) -> void:
	pass


func _on_body_entered(_body: Node3D) -> void:
	pass


func _on_body_exited(_body: Node3D) -> void:
	pass

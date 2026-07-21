class_name HidingSpot
extends Interactable
## Closets, containers, technical rooms — player can hide from the entity.

@export var spot_id: StringName = &"closet"


func _ready() -> void:
	super._ready()
	add_to_group("hiding_spots")
	interaction_prompt = "Спрятаться [E]"


func _on_interact(player: Node3D) -> void:
	if player.has_method("enter_hiding"):
		player.enter_hiding(self)
		MonsterMemory.record_hiding(spot_id, global_position)
		interaction_enabled = false


func release_player() -> void:
	interaction_enabled = true

class_name DocumentPickup
extends Interactable
## Collectible documents that advance the story toward secret ending.

@export var document_id: StringName = &"doc_shift_log"

var _collected: bool = false


func _ready() -> void:
	super._ready()
	interaction_prompt = "Подобрать документ [E]"


func _on_interact(_player: Node3D) -> void:
	if _collected:
		return
	_collected = true
	StoryManager.find_document(document_id)
	visible = false
	interaction_enabled = false
	set_collision_layer_value(4, false)

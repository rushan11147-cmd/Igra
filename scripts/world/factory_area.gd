extends Node3D
## Marks a factory zone. Visibility toggled by AreaManager when unlocked.

@export var area_id: StringName = &""
@export var locked_visible: bool = false  # Show silhouette when locked


func _ready() -> void:
	add_to_group("factory_areas")

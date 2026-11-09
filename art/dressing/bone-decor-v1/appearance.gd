extends Node3D
## Shared scenery material with the same world-space grain as the cave props.
@export var appearance: Material

func _ready() -> void:
	for mesh: MeshInstance3D in find_children("*", "MeshInstance3D", true, false):
		mesh.material_override = appearance
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

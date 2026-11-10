extends Node3D
## Shared registration; state remains owned by the event controller.
@export_enum("closed","open","empty") var state := "closed":
	set(value):
		state=value
		if is_node_ready(): _apply()
@export var palette_material: Material

func _ready() -> void:
	for mesh: MeshInstance3D in find_children("*","MeshInstance3D",true,false):
		mesh.material_override=palette_material
	_apply()

func _apply() -> void:
	$Fresh.visible=state!="empty"
	$Spent.visible=state=="empty"

func set_searched(searched: bool) -> void:
	state="empty" if searched else "closed"

func set_motion(_enabled: bool) -> void:
	pass # All three landmarks are intentionally static.

extends Node3D
## Static art. State strings only choose geometry; callers own all rules.
const SURFACE=preload("res://art/features/damp-passages-v1/wet-passages.tres")
@export var ground_material: Material
@export var kind: String="static"
@export var sign_label: String=""
@export var state: String="static":
	set(value):
		state=value
		_apply_state()

func _ready() -> void:
	var ground:=ground_material.duplicate() if ground_material else SURFACE
	if ground is StandardMaterial3D:
		ground.uv1_triplanar=true;ground.uv1_world_triplanar=true;ground.uv1_scale=Vector3.ONE*.5
	for mesh: MeshInstance3D in find_children("*","MeshInstance3D",true,false):
		mesh.material_override=ground if mesh.name.begins_with("Ground") else SURFACE
		mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if mesh.name.begins_with("Canopy"):mesh.add_to_group("ceiling")

	_apply_state()

func set_state(value: String,_animate:=false) -> bool:
	var valid: Array=["intact","opened"] if kind=="curtain" else (["blocked","cleared"] if kind=="siltfall" else ["static"])
	if value not in valid:return false
	state=value;return true

func _apply_state() -> void:
	for name: String in ["Intact","Opened","Blocked","Cleared"]:
		var part:=get_node_or_null(name) as Node3D
		if part:part.visible=name.to_lower()==state

func set_motion(_enabled: bool) -> void:
	pass # Exactly static; no processing, timers, particles or movement.

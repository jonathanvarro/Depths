extends Node3D
## Cosmetic transition/blocker. LevelBuilder and Party own travel and passage state.
@export var palette_material: Material
@export var ground_material: Material

func _ready() -> void:
	# The strands can cover the party token when a fight starts on the climb.
	if get_meta("asset_id", "") == "root-climb-up":
		add_to_group("ceiling")
	var ground: Material=palette_material
	if ground_material!=null:
		ground=ground_material.duplicate()
		if ground is StandardMaterial3D:
			ground.uv1_triplanar=true
			ground.uv1_world_triplanar=true
			ground.uv1_scale=Vector3(.5,.5,.5)
	var sky:=ShaderMaterial.new()
	sky.shader=load("res://art/features/transitions-3d-v1/daylight.gdshader")
	var vista: Material=palette_material.duplicate()
	if vista is StandardMaterial3D:
		vista.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
		vista.detail_enabled=false
	for item: MeshInstance3D in find_children("*","MeshInstance3D",true,false):
		item.material_override=ground if item.name.begins_with("Ground") else (sky if item.name.begins_with("Sky") else (vista if item.name.begins_with("Vista") else palette_material))
		item.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if item.name.begins_with("Canopy"): item.add_to_group("ceiling")

func set_motion(_enabled: bool) -> void:
	pass # All features are static; no light, travel or blocker authority.

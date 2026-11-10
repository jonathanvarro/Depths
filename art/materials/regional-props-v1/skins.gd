extends RefCounted
## #225 material choice only. The caller owns region, placement and density.
const REGIONS := ["fungal","scorched","waterlogged"]

static func material(region: String) -> Material:
	if region not in REGIONS:
		push_warning("Unknown regional prop material "+region)
		return null
	return load("res://art/materials/regional-props-v1/"+region+".tres")

static func apply(root: Node3D, shared: Material) -> void:
	if shared==null: return
	for item: MeshInstance3D in root.find_children("*","MeshInstance3D",true,false):
		item.material_override=shared
		item.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

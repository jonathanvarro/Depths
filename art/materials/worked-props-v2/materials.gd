extends RefCounted
const DIR := "res://art/materials/worked-props-v2/"

static func make() -> Dictionary:
	var result := {}
	for key in ["Wood","Iron","Silver","Gold","Stone","Cloth"]:
		# ResourceLoader shares read-only materials while props need them; no
		# static cache survives a floor. Only local glass materials are mutable.
		result[key]=load(DIR+key.to_lower()+".tres")
	return result

static func apply(root: Node3D, shared: Dictionary) -> void:
	for mesh: MeshInstance3D in root.find_children("*","MeshInstance3D",true,false):
		for kind: String in shared:
			if mesh.name.begins_with(kind):mesh.material_override=shared[kind];break
		mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

extends "res://art/enemies/creatures-predatory-v3/actor.gd"
## Old Whisker's fitted scars/whiskers and ash bristles use the same bones.
@export var details: PackedScene
const LEADER_MATERIAL:=preload("res://art/enemies/named-leaders-v1/whisker.tres")
func _ready() -> void:
	var requested:=current_pose;current_pose="idle"
	super._ready();sample("idle",0)
	for material in surfaces:
		if material.shader==COAT.shader and int(material.get_shader_parameter("surface_kind"))==0:material.set_shader_parameter("ash",.82)
	var rig: Skeleton3D=find_children("*","Skeleton3D",true,false)[0]
	var parts: Node3D=details.instantiate();add_child(parts)
	for mesh: MeshInstance3D in parts.find_children("*","MeshInstance3D",true,false):
		assert(rig.find_bone(mesh.name)>=0)
		var source_transform:=global_transform.affine_inverse()*mesh.global_transform
		var bind:=global_transform.affine_inverse()*rig.global_transform*rig.get_bone_global_pose(rig.find_bone(mesh.name))
		var mount:=BoneAttachment3D.new();mount.bone_name=mesh.name;rig.add_child(mount)
		mesh.reparent(mount,false);mesh.transform=bind.affine_inverse()*source_transform
		mesh.material_override=LEADER_MATERIAL;mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parts.free();play(requested)


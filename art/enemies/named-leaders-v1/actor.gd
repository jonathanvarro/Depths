extends "res://art/enemies/combat-roster-3d-v1/actor.gd"
## Original model/rig/clips remain intact. New details follow existing bones.
@export var details: PackedScene
var attachments: Array[BoneAttachment3D] = []

func _ready() -> void:
	var requested := current_pose
	current_pose="idle"
	super._ready()
	# Authoring coordinates are metric actor space at idle t=0, independent of
	# source skeleton scale, bind pose and any pose requested before tree entry.
	sample("idle",0)
	var rig: Skeleton3D=find_children("*","Skeleton3D",true,false)[0]
	var parts: Node3D=details.instantiate()
	add_child(parts)
	for mesh: MeshInstance3D in parts.find_children("*","MeshInstance3D",true,false):
		var bone:=rig.find_bone(mesh.name)
		assert(bone>=0,"Unknown leader attachment bone: "+mesh.name)
		var source_transform:=global_transform.affine_inverse()*mesh.global_transform
		var bind:=global_transform.affine_inverse()*rig.global_transform*rig.get_bone_global_pose(bone)
		var mount:=BoneAttachment3D.new();mount.name="Leader_"+mesh.name
		mount.bone_name=mesh.name;rig.add_child(mount);attachments.append(mount)
		mesh.reparent(mount,false)
		mesh.transform=bind.affine_inverse()*source_transform
		mesh.material_override=palette_material
		mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parts.free()
	play(requested)

extends Node3D
## Local GLB presentation only. Source body faces form disjoint coverage chunks.
var fit:String
var record:Dictionary
var model:Node3D
var skeleton:Skeleton3D
var player:AnimationPlayer
var meshes:Dictionary={}
var clips:Dictionary={}
var selected_bits:=31
var current_motion:="rest"
var motion_time:=0.0
var playing:=false
var display_scale:=1.0
var expected_display_height:=0.0
## Optional manifest "sequences": key -> clip ids played back to back (#218).
var sequences:Dictionary={}
## Per sequence, the model offset for each clip so its hips start where the
## previous clip's hips ended. Horizontal only: the floor never moves.
var sequence_offsets:Dictionary={}
var joins:Array=[]

func setup(identity:String,data:Dictionary)->void:
	fit=identity;record=data
	var policy:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://display_normalization.json"))
	display_scale=float(policy.source_unit_to_metres);expected_display_height=float(policy.fits[record.fit_id].display_body_height)
	# One uniform scale for both bodies preserves natural height differences.
	# This parent reference is fixed for every clip and clothing selection.
	scale=Vector3.ONE*display_scale;position.y=-float(record.floor_y)*display_scale
	model=load("res://"+str(record.export)).instantiate();add_child(model)
	skeleton=model.find_children("*","Skeleton3D",true,false)[0]
	player=model.find_children("*","AnimationPlayer",true,false)[0]
	player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	# Godot sanitizes glTF node dots and bone colons to underscores. Keep the
	# manifest's canonical names as keys, with an explicit one-to-one lookup.
	var instances=model.find_children("*","MeshInstance3D",true,false)
	for entry in record.body_chunks+record.garments:
		for instance:MeshInstance3D in instances:
			if str(instance.name)==str(entry.name).replace(".","_"):meshes[str(entry.name)]=instance
	assert(meshes.size()==instances.size(),"Every manifest mesh must map once")
	for motion in record.motions:
		var wanted:=str(motion.action).to_lower().replace(".","").replace("_","").replace("|","")
		for clip in player.get_animation_list():
			var actual:=str(clip).to_lower().replace(".","").replace("_","").replace("|","")
			if actual==wanted:clips[str(motion.id)]=clip
	for key in sequences:align_sequence(str(key))
	set_garments(31);set_motion("rest",0)

func hips_local()->Vector3:
	skeleton.force_update_all_bone_transforms()
	return to_local(skeleton.to_global(skeleton.get_bone_global_pose(skeleton.find_bone("mixamorig_Hips")).origin))

func clip_length(id:String)->float:
	return player.get_animation(clips[id]).length

func pose_at(id:String,time:float)->void:
	player.play(clips[id]);player.seek(time,true);player.advance(0)

func align_sequence(key:String)->void:
	var parts:Array=sequences[key];var offsets:Array=[Vector3.ZERO]
	for part in parts:assert(clips.has(str(part)),"Missing sequence clip "+fit+"/"+str(part))
	for i in range(1,parts.size()):
		var before:=str(parts[i-1]);var after:=str(parts[i])
		model.position=offsets[i-1];pose_at(before,clip_length(before));var end:=hips_local()
		model.position=Vector3.ZERO;pose_at(after,0);var start:=hips_local()
		var offset:=end-start;var vertical:=offset.y;offset.y=0
		offsets.append(offset)
		model.position=offset;pose_at(after,0);var residual:=hips_local()-end
		joins.append({"sequence":key,"from":before,"to":after,"offset_source_units":offset.length(),
			"vertical_gap_source_units":vertical,"aligned_horizontal_residual":Vector2(residual.x,residual.z).length()})
	model.position=Vector3.ZERO
	sequence_offsets[key]=offsets

## Seconds at which each sequence clip after the first begins.
func join_times(key:String)->Array:
	var result:=[];var time:=0.0;var parts:Array=sequences[key]
	for i in range(parts.size()-1):time+=clip_length(str(parts[i]));result.append(time)
	return result

func set_garments(bits:int)->void:
	selected_bits=bits
	for chunk in record.body_chunks:meshes[str(chunk.name)].visible=(int(chunk.hidden_by)&bits)==0
	var pieces:Array=["tunic","belt","trousers","boot.left","boot.right"]
	for garment in record.garments:meshes[str(garment.name)].visible=(bits&(1<<pieces.find(str(garment.piece))))!=0

func duration()->float:
	if sequences.has(current_motion):
		var total:=0.0
		for part in sequences[current_motion]:total+=clip_length(str(part))
		return total
	return player.get_animation(clips[current_motion]).length if clips.has(current_motion) else 0.0

func set_motion(key:String,time:float=0)->void:
	current_motion=key;motion_time=clampf(time,0,duration());model.position=Vector3.ZERO
	if sequences.has(key):
		var parts:Array=sequences[key];var local:=motion_time
		for i in parts.size():
			var length:=clip_length(str(parts[i]))
			if local<length or i==parts.size()-1:
				model.position=sequence_offsets[key][i];pose_at(str(parts[i]),minf(local,length));break
			local-=length
	elif key=="rest":
		player.stop();skeleton.reset_bone_poses()
	else:
		assert(clips.has(key),"Missing verified fitting clip "+fit+"/"+key)
		player.play(clips[key]);player.seek(motion_time,true);player.advance(0)
	skeleton.force_update_all_bone_transforms()

func step(delta:float)->void:
	if not playing or current_motion=="rest":return
	# Stop at the real endpoint. Repeating would falsely imply a verified loop.
	motion_time=minf(duration(),motion_time+delta);set_motion(current_motion,motion_time)
	if motion_time>=duration():playing=false

func bone_points()->Array[Vector3]:
	var result:Array[Vector3]=[]
	for i in skeleton.get_bone_count():result.append(skeleton.to_global(skeleton.get_bone_global_pose(i).origin))
	return result

func head_position()->Vector3:
	return skeleton.to_global(skeleton.get_bone_global_pose(skeleton.find_bone("mixamorig_Head")).origin)

func stats()->Dictionary:
	var triangles:=0;var surfaces:=0;var materials:={};var texture_pixels:=0;var textures:={}
	for instance:MeshInstance3D in meshes.values():
		if not instance.visible:continue
		for i in instance.mesh.get_surface_count():
			surfaces+=1;var arrays:Array=instance.mesh.surface_get_arrays(i);triangles+=arrays[Mesh.ARRAY_INDEX].size()/3
			var material:BaseMaterial3D=instance.get_active_material(i)
			if material:
				materials[material.get_instance_id()]=true
				if material.albedo_texture:textures[material.albedo_texture.get_instance_id()]=material.albedo_texture
	for texture:Texture2D in textures.values():texture_pixels+=texture.get_width()*texture.get_height()
	return {"triangles":triangles,"surfaces":surfaces,"materials":materials.size(),"texture_pixels":texture_pixels,"texture_count":textures.size(),"bones":skeleton.get_bone_count()}

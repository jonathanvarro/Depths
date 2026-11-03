extends SceneTree
## Isolated import/skin/animation check. No live Main, Settings or save lifecycle.
var checks:=0
var failures:Array[String]=[]
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures.append(label);push_error(label)
func _initialize()->void:call_deferred("run")
func cpu_bounds(instance:MeshInstance3D,skeleton:Skeleton3D)->AABB:
	var bounds:=AABB();var first:=true;var skin:Skin=instance.skin
	for surface in instance.mesh.get_surface_count():
		var a:Array=instance.mesh.surface_get_arrays(surface);var verts:PackedVector3Array=a[Mesh.ARRAY_VERTEX];var bones:PackedInt32Array=a[Mesh.ARRAY_BONES];var weights:PackedFloat32Array=a[Mesh.ARRAY_WEIGHTS];var stride:=weights.size()/verts.size()
		for i in verts.size():
			var position:=Vector3.ZERO
			for n in stride:
				var offset:=i*stride+n;var bind:=bones[offset]
				if weights[offset]<=0:continue
				var index:=skin.get_bind_bone(bind)
				if index<0:index=skeleton.find_bone(skin.get_bind_name(bind))
				position+=(skeleton.get_bone_global_pose(index)*skin.get_bind_pose(bind)*verts[i])*weights[offset]
			if first:bounds=AABB(position,Vector3.ZERO);first=false
			else:bounds=bounds.expand(position)
	return bounds
func run()->void:
	root.size=Vector2i(852,590)
	var camera:=Camera3D.new();root.add_child(camera);camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=4.9;camera.position=Vector3(5,2.6,8);camera.look_at(Vector3(0,1.9,0));camera.current=true
	var light:=DirectionalLight3D.new();root.add_child(light);light.rotation_degrees=Vector3(-40,-25,0);light.light_energy=1.5
	var world:=WorldEnvironment.new();world.environment=Environment.new();world.environment.background_mode=Environment.BG_COLOR;world.environment.background_color=Color(.12,.15,.15);world.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;world.environment.ambient_light_color=Color(.8,.85,.85);world.environment.ambient_light_energy=.7;root.add_child(world)
	var summary:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://summary.json"));var totals:={}
	for fit in summary:
		var model:Node3D=load("res://"+fit+"_kit.glb").instantiate();root.add_child(model);await process_frame
		var skeleton:Skeleton3D=model.find_children("*","Skeleton3D",true,false)[0];var player:AnimationPlayer=model.find_children("*","AnimationPlayer",true,false)[0]
		var meshes:=model.find_children("*","MeshInstance3D",true,false);check(meshes.size()==11,fit+" complete masked body and ten garment meshes")
		check(skeleton.get_bone_count()==int(summary[fit].bones),fit+" original full joint set")
		var triangles:=0;var surfaces:=0
		for instance:MeshInstance3D in meshes:
			check(instance.skin!=null and instance.get_node(instance.skeleton)==skeleton,fit+" real bound skin "+instance.name)
			for surface in instance.mesh.get_surface_count():
				surfaces+=1;var a:Array=instance.mesh.surface_get_arrays(surface);triangles+=a[Mesh.ARRAY_INDEX].size()/3
				var weights:PackedFloat32Array=a[Mesh.ARRAY_WEIGHTS];var bones:PackedInt32Array=a[Mesh.ARRAY_BONES];var stride:int=weights.size()/a[Mesh.ARRAY_VERTEX].size()
				check(stride in [4,8],fit+" supported influence layout")
				for v in a[Mesh.ARRAY_VERTEX].size():
					var total:=0.0;var valid:=true
					for n in stride:total+=weights[v*stride+n];valid=valid and bones[v*stride+n]<instance.skin.get_bind_count()
					check(absf(total-1)<.001 and valid,fit+" normalized valid vertex "+str(v))
				check(instance.mesh.surface_get_material(surface)!=null,fit+" portable material")
				if fit=="female" and instance.name.begins_with("body"):
					var material:BaseMaterial3D=instance.mesh.surface_get_material(surface)
					check(material.transparency==BaseMaterial3D.TRANSPARENCY_DISABLED and material.albedo_texture!=null and material.albedo_texture.get_width()==1024,"Female original opaque skin texture has correct depth behavior")
		check(triangles==int(summary[fit].triangles),fit+" exact baked garment/mask triangle count")
		var clips:Array[String]=[]
		for name in player.get_animation_list():
			if name!="RESET":clips.append(name)
		check(clips.size()==int(summary[fit].get("motions",5)),fit+" intended motion count")
		var samples:=0
		for clip in clips:
			var length:float=player.get_animation(clip).length
			for time in [0.0,length*.25+.004,length*.5+.008,length]:
				player.play(clip);player.seek(time,true);player.advance(0);await process_frame;skeleton.force_update_all_bone_transforms()
				if DisplayServer.get_name()!="headless":await RenderingServer.frame_post_draw
				for instance:MeshInstance3D in meshes:
					var bounds:=cpu_bounds(instance,skeleton);var world_bounds:AABB=instance.global_transform*bounds
					check(world_bounds.position.is_finite() and world_bounds.size.is_finite() and world_bounds.size.length()<12,fit+" finite actual world deformation "+clip+instance.name)
					if DisplayServer.get_name()!="headless":
						var baked:=instance.bake_mesh_from_current_skeleton_pose();check(baked!=null and baked.get_aabb().size.distance_to(bounds.size)<.025,fit+" native skin bake matches CPU "+clip+instance.name)
					samples+=1
				if DisplayServer.get_name()!="headless" and clip.contains(str(summary[fit].get("capture_clip_contains","idle"))) and is_zero_approx(time):
					check(root.get_texture().get_image().save_png("res://native-"+fit+".png")==OK,fit+" actual native import render")
			player.stop()
		model.free();await process_frame;totals[fit]={"triangles":triangles,"surfaces":surfaces,"deformed_mesh_samples":samples}
	var f:=FileAccess.open("res://godot-validation.json",FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"failures":failures,"totals":totals,"renderer":RenderingServer.get_current_rendering_method(),"player_files_used":false,"physical_iphone_tested":false},"\t")+"\n");f.close()
	print("GARMENT_GODOT: %d checks, %d failures"%[checks,failures.size()]);quit(0 if failures.is_empty() else 1)

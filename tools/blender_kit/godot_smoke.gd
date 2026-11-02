extends SceneTree
## Standalone project only: never loads live Main or player settings/saves.
var checks:=0
var failures:Array[String]=[]
func check(ok:bool,label:String) -> void:
	checks+=1
	if not ok:failures.append(label);push_error(label)
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var fits:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://summary.json"))
	for fit in ["female","male"]:
		var model:Node3D=load("res://"+fit+"_base.glb").instantiate();root.add_child(model)
		await process_frame
		var skeleton:Skeleton3D=model.find_children("*","Skeleton3D",true,false)[0]
		var player:AnimationPlayer=model.find_children("*","AnimationPlayer",true,false)[0]
		check(skeleton.get_bone_count()==int(fits[fit].bones),fit+" full imported bone count")
		var triangles:=0;var influences:=0
		for instance:MeshInstance3D in model.find_children("*","MeshInstance3D",true,false):
			check(instance.skin!=null,fit+" real skin resource")
			for i in instance.mesh.get_surface_count():
				var material:Material=instance.mesh.surface_get_material(i)
				check(material is BaseMaterial3D,fit+" portable material")
				if fit=="female":check(material.albedo_texture!=null and material.albedo_texture.get_width()==1024,fit+" original packed texture imports")
				var arrays:Array=instance.mesh.surface_get_arrays(i)
				triangles+=arrays[Mesh.ARRAY_INDEX].size()/3
				var stride:int=arrays[Mesh.ARRAY_WEIGHTS].size()/arrays[Mesh.ARRAY_VERTEX].size()
				influences=maxi(influences,stride)
				check(stride==8,fit+" imports eight-weight layout")
				var weights:PackedFloat32Array=arrays[Mesh.ARRAY_WEIGHTS]
				for v in arrays[Mesh.ARRAY_VERTEX].size():
					var total:=0.0
					for n in stride:total+=weights[v*stride+n]
					check(absf(total-1.0)<.001,fit+" normalized skin vertex "+str(v))
		check(triangles==int(fits[fit].triangles),fit+" source triangle count retained")
		var clips:Array[String]=[]
		for name in player.get_animation_list():
			if name!="RESET":clips.append(name)
		check(clips.size()==1,fit+" one preserved source motion")
		var animation:=player.get_animation(clips[0]);check(absf(animation.length-260.0/60.0)<.01,fit+" source duration in seconds")
		var poses:Array=[]
		for t in [0.0,0.525,1.075,2.166667,3.241667,4.333333]:
			player.play(clips[0]);player.seek(t,true);player.advance(0);await process_frame
			var transform:=skeleton.get_bone_global_pose(0)
			check(transform.origin.is_finite() and transform.basis.is_finite(),fit+" finite animated bone at "+str(t));poses.append(transform)
		check(not poses[0].is_equal_approx(poses[3]),fit+" preserved animation actually moves imported rig")
		model.free();await process_frame
	var f:=FileAccess.open("res://godot-validation.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks":checks,"failures":failures,"godot":Engine.get_version_info().string,"renderer":RenderingServer.get_current_rendering_method(),"player_files_used":false},"\t")+"\n");f.close()
	print("KIT_GODOT: %d checks, %d failures"%[checks,failures.size()]);quit(0 if failures.is_empty() else 1)

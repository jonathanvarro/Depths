extends SceneTree
## Verify packaged static native scenes load independently of the builder script.
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var directory=""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("out="):directory=arg.substr(4)
	if directory=="":push_error("Pass out=<packaged review folder>");quit(1);return
	for identity in ["rook","branna"]:
		var packed=load(directory+"/"+identity+"-study.tscn") as PackedScene
		if packed==null:push_error("Cannot load "+identity);quit(1);return
		var instance=packed.instantiate();root.add_child(instance)
		var skeleton=instance.get_node("SharedHumanoid") as Skeleton3D
		if instance.get_script()!=null or skeleton==null or skeleton.get_bone_count()!=16:
			push_error("Invalid independent model "+identity);quit(1);return
		await process_frame
		if not skeleton.get_bone_global_pose(3).origin.is_finite():push_error("Invalid head transform");quit(1);return
		instance.queue_free();await process_frame
	print("CHARACTER3D_EXPORTS: two independent native scenes load with sixteen bones and no builder script")
	quit(0)


func jacket_checks()->void:
	root.size=Vector2i(1278,590);app.view_index=0;app.angle_index=1;await settle(5)
	for outfit in ["tunic","jacket"]:
		app.set_outfit(outfit)
		for bits in range(32):
			app.set_garments(bits)
			for actor in app.actors:
				for entry in actor.record.garments:
					var expected:bool=(bits&(1<<app.PIECES.find(str(entry.piece))))!=0 and str(entry.get("outfit","both")) in ["both",outfit]
					check(actor.meshes[str(entry.name)].visible==expected,"Exclusive outfit/coverage "+actor.fit+outfit+str(bits)+str(entry.name))
		coverage_matrix(1)
		app.set_garments(31)
		for motion in ["rest","walk","sit_down","seated","stand_up","dying"]:
			app.set_motion_fraction(motion,.5,true);app.frame_cameras();await settle()
			for actor in app.actors:visible_deformation(actor)
			for angle in [0,1,2,3]:
				app.angle_index=angle;app.frame_cameras();await capture("outfit-"+outfit+"-"+motion+"-"+str(angle))
		app.set_motion("idle",0,true);app.view_index=2
		for angle in [0,1,2,3]:
			app.angle_index=angle;app.frame_cameras();await capture("detail-"+outfit+"-"+str(angle))
		app.view_index=0
	# Switch without replacing actors, resetting playback, changing bones or
	# changing source curves. Repeat at a between-frame chair pose.
	app.set_motion("sit_down",.725,true)
	var snapshots:=[]
	for actor in app.actors:snapshots.append([actor.get_instance_id(),actor.skeleton.get_instance_id(),actor.motion_time,actor.bone_points()])
	for index in 12:
		app.set_outfit("tunic" if index%2==0 else "jacket")
		for i in 2:
			var actor=app.actors[i]
			check(actor.get_instance_id()==snapshots[i][0] and actor.skeleton.get_instance_id()==snapshots[i][1],"Swap reuses actor and skeleton")
			check(is_equal_approx(actor.motion_time,snapshots[i][2]) and actor.bone_points()==snapshots[i][3],"Swap preserves exact paused pose")
	# Use native popup input, not only direct method calls.
	await pointer(app.outfit_choice,true)
	check(app.outfit_choice.get_popup().visible,"Touch opens real outfit selector")
	var popup:PopupMenu=app.outfit_choice.get_popup()
	var point:=Vector2(popup.position)+Vector2(popup.size.x*.5,popup.size.y-18)
	for on in [true,false]:
		var event=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.position=point;event.pressed=on;event.button_mask=MOUSE_BUTTON_MASK_LEFT if on else 0;Input.parse_input_event(event);await settle(1)
	check(app.outfit=="tunic","Mouse chooses actual tunic popup entry")
	app.outfit_choice.select(0);app.set_outfit("jacket")
	app.set_motion("idle",0,true);app.angle_index=1;app.frame_cameras();await capture("jacket-summary",true)

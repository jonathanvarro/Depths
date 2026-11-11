extends SceneTree
var checks:=0
var failures: Array[String]=[]
var captures: Array[String]=[]
var bounds_by_pose:={}
var loop_seams:={}

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok:failures.append(message);push_error(message)

func settle() -> void:
	for i in 5:await process_frame

func capture(app, name: String, full:=false) -> void:
	await settle();await RenderingServer.frame_post_draw
	var image: Image=root.get_texture().get_image() if full else app.viewport.get_texture().get_image()
	check(image.save_png("res://captures/"+name+".png")==OK,"Capture "+name)
	captures.append(name+".png")

func skin_points(model: Node3D) -> PackedVector3Array:
	var points:=PackedVector3Array()
	var skeleton: Skeleton3D=model.find_child("Skeleton3D",true,false)
	if not skeleton:
		var candidates:=model.find_children("*","Skeleton3D",true,false)
		if not candidates.is_empty():skeleton=candidates[0]
	if not skeleton:return points
	skeleton.force_update_all_bone_transforms()
	for mesh: MeshInstance3D in model.find_children("*","MeshInstance3D",true,false):
		var arrays:=mesh.mesh.surface_get_arrays(0)
		var verts: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
		var bones: PackedInt32Array=arrays[Mesh.ARRAY_BONES]
		var weights: PackedFloat32Array=arrays[Mesh.ARRAY_WEIGHTS]
		var influences:=weights.size()/verts.size()
		for v in verts.size():
			var point:=Vector3.ZERO
			for k in int(influences):
				var idx:=v*int(influences)+k
				if weights[idx]<=0:continue
				var bind:=bones[idx]
				var bone:=mesh.skin.get_bind_bone(bind)
				if bone<0:bone=skeleton.find_bone(mesh.skin.get_bind_name(bind))
				point+=(skeleton.get_bone_global_pose(bone)*mesh.skin.get_bind_pose(bind)*verts[v])*weights[idx]
			points.append(skeleton.global_transform*point)
	return points

func point_bounds(points: PackedVector3Array) -> AABB:
	var box:=AABB(points[0],Vector3.ZERO)
	for p in points:box=box.expand(p)
	return box

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://captures"))
	root.size=Vector2i(1278,590)
	var app=load("res://review.tscn").instantiate();root.add_child(app);await settle()
	print("RAT_ANIMATIONS ",app.prop.player.get_animation_list())
	var rat=app.prop
	var triangles:=0
	for mesh: MeshInstance3D in rat.find_children("*","MeshInstance3D",true,false):
		triangles+=mesh.mesh.get_faces().size()/3
		check(mesh.mesh.get_surface_count()==1,"Rat uses one surface")
		check(mesh.skin!=null,"Rat is actually skinned")
	check(triangles==270,"270 triangle source budget")
	check(rat.find_children("*","Light3D",true,false).is_empty(),"No rat lights")
	check(rat.find_children("*","CollisionObject3D",true,false).is_empty(),"No rat collision")
	var skeleton: Skeleton3D=rat.find_children("*","Skeleton3D",true,false)[0]
	check(skeleton.get_bone_count()==21,"Original 21-bone rig")
	for pose in app.POSES:
		check(rat.player.has_animation(pose),"Imported clip "+pose)
		if not rat.player.has_animation(pose):continue
		var length: float=rat.player.get_animation(pose).length
		var loop_before: int=rat.player.get_animation(pose).loop_mode
		rat.player.get_animation(pose).loop_mode=Animation.LOOP_NONE
		check(length>0.3 and length<0.8,"Short clip duration "+pose)
		var first:=PackedVector3Array()
		var last:=PackedVector3Array()
		var combined:=AABB()
		var root_transform: Transform3D=rat.transform
		for i in 17:
			rat.sample(pose,length*i/16.0);await settle()
			var points:=skin_points(rat)
			check(not points.is_empty(),"Evaluated skin "+pose)
			if points.is_empty():continue
			var box:=point_bounds(points)
			combined=box if i==0 else combined.merge(box)
			check(box.size.length()<3.0 and box.position.is_finite(),"Finite metric skin "+pose)
			check(box.position.y>=-0.012,"Ground clearance "+pose+" "+str(box.position.y))
			check(box.position.x>=-1 and box.end.x<=1 and box.position.z>=-1 and box.end.z<=1,"Fits 2 m tile "+pose)
			check(rat.transform==root_transform,"Fixed floor origin "+pose)
			if i==0:first=points
			if i==16:last=points
		bounds_by_pose[pose]={"low":str(combined.position),"high":str(combined.end)}
		if pose in ["idle","walk","run"]:
			var seam:=0.0
			for i in first.size():seam=maxf(seam,first[i].distance_to(last[i]))
			loop_seams[pose]=seam
			check(seam<0.006,"Loop seam "+pose+" "+str(seam))
		rat.player.get_animation(pose).loop_mode=loop_before
		for angle in [0,1,2]:
			app.angle=angle;app.pose=pose
			for t in [0.0,0.25,0.5,0.75,1.0]:
				app.time=length*t;app.apply_state();await capture(app,"rat-%s-%d-%d" % [pose,angle,int(t*100)])
	# Freeze is immediate and samples never advance between rendered frames.
	rat.sample("idle",0);var idle_start:=skin_points(rat)
	rat.sample("hurt",0);var hurt_start:=skin_points(rat)
	var join_error:=0.0
	for i in idle_start.size():join_error=maxf(join_error,idle_start[i].distance_to(hurt_start[i]))
	check(join_error<0.006,"Hurt joins idle "+str(join_error))
	rat.sample("attack",0.29);var before:=skin_points(rat);await create_timer(0.15).timeout
	check(before==skin_points(rat),"Paused sample is exact")
	rat.set_motion(false);var frozen:=skin_points(rat);await create_timer(0.12).timeout
	check(frozen==skin_points(rat),"Effects-off is exact")
	rat.set_motion(true);rat.play("hurt");await create_timer(0.7).timeout
	check(rat.current_pose=="idle","Hurt returns to idle")
	rat.play("attack");await create_timer(0.9).timeout
	check(rat.current_pose=="idle","Attack returns to idle")
	rat.play("fall");await create_timer(0.9).timeout
	check(rat.current_pose=="fall" and not rat.player.is_playing(),"Fall stays down")
	var catalog: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(app.ART+"catalog.json"))
	for entry in catalog.assets:
		var model: Node3D=load(app.ART+entry.id+".glb").instantiate();root.add_child(model)
		var tris:=0;var actual:=AABB();var first:=true
		for mesh: MeshInstance3D in model.find_children("*","MeshInstance3D",true,false):
			tris+=mesh.mesh.get_faces().size()/3
			var box: AABB=mesh.global_transform*mesh.get_aabb();actual=box if first else actual.merge(box);first=false
			var arrays:=mesh.mesh.surface_get_arrays(0)
			check(arrays[Mesh.ARRAY_VERTEX].size()==arrays[Mesh.ARRAY_TEX_UV].size(),"Palette UV "+str(entry.id))
		var low:=Vector3(entry.min[0],entry.min[2],-entry.max[1]);var high:=Vector3(entry.max[0],entry.max[2],-entry.min[1])
		check(actual.position.distance_to(low)<0.0001 and actual.end.distance_to(high)<0.0001,"Bounds "+str(entry.id))
		check(tris==int(entry.triangles),"Budget "+str(entry.id))
		model.queue_free()
	for selected in [1,2,3]:
		app.selected=selected;app.load_prop();await settle()
		check(app.prop.find_children("*","Light3D",true,false).is_empty(),"No landmark lights")
		check(app.prop.find_children("*","CollisionObject3D",true,false).is_empty(),"No landmark collision")
		for cave in [true,false]:
			app.cave=cave
			for angle in [0,1,2,4]:
				app.angle=angle
				for state in ["closed","empty"]:
					app.state=state;app.apply_state()
					check(app.prop.get_node("Fresh").visible==(state=="closed"),"Fresh state")
					check(app.prop.get_node("Spent").visible==(state=="empty"),"Resolved state")
					check(app.prop.transform==Transform3D.IDENTITY,"Registered root")
					await capture(app,"%s-%s-%d-%s" % [app.IDS[selected],"cave" if cave else "neutral",angle,state])
		app.prop.set_searched(true);check(app.prop.state=="empty","Search API")
	for dimensions in [Vector2i(1278,590),Vector2i(852,393),Vector2i(667,375)]:
		root.size=dimensions;await settle()
		for selected in [0,1,2,3]:
			app.selected=selected;app.load_prop();app.cave=true;app.angle=3 if selected==0 else 0
			app.pose="attack";app.time=0.29;app.state="closed";app.apply_state();await settle()
			check(app.viewport.size.y>=120,"Phone viewport remains usable "+str(dimensions))
			for c: Control in app.controls:
				check(c.size.y>=44,"Touch height")
			await capture(app,"phone-%d-%s" % [dimensions.x,app.IDS[selected]],true)
	var report:={"checks":checks,"failures":failures,"captures":captures,"skin_bounds":bounds_by_pose,
		"loop_seams_metres":loop_seams,"hurt_join_metres":join_error,
		"renderer":RenderingServer.get_current_rendering_method(),"physical_iphone":false}
	FileAccess.open("res://validation.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  ")+"\n")
	print("RAT_LANDMARK_CHECKS ",checks," failures=",failures)
	quit(0 if failures.is_empty() else 1)

extends SceneTree
## Checks the imported skin rather than comparing image pixels between frames.
var checks := 0
var failures: Array[String] = []
var captures: Array[String] = []
var maximum_skin_error := 0.0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		push_error(label)

func settle() -> void:
	for frame in 3:
		await process_frame

func capture(app, name: String, full := false) -> void:
	await settle()
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image() if full else app.viewport.get_texture().get_image()
	var file := name + ".png"
	check(image.save_png("res://captures/" + file) == OK, "Capture " + name)
	captures.append(file)

func vector(items: Array) -> Vector3:
	return Vector3(items[0], items[1], items[2])

func displacement(first: PackedVector3Array, last: PackedVector3Array) -> float:
	var maximum := 0.0
	for index in first.size():
		maximum = maxf(maximum,first[index].distance_to(last[index]))
	return maximum

func verify(app, entry: Dictionary) -> void:
	var actor = app.prop
	var name: String = entry.id
	var sk: Skeleton3D = actor.find_children("*","Skeleton3D",true,false)[0]
	check(sk.get_bone_count() == int(entry.bones), "Rig count " + name)
	check(actor.find_children("*","CollisionObject3D",true,false).is_empty(), "No collision " + name)
	check(actor.find_children("*","Light3D",true,false).is_empty(), "No model-owned lights " + name)
	var triangles := 0
	var surfaces := 0
	for mesh: MeshInstance3D in actor.find_children("*","MeshInstance3D",true,false):
		triangles += mesh.mesh.get_faces().size() / 3
		surfaces += mesh.mesh.get_surface_count()
		check(mesh.skin != null, "Skin " + name + " " + str(mesh.name))
	check(triangles == int(entry.triangles) and triangles <= 4000 and surfaces <= 4, "Mesh budget " + name + " " + str(triangles))
	var idle_start := PackedVector3Array()
	for pose: String in entry.clips:
		var clip: Dictionary = entry.clips[pose]
		check(actor.player.has_animation(pose), name + " imports " + pose)
		if not actor.player.has_animation(pose):
			continue
		var animation: Animation = actor.player.get_animation(pose)
		check(absf(animation.length - float(clip.frames)/24.0) < .004, name + " clip length " + pose)
		var loop := animation.loop_mode
		animation.loop_mode = Animation.LOOP_NONE
		var first := PackedVector3Array()
		var last := PackedVector3Array()
		var motion := 0.0
		for index in clip.samples.size():
			var sample: Dictionary = clip.samples[index]
			app.angle = 0
			app.pose = pose
			app.time = float(sample.frame)/24.0
			app.apply_pose()
			var points := skin_points(actor)
			var bounds := point_bounds(points)
			var error := maxf(bounds.position.distance_to(vector(sample.low)),bounds.end.distance_to(vector(sample.high)))
			maximum_skin_error = maxf(maximum_skin_error,error)
			check(error < .05, "%s %s %d Blender/native bounds %.3f" % [name,pose,index,error])
			check(bounds.position.y >= -.014, "%s %s ground %.3f" % [name,pose,bounds.position.y])
			check(bounds.position.x >= -1.04 and bounds.end.x <= 1.04 and bounds.position.z >= -1.04 and bounds.end.z <= 1.04,
				"%s %s tile %s" % [name,pose,bounds])
			check(actor.transform == Transform3D.IDENTITY, "Fixed scene origin " + name)
			if index == 0:
				first = points
			else:
				motion = maxf(motion,displacement(first,points))
			last = points
			if pose in ["idle","attack","hurt","fall"] or pose not in ["run","walk"]:
				await capture(app,"%s-%s-%d" % [name,pose,index])
		if pose == "idle":
			idle_start = first
		if pose in ["idle","walk","run"]:
			check(displacement(first,last) < .015, "%s %s loop seam %.4f" % [name,pose,displacement(first,last)])
		check(motion > .006, "%s %s moves %.4f m" % [name,pose,motion])
		if pose == "fall":
			var start_bounds := point_bounds(first)
			var end_bounds := point_bounds(last)
			if name in ["great-rat","broodmother"]:
				# Tail and folded legs can stick up. Verify the changed resting
				# silhouette and floor contact rather than overall height alone.
				check(displacement(first,last) > .3 and end_bounds.position.y < .025,
					"Quadruped reaches a grounded fall " + name)
			else:
				check(end_bounds.end.y < start_bounds.end.y*.87, "Fall ends down " + name)
		animation.loop_mode = loop
	check(not idle_start.is_empty(),"Idle was sampled " + name)
	var tested_pose := "plant" if name == "goblin-king" else "attack"
	actor.sample(tested_pose,.27)
	var paused := skin_points(actor)
	await create_timer(.07).timeout
	check(displacement(paused,skin_points(actor)) < .00001,"Sample holds " + name)
	actor.set_motion(false)
	actor.play(tested_pose)
	var still := skin_points(actor)
	await create_timer(.07).timeout
	check(displacement(still,skin_points(actor)) < .00001,"Still holds " + name)
	if name == "goblin-king":
		check(absf(actor.player.current_animation_position - 15.0/24.0) < .001,"Planted still pose")
		actor.sample("plant",0)
		var start_staff := sk.get_bone_global_pose(sk.find_bone("staff")).origin
		var start_grip := sk.get_bone_global_pose(sk.find_bone("hand_L")).origin
		actor.sample("plant",15.0/24.0)
		sk.force_update_all_bone_transforms()
		check(start_staff.distance_to(sk.get_bone_global_pose(sk.find_bone("staff")).origin) < .001,"Planted staff anchor")
		check(start_grip.distance_to(sk.get_bone_global_pose(sk.find_bone("hand_L")).origin) < .001,"Planted hand anchor")
		var cue_frames := {"attack":18.0,"hurt":4.0,"fall":32.0}
		for cue in cue_frames:
			actor.play(cue)
			check(absf(actor.player.current_animation_position - cue_frames[cue]/24.0) < .001,"King still frame " + cue)
	for piece in ["Knife","RoleKit","Kit"]:
		var node = actor.find_child(piece,true,false)
		if node is Node3D:
			actor.set_equipment(piece,false)
			check(not node.visible,"Remove " + name + " " + piece)
			actor.set_equipment(piece,true)
			check(node.visible,"Restore " + name + " " + piece)
	for width in [1278,852,667]:
		root.size = Vector2i(width,{1278:590,852:393,667:375}[width])
		await settle()
		app.angle = 3
		app.pose = "idle"
		app.time = 0
		app.apply_pose()
		check(app.viewport.size.y >= 120,"Review viewport " + str(width))
		for control: Control in app.controls:
			check(control.size.y >= 44, "Touch control " + str(width))
		if width == 667:
			await capture(app,name + "-native-phone",true)
	root.size = Vector2i(1278,590)
	app.angle = 1
	app.apply_pose()
	await capture(app,name + "-front")
	app.angle = 4
	app.apply_pose()
	await capture(app,name + "-first-person")

func lineup(app, ids: Array, name: String, separation: float, height: float) -> void:
	if app.prop:
		app.stage.remove_child(app.prop)
		app.prop.queue_free()
		app.prop = null
	var group := Node3D.new()
	app.stage.add_child(group)
	for i in ids.size():
		var path: String = ids[i] if ids[i].begins_with("res://") else app.ART+ids[i]+".tscn"
		var item: Node3D = load(path).instantiate()
		group.add_child(item)
		item.position = Vector3((i-(ids.size()-1)*.5)*separation,0,0)
		item.set_motion(false)
	app.tiles.visible = false
	app.camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	app.camera.size = height
	app.camera.position = Vector3(.22,3.4,5.3)
	app.camera.look_at(Vector3(0,.69,0))
	await capture(app,name)
	group.queue_free()
	await settle()

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://captures"))
	root.size = Vector2i(1278,590)
	var app = load("res://review.tscn").instantiate()
	root.add_child(app)
	await settle()
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(app.ART+"catalog.json"))
	for index in catalog.assets.size():
		app.selected = index
		app.angle = 0
		app.load_prop()
		await settle()
		await verify(app,catalog.assets[index])
	await lineup(app,["fortress-goblin","fortress-guard","fortress-archer","goblin-king"],"lineup",1.38,2.26)
	var report := {"checks":checks,"failures":failures,"captures":captures,
		"maximum_native_skin_difference_metres":maximum_skin_error,
		"renderer":RenderingServer.get_current_rendering_method()}
	FileAccess.open("res://validation.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  ")+"\n")
	print("ROSTER_NATIVE ",checks," failed=",failures.size()," max_skin_error=",maximum_skin_error)
	quit(0 if failures.is_empty() else 1)

# Skin evaluation helpers reused from the checked rat pilot.
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

extends SceneTree
var checks:=0
var failures: Array[String]=[]
var captures: Array[String]=[]
var bounds_by_pose:={}
var seams:={}
func _initialize() -> void:call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks+=1
	if not ok:failures.append(label);push_error(label)
func settle() -> void:
	for i in 4:await process_frame
func capture(app,name: String,full:=false) -> void:
	await settle();await RenderingServer.frame_post_draw
	var image: Image=root.get_texture().get_image() if full else app.viewport.get_texture().get_image()
	check(image.save_png("res://captures/"+name+".png")==OK,"Capture "+name);captures.append(name+".png")
func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://captures"))
	root.size=Vector2i(1278,590)
	var app=load("res://review.tscn").instantiate();root.add_child(app);await settle()
	var catalog: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(app.ART+"catalog.json"))
	var refs: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(app.ART+"reference-poses.json"))
	for i in app.ids.size():
		app.selected=i;app.load_prop();await settle()
		for pose in app.poses:
			check(app.prop.player.has_animation(pose),"Pose "+str(app.ids[i])+" "+pose)
			for angle in [0,1,2]:
				app.angle=angle;app.pose=pose
				app.time=app.prop.player.get_animation(pose).length*(1 if pose=="fall" else .5);app.apply_pose()
				await capture(app,"%s-%s-%d" % [app.ids[i],pose,angle])
		await verify_actor(app,catalog.assets[i],refs[app.ids[i]])
	await family_capture(app)
	FileAccess.open("res://validation.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"captures":captures,"skin_bounds":bounds_by_pose,"loop_seams_metres":seams,"renderer":RenderingServer.get_current_rendering_method(),"physical_iphone":false},"  ")+"\n")
	print("CREATURE_NATIVE ",checks," failures=",failures)
	quit(0 if failures.is_empty() else 1)

func as_v3(a: Array) -> Vector3:return Vector3(a[0],a[1],a[2])
func max_error(a: PackedVector3Array,b: PackedVector3Array) -> float:
	var e:=0.0
	for i in a.size():e=maxf(e,a[i].distance_to(b[i]))
	return e
func verify_actor(app,entry: Dictionary,refs: Dictionary) -> void:
	var actor=app.prop;var id: String=entry.id
	var sk: Skeleton3D=actor.find_children("*","Skeleton3D",true,false)[0]
	check(sk.get_bone_count()==int(entry.bones),"Rig count "+id+" "+str(sk.get_bone_count()))
	check(actor.find_children("*","Light3D",true,false).is_empty(),"No world lights "+id)
	check(actor.find_children("*","CollisionObject3D",true,false).is_empty(),"No collision "+id)
	var triangles:=0
	for mesh: MeshInstance3D in actor.find_children("*","MeshInstance3D",true,false):
		triangles+=mesh.mesh.get_faces().size()/3
		check(mesh.mesh.get_surface_count()==1,"One surface per mesh "+id)
		var arrays:=mesh.mesh.surface_get_arrays(0)
		check(arrays[Mesh.ARRAY_TEX_UV].size()==arrays[Mesh.ARRAY_VERTEX].size(),"Palette UVs "+id)
	check(triangles==int(entry.triangles) and triangles<=2500,"Native triangle budget "+id+" "+str(triangles))
	for pose in refs:
		var animation: Animation=actor.player.get_animation(pose);var loop_before:=animation.loop_mode;animation.loop_mode=Animation.LOOP_NONE
		check(absf(animation.length-float(entry.clips[pose].frames[1])/24)<.001,"Clip timing "+id+" "+pose)
		var first:=PackedVector3Array();var last:=PackedVector3Array();var motion:=0.0;var bounds:=AABB()
		for sample in refs[pose]:
			actor.sample(pose,sample.seconds);await settle();sk.force_update_all_bone_transforms()
			for name in sample.bones:
				var bone:=sk.find_bone(name);check(bone>=0,"Bone label "+name)
				if bone<0:continue
				var actual: Vector3=sk.global_transform*sk.get_bone_global_pose(bone).origin
				var error:=actual.distance_to(as_v3(sample.bones[name]))
				check(error<.025,"Blender/native bone "+id+" "+pose+" "+name+" "+str(error))
			var points:=skin_points(actor);var current:=point_bounds(points)
			if first.is_empty():first=points;bounds=current
			else:motion=maxf(motion,max_error(first,points));bounds=bounds.merge(current)
			last=points
			check(current.position.distance_to(as_v3(sample.low))<.035 and current.end.distance_to(as_v3(sample.high))<.035,"Blender/native skin "+id+" "+pose)
			check(current.position.y>=-.012,"Ground "+id+" "+pose+" "+str(current.position.y))
			check(current.position.x>=-1.01 and current.end.x<=1.01 and current.position.z>=-1.01 and current.end.z<=1.01,"2m tile "+id+" "+pose+" "+str(current))
			check(actor.transform==Transform3D.IDENTITY,"Fixed outer origin")
			app.pose=pose;app.time=sample.seconds;app.angle=0;app.apply_pose()
			check(is_equal_approx(app.time,float(sample.seconds)),"Scrubber preserves time")
			await capture(app,"%s-%s-0-%d" % [id,pose,int(sample.ratio*100)])
		bounds_by_pose[id+"/"+pose]={"low":str(bounds.position),"high":str(bounds.end),"motion_metres":motion}
		if pose in ["idle","walk"]:
			var seam:=max_error(first,last);seams[id+"/"+pose]=seam;check(seam<.008,"Loop seam "+id+" "+pose+" "+str(seam))
		else:check(motion>.015,"Visible motion "+id+" "+pose+" "+str(motion))
		animation.loop_mode=loop_before
	actor.sample("attack",.29);var paused:=skin_points(actor);await create_timer(.10).timeout;check(max_error(paused,skin_points(actor))<.000001,"Exact paused skin "+id)
	actor.set_motion(false);var still:=skin_points(actor);await create_timer(.10).timeout;check(max_error(still,skin_points(actor))<.000001,"Effects-off still "+id)
	actor.set_motion(true);actor.play("hurt");await create_timer(.65).timeout;check(actor.current_pose=="idle","Hurt returns idle "+id)
	actor.play("fall");await create_timer(actor.player.get_animation("fall").length+.08).timeout;check(actor.current_pose=="fall" and not actor.player.is_playing(),"Fall stays down "+id)
	if id=="goblin":
		for piece in ["Knife","Buckler"]:
			var node: Node3D=actor.find_child(piece,true,false);check(node!=null,"Named equipment "+piece)
			actor.set_equipment(piece,false);check(not node.visible,"Remove "+piece)
			actor.set_equipment(piece,true);check(node.visible,"Restore "+piece)
	for dimensions in [Vector2i(1278,590),Vector2i(852,393),Vector2i(667,375)]:
		root.size=dimensions;await settle();app.motion=false;app.pose="idle";app.time=0
		for angle in [0,3,5,6]:
			app.angle=angle;app.apply_pose();await settle()
			check(app.viewport.size.y>=120,"Phone viewport")
			for c: Control in app.controls:check(c.size.y>=44,"44px control")
			await capture(app,"phone-%d-%s-%d" % [dimensions.x,id,angle],true)
	root.size=Vector2i(1278,590);await settle()

func family_capture(app) -> void:
	app.stage.remove_child(app.prop);app.prop.queue_free();app.prop=null
	var group:=Node3D.new();app.stage.add_child(group)
	for i in 3:
		var item: Node3D=load(app.ART+app.ids[i]+".tscn").instantiate();group.add_child(item);item.position=Vector3((i-1)*2.1,0,0);item.set_motion(false)
	app.tiles.visible=false;app.camera.projection=Camera3D.PROJECTION_ORTHOGONAL;app.camera.size=2.3;app.camera.position=Vector3(1.2,2.7,4);app.camera.look_at(Vector3(0,.25,0));await capture(app,"spider-family")
	for child in group.get_children():child.queue_free()
	await settle()
	for i in 2:
		var path: String="res://art/enemies/rat-3d-v1/scene.tscn" if i==0 else app.ART+"goblin.tscn"
		var item: Node3D=load(path).instantiate();group.add_child(item);item.position=Vector3((i-.5)*2,0,0);item.set_motion(false)
	app.camera.size=2.0;app.camera.position=Vector3(1.8,1.8,4);app.camera.look_at(Vector3(0,.55,0));await capture(app,"rat-goblin-scale")

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

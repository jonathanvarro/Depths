extends "res://tools/mine_polish/capture.gd"
## Metric geometry, real material data, registered states and live placement.
const DRESSING := preload("res://scripts/dressing.gd")
const MAP := preload("res://scripts/dungeon_map.gd")
const LEVEL := preload("res://scripts/level_builder.gd")
const LIBRARY := preload("res://art/props/loot-chests-v2/library.gd")
var checks := 0
var failures: Array[String] = []

func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures.append(label);push_error(label)

func settle() -> void:
	for i in 5:await process_frame

func stats(node: Node3D) -> Dictionary:
	var triangles:=0
	var surfaces:=0
	for mesh: MeshInstance3D in node.find_children("*","MeshInstance3D",true,false):
		if not mesh.is_visible_in_tree():continue
		for surface in mesh.mesh.get_surface_count():
			surfaces+=1
			var arrays:=mesh.mesh.surface_get_arrays(surface)
			var count: int=arrays[Mesh.ARRAY_INDEX].size() if arrays[Mesh.ARRAY_INDEX]!=null else arrays[Mesh.ARRAY_VERTEX].size()
			triangles+=count/3
			if mesh.name.begins_with("Flame"):continue
			check(arrays[Mesh.ARRAY_COLOR]!=null and arrays[Mesh.ARRAY_COLOR].size()==arrays[Mesh.ARRAY_VERTEX].size(),"vertex material colours retained")
			check(arrays[Mesh.ARRAY_TEX_UV2]!=null and arrays[Mesh.ARRAY_TEX_UV2].size()==arrays[Mesh.ARRAY_VERTEX].size(),"grain seed/end-grain data retained")
			if mesh.name.begins_with("Wood"):
				var lo:=Vector2(INF,INF);var hi:=Vector2(-INF,-INF)
				for uv: Vector2 in arrays[Mesh.ARRAY_TEX_UV]:lo=lo.min(uv);hi=hi.max(uv)
				check((hi-lo).length()>.09,"wood has physical texture coordinates rather than palette points")
		check(mesh.material_override!=null,"material fitted to each surface family")
	return {"triangles":triangles,"surfaces":surfaces}

func run() -> void:
	root.size=Vector2i(1280,720)
	for id in ["support","support-damaged","lantern-standing","lantern-hanging","miners-shrine","old-workings","rails","rails-broken"]:
		show_asset(MINE+id+".tscn")
		check(subject.find_children("*","Light3D",true,false).is_empty(),id+" adds no world lighting")
		check(subject.find_children("*","CollisionObject3D",true,false).is_empty(),id+" adds no collision")
		var report:=stats(subject)
		check(report.triangles<5000,id+" stays under 5000 triangles")
		check(report.surfaces<=8,id+" has a bounded material count")
		var box:=bounds(subject)
		check(box.size.x<2.2 and box.size.y<2.43,id+" fits the original mine envelope")
		if id.begins_with("support"):
			# Cast the intended walking rectangle through actual mesh triangles.
			var hits:=0
			for x in [-.76,0.0,.76]:
				for y in [.10,1.20,1.80]:
					for mesh: MeshInstance3D in subject.find_children("*","MeshInstance3D",true,false):
						for surface in mesh.mesh.get_surface_count():
							var arrays:=mesh.mesh.surface_get_arrays(surface)
							for index in range(0,arrays[Mesh.ARRAY_INDEX].size(),3):
								var points:=PackedVector3Array()
								for j in 3:points.append(mesh.global_transform*arrays[Mesh.ARRAY_VERTEX][arrays[Mesh.ARRAY_INDEX][index+j]])
								if Geometry3D.segment_intersects_triangle(Vector3(x,y,-.45),Vector3(x,y,.45),points[0],points[1],points[2])!=null:hits+=1
			check(hits==0,"support keeps the central walking/eye rectangle clear")
		if id=="miners-shrine" or id=="old-workings":
			var base: Transform3D=subject.get_node("Base").transform if id=="miners-shrine" else subject.get_node("Fresh").transform
			subject.state="empty"
			check(not subject.get_node("Fresh").visible and subject.get_node("Spent").visible,id+" swaps fresh/spent")
			if id=="miners-shrine":check(subject.get_node("Base").transform==base,"shrine base is fixed across states")
			subject.state="closed"
			check(subject.get_node("Fresh").visible and not subject.get_node("Spent").visible,id+" restores immediately")
		if id.begins_with("lantern"):
			subject.lit=false
			check(not subject._glass.emission_enabled and not subject.is_processing(),"extinguished lantern stops emission and processing")
			subject.lit=true;subject.set_motion(false)
			check(subject._glass.emission_enabled and not subject.is_processing(),"lantern still mode keeps constant glow")
		await snap(id+"-checked")
	# Tiers are distinct model pairs, not a common model with a colour override.
	var paths:=[]
	for tier: String in LIBRARY.SCENES:
		show_asset(LIBRARY.SCENES[tier])
		check(subject.get_meta("chest_type")==tier,"tier label matches scene")
		var compatible: Node3D=load("res://art/props/chests-v1/"+tier+".tscn").instantiate()
		check(compatible.get_meta("chest_type")==tier and compatible.has_method("set_state"),"tier dispatcher compatibility scene")
		compatible.free()
		paths.append(subject.get_node("Base").scene_file_path)
		var report:=stats(subject)
		check(report.triangles<4000,tier+" closed chest budget")
		check(report.surfaces<=8,tier+" material surface budget")
		var base_transform: Transform3D=subject.get_node("Base").transform
		var hinge: Vector3=subject.get_node("LidPivot").position
		for state in ["open","empty","closed"]:
			subject.state=state
			check(subject.get_node("Base").transform==base_transform and subject.get_node("LidPivot").position==hinge,"state keeps the hinge and base registered")
			check(subject.get_node("Contents").visible==(state=="open"),"only open shows decorative contents")
			check(is_equal_approx(subject.get_node("LidPivot").rotation.x,0.0 if state=="closed" else deg_to_rad(-102)),"still mode applies the exact lid angle")
			var box:=bounds(subject)
			check(box.position.y>=-.01 and box.end.y<1.6,"closed and open chest stay in the floor envelope")
		# Stop/reverse an active lid tween, then choose exact still presentation.
		subject.set_motion(true);subject.state="open"
		await create_timer(.10).timeout
		var angle: float=subject.get_node("LidPivot").rotation.x
		check(angle<0 and angle>deg_to_rad(-102),"lid moves from its hinge")
		subject.state="closed"
		check(is_equal_approx(subject.get_node("LidPivot").rotation.x,angle),"interrupting a lid does not snap it")
		subject.state="empty";subject.set_motion(false)
		check(is_equal_approx(subject.get_node("LidPivot").rotation.x,deg_to_rad(-102)),"disabling motion finishes the latest state")
		check(not subject.get_node("Contents").visible,"empty remains empty after interruption")
		subject.state="open"
		await snap("chest-"+tier+"-checked-open")
	check(paths[0]!=paths[1] and paths[1]!=paths[2],"tiers use different authored meshes")
	check(LIBRARY.scene("unknown")==null,"art lookup does not invent rarity assignment")
	# Actual dresser and event resources, with no changes to their choices/rewards.
	for id in ["mine-support","mine-support-damaged","mine-rails","mine-rails-broken","lantern-standing","lantern-hanging"]:
		check(DRESSING.MODELS[id].begins_with(MINE),"live "+id+" uses refined art")
	for id in ["chest_old_workings","object_miners_shrine"]:
		var event=load("res://data/events/"+id+".tres")
		check(event.prop.resource_path.begins_with(MINE),"live event binds refined mine art")
	# A real dressed opening: model mounts, first-person eye and phone frame.
	setup(false)
	var map=MAP.new(PackedStringArray(["#######","#,,,,,#","#,,,,,#","###.###","###.###","###S###","#######"]))
	var level=LEVEL.new();stage.add_child(level);level.build(map,load("res://themes/cave.tres"),2.0,2.4)
	DRESSING.dress_opening(level,map,48,2.0,2.4)
	check(level.get_node_or_null("Dressing")!=null,"real opening dressing builds")
	var prop: Node3D=load(MINE+"support-damaged.tscn").instantiate();prop.position=Vector3(6,0,6);level.add_child(prop)
	camera.position=Vector3(6,1.2,8);camera.look_at(Vector3(6,1.2,6));camera.fov=70
	lamp.position=camera.position+Vector3(.3,-.2,0)
	await snap("mine-corridor-desktop")
	for size in [Vector2i(844,390),Vector2i(667,375)]:
		root.size=size
		await snap("mine-corridor-phone-"+str(size.x))
	for tier in ["common","silver","gold"]:
		show_asset(CHESTS+tier+".tscn","open",false)
		await snap("chest-"+tier+"-phone")
	stage.free()
	FileAccess.open(output.path_join("validation.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"physical_iPhone":false},"\t"))
	print("MINE_POLISH checks=",checks," failures=",failures.size())
	quit(0 if failures.is_empty() else 1)

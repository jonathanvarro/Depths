extends SceneTree
var checks := 0
var failures: Array[String] = []
var captures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok:
		failures.append(message)
		push_error(message)

func settle() -> void:
	for frame in 4: await process_frame

func capture(app, name: String, full := false) -> void:
	await settle()
	await RenderingServer.frame_post_draw
	var image: Image=root.get_texture().get_image() if full else app.viewport.get_texture().get_image()
	check(image.save_png("res://captures/"+name)==OK,"Capture "+name)
	captures.append(name)

func bounds(node: Node3D, visible_only := false) -> AABB:
	var result:=AABB()
	var first:=true
	for item: MeshInstance3D in node.find_children("*","MeshInstance3D",true,false):
		if visible_only and not item.is_visible_in_tree(): continue
		var piece: AABB=(node.global_transform.affine_inverse()*item.global_transform)*item.get_aabb()
		result=piece if first else result.merge(piece)
		first=false
	return result

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://captures"))
	root.size=Vector2i(1278,590)
	var app=load("res://review.tscn").instantiate()
	root.add_child(app)
	await settle()
	for entry in app.catalog.assets:
		var model: Node3D=load(app.ART+entry.id+".glb").instantiate()
		app.stage.add_child(model)
		var actual:=bounds(model)
		var low:=Vector3(entry.min[0],entry.min[2],-entry.max[1])
		var high:=Vector3(entry.max[0],entry.max[2],-entry.min[1])
		check(actual.position.distance_to(low)<.0001 and actual.end.distance_to(high)<.0001,"Actual metric mesh "+entry.id)
		var triangles:=0
		for item: MeshInstance3D in model.find_children("*","MeshInstance3D",true,false):
			check(item.mesh.get_surface_count()==1,"One surface "+entry.id)
			var arrays: Array=item.mesh.surface_get_arrays(0)
			triangles+=arrays[Mesh.ARRAY_INDEX].size()/3
			check(arrays[Mesh.ARRAY_TEX_UV].size()==arrays[Mesh.ARRAY_VERTEX].size(),"Palette UVs "+entry.id)
			var material: Material=item.mesh.surface_get_material(0)
			check(material==null or (material is StandardMaterial3D and material.albedo_texture==null),"No embedded source texture "+entry.id)
			if entry.id in ["sluice-frame","flow-frame"]:
				var colour_index: int=app.catalog.palette.keys().find("blackwater")
				# glTF flips Blender's vertical texture coordinate on export.
				var uv:=Vector2((colour_index%8+.5)/8,1.0-(floorf(colour_index/8.0)+.5)/4)
				var found:=false
				var in_front:=true
				for i in arrays[Mesh.ARRAY_VERTEX].size():
					if arrays[Mesh.ARRAY_TEX_UV][i].distance_to(uv)<.001:
						found=true
						in_front=in_front and arrays[Mesh.ARRAY_VERTEX][i].z>.04
				check(found and in_front,"Opaque outflow conceals wall "+entry.id)
		check(triangles==int(entry.triangles) and triangles<=4000,"Mesh triangle budget "+entry.id)
		model.free()
	for index in app.catalog.recipes.size():
		var entry: Dictionary=app.catalog.recipes[index]
		app.selected=index
		app.state="closed"
		app.motion=false
		app.load_prop()
		await settle()
		check(not app.prop.is_processing(),"No idle processing "+entry.id)
		check(app.prop.find_children("*","CollisionObject3D",true,false).is_empty(),"No new collision")
		check(app.prop.find_children("*","Light3D",true,false).is_empty(),"No new lights")
		var fixed: Transform3D=app.prop.transform
		var envelope:=AABB(Vector3(entry.bounds_min[0],entry.bounds_min[1],entry.bounds_min[2]),
			Vector3(entry.bounds_max[0]-entry.bounds_min[0],entry.bounds_max[1]-entry.bounds_min[1],entry.bounds_max[2]-entry.bounds_min[2]))
		check(envelope.size.x<=2,"Fits one wall/cell width "+entry.id)
		check(int(entry.triangles)<=4500,"Scene budget "+entry.id)
		if entry.mount=="ceiling":
			check(absf(envelope.end.y)<.04,"Registered roof mount "+entry.id)
			if entry.id=="overhead-walkway": check(2.4+envelope.position.y>=1.85,"Walkway head clearance")
			else: check(2.4+envelope.position.y>=1.25,"Cage in side alcove")
		elif entry.mount in ["floor","floor-wall"]:
			check(envelope.position.y>=-.065 and envelope.position.y<=.025,"Registered floor "+entry.id)
			check(envelope.end.y<=2.34,"Below ceiling in raised state "+entry.id)
		else: check(envelope.position.z>=-.075 and envelope.end.z<=.44,"Wall projection "+entry.id)
		var states: Array=["closed","empty"] if entry.id=="palisade" else (["closed","open","empty"] if entry.has("lift") else ["closed"])
		for state in states:
			app.state=state
			app.apply_state()
			var actual:=bounds(app.prop,true)
			check(envelope.grow(.025).encloses(actual),"Visible mesh inside fixed review envelope "+entry.id+" "+state)
			check(app.prop.transform==fixed,"Registered root across states "+entry.id)
			for item: MeshInstance3D in app.prop.find_children("*","MeshInstance3D",true,false):
				check(item.material_override!=null and item.cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,"Rough palette and economical shadow "+entry.id)
			if entry.id=="palisade": check(app.prop.get_node("Spent").visible==(state=="empty"),"Broken/intact visibility")
			for cave in [true,false]:
				app.cave=cave
				for angle in 3:
					app.angle=angle
					app.frame_prop()
					await capture(app,"%s-%s-%d-%s.png" % [entry.id,"cave" if cave else "neutral",angle,state])
		if entry.has("lift"):
			var frame: Node3D=app.prop.get_node("Frame")
			var frame_fixed:=frame.transform
			var lift: Node3D=app.prop.get_node("Lift")
			check(is_equal_approx(lift.position.y,float(entry.lift_origin[1])+float(entry.lift)),"Fully raised shutter")
			app.prop.set_state("closed")
			check(is_equal_approx(lift.position.y,float(entry.lift_origin[1])),"Lowered shutter")
			app.prop.set_motion(true)
			app.prop.set_state("open")
			await create_timer(.18).timeout
			check(app.prop._progress>0 and app.prop._progress<1,"Real intermediate motion")
			var before: float=app.prop._progress
			app.prop.set_motion(true)
			check(is_equal_approx(app.prop._progress,before),"Reapplying effects preference preserves current pose")
			app.prop.set_state("closed")
			await create_timer(.08).timeout
			app.prop.set_state("empty")
			await create_timer(.75).timeout
			check(is_equal_approx(app.prop._progress,1),"Latest interrupted request wins")
			app.prop.set_state("closed")
			await create_timer(.08).timeout
			app.prop.set_motion(false)
			check(is_zero_approx(app.prop._progress),"Still mode finishes requested state immediately")
			await settle()
			check(is_zero_approx(app.prop._progress) and frame.transform==frame_fixed,"Exact still pose and fixed frame")
			app.cave=true
			app.angle=0
			app.frame_prop()
			for phase in [.25,.5,.75]:
				app.prop.set_display_phase(phase)
				check(is_equal_approx(lift.position.y,float(entry.lift_origin[1])+float(entry.lift)*phase),"Paused lift registration")
				await capture(app,"%s-phase-%d.png" % [entry.id,roundi(phase*100)])
			var restored: Node3D=load(app.ART+entry.id+".tscn").instantiate()
			restored.state="empty"
			app.stage.add_child(restored)
			check(is_equal_approx(restored._progress,1),"Restore applies before ready without animated replay")
			restored.free()
	for selected in [1,6]:
		app.selected=selected
		app.state="closed"
		app.cave=true
		app.angle=0
		app.motion=false
		app.load_prop()
		for size in [Vector2i(1278,590),Vector2i(852,393),Vector2i(667,375)]:
			root.size=size
			await settle()
			app.frame_prop()
			for control: Control in app.controls:
				var rect:=control.get_global_rect()
				check(rect.size.y>=44 and rect.end.x<=size.x-43,"Safe 44px controls "+str(size))
			check(app.viewport.size.y>=190,"Phone review display height")
			await capture(app,"screen-%d-%d.png" % [selected,size.x],true)
	root.size=Vector2i(1278,590)
	await settle()
	for side in [-1,1]:
		var wall:=MeshInstance3D.new()
		var box:=BoxMesh.new()
		box.size=Vector3(.02,2.4,6)
		wall.mesh=box
		wall.position=Vector3(side*2.01,1.2,0)
		app.stage.add_child(wall)
	var batches: Array=[
		[["throne",Vector3(0,0,-2.55),0.0],["watch-post",Vector3(-1.25,0,-.80),0.0],
		 ["palisade",Vector3(-1.0,0,-2.72),0.0],["overhead-walkway",Vector3(0,2.4,-.55),0.0],
		 ["hanging-cage",Vector3(1.40,2.4,-.85),0.0],["hanging-bracket",Vector3(1.98,1.70,-1.8),-PI/2]],
		[["sluice",Vector3(-.97,0,-2.72),0.0],["flow-gate",Vector3(.98,0,-2.72),0.0],
		 ["broken-pipe",Vector3(-1.98,1.1,-.85),PI/2],["wall-gutter",Vector3(1.98,1.35,-.80),-PI/2]],
	]
	for batch in batches.size():
		app.selected=0 if batch==0 else 6
		app.cave=true
		app.frame_prop()
		app.stage.remove_child(app.prop)
		app.prop.queue_free()
		app.wall.visible=true
		app.wall.position.z=-2.77
		app.wall.material_override=app.surface("wall")
		app.ceiling.visible=true
		app.ceiling.position.z=0
		(app.ceiling.mesh as PlaneMesh).size=Vector2(4,6)
		app.ceiling.material_override=app.surface("ceiling")
		app.floor_mesh.material_override=app.surface("floor")
		for node in app.stage.get_children():
			if node is MeshInstance3D and node not in [app.wall,app.ceiling,app.floor_mesh]: node.material_override=app.surface("wall")
		var group:=Node3D.new()
		app.stage.add_child(group)
		app.prop=group
		for entry in batches[batch]:
			var item=load(app.ART+entry[0]+".tscn").instantiate()
			item.animate_motion=false
			item.position=entry[1]
			item.rotation.y=entry[2]
			group.add_child(item)
		app.camera.projection=Camera3D.PROJECTION_PERSPECTIVE
		app.camera.fov=68
		app.camera.position=Vector3(0,1.55,2.9)
		app.camera.look_at(Vector3(0,1.15,-1.3))
		for state in ["closed","empty"]:
			for item in group.get_children(): item.set_state(state)
			await capture(app,"room-%d-%s.png" % [batch,state])
	var report:={"checks":checks,"failures":failures,"captures":captures,
		"renderer":RenderingServer.get_current_rendering_method(),"physical_iphone":false,
		"catalog_sha256":FileAccess.get_sha256(app.ART+"catalog.json")}
	var file:=FileAccess.open("res://validation.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"  ")+"\n")
	print("FORTRESS_WATERWORKS_CHECKS ",checks," failures=",failures.size())
	quit(0 if failures.is_empty() else 1)

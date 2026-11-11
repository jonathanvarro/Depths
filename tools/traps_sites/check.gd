extends SceneTree
var checks := 0
var failures: Array[String] = []
var captures: Array[String] = []

class WallMap:
	extends RefCounted
	func is_wall(cell: Vector2i) -> bool: return cell.y==-1

func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok:
		failures.append(message)
		push_error(message)
func settle() -> void:
	for i in 4: await process_frame
func capture(app,name: String,full := false) -> Image:
	await settle()
	await RenderingServer.frame_post_draw
	var image: Image=root.get_texture().get_image() if full else app.viewport.get_texture().get_image()
	check(image.save_png("res://captures/"+name)==OK,"Capture "+name)
	captures.append(name)
	return image
func bounds(node: Node3D) -> AABB:
	var result:=AABB()
	var first:=true
	for item: MeshInstance3D in node.find_children("*","MeshInstance3D",true,false):
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
		check(actual.position.distance_to(low)<.0001 and actual.end.distance_to(high)<.0001,"Metric imported mesh "+entry.id)
		var triangles:=0
		for item: MeshInstance3D in model.find_children("*","MeshInstance3D",true,false):
			check(item.mesh.get_surface_count()==1,"One surface per component")
			var arrays: Array=item.mesh.surface_get_arrays(0)
			triangles+=arrays[Mesh.ARRAY_INDEX].size()/3
			check(arrays[Mesh.ARRAY_TEX_UV].size()==arrays[Mesh.ARRAY_VERTEX].size(),"Palette UVs")
		check(triangles==int(entry.triangles) and triangles<=1400,"Modest mesh budget "+entry.id)
		model.free()
	for index in app.catalog.recipes.size():
		app.selected=index
		app.motion=false
		app.mist_enabled=false
		app.state="closed"
		app.load_prop()
		await settle()
		var entry: Dictionary=app.catalog.recipes[index]
		var fixed: Transform3D=app.prop.transform
		check(not app.prop.is_processing(),"Static ready state "+entry.id)
		check(app.prop.find_children("*","CollisionObject3D",true,false).is_empty(),"No hazard collision")
		check(app.prop.find_children("*","Light3D",true,false).is_empty(),"No new light")
		check(float(entry.bounds_max[0])-float(entry.bounds_min[0])<=2.0,"Cell width "+entry.id)
		check(float(entry.bounds_min[1])>=-.06,"Floor contact "+entry.id)
		for state in ["closed","open","empty"]:
			app.state=state
			app.apply_state()
			var visible_count:=0
			for label in ["Fresh","Open","Spent"]:
				var node: Node3D=app.prop.get_node_or_null(label)
				if node!=null and node.visible: visible_count+=1
			check(visible_count==1,"Exactly one state visible "+entry.id+" "+state)
			check(app.prop.transform==fixed,"Registered root "+entry.id)
			for cave in [true,false]:
				app.cave=cave
				for angle in 3:
					app.angle=angle
					app.frame_prop()
					await capture(app,"%s-%s-%d-%s.png" % [entry.id,"cave" if cave else "neutral",angle,state])
		if entry.id=="dart-plate":
			app.prop.mount_in_cell(WallMap.new(),Vector2i.ZERO,2.0)
			check(app.prop.get_node("Ports").visible and app.prop.get_node("Ports").position.is_equal_approx(Vector3(0,.48,-.985)),"Dart ports use real wall anchor")
		if entry.id=="still-pool":
			app.prop.set_motion(true)
			var phase: float=app.prop._phase
			await create_timer(.08).timeout
			check(app.prop._phase>phase,"Disturbed pool moves gently")
			app.prop.set_motion(false)
			phase=app.prop._phase
			await settle()
			check(app.prop._phase==phase and not app.prop.is_processing(),"Pool exact still mode")
		var restored: Node3D=load(app.ART+entry.id+".tscn").instantiate()
		restored.state="empty"
		restored.animate_motion=false
		app.stage.add_child(restored)
		check(restored.get_node("Spent").visible and not restored.get_node("Fresh").visible,"Resolved restore before ready "+entry.id)
		restored.free()
	for index in [2,5]:
		app.selected=index
		app.state="closed"
		app.cave=true
		app.angle=0
		app.load_prop()
		for size in [Vector2i(1278,590),Vector2i(852,393),Vector2i(667,375)]:
			root.size=size
			await settle()
			app.frame_prop()
			for control: Control in app.controls:
				var rect:=control.get_global_rect()
				check(rect.size.y>=44 and rect.end.x<=size.x-43,"Safe 44px controls "+str(size))
			check(app.viewport.size.y>=190,"Phone view height")
			await capture(app,"screen-%d-%d.png" % [index,size.x],true)
	root.size=Vector2i(1278,590)
	await settle()
	app.wall.visible=true
	app.wall.position.z=-2.8
	app.ceiling.visible=true
	(app.ceiling.mesh as PlaneMesh).size=Vector2(4,6)
	for side in [-1,1]:
		var wall:=MeshInstance3D.new()
		var box:=BoxMesh.new()
		box.size=Vector3(.02,2.4,6)
		wall.mesh=box
		wall.position=Vector3(side*2.01,1.2,0)
		wall.material_override=app.surface("wall")
		app.stage.add_child(wall)
	var batches: Array=[
		[["tripwire",Vector3(0,0,-.9)],["bell-alarm",Vector3(-1.20,0,-2.1)],
		 ["snare",Vector3(1.2,0,-.45)],["dart-plate",Vector3(.9,0,-2.2)]],
		[["idol-niche",Vector3(-.95,0,-2.74)],["still-pool",Vector3(.9,0,-1.0)],["hollow-floor",Vector3(-.8,0,-.25)]],
	]
	for batch in batches.size():
		app.stage.remove_child(app.prop)
		app.prop.queue_free()
		var group:=Node3D.new()
		app.stage.add_child(group)
		app.prop=group
		for entry in batches[batch]:
			var item=load(app.ART+entry[0]+".tscn").instantiate()
			item.animate_motion=false
			item.position=entry[1]
			group.add_child(item)
			if entry[0]=="dart-plate":
				item.get_node("Ports").position=Vector3(0,.48,-.55)
				item.get_node("Ports").show()
		app.camera.projection=Camera3D.PROJECTION_PERSPECTIVE
		app.camera.fov=68
		app.camera.position=Vector3(0,1.55,2.2)
		app.camera.look_at(Vector3(0,.62,-1.1))
		app.key.light_energy=1.5
		app.environment.ambient_light_energy=.30
		app.mist.set_motion(false)
		app.mist.visible=false
		await capture(app,"room-%d-clear.png" % batch)
		for item in group.get_children(): item.set_state("empty")
		await capture(app,"room-%d-resolved.png" % batch)
		for item in group.get_children(): item.set_state("closed")
		app.mist.visible=true
		app.mist.set_light_strength(1.0)
		app.mist.set_display_phase(0)
		var still: Image=await capture(app,"room-%d-mist.png" % batch)
		await create_timer(.10).timeout
		await RenderingServer.frame_post_draw
		check(still.get_data()==app.viewport.get_texture().get_image().get_data(),"Pixel-exact frozen mist")
		app.mist.set_display_phase(12)
		var moved: Image=await capture(app,"room-%d-drift.png" % batch)
		check(still.get_data()!=moved.get_data(),"Actual mist phase changes rendered pixels")
		if batch==0:
			for i in 12:
				app.mist.set_display_phase(i*.6)
				await capture(app,"mist-motion-%02d.png" % i)
			app.mist.set_display_phase(12)
		app.mist.set_light_strength(.25)
		app.key.light_energy=.375
		app.environment.ambient_light_energy=.075
		await capture(app,"room-%d-low-light.png" % batch)
	check(app.mist.get_child_count()==3,"Three inexpensive fog layers")
	for layer: MeshInstance3D in app.mist.get_children():
		check(layer.mesh is PlaneMesh and layer.position.y<=.50,"Low ground sheet")
		check(layer.cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,"No fog shadow")
	app.mist.set_motion(true)
	var phase: float=app.mist._phase
	await create_timer(.08).timeout
	check(app.mist._phase>phase,"Mist motion control")
	app.mist.visible=false
	check(not app.mist.is_processing(),"Hidden fog stops processing")
	app.mist.set_centre(Vector3(2,8,4))
	check(app.mist.global_position==Vector3(2,0,4),"Ground registration ignores camera height")
	var report:={"checks":checks,"failures":failures,"captures":captures,
		"renderer":RenderingServer.get_current_rendering_method(),"physical_iphone":false,
		"catalog_sha256":FileAccess.get_sha256(app.ART+"catalog.json")}
	report["runtime_sha256"]={}
	for path in [app.ART+"prop.gd",app.ART+"pool.gdshader","res://art/effects/exploration-mist-v1/mist.gd","res://art/effects/exploration-mist-v1/mist.gdshader"]:
		report.runtime_sha256[path]=FileAccess.get_sha256(path)
	var file:=FileAccess.open("res://validation.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"  ")+"\n")
	print("TRAPS_SITES_CHECKS ",checks," failures=",failures.size())
	quit(0 if failures.is_empty() else 1)

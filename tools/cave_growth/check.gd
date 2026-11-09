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

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://captures"))
	root.size=Vector2i(1278,590)
	var app=load("res://review.tscn").instantiate()
	root.add_child(app)
	await settle()
	for index in app.catalog.assets.size():
		var entry: Dictionary=app.catalog.assets[index]
		app.selected=index
		app.glow=false
		app.motion=false
		app.load_prop()
		await settle()
		check(not app.prop.is_processing(),"Static default "+entry.id)
		check(not app.prop._caps.emission_enabled,"No default emission "+entry.id)
		check(app.prop.find_children("*","CollisionObject3D",true,false).is_empty(),"Decor has no collision")
		check(app.prop.find_children("*","Light3D",true,false).is_empty(),"Decor has no world light")
		check(app.prop.find_children("*","AnimationPlayer",true,false).is_empty(),"Static geometry")
		var bounds:=AABB()
		var first:=true
		var triangles:=0
		for mesh: MeshInstance3D in app.prop.find_children("*","MeshInstance3D",true,false):
			var piece: AABB=(app.prop.global_transform.affine_inverse()*mesh.global_transform)*mesh.get_aabb()
			bounds=piece if first else bounds.merge(piece)
			first=false
			check(mesh.mesh.get_surface_count()==1,"One surface per component")
			var arrays: Array=mesh.mesh.surface_get_arrays(0)
			triangles+=arrays[Mesh.ARRAY_INDEX].size()/3
			check(arrays[Mesh.ARRAY_TEX_UV].size()==arrays[Mesh.ARRAY_VERTEX].size(),"Palette UVs retained")
		var low:=Vector3(entry.min[0],entry.min[2],-entry.max[1])
		var high:=Vector3(entry.max[0],entry.max[2],-entry.min[1])
		check(bounds.position.distance_to(low)<.0001 and bounds.end.distance_to(high)<.0001,"Metric envelope "+entry.id)
		var budget:=1000 if entry.id.ends_with("roots") else 600
		check(triangles==int(entry.triangles) and triangles<=budget,"Conservative triangle count "+entry.id)
		if entry.mount=="floor":
			check(bounds.position.y>=-.04 and bounds.position.y<=.025,"Seated floor mount "+entry.id)
		elif entry.mount=="ceiling":
			check(absf(bounds.end.y)<=.04,"Registered ceiling root "+entry.id)
			check(2.4+bounds.position.y>=1.65,"Roof growth leaves headroom "+entry.id)
		else:
			check(bounds.position.z>=-.075 and bounds.end.z<=.25,"Shallow wall envelope "+entry.id)
		for cave in [true,false]:
			app.cave=cave
			for angle in 3:
				app.angle=angle
				var glows: Array=[false,true] if entry.optional_glow else [false]
				for glow in glows:
					app.glow=glow
					app.apply_effects()
					var name: String="%s-%s-%d-%s.png" % [entry.id,"cave" if cave else "neutral",angle,"glow" if glow else "plain"]
					await capture(app,name)
		app.glow=true
		app.motion=true
		app.apply_effects()
		check(app.prop.is_processing()==bool(entry.optional_glow),"Glow motion only for fungal caps")
		if entry.optional_glow:
			var energy: float=app.prop._caps.emission_energy_multiplier
			await create_timer(.08).timeout
			check(app.prop._caps.emission_energy_multiplier!=energy,"Slow cap pulse")
		app.prop.set_motion(false)
		var fixed: float=app.prop._caps.emission_energy_multiplier
		await settle()
		check(not app.prop.is_processing() and app.prop._caps.emission_energy_multiplier==fixed,"Exact still mode")
	app.selected=11
	app.glow=false
	app.motion=false
	app.cave=true
	app.angle=0
	app.load_prop()
	for size in [Vector2i(1278,590),Vector2i(852,393),Vector2i(667,375)]:
		root.size=size
		await settle()
		app.frame_prop()
		for control: Control in app.controls:
			var rect:=control.get_global_rect()
			check(rect.size.y>=44 and rect.end.x<=size.x-43,"Safe controls "+str(size))
		check(app.viewport.size.y>=190,"Phone display height")
		await capture(app,"screen-%d.png" % size.x,true)
	root.size=Vector2i(1278,590)
	await settle()
	app.wall.visible=true
	app.wall.position.z=-2.9
	app.ceiling.visible=true
	app.ceiling.position.z=0
	(app.ceiling.mesh as PlaneMesh).size=Vector2(2,6)
	for side in [-1,1]:
		var wall:=MeshInstance3D.new()
		var box:=BoxMesh.new()
		box.size=Vector3(.02,2.4,6)
		wall.mesh=box
		wall.position=Vector3(side*1.01,1.2,0)
		wall.material_override=app.surface("wall")
		app.stage.add_child(wall)
	var batches: Array=[
		[["stalagmite-tall",Vector3(-.77,0,-.2),0.0],["stalagmite-stub",Vector3(.77,0,-.5),0.0],
		 ["stalagmite-broken",Vector3(.76,0,-1.7),0.0],["stalagmite-cluster",Vector3(-.70,0,-1.6),0.0],
		 ["stalactite-single",Vector3(-.65,2.4,-.1),0.0],["stalactite-cluster",Vector3(.65,2.4,-1.5),0.0],
		 ["flowstone-wall",Vector3(0,1.2,-2.88),0.0],["rubble-cluster",Vector3(.6,0,.65),0.0]],
		[["wall-roots",Vector3(-.99,1.2,-.4),PI/2],["hanging-roots",Vector3(.68,2.4,-.4),0.0],
		 ["floor-roots",Vector3(-.4,0,-1.5),0.0],["mushroom-clump",Vector3(.65,0,-.4),0.0],
		 ["shelf-fungus",Vector3(.99,.9,-1.6),-PI/2],["fungal-mat",Vector3(-.6,0,.75),0.0]],
	]
	for batch in batches.size():
		app.stage.remove_child(app.prop)
		app.prop.queue_free()
		var group:=Node3D.new()
		app.stage.add_child(group)
		app.prop=group
		for entry in batches[batch]:
			var item=load(app.ART+entry[0]+".tscn").instantiate()
			item.glow_enabled=false
			item.animate_motion=false
			item.position=entry[1]
			item.rotation.y=entry[2]
			group.add_child(item)
		for x in [-.2,0.0,.2]:
			var clear:=true
			for mesh: MeshInstance3D in group.find_children("*","MeshInstance3D",true,false):
				var arrays: Array=mesh.mesh.surface_get_arrays(0)
				for i in range(0,arrays[Mesh.ARRAY_INDEX].size(),3):
					var vertices:=[]
					for j in 3: vertices.append(mesh.global_transform*arrays[Mesh.ARRAY_VERTEX][arrays[Mesh.ARRAY_INDEX][i+j]])
					if Geometry3D.segment_intersects_triangle(Vector3(x,1.55,2.2),Vector3(x,1.55,-2.1),vertices[0],vertices[1],vertices[2])!=null: clear=false
			check(clear,"Mounted room leaves the centre sightline clear")
		app.camera.projection=Camera3D.PROJECTION_PERSPECTIVE
		app.camera.fov=68
		app.camera.position=Vector3(0,1.55,2.2)
		app.camera.look_at(Vector3(0,1.43,-1))
		await capture(app,"room-%d.png" % batch)
	var report:={"checks":checks,"failures":failures,"captures":captures,
		"renderer":RenderingServer.get_current_rendering_method(),"physical_iphone":false,
		"catalog_sha256":FileAccess.get_sha256(app.ART+"catalog.json")}
	var file:=FileAccess.open("res://validation.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"  ")+"\n")
	print("GROWTH_CHECKS ",checks," failures=",failures.size())
	quit(0 if failures.is_empty() else 1)

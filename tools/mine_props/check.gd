extends SceneTree
var checks := 0
var failures: Array[String] = []
var captures: Array[String] = []
var scene_triangles := {}

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func settle() -> void:
	for frame in 4: await process_frame

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://captures"))
	root.size = Vector2i(1278,590)
	var app = load("res://review.tscn").instantiate()
	root.add_child(app)
	await settle()
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(app.ART+"catalog.json"))
	for entry in catalog.assets:
		var node: Node3D = load(app.ART+entry.id+".glb").instantiate()
		root.add_child(node)
		var triangles := 0
		var bounds := AABB()
		var first := true
		for mesh: MeshInstance3D in node.find_children("*","MeshInstance3D",true,false):
			var piece := mesh.transform*mesh.get_aabb()
			bounds = piece if first else bounds.merge(piece)
			first = false
			check(mesh.mesh.get_surface_count() == 1, "One surface per mesh")
			var arrays: Array = mesh.mesh.surface_get_arrays(0)
			triangles += arrays[Mesh.ARRAY_INDEX].size()/3
			check(arrays[Mesh.ARRAY_TEX_UV].size() == arrays[Mesh.ARRAY_VERTEX].size(), "Palette UVs retained")
			if entry.id.begins_with("support"):
				for x in [-.75,0.0,.75]:
					for y in [.4,1.55,1.85]:
						var clear := true
						for i in range(0,arrays[Mesh.ARRAY_INDEX].size(),3):
							var vertices := []
							for j in 3: vertices.append(mesh.transform*arrays[Mesh.ARRAY_VERTEX][arrays[Mesh.ARRAY_INDEX][i+j]])
							if Geometry3D.segment_intersects_triangle(Vector3(x,y,1),Vector3(x,y,-1),vertices[0],vertices[1],vertices[2]) != null:
								clear = false
						check(clear, "Open support passage at " + str(Vector2(x,y)))
		var expected_min := Vector3(entry.min[0],entry.min[2],-entry.max[1])
		var expected_max := Vector3(entry.max[0],entry.max[2],-entry.min[1])
		check(bounds.position.distance_to(expected_min)<.0001 and bounds.end.distance_to(expected_max)<.0001,"Metric registration " + str(entry.id))
		check(triangles == int(entry.triangles),"Triangle budget " + str(entry.id))
		node.queue_free()
	for index in app.IDS.size():
		app.selected = index
		app.load_prop()
		await settle()
		check(app.prop.find_children("*", "CollisionObject3D", true, false).is_empty(), "Presentation has no collision")
		check(app.prop.find_children("*", "Light3D", true, false).is_empty(), "World lighting remains caller-owned")
		var transform: Transform3D = app.prop.transform
		for used in [false,true,false]:
			app.used = used
			app.apply_state()
			check(app.prop.transform == transform, "State keeps registration")
			var triangles := 0
			for mesh: MeshInstance3D in app.prop.find_children("*","MeshInstance3D",true,false):
				if mesh.is_visible_in_tree(): triangles += mesh.mesh.get_faces().size()/3
			scene_triangles[app.IDS[index]+("-used" if used else "-fresh")] = triangles
			if index == 4:
				check(app.prop.get_node("Fresh").visible != used, "Fresh offerings state")
				check(app.prop.get_node("Spent").visible == used, "Spent offerings state")
				check(app.prop.get_node("Flames").visible != used, "Candle state")
		check(not app.prop.is_processing(), "Exact still mode")
		for cave in [true,false]:
			app.cave = cave
			for angle in 3:
				app.angle = angle
				var states := [false] if index < 2 else [false,true]
				for used in states:
					app.used = used
					app.apply_state()
					await settle()
					await RenderingServer.frame_post_draw
					var name: String = "%s-%s-%d-%s.png" % [app.IDS[index], "cave" if cave else "neutral", angle, "used" if used else "fresh"]
					var image: Image = app.viewport.get_texture().get_image()
					check(image.save_png("res://captures/"+name) == OK, "Native capture")
					captures.append(name)
		app.used = false
		app.still = false
		app.apply_state()
		check(app.prop.is_processing() == (index >= 2), "Optional glow animation")
		if index >= 2:
			var energy: float = app.prop._glass.emission_energy_multiplier
			await settle()
			check(app.prop._glass.emission_energy_multiplier != energy, "Glow changes while enabled")
		app.still = true
		app.apply_state()
		var fixed_energy: float = app.prop._glass.emission_energy_multiplier
		await settle()
		check(app.prop._glass.emission_energy_multiplier == fixed_energy, "Glow holds in still mode")
	for size in [Vector2i(1278,590),Vector2i(852,393),Vector2i(667,375)]:
		root.size = size
		await settle()
		app.update_stage()
		for control: Control in app.controls:
			var rect := control.get_global_rect()
			check(rect.size.y >= 44 and rect.end.x <= size.x-43, "Safe phone controls " + str(size))
		check(app.viewport.size.y >= 200, "Phone prop height")
		await RenderingServer.frame_post_draw
		var phone_capture := "screen-%d.png" % size.x
		check(root.get_texture().get_image().save_png("res://captures/"+phone_capture) == OK, "Native phone screen")
		captures.append(phone_capture)
	root.size = Vector2i(1278,590)
	await settle()
	app.selected = 0
	app.angle = 1
	app.cave = true
	app.used = false
	app.load_prop()
	await settle()
	for side in [-1,1]:
		var mesh := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(.02,2.4,6)
		mesh.mesh = box
		mesh.position = Vector3(side*1.01,1.2,0)
		mesh.material_override = app.surface("wall")
		app.stage.add_child(mesh)
	app.wall.visible = true
	app.wall.position.z = -2.9
	var ceiling := MeshInstance3D.new()
	var ceiling_plane := PlaneMesh.new()
	ceiling_plane.size = Vector2(2,6)
	ceiling.mesh = ceiling_plane
	ceiling.rotation.x = PI
	ceiling.position.y = 2.4
	ceiling.material_override = app.surface("ceiling")
	app.stage.add_child(ceiling)
	var shrine = load(app.ART+"miners-shrine.tscn").instantiate()
	shrine.animate_glow = false
	shrine.position.z = -2.85
	app.stage.add_child(shrine)
	var lantern = load(app.ART+"lantern-hanging.tscn").instantiate()
	lantern.animate_glow = false
	lantern.position = Vector3(.92,1.96,.14)
	app.stage.add_child(lantern)
	app.camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	app.camera.fov = 68
	app.camera.position = Vector3(0,1.55,2.2)
	app.camera.look_at(Vector3(0,1.25,-1))
	await settle()
	await RenderingServer.frame_post_draw
	check(app.viewport.get_texture().get_image().save_png("res://captures/corridor.png") == OK, "Mounted corridor preview")
	captures.append("corridor.png")
	var report := {"checks":checks,"failures":failures,"captures":captures,"scene_triangles":scene_triangles,
		"renderer":RenderingServer.get_current_rendering_method(),"physical_iphone":false}
	var file := FileAccess.open("res://validation.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"  ")+"\n")
	print("MINE_CHECKS ",checks," failures=",failures.size())
	quit(0 if failures.is_empty() else 1)

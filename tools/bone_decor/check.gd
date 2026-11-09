extends SceneTree
var checks := 0
var failures: Array[String] = []
var captures: Array = []

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func settle() -> void:
	for frame in 4:
		await process_frame

func save_image(image: Image, path: String) -> void:
	check(image.save_png("res://captures/" + path) == OK, "Capture " + path)
	captures.append(path)

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://captures"))
	root.size = Vector2i(1278, 590)
	var app = load("res://review.tscn").instantiate()
	root.add_child(app)
	await settle()
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(app.ROOT_DIR + "catalog.json"))
	for entry in catalog.assets:
		var node: Node3D = load(app.ROOT_DIR + str(entry.name) + ".glb").instantiate()
		root.add_child(node)
		check(node.find_children("*", "Skeleton3D", true, false).is_empty(), "Static geometry " + str(entry.name))
		check(node.find_children("*", "AnimationPlayer", true, false).is_empty(), "Static pose export " + str(entry.name))
		var meshes := node.find_children("*", "MeshInstance3D", true, false)
		check(meshes.size() == 1, "One combined mesh " + str(entry.name))
		var mesh: MeshInstance3D = meshes[0]
		var bounds := mesh.transform * mesh.get_aabb()
		var expected := Vector3(entry.dimensions[0], entry.dimensions[2], entry.dimensions[1])
		check(bounds.size.distance_to(expected) < .0001, "Declared metric dimensions " + str(entry.name))
		check(absf(bounds.position.y) < .0001, "Floor-centred origin " + str(entry.name))
		check(mesh.mesh.get_surface_count() == 1, "One material surface " + str(entry.name))
		var arrays: Array = mesh.mesh.surface_get_arrays(0)
		check(arrays[Mesh.ARRAY_INDEX].size()/3 == int(entry.triangles), "Native triangle count " + str(entry.name))
		check(arrays[Mesh.ARRAY_TEX_UV].size() == arrays[Mesh.ARRAY_VERTEX].size(), "Retained atlas UVs " + str(entry.name))
		node.queue_free()
	for family in ["halloween", "skeletons"]:
		var material: StandardMaterial3D = load(app.ROOT_DIR + "material-" + family + ".tres")
		check(material.detail_blend_mode == BaseMaterial3D.BLEND_MODE_MUL, "Cave grain multiplication")
		check(material.uv2_world_triplanar and material.uv2_triplanar, "World-space cave grain")
		check(material.albedo_texture.get_size() == Vector2(256, 256), "Small shared atlas")
		check(material.texture_filter == BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS, "Crisp material filter")
	var scene_triangles := {}
	for index in app.props.size():
		var triangles := 0
		for mesh: MeshInstance3D in app.props[index].find_children("*", "MeshInstance3D", true, false):
			for surface in mesh.mesh.get_surface_count():
				triangles += mesh.mesh.surface_get_arrays(surface)[Mesh.ARRAY_INDEX].size()/3
		scene_triangles[app.NAMES[index]] = triangles
	for shape in [Vector2i(1278, 590), Vector2i(852, 393), Vector2i(1334, 750)]:
		root.size = shape
		await settle()
		app.update_stage()
		for control: Control in app.controls:
			var rect := control.get_global_rect()
			check(rect.size.y >= 44 and rect.end.x <= shape.x - 43, "Phone safe controls " + str(shape))
		for viewport: SubViewport in app.viewports:
			check(viewport.size.y >= 100, "Readable panel height")
	root.size = Vector2i(1278, 590)
	await settle()
	for cave in [true, false]:
		app.cave = cave
		for angle in 4:
			app.angle = angle
			app.update_stage()
			await settle()
			await RenderingServer.frame_post_draw
			var light_name := "cave" if cave else "neutral"
			for index in 4:
				var image: Image = app.viewports[index].get_texture().get_image()
				check(image.get_size().x > 200 and image.get_size().y > 100, "Native asset capture dimensions")
				save_image(image, "%s-%s-%d.png" % [app.NAMES[index], light_name, angle])
			if cave and angle == 0:
				save_image(root.get_texture().get_image(), "overview.png")
	var report := {"checks": checks, "failures": failures, "captures": captures,
		"renderer": RenderingServer.get_current_rendering_method(), "physical_iphone": false,
		"scene_triangles": scene_triangles}
	var file := FileAccess.open("res://validation.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  ") + "\n")
	print("BONE_CHECKS ", checks, " failures=", failures.size())
	quit(0 if failures.is_empty() else 1)

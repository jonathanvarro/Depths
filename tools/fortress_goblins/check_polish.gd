extends SceneTree
## Focused render and imported-animation checks for the fortress follow-up.
const FORTRESS := "res://art/enemies/fortress-goblins-3d-v1/"
const PICKUP := "res://art/props/treatment-supplies-v1/scene.tscn"
var viewport: SubViewport
var stage: Node3D
var camera: Camera3D
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		push_error(label)

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://polish"))
	viewport = SubViewport.new()
	viewport.size = Vector2i(640, 640)
	viewport.own_world_3d = true
	viewport.transparent_bg = true
	viewport.msaa_3d = Viewport.MSAA_4X
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	stage = Node3D.new()
	viewport.add_child(stage)
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color("e0e5ee")
	world.environment.ambient_light_energy = .75
	stage.add_child(world)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-52, -32, 0)
	light.light_color = Color("ffe2bc")
	light.light_energy = 1.05
	stage.add_child(light)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	stage.add_child(camera)
	camera.current = true

	var king: Node3D = load(FORTRESS + "goblin-king.tscn").instantiate()
	stage.add_child(king)
	king.sample("idle", 0)
	frame(Vector3(3.2, 1.9, 3.9), Vector3(0, .98, 0), 2.35)
	await capture("king")
	frame(Vector3(-3.9, .60, 3.0), Vector3(0, .98, 0), 2.35)
	await capture("king-profile")
	frame(Vector3(3.9, .60, 3.0), Vector3(0, .98, 0), 2.35)
	await capture("king-opposite")
	king.free()

	var prop: Node3D = load(PICKUP).instantiate()
	stage.add_child(prop)
	var model := prop.find_child("TreatmentBundle", true, false) as MeshInstance3D
	check(model != null and model.material_override != null, "Pickup uses the roster palette")
	check(prop.find_children("*", "CollisionObject3D").is_empty(), "Pickup scene is visual only")
	check(prop.transform == Transform3D.IDENTITY, "Pickup keeps its floor-centre origin")
	if model:
		var bounds := model.get_aabb()
		check(bounds.position.y >= 0 and bounds.position.y < .02, "Pickup meets the floor")
		check(bounds.size.x < .45 and bounds.size.y < .20 and bounds.size.z < .35, "Pickup envelope")
	frame(Vector3(.33, .49, .67), Vector3(0, .07, 0), .49)
	await capture("treatment")
	var floor_mesh := MeshInstance3D.new()
	floor_mesh.mesh = PlaneMesh.new()
	var floor_material := StandardMaterial3D.new()
	floor_material.albedo_texture = load("res://art/textures/cave-v1/floor.png")
	floor_mesh.material_override = floor_material
	stage.add_child(floor_mesh)
	frame(Vector3(.34, 1.34, 1.73), Vector3(0, .27, 0), 1.38)
	await capture("treatment-floor")
	floor_mesh.free()
	prop.free()

	var archer: Node3D = load(FORTRESS + "fortress-archer.tscn").instantiate()
	stage.add_child(archer)
	var skeleton := archer.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	var control := skeleton.find_bone("BowstringPull")
	check(control >= 0, "Archer imports the draw control")
	if control >= 0:
		var rest := skeleton.get_bone_rest(control).origin
		var idle := pull(archer, skeleton, control, "idle", 0, rest)
		var drawn := pull(archer, skeleton, control, "draw", 5, rest)
		var held := pull(archer, skeleton, control, "draw", 7, rest)
		var attack_draw := pull(archer, skeleton, control, "attack", 7, rest)
		var released := pull(archer, skeleton, control, "attack", 8, rest)
		check(idle < .001 and drawn > .08, "String draws from straight idle")
		check(absf(drawn - held) < .003 and absf(drawn - attack_draw) < .003,
			"Draw and attack reach the same held tension")
		check(released < .001, "String returns to straight on the release frame")
		check(pull(archer, skeleton, control, "draw", 8, rest) < .001,
			"Shoot releases before the live 0.4-second action reset")
		for clip in ["idle", "hurt", "fall"]:
			check(pull(archer, skeleton, control, clip, 8, rest) < .001,
				"An interrupted draw resets during %s" % clip)
		archer.set_motion(false)
		archer.play("draw")
		check(skeleton.get_bone_pose_position(control).distance_to(rest) > .08,
			"Reduced motion holds a readable drawn string")
	frame(Vector3(-3.1, 1.75, 4), Vector3(0, .82, 0), 1.7)
	for pose in [["attack-ready", 0], ["attack-drawn", 7], ["attack-release", 8]]:
		archer.sample("draw", float(pose[1]) / 24.0)
		await capture(pose[0])
	print("FORTRESS POLISH: %d failures" % failures)
	quit(int(failures > 0))

func frame(position: Vector3, target: Vector3, size: float) -> void:
	camera.position = position
	camera.look_at(target)
	camera.size = size

func pull(archer: Node3D, skeleton: Skeleton3D, control: int, clip: String,
		frame_number: int, rest: Vector3) -> float:
	archer.sample(clip, frame_number / 24.0)
	return skeleton.get_bone_pose_position(control).distance_to(rest)

func capture(name: String) -> void:
	for frame_number in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := viewport.get_texture().get_image()
	var used := image.get_used_rect()
	check(used.size.x > 100 and used.size.y > 100, "Nonblank transparent capture for %s" % name)
	check(not used.has_point(Vector2i.ZERO), "Transparent corner for %s" % name)
	check(image.save_png("res://polish/" + name + ".png") == OK, "Saved %s capture" % name)

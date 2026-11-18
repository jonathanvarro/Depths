extends SceneTree
## Validate live resource bindings, pose dispatch, and the Bitter Moss state.
const FoeView := preload("res://scripts/foe_view.gd")
const State := preload("res://scripts/combat_state.gd")
const CombatScreen := preload("res://scripts/combat_screen.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(passed: bool, label: String) -> void:
	print("PASS " if passed else "FAIL ", label)
	if not passed:
		failures += 1

func run() -> void:
	var combat = CombatScreen.new()
	root.add_child(combat)
	var cases: Array = [
		["cave_bat","landed",State.Intent.SWOOP,"swoop"],
		["rock_beetle","curled",State.Intent.CURL,"curled"],
		["hollow_miner","grab",State.Intent.GRAB,"grab"],
		["gas_bloat","swell",State.Intent.SWELL,"attack"],
		["lamp_eater","idle",State.Intent.DRAIN,"drain"],
		["breach_hound","idle",State.Intent.LUNGE,"lunge"],
	]
	for row in cases:
		var type: EnemyType = load("res://data/enemies/%s.tres" % row[0])
		var model: Node3D = type.model.instantiate()
		root.add_child(model)
		check(FoeView.is_model(model) and type.scene != null, row[0] + " model and sprite fallback")
		var foe := State.Foe.new(type,type.display_name)
		foe.node = model
		check(combat._action_pose(foe,row[2],{}) == row[3], row[0] + " live action dispatch")
		model.set_motion(false)
		FoeView.play(model,row[1])
		var time: float = model.player.current_animation_position
		await process_frame
		await process_frame
		check(FoeView.current(model) == row[1] and model.player.current_animation_position == time,
			row[0] + " still pose")
		model.queue_free()
	var event: RoomEvent = load("res://data/events/quest_healing_moss.tres")
	var moss = event.prop.instantiate()
	root.add_child(moss)
	check(moss._full.visible and not moss._scraped.visible, "quest uses fresh Bitter Moss")
	moss.state = "empty"
	check(not moss._full.visible and moss._scraped.visible, "gathering displays scraped stone")
	moss.state = "closed"
	check(moss._full.visible and not moss._scraped.visible, "restoring fresh state is immediate")
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		await capture_moss(event.prop,moss,args[0])
	print("fails=",failures)
	quit(failures)

func capture_moss(prop: PackedScene, moss, output: String) -> void:
	var stage := Node3D.new()
	root.add_child(stage)
	moss.reparent(stage)
	moss.position.x = -.69
	var used = prop.instantiate()
	used.state = "empty"
	stage.add_child(used)
	used.position.x = .69
	var floor_mesh := PlaneMesh.new()
	floor_mesh.size = Vector2(100,100)
	var floor_model := MeshInstance3D.new()
	floor_model.mesh = floor_mesh
	var stone := StandardMaterial3D.new()
	stone.albedo_texture = load("res://art/textures/cave-v1/floor.png")
	stone.uv1_scale = Vector3(35,35,1)
	floor_model.material_override = stone
	stage.add_child(floor_model)
	var eye := Camera3D.new()
	stage.add_child(eye)
	eye.position = Vector3(.10,2.0,2.9)
	eye.look_at(Vector3.ZERO)
	eye.projection = Camera3D.PROJECTION_ORTHOGONAL
	eye.size = 2.02
	eye.current = true
	var light := DirectionalLight3D.new()
	stage.add_child(light)
	light.rotation_degrees = Vector3(-56,-26,0)
	light.light_color = Color("e8cda7")
	light.light_energy = 1.15
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color("afbcc5")
	world.environment.ambient_light_energy = .67
	stage.add_child(world)
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(output) == OK,"saved Bitter Moss comparison")

extends SceneTree
var OUT: String
const CASES={"rat":"res://art/enemies/creatures-refined-v2/rat.tscn","great-rat":"res://art/enemies/creatures-refined-v2/great-rat.tscn","bat":"res://art/enemies/creatures-refined-v2/cave-bat.tscn","whisker":"res://art/enemies/creatures-refined-v2/whisker.tscn"}
var stage: Node3D
var camera: Camera3D
var actor: Node3D
var rows: Array=[]

func _initialize() -> void:
	OUT=OS.get_cmdline_user_args()[0] if not OS.get_cmdline_user_args().is_empty() else "res://build/local-creatures-refined-v2"
	DirAccess.make_dir_recursive_absolute(OUT+"/captures")
	preload("res://scripts/save_game.gd").set_path(OUT+"/private-save.dat")
	Engine.set_meta("depths_settings",preload("res://scripts/settings.gd").DEFAULTS.duplicate())
	Engine.set_meta("depths_settings_loaded",true)
	call_deferred("run")

func settle() -> void:
	for i in 8:await process_frame

func snap(label: String) -> void:
	await settle();await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+"/captures/"+label+".png")

func frame(id: String,pose: String,t: float,yaw: float=0.0,low:=false) -> void:
	actor.sample(pose,t)
	var target:=Vector3(0,1.07,0) if id=="bat" else Vector3(0,.26 if id=="rat" else .34,0)
	if pose in ["landed","bite","fall","hurt-ground","fall-ground"] and id=="bat":target.y=.23
	var distance:=2.25 if id!="bat" else 2.65
	var angle:=deg_to_rad(yaw)
	camera.position=target+Vector3(sin(angle)*distance,.06 if low else .42,cos(angle)*distance)
	camera.look_at(target)
	await snap("%s-%s-%d-%d"%[id,pose,roundi(t*100),roundi(yaw)])

func run() -> void:
	root.size=Vector2i(1000,650)
	stage=Node3D.new();root.add_child(stage)
	var world:=WorldEnvironment.new();var env:=Environment.new()
	env.background_mode=Environment.BG_COLOR;env.background_color=Color("262a2c")
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color("c1c8ce");env.ambient_light_energy=.45
	env.tonemap_mode=Environment.TONE_MAPPER_FILMIC;world.environment=env;stage.add_child(world)
	var light:=DirectionalLight3D.new();light.rotation_degrees=Vector3(-38,-28,0);light.light_energy=1.2;stage.add_child(light)
	var fill:=DirectionalLight3D.new();fill.rotation_degrees=Vector3(-20,135,0);fill.light_energy=.35;stage.add_child(fill)
	var floor_mesh:=MeshInstance3D.new();var plane:=PlaneMesh.new();plane.size=Vector2(8,8);floor_mesh.mesh=plane
	var material:=StandardMaterial3D.new();material.albedo_color=Color("4c4e49");material.roughness=1;floor_mesh.material_override=material;stage.add_child(floor_mesh)
	camera=Camera3D.new();camera.fov=40;stage.add_child(camera);camera.make_current()
	for id: String in CASES.keys():
		actor=load(CASES[id]).instantiate();stage.add_child(actor);await settle()
		actor.set_motion(false)
		var bones:=actor.find_child("Skeleton3D",true,false) as Skeleton3D
		rows.append({"id":id,"source":CASES[id],"clips":Array(actor.player.get_animation_list()),"bones":bones.get_bone_count() if bones else 0,"visual_height":actor.get_meta("visual_height")})
		for yaw in [0.0,40.0,90.0,180.0]:await frame(id,"idle",0,yaw,id=="bat")
		for t in [.0,.29,.50]:await frame(id,"attack",t,40)
		if id=="bat":
			for t in [.25,.5,.75]:await frame(id,"idle",t,0,true)
			for t in [.0,.29,.55]:await frame(id,"swoop",t,40)
			await frame(id,"landed",0,40);await frame(id,"bite",.29,40)
			await frame(id,"hurt-ground",.125,40);await frame(id,"fall-ground",1.0,40)
		else:
			for t in [.0,.17,.33]:await frame(id,"walk",t,90)
		await frame(id,"fall",actor.player.get_animation("fall").length,40)
		actor.queue_free();await settle()
	stage.queue_free();await settle()
	# Use the current live field encounter path, not the retired overhead camera.
	for id: String in ["rat","cave_bat"]:
		var main=load("res://scenes/main.tscn").instantiate()
		main.play_opening=false;main.use_debug_layout=true;main.wandering=false;main.simulate_phone_safe_area=true
		root.add_child(main);await create_timer(.5).timeout
		var types: Array[EnemyType]=[load("res://data/enemies/"+id+".tres")]
		var here: Vector2i=main._party.cell
		var next:=here
		for direction in [Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]:
			if not main._map.is_wall(here+direction):next=here+direction;break
		var group=preload("res://scripts/roamers.gd").Group.new();group.cell=next;group.types=types
		main.use_debug_layout=false  # retain known map, enable the live field path
		main._engaged=group;main._next_opening="party"
		main._start_combat(next,types);await create_timer(.9).timeout
		var foe=main._combat._state.foes[0]
		print("LIVE ",id," model=",preload("res://scripts/foe_view.gd").is_model(foe.node)," field=",main._combat._state.field," scene=",foe.node.scene_file_path," distance=",main._party.global_position.distance_to(foe.node.global_position))
		for shape in [Vector2i(1278,590),Vector2i(844,390)]:
			root.size=shape;main._apply_safe_area();await settle();await snap("live-%s-%d"%[id,shape.x])
		main._combat.set_process(false)
		main._combat._busy[foe]=true
		for pose: String in (["idle","attack"] if id=="rat" else ["idle","swoop","landed","bite"]):
			if id=="cave_bat":
				foe.row_override="front" if pose in ["landed","bite"] else "back"
				foe.intent=main.CombatState.Intent.BITE if foe.row_override=="front" else main.CombatState.Intent.SWOOP
				main._combat._process(0)
			foe.node.sample(pose,.29 if pose not in ["idle","landed"] else .0)
			await create_timer(.65).timeout
			main._combat._process(0)
			print("FRAME ",id," ",pose," pitch=",main._party.camera.rotation_degrees.x," fov=",main._party.camera.fov)
			await snap("live-%s-%s-844"%[id,pose])
		main.queue_free();await settle()
	FileAccess.open(OUT+"/models.json",FileAccess.WRITE).store_string(JSON.stringify(rows,"  "))
	print("REVIEW COMPLETE")
	quit()


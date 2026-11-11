extends SceneTree
## Render the event props at the mounted scale and verify their visual states.
const EVENTS := {"tool-rack":"chest_tool_rack","coal-seam":"chest_coal_seam"}
const ICONS := {"mattock":"res://data/gear/mattock.tres",
	"coal":"res://data/items/coal.tres","miners_sledge":"res://data/gear/miners_sledge.tres"}
const CAMP := "res://art/camp/skills-trainer-v1/"
var checks := 0
var failures: Array[String] = []
var captures: Array[String] = []
var out := ""

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		push_error(label)

func textured_box(stage: Node3D, at: Vector3, dimensions: Vector3, texture: String) -> void:
	var node := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = dimensions
	node.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = load(texture)
	mat.roughness = 1
	node.material_override = mat
	node.position = at
	stage.add_child(node)

func capture(name: String) -> void:
	for frame in 5:
		await process_frame
	if DisplayServer.get_name()=="headless":
		return
	await RenderingServer.frame_post_draw
	var filename := name + ".png"
	check(root.get_texture().get_image().save_png(out + "/" + filename) == OK, "Capture " + name)
	captures.append(filename)

func run() -> void:
	out = OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(out)
	var stage := Node3D.new()
	root.add_child(stage)
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color("171b18")
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color("b0aca0")
	world.environment.ambient_light_energy = .37
	stage.add_child(world)
	var light := OmniLight3D.new()
	light.position = Vector3(-.85,1.88,1.78)
	light.light_color = Color("ffd3a1")
	light.light_energy = 2.05
	light.omni_range = 5
	stage.add_child(light)
	textured_box(stage,Vector3(0,-.09,1.7),Vector3(4,.18,5),"res://art/textures/cave-v1/floor.png")
	textured_box(stage,Vector3(0,1.2,-.10),Vector3(4,2.4,.18),"res://art/textures/cave-v1/wall.png")
	var camera := Camera3D.new()
	stage.add_child(camera)
	camera.current = true
	camera.fov = 56
	camera.position = Vector3(.20,1.32,2.40)
	camera.look_at(Vector3(0,.76,.12))
	for id: String in EVENTS:
		var event := load("res://data/events/"+EVENTS[id]+".tres") as RoomEvent
		check(event.prop_on_wall and event.min_depth==1 and event.max_depth==2,"Wall anchor and depths " + id)
		check(event.prop.resource_path.ends_with("/"+id+".tscn"),"Dedicated prop binding " + id)
		var prop := event.prop.instantiate() as Node3D
		stage.add_child(prop)
		prop.set_motion(false)
		var base := prop.get_node("Frame") as Node3D
		var fresh := prop.get_node("Fresh") as Node3D
		var spent := prop.get_node("Spent") as Node3D
		check(base.visible and fresh.visible and not spent.visible,"Fresh " + id)
		for size in [Vector2i(1278,590),Vector2i(852,393)]:
			root.size = size
			await capture(id+"-fresh-"+str(size.x))
		prop.state = "empty"
		check(base.visible and not fresh.visible and spent.visible,"Resolved " + id)
		for size in [Vector2i(1278,590),Vector2i(852,393)]:
			root.size = size
			await capture(id+"-searched-"+str(size.x))
		prop.set_searched(false)
		check(base.visible and fresh.visible and not spent.visible,"Reset " + id)
		stage.remove_child(prop)
		prop.queue_free()
	for id: String in ICONS:
		var item = load(ICONS[id])
		check(item.icon.get_size()==Vector2(128,128) and item.icon.resource_path.ends_with("/"+id+".png"),
			"Current inventory icon " + id)
	var coal = load(ICONS["coal"])
	var black_ore = load("res://data/items/black_ore.tres")
	check(black_ore != null and coal.icon.resource_path != black_ore.icon.resource_path,"Coal and ore have distinct icons")
	var portrait := load(CAMP+"trainer.png") as Texture2D
	check(portrait.get_size()==Vector2(192,192),"Trainer dialogue portrait canvas")
	var shelter := (load(CAMP+"shelter.tscn") as PackedScene).instantiate() as Node2D
	check((shelter.get_node("Base") as Sprite2D).texture.get_size()==Vector2(512,256),"Shelter mount canvas")
	shelter.free()
	var report := {"checks":checks,"failures":failures,"captures":captures,
		"renderer":RenderingServer.get_current_rendering_method()}
	var suffix := "headless" if DisplayServer.get_name()=="headless" else "mobile"
	FileAccess.open(out+"/"+suffix+".json",FileAccess.WRITE).store_string(JSON.stringify(report,"  ")+"\n")
	print("MINING_AND_TRAINER ",checks," failures=",failures)
	stage.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)

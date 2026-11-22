extends SceneTree
const MINE := "res://art/dressing/mine-refined-v2/"
const CHESTS := "res://art/props/loot-chests-v2/"
var output := "res://build/mine-polish-review"
var stage: Node3D
var subject: Node3D
var camera: Camera3D
var key: DirectionalLight3D
var lamp: OmniLight3D
var environment: Environment

func _initialize() -> void:
	if not OS.get_cmdline_user_args().is_empty():output=OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(output)
	call_deferred("run")

func bounds(node: Node3D) -> AABB:
	var result:=AABB()
	var first:=true
	for mesh: MeshInstance3D in node.find_children("*","MeshInstance3D",true,false):
		if not mesh.is_visible_in_tree():continue
		var box: AABB=mesh.global_transform*mesh.get_aabb()
		result=box if first else result.merge(box)
		first=false
	return result

func setup(neutral: bool) -> void:
	if is_instance_valid(stage):stage.free()
	stage=Node3D.new();root.add_child(stage)
	var world:=WorldEnvironment.new();environment=Environment.new();world.environment=environment
	environment.background_mode=Environment.BG_COLOR
	environment.background_color=Color("171e20") if neutral else Color.BLACK
	environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color=Color("9ca6a2") if neutral else Color("1a2424")
	environment.ambient_light_energy=.50 if neutral else .4
	environment.fog_enabled=not neutral;environment.fog_light_color=Color.BLACK;environment.fog_density=.08
	stage.add_child(world)
	key=DirectionalLight3D.new();key.rotation_degrees=Vector3(-46,-32,0)
	key.light_color=Color("e4dfd1");key.light_energy=.95 if neutral else 0.0;stage.add_child(key)
	lamp=OmniLight3D.new();lamp.light_color=Color("e8a84a");lamp.light_energy=0 if neutral else 1.6
	lamp.omni_range=7.0;lamp.omni_attenuation=1.2;stage.add_child(lamp)
	camera=Camera3D.new();camera.current=true;camera.fov=48;stage.add_child(camera)
	var floor:=MeshInstance3D.new();var plane:=PlaneMesh.new();plane.size=Vector2(7,7)
	var material:=StandardMaterial3D.new();material.albedo_color=Color("333b37");material.roughness=1
	plane.material=material;floor.mesh=plane;floor.position.y=-.01;stage.add_child(floor)

func show_asset(path: String,state := "closed",neutral := true) -> void:
	setup(neutral)
	subject=load(path).instantiate()
	if "state" in subject:subject.state=state
	if subject.has_method("set_motion"):subject.set_motion(false)
	stage.add_child(subject)
	var box:=bounds(subject)
	var centre:=box.get_center()
	var extent:=maxf(box.size.x,box.size.y)
	var distance:=maxf(.5,extent)*2.05
	camera.position=centre+Vector3(.60,.38,1.0).normalized()*distance
	camera.look_at(centre)
	lamp.position=camera.position+Vector3(.3,-.15,0)
	if path.contains("hanging"):
		var wall:=MeshInstance3D.new();var back:=BoxMesh.new();back.size=Vector3(.50,.75,.025)
		wall.mesh=back;wall.position=Vector3(0,-.25,-.025);stage.add_child(wall)
		var mat:=StandardMaterial3D.new();mat.albedo_color=Color("44483e");mat.roughness=1;back.material=mat

func snap(name: String) -> void:
	for i in 6:await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(name+".png"))
	print("saved ",name)

func run() -> void:
	root.size=Vector2i(1280,720)
	for id in ["support","support-damaged","lantern-standing","lantern-hanging","miners-shrine","old-workings","rails","rails-broken"]:
		for neutral in [true,false]:
			show_asset(MINE+id+".tscn","closed",neutral)
			await snap(id+("-neutral" if neutral else "-cave"))
		if id in ["miners-shrine","old-workings"]:
			show_asset(MINE+id+".tscn","empty")
			await snap(id+"-spent")
		# The same camera/lighting for the older mesh/material comparison.
		if id in ["support","lantern-standing","miners-shrine","rails"]:
			show_asset(MINE+id+".tscn")
			var framing: Transform3D=camera.transform
			var light_at:=lamp.position
			var old_dir: String="res://art/props/expedition-3d-v1/" if id=="rails" else "res://art/dressing/mine-3d-v1/"
			show_asset(old_dir+id+".tscn")
			camera.transform=framing;lamp.position=light_at
			await snap(id+"-previous")
	for tier in ["common","silver","gold"]:
		for state in ["closed","open","empty"]:
			show_asset(CHESTS+tier+".tscn",state)
			await snap("chest-"+tier+"-"+state)
	setup(true)
	for index in 3:
		var tier: String=["common","silver","gold"][index]
		var chest: Node3D=load(CHESTS+tier+".tscn").instantiate();chest.set_motion(false)
		chest.position.x=(index-1)*1.30;stage.add_child(chest)
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=2.6
	camera.position=Vector3(1.5,1.65,4.4);camera.look_at(Vector3(0,.36,0))
	await snap("chest-types")
	stage.free()
	quit()

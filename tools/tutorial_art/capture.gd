extends "res://tools/mine_polish/capture.gd"
const BODIES := "res://art/props/opening-bodies-3d-v1/"
const FIRE := "res://art/features/campfire-3d-v1/scene.tscn"
const TORCH := "res://art/dressing/wall-torch-3d-v1/"

func frame_body(path: String, neutral: bool, angle: float) -> void:
	show_asset(path,"",neutral)
	var centre := bounds(subject).get_center()
	camera.position=centre+Vector3(sin(angle)*1.9,1.5,cos(angle)*1.9)
	camera.look_at(centre)
	lamp.position=camera.position+Vector3(0.3,-0.2,0)

func run() -> void:
	root.size=Vector2i(1280,720)
	for id in ["fallen-a","fallen-b"]:
		for index in 4:
			frame_body(BODIES+id+".tscn",true,index*PI/2+.3)
			await snap(id+"-angle-"+str(index))
		frame_body(BODIES+id+".tscn",false,.3)
		await snap(id+"-cave")
	for neutral in [true,false]:
		show_asset(FIRE,"",neutral)
		camera.position=Vector3(.95,.9,1.4);camera.look_at(Vector3(0,.15,0))
		await snap("campfire-"+("neutral" if neutral else "cave"))
	setup(true)
	for index in 2:
		var body: Node3D=load(BODIES+["fallen-a","fallen-b"][index]+".tscn").instantiate()
		body.position.x=(index-.5)*1.20;stage.add_child(body)
	camera.position=Vector3(.5,3.0,3.2);camera.look_at(Vector3(0,.2,0))
	await snap("fallen-companions")
	for id in ["burnt-sconce","goblin-torch-lit"]:
		show_asset(TORCH+id+".tscn")
		subject.follow_settings=false;subject.set_motion(false)
		for child in stage.get_children():
			if child is MeshInstance3D:child.position.y=-1.6
		var wall:=MeshInstance3D.new();var box:=BoxMesh.new();box.size=Vector3(.9,1.0,.03)
		wall.mesh=box;wall.position.z=-.02;stage.add_child(wall)
		var mat:=StandardMaterial3D.new();mat.albedo_color=Color("3e4138");mat.roughness=1;box.material=mat
		camera.position=Vector3(.45,.15,.90);camera.look_at(Vector3(0,0,.07))
		await snap(id+"-3d")
	stage.free()
	quit()

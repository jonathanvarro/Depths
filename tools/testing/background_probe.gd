extends SceneTree
## Run only in the disposable background-render probe project.
func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var stage:=Node3D.new();root.add_child(stage)
	var world:=WorldEnvironment.new();var environment:=Environment.new()
	environment.background_mode=Environment.BG_COLOR;environment.background_color=Color("101721")
	environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color=Color.WHITE;environment.ambient_light_energy=0.6
	world.environment=environment;stage.add_child(world)
	var box:=MeshInstance3D.new();box.mesh=BoxMesh.new()
	var material:=StandardMaterial3D.new();material.albedo_color=Color("c38044");box.material_override=material
	box.rotation=Vector3(0.15,0.4,0);stage.add_child(box)
	var light:=DirectionalLight3D.new();light.rotation_degrees=Vector3(-45,-25,0);stage.add_child(light)
	var camera:=Camera3D.new();stage.add_child(camera);camera.position=Vector3(1.8,1.2,2.5);camera.look_at(Vector3.ZERO);camera.current=true
	for i in 12:await process_frame
	root.size=Vector2i(480,270)
	for i in 8:await process_frame
	await RenderingServer.frame_post_draw
	var image:=root.get_texture().get_image()
	var center:=image.get_pixel(image.get_width()/2,image.get_height()/2)
	var edge:=image.get_pixel(4,4)
	var passed:=RenderingServer.get_current_rendering_method()=="mobile" and image.get_width()==480 and center.r>edge.r+0.15
	image.save_png("res://capture.png")
	var report:={"passed":passed,"renderer":RenderingServer.get_current_rendering_method(),"display":DisplayServer.get_name(),"size":str(image.get_size()),"center":str(center),"edge":str(edge)}
	FileAccess.open("res://render.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  ")+"\n")
	print("BACKGROUND_RENDER_PROBE ",report)
	quit(0 if passed else 1)

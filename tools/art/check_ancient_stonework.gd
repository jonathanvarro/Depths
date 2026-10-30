extends "res://tools/art/check_waterworks.gd"
const REVIEW := "res://art/concepts/descent-production-v1/"

func run() -> void:
	if DisplayServer.get_name()=="headless":
		quit(0)
		return
	build_world()
	for item in props:item.queue_free()
	props.clear()
	for water in waters:water.visible=false
	build_level("wet-plain")
	var stone=load("res://art/props/ancient-stonework-v1/scene.tscn").instantiate()
	world.add_child(stone);stone.position=Vector3(4,0,1.025)
	for viewport in [Vector2i(1280,720),Vector2i(1278,590)]:
		root.size=viewport
		camera.position=Vector3(4,1.15,4.8)
		for pose in ["still","peak","off","dim"]:
			stone.set_motion(false);stone.set_effects(pose!="off")
			stone.set_phase(PI if pose=="peak" else 0.0)
			lamp.light_energy=0.6 if pose=="dim" else 2.0
			await capture("stone-"+pose+"-"+str(viewport.x))
	stone.set_effects(true);stone.set_motion(false);lamp.light_energy=1.0
	for i in 5:await process_frame
	await RenderingServer.frame_post_draw
	var image_a:=root.get_texture().get_image().get_data()
	await create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	check(image_a==root.get_texture().get_image().get_data(),"Still pixels fixed")
	stone.set_phase(PI)
	for i in 5:await process_frame
	await RenderingServer.frame_post_draw
	check(image_a!=root.get_texture().get_image().get_data(),"Separate overlay affects renderer")
	stone.set_motion(true)
	var phase:float=stone._phase
	await create_timer(0.3).timeout
	check(stone._phase!=phase,"Slow pulse progresses")
	stone.set_motion(false)
	world.queue_free();waters.clear();props.clear();level=null;lamp=null;camera=null
	await process_frame
	await process_frame
	FileAccess.open(REVIEW+"stone-validation.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"captures":captures,"physical_iphone":false},"  ")+"\n")
	print("STONE_RENDER ",checks," failures=",failures.size())
	quit(0 if failures.is_empty() else 1)

func capture(name: String) -> void:
	for i in 6:await process_frame
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(REVIEW+name+".png")==OK,name)
	captures.append(name+".png")

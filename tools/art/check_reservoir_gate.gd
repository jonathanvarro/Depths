extends "res://tools/art/check_waterworks.gd"
const REVIEW:="res://art/concepts/shepherd-gate-v1/"
func run() -> void:
	if DisplayServer.get_name()=="headless":
		quit(0)
		return
	build_world()
	for child in world.get_children():
		if child is Node3D and child.get_node_or_null("Sprite"):
			child.queue_free()
	props.clear();build_level("wet-plain")
	var gate=load("res://art/props/reservoir-flow-gate-v1/scene.tscn").instantiate()
	world.add_child(gate);gate.position=Vector3(4,0,1.025)
	for viewport in [Vector2i(1280,720),Vector2i(1278,590)]:
		root.size=viewport
		for distance in [5.6,3.8]:
			camera.position=Vector3(4,1.10,distance);camera.rotation=Vector3.ZERO
			for resolved in [false,true]:
				gate.state="empty" if resolved else "closed"
				lamp.light_energy=2.0
				for water in waters:water.visible=not resolved and (water.deep if water.get_meta("x")==2 else not water.deep)
				await capture("gate-"+("open-drained" if resolved else "closed-flooded")+"-"+("near" if distance<4 else "far")+"-"+str(viewport.x))
		camera.position=Vector3(4,1.10,4.5);gate.state="empty";lamp.light_energy=0.6
		await capture("gate-dim-open-"+str(viewport.x))
	world.queue_free();waters.clear();props.clear();level=null;camera=null;lamp=null
	await process_frame
	await process_frame
	FileAccess.open(REVIEW+"gate-validation.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"captures":captures,"physical_iphone":false,"scope":"Isolated art state demonstration, no game flood flags touched"},"  ")+"\n")
	print("FLOW_GATE ",checks," failures=",failures.size())
	quit(0 if failures.is_empty() else 1)
func capture(name:String) -> void:
	for i in 6:await process_frame
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(REVIEW+name+".png")==OK,name)
	captures.append(name+".png")

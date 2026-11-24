extends "res://tools/mine_polish/capture.gd"
const PREFS := preload("res://scripts/settings.gd")
const BODIES := "res://art/props/opening-bodies-3d-v1/"
const FIRE := "res://art/features/campfire-3d-v1/scene.tscn"
var failures: Array[String]=[]
var checks:=0

func check(label: String, ok: bool) -> void:
	checks+=1
	print("PASS " if ok else "FAIL ",label)
	if not ok:failures.append(label)

func run() -> void:
	for id in ["fallen-a","fallen-b"]:
		show_asset(BODIES+id+".tscn")
		var box:=bounds(subject)
		check(id+" entirely inside its cell",absf(box.position.x)<.96 and absf(box.end.x)<.96 and absf(box.position.z)<.96 and absf(box.end.z)<.96)
		check(id+" grounded low pose",box.position.y>=0 and box.position.y<.04 and box.end.y<.42)
		check(id+" true static geometry",subject.find_children("*","MeshInstance3D",true,false).size()==2 and subject.find_children("*","SpriteBase3D",true,false).is_empty() and subject.find_children("*","Skeleton3D",true,false).is_empty())
		check(id+" no collision or gameplay behaviour",subject.find_children("*","CollisionObject3D",true,false).is_empty() and not subject.is_processing())
	show_asset(FIRE)
	var fire=subject
	check("fire has no billboard or particles",fire.find_children("*","SpriteBase3D",true,false).is_empty() and fire.find_children("*","GPUParticles3D",true,false).is_empty())
	check("fire fits original solid cell",bounds(fire).size.x<1.1 and bounds(fire).size.z<1.1 and bounds(fire).end.y<.55)
	var light: OmniLight3D=fire.get_node("Light")
	check("original local light budget",is_equal_approx(light.light_energy,.85) and is_equal_approx(light.omni_range,3.5) and is_equal_approx(light.omni_attenuation,1.5))
	var rotation_before: Vector3=fire.rotation
	camera.position.x+=1.0
	await snap("fire-still")
	var still:=root.get_texture().get_image().get_data()
	for i in 12:await process_frame
	await RenderingServer.frame_post_draw
	check("exact still image",still==root.get_texture().get_image().get_data())
	check("camera does not rotate the prop",fire.rotation==rotation_before)
	fire.set_motion(true)
	for i in 5:await process_frame
	check("fire motion advances",fire._phase>0)
	var copy=load(FIRE).instantiate();copy.set_motion(false);stage.add_child(copy)
	check("independent mutable flame materials",fire._flame!=copy._flame and copy._phase==0)
	fire.follow_settings=true
	PREFS.set_value("flashes",false)
	for i in 3:await process_frame
	check("live settings freeze both flame and light",fire._phase==0 and is_equal_approx(light.light_energy,.85))
	PREFS.set_value("flashes",true)
	for i in 3:await process_frame
	check("live settings resume fire",fire._phase>0)
	stage.free()
	PREFS.set_value("flashes",false)
	var main=load("res://scenes/main.tscn").instantiate()
	main.floor_seed=11;main.simulate_phone_safe_area=true
	root.add_child(main)
	await create_timer(14.0).timeout
	check("real tutorial starts",main._in_opening)
	for index in 2:
		var body: Node3D=main._level.find_child(["FallenTravellerA","FallenTravellerB"][index],true,false)
		var cell: Vector2i=main._opening_body_cells()[index]
		check("tutorial model "+str(index)+" preserves cell",body!=null and body.position==Vector3(cell.x*2,0,cell.y*2) and main._map.solid.has(cell))
	var live_fire=main._level.find_child("TutorialCampfire",true,false)
	check("tutorial uses still-aware fire",live_fire!=null and live_fire.follow_settings and live_fire._phase==0)
	await snap("tutorial-waking-phone")
	main._party.place(main._map,main._opening.start+Vector2i(1,0))
	main._party.facing=1
	main._party.rotation.y=main._party._facing_to_yaw(1)
	check("wake eyelids have cleared",not main._eyelids.visible)
	await snap("tutorial-room-phone")
	main.queue_free()
	await process_frame
	FileAccess.open(output.path_join("validation.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"physical_iphone_test":false},"  "))
	print("TUTORIAL_3D checks=",checks," failures=",failures.size())
	quit(0 if failures.is_empty() else 1)

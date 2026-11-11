extends SceneTree
## #247 checks the actual Ambience/controller handoff in a live dungeon.
var checks := 0
var failures: Array[String] = []
const OUT := "E:/GitHub/Depths/build/local-traps-sites-mist-v1/"
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok: failures.append(label); push_error(label)
func settle() -> void:
	for i in 4: await process_frame
func run() -> void:
	var settings=load("res://scripts/settings.gd")
	var prior: bool=settings.get_value("flashes")
	settings.set_value("flashes",true)
	root.size=Vector2i(1278,590)
	var main=load("res://scenes/main.tscn").instantiate()
	main.play_opening=false
	main.use_debug_layout=true
	root.add_child(main)
	await create_timer(.6).timeout
	main._go_to_floor(2,main.Arrival.FROM_ABOVE)
	await create_timer(.5).timeout
	var mist: Node3D=main._ambience._fog
	check(mist.get_child_count()==3 and mist.visible,"Live exploration uses three mist layers")
	var phase: float=mist._phase
	await create_timer(.1).timeout
	check(mist._phase>phase,"Live mist drifts")
	settings.set_value("flashes",false)
	await settle()
	phase=mist._phase
	await create_timer(.1).timeout
	check(mist._phase==phase and not mist.is_processing(),"Existing reduced-effects setting freezes live mist")
	main._party_state.supplies.source=main._party_state.supplies.Source.LANTERN
	main._party_state.supplies.oil=main._party_state.supplies.LANTERN_CAPACITY
	await settle()
	check(is_equal_approx(mist._light,1.0),"Bright lantern controls mist light")
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(OUT+"captures/live-mist.png")==OK,"Actual dungeon capture")
	main._party_state.supplies.oil=0
	await settle()
	check(is_equal_approx(mist._light,.25),"Unlit dungeon dims mist")
	# Exercise Ambience's combat gate without leaving a suspended combat UI at exit.
	main._in_combat=true
	await create_timer(.2).timeout
	check(not mist.visible and not mist.is_processing(),"Combat hides exploration mist")
	settings.set_value("flashes",prior)
	main.queue_free()
	await settle()
	var file:=FileAccess.open(OUT+"live-mist-validation.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures},"  ")+"\n")
	print("LIVE_MIST_CHECKS ",checks," failures=",failures.size())
	quit(0 if failures.is_empty() else 1)

extends SceneTree
var failures: Array[String] = []
var checks := 0

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.size = Vector2i(1278,590)
	var app = load("res://review.tscn").instantiate()
	root.add_child(app)
	check(app.stools.size() == 2, "Two fixed stool references")
	var anchors := []
	for stool in app.stools:
		check(stool.scale == Vector3.ONE, "Same stool dimensions on each body")
		check(stool.position.y == 0, "Stool stays on fixed floor")
		anchors.append(stool.transform)
	var joins: Array = app.actors[0].join_times("chair_sequence")
	var samples := {"seated-side": float(joins[0])+0.1, "sit-approach": float(joins[0])-0.45, "stand-rise": float(joins[1])+0.5}
	for name in samples:
		app.set_motion("chair_sequence", samples[name], true)
		for i in 3:
			await process_frame
		await RenderingServer.frame_post_draw
		for i in app.stools.size():
			check(app.stools[i].transform == anchors[i], "Seat stays fixed through " + name)
		if root.get_texture().get_image().save_png("res://"+name+".png") != OK:
			quit(1)
			return
	app.set_motion("idle",0,true)
	await process_frame
	await process_frame
	for stool in app.stools:
		check(not stool.visible, "Hide contact reference outside chair sequence")
	var report := {"checks": checks, "failures": failures, "seat_height_metres": 0.43,
		"renderer": RenderingServer.get_current_rendering_method(), "contact_acceptance_pending": 218}
	var file := FileAccess.open("res://stool-validation.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  ") + "\n")
	print("STOOL_REVIEW_OK")
	quit(0 if failures.is_empty() else 1)

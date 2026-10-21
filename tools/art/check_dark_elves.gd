extends SceneTree
## New rigs through the unchanged PortraitView and a disposable combat fixture.
const OUT := "res://art/concepts/dark-elves-v1/"
const VIEW := preload("res://scripts/portrait_view.gd")
const SAVE := preload("res://scripts/save_game.gd")
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		push_error(label)

func snap(name: String) -> void:
	for i in 4: await process_frame
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(OUT + name + ".png") == OK, "Captured " + name)

func run() -> void:
	for pixels in [192, 96]:
		root.size = Vector2i(1152,432) if pixels == 192 else Vector2i(1278,590)
		var controls: Array[Control] = []
		for row in 2:
			var id: String = ["dark-elf-man", "dark-elf-woman"][row]
			var rig: PortraitSet = load("res://data/portraits/dark-elves-v1/" + id + ".tres")
			check(rig.rig_kind == "Unique" and rig.face_id == StringName(id), "Face owns unique rig " + id)
			check(rig.blink_frames.size() == 2 and rig.talk_frames.size() == 3, "All authored animation frames " + id)
			for col in 6:
				var view = VIEW.new()
				root.add_child(view)
				controls.append(view)
				view.position = Vector2(col*pixels, row*(pixels+24)+24)
				view.size = Vector2(pixels,pixels)
				view.show_portrait(rig)
				view.set_animated(false)
				if col in [1,2]: view._eyes.texture = rig.blink_frames[col-1]
				if col >= 3: view._mouth.texture = rig.talk_frames[col-3]
				var label := Label.new()
				root.add_child(label)
				controls.append(label)
				label.position = view.position - Vector2(0,24)
				label.add_theme_font_size_override("font_size",12)
				label.text = ["Rest", "Half", "Closed", "Small", "Open", "Round"][col]
		await snap("held-" + str(pixels))
		for view in controls: view.queue_free()
		await process_frame
	root.size = Vector2i(1152,460)
	var views: Array = []
	for row in 2:
		var id: String = ["dark-elf-man", "dark-elf-woman"][row]
		var rig: PortraitSet = load("res://data/portraits/dark-elves-v1/" + id + ".tres")
		for col in 3:
			var view = VIEW.new()
			root.add_child(view)
			views.append(view)
			view.position = Vector2(170+col*300,row*220+16)
			view.size = Vector2(192,192)
			view.show_portrait(rig)
			view.set_illumination(["neutral", "warm", "dim"][col])
			check(view._light_shadow != null and view._light_highlight != null, "Separate light masks " + id)
			view.blink()
			view.talk(.7)
	await create_timer(.06).timeout
	await snap("moving-and-lighting")
	await create_timer(.8).timeout
	for view in views:
		check(view._mouth.texture == view.portrait_set.mouth and view._eyes.texture == view.portrait_set.eyes, "Playback returns to neutral")
		view.talk(1)
		view.hide()
		check(view._mouth.texture == view.portrait_set.mouth and view._eyes.texture == view.portrait_set.eyes, "Hidden playback stops coherently")
		view.queue_free()
	await process_frame
	# Never touch the owner's slot or existing test saves. Leave this ignored
	# fixture output in place; there is deliberately no delete operation.
	SAVE.set_path("res://build/art131-review-save.dat")
	SAVE.set_continue_requested(false)
	for phone in [false,true]:
		root.size = Vector2i(1278,590) if phone else Vector2i(1280,720)
		var main = load("res://scenes/main.tscn").instantiate()
		main.play_opening = false
		main.use_debug_layout = true
		main.simulate_phone_safe_area = phone
		main.floor_seed = 33
		root.add_child(main)
		await create_timer(.4).timeout
		main._party_state.members[0].initiative = 100
		var type: EnemyType = load("res://data/enemies/goblin.tres").duplicate()
		type.scene = load("res://art/enemies/dark-elves-v1/spearman/scene.tscn")
		type.display_name = "Dark elf · art fixture"
		var types: Array[EnemyType] = [type]
		main._start_combat(main._party.cell, types)
		await create_timer(.9).timeout
		var node: Node3D = main._combat._state.foes[0].node
		var sprite: AnimatedSprite3D = node.get_node("Sprite")
		check(sprite.shaded and sprite.billboard == 1 and sprite.texture_filter == 0, "World-lit nearest combat sprite")
		check(absf(sprite.position.y - 56*sprite.pixel_size) < .00001, "Ground pivot remains local origin")
		for pose in [&"idle", &"attack", &"hurt"]:
			sprite.play(pose)
			check(sprite.sprite_frames.get_frame_count(pose) == 1, "Discrete combat pose " + pose)
			check(sprite.sprite_frames.get_frame_texture(pose,0).get_size() == Vector2(128,128), "Exact canvas " + pose)
			await snap("combat-" + pose + ("-phone" if phone else "-desktop"))
		main.queue_free()
		await process_frame
	var file := FileAccess.open(OUT + "godot-validation.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures},"\t")+"\n")
	file.close()
	print("DARK_ELVES checks=%d failures=%d" % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)

extends SceneTree
## #120: real rig registration, speech/eye lifecycle and portrait replacements.
const VIEW = preload("res://scripts/portrait_view.gd")
const OUT = "res://art/concepts/portrait-coherence-v1/"
var checks := 0
var failures: Array[String] = []
var paths: Array[String] = []

func _initialize() -> void:
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	DirAccess.make_dir_recursive_absolute(OUT)
	call_deferred("_run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		push_error(label)

func gather(directory: String) -> void:
	for file in DirAccess.get_files_at(directory):
		if file.ends_with(".tres"): paths.append(directory + "/" + file)
	for folder in DirAccess.get_directories_at(directory): gather(directory + "/" + folder)

func _run() -> void:
	gather("res://data/portraits")
	var neutral: Array[PortraitSet] = []
	for path in paths:
		var layers: PortraitSet = load(path)
		for texture in [layers.body, layers.head, layers.eyes, layers.mouth] + Array(layers.blink_frames) + Array(layers.talk_frames):
			if texture == null: continue
			check(texture.get_size() == Vector2(192,192), path + " registered 192 canvas")
			check(texture.get_image().get_pixel(0,0).a == 0, path + " transparent exterior")
		var view = VIEW.new()
		root.add_child(view)
		view.size = Vector2(192,192)
		view.show_portrait(layers)
		view._blink_timer.stop()
		if not layers.blink_frames.is_empty():
			neutral.append(layers)
			view.blink()
			await view._eye_tween.finished
			check(view._eyes.texture == layers.eyes, path + " blink restores eyes")
			view.talk(0.32)
			await create_timer(0.04).timeout
			check(view._mouth.texture == layers.talk_frames[0], path + " speech starts small")
			await view._talk_tween.finished
			check(view._mouth.texture == layers.mouth, path + " speech restores resting mouth")
			view.talk(1.0)
			view.blink()
			view.hide()
			check(view._mouth.texture == layers.mouth and view._eyes.texture == layers.eyes and view._blink_timer.is_stopped(), path + " hiding cancels animation")
			view.show()
			check(not view._blink_timer.is_stopped(), path + " visible again schedules blink")
			view.set_animated(false)
			view.talk(0.5)
			view.blink()
			check(view._mouth.texture == layers.mouth and view._eyes.texture == layers.eyes and view._blink_timer.is_stopped(), path + " fallen face stays still")
			view.set_animated(true)
			view.talk(0.3)
			view.show_portrait(load("res://data/portraits/mara.tres"))
			await create_timer(0.36).timeout
			check(view._mouth.texture == view.portrait_set.mouth and view.get_child_count() == 3, path + " replacement removes old rig and callbacks")
		else:
			view.blink(); view.talk(0.3)
			check(view._eyes.texture == layers.eyes and view._mouth.texture == layers.mouth, path + " expression without authored frames stays still")
		view.queue_free()
		await process_frame
	check(neutral.size() == 12, "All three heroes and nine recruit faces covered")
	var speech=VIEW.new();root.add_child(speech);speech.show_portrait(neutral[0]);speech._blink_timer.stop()
	seed(120)
	var expected_random:=randi()
	seed(120)
	speech._schedule_blink()
	check(randi()==expected_random,"Cosmetic scheduling leaves the gameplay random stream alone")
	speech._blink_timer.stop();speech.talk(0.8)
	var saw_pause:=false
	var saw_open:=false
	for tick in 15:
		await create_timer(0.04).timeout
		saw_pause=saw_pause or speech._mouth.texture==speech.portrait_set.mouth
		saw_open=saw_open or speech._mouth.texture==speech.portrait_set.talk_frames[1]
	check(saw_pause and saw_open,"Speech includes open syllables and resting pauses")
	speech.talk(0.0)
	check(speech._mouth.texture==speech.portrait_set.mouth,"Explicit interruption restores neutral immediately")
	speech.queue_free();await process_frame
	# Native rig contact sheets: no art editing or painting, only frame selection.
	root.size = Vector2i(1344,672)
	for group in 4:
		var controls: Array[Control] = []
		for row in 3:
			var layers := neutral[group * 3 + row]
			var title := Label.new(); title.text = layers.resource_path.get_file().get_basename()
			title.position = Vector2(4,row*224);root.add_child(title);controls.append(title)
			for col in 7:
				var view = VIEW.new(); root.add_child(view); controls.append(view)
				view.position = Vector2(col*192,row*224+28);view.size=Vector2(192,192);view.show_portrait(layers);view._blink_timer.stop()
				if col in [1,2]:view._eyes.texture=layers.blink_frames[col-1]
				if col in [3,4,5]:view._mouth.texture=layers.talk_frames[mini(col-3,layers.talk_frames.size()-1)]
		await process_frame;await RenderingServer.frame_post_draw
		check(root.get_texture().get_image().save_png(OUT+"registration-%d.png"%group)==OK,"Registration capture")
		for control in controls:control.queue_free()
		await process_frame
	root.size=Vector2i(512,448)
	var views: Array[Control] = []
	for i in neutral.size():
		var view=VIEW.new();root.add_child(view);view.position=Vector2((i%4)*128,(i/4)*144);view.size=Vector2(128,128);view.show_portrait(neutral[i]);view._blink_timer.stop();views.append(view)
		var label:=Label.new();label.text=neutral[i].resource_path.get_file().get_basename();label.position=view.position+Vector2(0,126);label.add_theme_font_size_override("font_size",13);root.add_child(label)
	for frame in 18:
		if frame==1:
			for view in views:view.talk(0.75)
		if frame==5:
			for view in views:view.blink()
		await create_timer(0.07).timeout;await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OUT+"motion-%02d.png"%frame)
	var report:={"checks":checks,"failures":failures,"portrait_sets":paths.size(),"animated_faces":neutral.size(),"registration_columns":["neutral","half lid","closed","small mouth","open mouth","round or open mouth","restored neutral"],"note":"NPC flat portraits and worried/exhausted expression sets remain static; no borrowed animation drawings."}
	var file:=FileAccess.open(OUT+"validation.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"\t")+"\n");file.close()
	print("PORTRAIT_COHERENCE: checks=%d failures=%d sets=%d"%[checks,failures.size(),paths.size()])
	quit(0 if failures.is_empty() else 1)

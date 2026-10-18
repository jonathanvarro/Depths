extends SceneTree
## Native art, real PortraitView animation, optional lighting and phone review.
const DIR := "res://art/portraits/recruit-kit-v1/"
const DATA := "res://data/portraits/recruits-v1/"
const OUT := "res://art/concepts/recruit-kit-v1/"
var checks := 0
var failures: Array[String] = []
var captures := 0

func _initialize() -> void:
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func _run() -> void:
	var body: Texture2D
	var outfit: Texture2D
	for id in ["warden-a","scout-a"]:
		for emotion in ["neutral","worried","exhausted"]:
			var suffix: String = "" if emotion == "neutral" else "-" + emotion
			var portrait: PortraitSet = load(DATA + id + suffix + ".tres")
			check(portrait != null,id + " resource " + emotion)
			if body == null:
				body = portrait.body
				outfit = portrait.clothing[0]
			check(portrait.body == body and portrait.clothing[0] == outfit,id + " shares actual body/outfit resources " + emotion)
			check(portrait.conditions.size() == 4,id + " condition names " + emotion)
			check(portrait.blink_frames.size() == (2 if emotion == "neutral" else 0),id + " explicit blink coverage " + emotion)
			check(portrait.talk_frames.size() == (2 if emotion == "neutral" else 0),id + " explicit talk coverage " + emotion)
		for name in ["head","eyes-neutral","mouth-neutral","eyes-half","eyes-closed","mouth-small","mouth-open","eyes-worried","mouth-worried","eyes-exhausted","mouth-exhausted","blood","dirt","bandage","pallor","shadow-left","highlight-left","preview"]:
			var texture: Texture2D = load(DIR + id + "/" + name + ".png")
			check(texture.get_size() == Vector2(192,192),id + "/" + name + " full canvas")
			check(texture.get_image().get_pixel(0,0).a == 0,id + "/" + name + " transparent exterior")
	var plain = load("res://scripts/portrait_view.gd").new()
	plain.position = Vector2(-256,-256)
	plain.size = Vector2(192,192)
	root.add_child(plain)
	plain.show_portrait(load(DATA + "warden-a.tres"))
	plain._blink_timer.stop()
	plain.blink()
	await create_timer(0.055).timeout
	check(plain._eyes.texture != plain.portrait_set.eyes,"Unmodified PortraitView blinks with the new resource")
	await create_timer(0.16).timeout
	check(plain._eyes.texture == plain.portrait_set.eyes,"Unmodified PortraitView restores new neutral eyes")
	plain.talk(0.3)
	await create_timer(0.03).timeout
	check(plain._mouth.texture != plain.portrait_set.mouth,"Unmodified PortraitView talks with the new resource")
	plain.queue_free()
	await process_frame
	var preview = load(DIR + "preview.tscn").instantiate()
	root.add_child(preview)
	await process_frame
	_stop_auto(preview)
	var view = preview.views[0]
	preview.blink_all()
	await create_timer(0.055).timeout
	check(view._eyes.texture != view.portrait_set.eyes,"Blink swaps registered eye drawing")
	await create_timer(0.16).timeout
	check(view._eyes.texture == view.portrait_set.eyes,"Blink restores neutral eyes")
	preview.talk_all()
	await create_timer(0.03).timeout
	check(view._mouth.texture != view.portrait_set.mouth,"Talk swaps registered mouth drawing")
	# Switching during animation must not restore old expression components.
	preview.set_expression("worried")
	_stop_auto(preview)
	await create_timer(0.18).timeout
	check(preview.views[0]._eyes.texture == preview.views[0].portrait_set.eyes,"Expression switch cancels prior animation")
	check(preview.views[0]._mouth.texture == preview.views[0].portrait_set.mouth,"Expression switch cancels prior talk")
	preview.set_expression("neutral")
	_stop_auto(preview)
	await process_frame
	var states := [
		["neutral","neutral","",true],["neutral","worried","",true],["neutral","exhausted","",true],
		["neutral","neutral","blood",true],["neutral","neutral","dirt",true],
		["neutral","neutral","bandage",true],["neutral","neutral","pallor",true],
		["warm","neutral","bandage",true],["dim","neutral","pallor",true],
		["neutral","neutral","",false]]
	for viewport in [Vector2i(1280,720),Vector2i(1278,590)]:
		root.size = viewport
		await process_frame
		await process_frame
		var suffix := str(viewport.x)+"x"+str(viewport.y)
		var canvas_rect := Rect2(preview.canvas.position,Vector2(640,360)*preview.canvas.scale)
		check(Rect2(Vector2.ZERO,Vector2(viewport)).encloses(canvas_rect),"Safe scene fits " + suffix)
		for state in states:
			preview.set_expression(state[1])
			preview.set_light(state[0])
			preview.set_condition(state[2])
			preview.set_outfit(state[3])
			_stop_auto(preview)
			await process_frame
			for current in preview.views:
				check(canvas_rect.encloses(current.get_global_rect()),"Portrait fits " + suffix)
				check(current._shadow.get_index() > current._overlays.pallor.get_index(),"Illumination follows conditions")
				if state[2] != "":
					check(current._overlays[state[2]].visible,"Condition survives illumination/expression updates")
				check(current.portrait_set.head.resource_path.contains(current.character_id),"Own head retained")
			if "--capture" in OS.get_cmdline_user_args():
				var label: String = state[0]+"-"+state[1]+"-"+("clear" if state[2]=="" else state[2])+("-shirt" if not state[3] else "")
				await _capture(label+"-"+suffix)
		preview.set_expression("neutral")
		preview.set_condition("")
		preview.set_light("neutral")
		preview.set_outfit(true)
		_stop_auto(preview)
		preview.blink_all()
		await create_timer(0.055).timeout
		if "--capture" in OS.get_cmdline_user_args():
			await _capture("blink-"+suffix)
		await create_timer(0.16).timeout
		preview.talk_all()
		await create_timer(0.03).timeout
		if "--capture" in OS.get_cmdline_user_args():
			await _capture("talk-"+suffix)
	preview.queue_free()
	await process_frame
	var report := {"godot":"4.7.2","checks":checks,"failures":failures,"captures":captures,
		"viewports":[[1280,720],[1278,590]],"native_portrait_sizes":[[192,192],[96,96]],
		"physical_phone_test":false,"scope":"Two recruits and shared template; no live recruitment or Mara migration."}
	FileAccess.open(OUT + "godot-validation.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  ")+"\n")
	print("RECRUIT_KIT_CHECKS: ",checks," failures: ",failures.size()," captures: ",captures)
	quit(0 if failures.is_empty() else 1)

func _stop_auto(preview) -> void:
	for view in preview.views:
		view._blink_timer.stop()

func _capture(label: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(OUT+label+".png") == OK,"Capture "+label)
	captures += 1

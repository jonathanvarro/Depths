extends SceneTree
## Verify the combined roster with the actual portrait renderer and review scene.
const DIR := "res://art/portraits/recruit-roster-v1/"
const OUT := "res://art/concepts/recruit-roster-v1/"
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
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DIR+"catalog.json"))
	check(catalog.portraits.size() == 9,"Nine unique roster entries")
	var ids: Array[String] = []
	var body: Texture2D
	var outfit: Texture2D
	for role in ["Warden","Scout","Brawler"]:
		check(catalog.by_role[role].size() == 3,"Three faces for "+role)
	for profile in catalog.portraits:
		var id: String = profile.id
		check(not ids.has(id),"Unique ID "+id)
		ids.append(id)
		check(catalog.by_role[profile.role].has(id),"Role mapping "+id)
		for emotion in ["neutral","worried","exhausted"]:
			var suffix: String = "" if emotion == "neutral" else "-"+emotion
			var portrait: PortraitSet = load(profile.portrait_set.trim_suffix(".tres")+suffix+".tres")
			check(portrait != null,id+" resource "+emotion)
			if body == null:
				body = portrait.body
				outfit = portrait.clothing[0]
			check(portrait.body == body and portrait.clothing[0] == outfit,id+" actual shared body/outfit "+emotion)
			check(portrait.conditions.size() == 4,id+" four conditions "+emotion)
			check(portrait.blink_frames.size() == (2 if emotion == "neutral" else 0),id+" blink coverage "+emotion)
			check(portrait.talk_frames.size() == (2 if emotion == "neutral" else 0),id+" talk coverage "+emotion)
		var folder: String = profile.portrait.get_base_dir()+"/"
		for name in ["head","eyes-neutral","mouth-neutral","eyes-half","eyes-closed","mouth-small","mouth-open","eyes-worried","mouth-worried","eyes-exhausted","mouth-exhausted","blood","dirt","bandage","pallor","shadow-left","highlight-left","preview"]:
			var texture: Texture2D = load(folder+name+".png")
			check(texture.get_size() == Vector2(192,192),id+"/"+name+" fixed canvas")
			var image := texture.get_image()
			check(image.get_pixel(0,0).a == 0 and image.get_pixel(191,191).a == 0,id+"/"+name+" alpha exterior")
			check(not image.is_invisible(),id+"/"+name+" nonempty")
	# Each role's neutral resources must animate in the unmodified gameplay view.
	for role in ["Warden","Scout","Brawler"]:
		var profile: Dictionary
		for entry in catalog.portraits:
			if entry.role == role: profile = entry
		var plain = load("res://scripts/portrait_view.gd").new()
		plain.position = Vector2(-256,-256)
		plain.size = Vector2(192,192)
		root.add_child(plain)
		plain.show_portrait(load(profile.portrait_set))
		plain._blink_timer.stop()
		plain.blink()
		await create_timer(0.055).timeout
		check(plain._eyes.texture != plain.portrait_set.eyes,role+" plain view blinks")
		await create_timer(0.16).timeout
		check(plain._eyes.texture == plain.portrait_set.eyes,role+" neutral eyes restored")
		plain.talk(0.3)
		await create_timer(0.03).timeout
		check(plain._mouth.texture != plain.portrait_set.mouth,role+" plain view talks")
		plain.queue_free()
		await process_frame
	var preview = load(DIR+"preview.tscn").instantiate()
	root.add_child(preview)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	_stop_auto(preview)
	check(preview.views.size() == 9,"Nine review pairs")
	preview.blink_all()
	preview.talk_all()
	await create_timer(0.055).timeout
	for group in preview.views:
		check(group[0]._eyes.texture != group[0].portrait_set.eyes,"Registered blink "+group[0].character_id)
		check(group[0]._mouth.texture != group[0].portrait_set.mouth,"Registered talk "+group[0].character_id)
	preview.set_expression("worried")
	_stop_auto(preview)
	await create_timer(0.18).timeout
	for group in preview.views:
		check(group[0]._eyes.texture == group[0].portrait_set.eyes,"Expression cancels blink "+group[0].character_id)
		check(group[0]._mouth.texture == group[0].portrait_set.mouth,"Expression cancels talk "+group[0].character_id)
	var states := [["neutral","neutral","",true],["neutral","worried","",true],["neutral","exhausted","",true],
		["neutral","neutral","blood",true],["neutral","neutral","dirt",true],["neutral","neutral","bandage",true],
		["neutral","neutral","pallor",true],["warm","neutral","bandage",true],["dim","neutral","pallor",true],["neutral","neutral","",false]]
	for viewport in [Vector2i(1280,720),Vector2i(1278,590)]:
		root.size = viewport
		await process_frame
		await process_frame
		var suffix := str(viewport.x)+"x"+str(viewport.y)
		var canvas_rect := Rect2(preview.canvas.position,Vector2(800,560)*preview.canvas.scale)
		check(Rect2(Vector2.ZERO,Vector2(viewport)).encloses(canvas_rect),"Canvas fits "+suffix)
		var buttons: Array[Rect2] = []
		for button in preview.controls.values():
			var rect: Rect2 = button.get_global_rect()
			check(rect.size.y >= 44 and canvas_rect.encloses(rect),"Touch button fits "+suffix)
			for other in buttons:check(not rect.intersects(other),"Touch buttons do not overlap "+suffix)
			buttons.append(rect)
		for state in states:
			preview.set_expression(state[1])
			preview.set_light(state[0])
			preview.set_condition(state[2])
			preview.set_outfit(state[3])
			_stop_auto(preview)
			await process_frame
			for group in preview.views:
				for current in group:
					check(canvas_rect.encloses(current.get_global_rect()),"Portrait fits "+suffix)
					check(current._shadow.get_index() > current._overlays.pallor.get_index(),"Light above conditions")
					check(current.portrait_set.head.resource_path.contains(current.character_id),"Own head retained")
					check(current._shadow.texture.resource_path.contains(current.character_id),"Own light mask retained")
					if state[2] != "":check(current._overlays[state[2]].visible,"Condition retained")
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
		if "--capture" in OS.get_cmdline_user_args():await _capture("blink-"+suffix)
		await create_timer(0.16).timeout
		preview.talk_all()
		await create_timer(0.03).timeout
		if "--capture" in OS.get_cmdline_user_args():await _capture("talk-"+suffix)
	preview.queue_free()
	await process_frame
	var report := {"godot":"4.7.2","checks":checks,"failures":failures,"captures":captures,
		"viewports":[[1280,720],[1278,590]],"review_portrait_sizes":[[128,128],[96,96]],"asset_canvas":[192,192],
		"physical_phone_test":false,"scope":"Nine recruits; shared existing body/outfit; no live recruitment wiring or Mara migration."}
	FileAccess.open(OUT+"godot-validation.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  ")+"\n")
	print("RECRUIT_ROSTER_CHECKS: ",checks," failures: ",failures.size()," captures: ",captures)
	quit(0 if failures.is_empty() else 1)

func _stop_auto(preview) -> void:
	for group in preview.views:
		for view in group:view._blink_timer.stop()

func _capture(label: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(OUT+label+".png") == OK,"Capture "+label)
	captures += 1

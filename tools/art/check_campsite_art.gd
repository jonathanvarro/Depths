extends SceneTree
## Isolated camp art/input review. Never instantiates the live campaign.
const DIR := "res://art/camp/cave-camp-v1/"
const OUT := "res://art/concepts/campsite-v1/"
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
	for name in ["supplies","smith","treatment","rest","fire","cave"]:
		var scene = load(DIR + name + ".tscn").instantiate()
		var sprite: Sprite2D = scene.get_node("Base")
		check(sprite.texture.get_size() == Vector2(256,192),name + " native site canvas")
		check(not sprite.centered and sprite.position == Vector2(-128,-184),name + " common contact")
		check(scene.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST,name + " nearest filter")
		check(sprite.texture.get_image().get_pixel(0,0).a == 0,name + " transparent margin")
		scene.free()
	for name in ["merchant","apprentice","nurse"]:
		var texture: Texture2D = load(DIR + name + ".png")
		check(texture.get_size() == Vector2(192,192),name + " native portrait canvas")
		check(texture.get_image().get_pixel(0,0).a == 0,name + " transparent margin")
	check(load(DIR + "clearing.png").get_size() == Vector2(640,360),"Background canvas")
	var preview = load(DIR + "preview.tscn").instantiate()
	root.add_child(preview)
	await process_frame
	var flame: AnimatedSprite2D = preview.art_nodes.fire.get_node("FlameAnchor/Flames")
	check(flame.sprite_frames.resource_path == "res://art/features/campfire-v1/frames.tres","Reuses existing flame resource")
	check(flame.is_playing(),"Flame starts automatically")
	var first := flame.frame
	await create_timer(0.2).timeout
	check(flame.frame != first,"Flame advances")
	preview.art_nodes.fire.hide()
	check(not flame.is_playing(),"Hidden fire pauses")
	preview.art_nodes.fire.show()
	check(flame.is_playing(),"Visible fire resumes")
	preview.art_nodes.fire.animate_flames = false
	check(not flame.is_playing() and flame.frame == 0,"Reduced-motion fire holds a static frame")
	flame.pause()
	flame.frame = 0
	for viewport in [Vector2i(1280,720),Vector2i(1278,590),Vector2i(1334,750)]:
		root.size = viewport
		await process_frame
		await process_frame
		var suffix := str(viewport.x) + "x" + str(viewport.y)
		var canvas_rect := Rect2(preview.canvas.position,Vector2(640,360)*preview.canvas.scale)
		check(Rect2(Vector2.ZERO,Vector2(viewport)).encloses(canvas_rect),"Scene fits " + suffix)
		check(preview.buttons.size() == 6,"Six destinations " + suffix)
		var rects: Array[Rect2] = []
		for item in preview.destinations:
			var button: Button = preview.buttons[item.id]
			var rect := button.get_global_rect()
			check(rect.size.x >= 44 and rect.size.y >= 44,item.id + " touch target " + suffix)
			check(canvas_rect.encloses(rect),item.id + " target stays in safe scene " + suffix)
			for other in rects:
				check(not rect.intersects(other),item.id + " separate target " + suffix)
			rects.append(rect)
			await _click(rect.get_center())
			check(preview.current_id == item.id and preview.activity.visible,item.id + " mouse opens " + suffix)
			check(preview.back.has_focus(),"Focus enters activity " + item.id)
			if "--capture" in OS.get_cmdline_user_args() and item.npc != "":
				await _capture(item.npc + "-" + suffix)
			var escape := InputEventKey.new()
			escape.keycode = KEY_ESCAPE
			escape.pressed = true
			root.push_input(escape)
			await process_frame
			check(preview.current_id == "" and not preview.activity.visible,item.id + " Escape returns " + suffix)
			check(button.has_focus(),item.id + " restores focus " + suffix)
		# Touch uses the same persistent targets, without hover.
		var target: Button = preview.buttons.treatment
		var touch := InputEventScreenTouch.new()
		touch.position = target.get_global_rect().get_center()
		touch.pressed = true
		root.push_input(touch)
		touch = touch.duplicate()
		touch.pressed = false
		root.push_input(touch)
		await process_frame
		check(preview.current_id == "treatment","Single touch opens nurse " + suffix)
		preview.close_area()
		var focus_target: Button = preview.buttons.supplies
		focus_target.grab_focus()
		var accept := InputEventKey.new()
		accept.keycode = KEY_ENTER
		accept.pressed = true
		root.push_input(accept)
		accept = accept.duplicate()
		accept.pressed = false
		root.push_input(accept)
		await process_frame
		check(preview.current_id == "supplies","Keyboard opens merchant " + suffix)
		preview.close_area()
		preview.buttons.supplies.release_focus()
		if "--capture" in OS.get_cmdline_user_args():
			await _capture("clearing-" + suffix)
			preview.buttons.smith.grab_focus()
			await _capture("focus-" + suffix)
			preview.buttons.smith.release_focus()
	preview.queue_free()
	await process_frame
	var report := {"godot":"4.7.2","checks":checks,"failures":failures,"captures":captures,
		"viewports":[[1280,720],[1278,590],[1334,750]],"physical_phone_test":false,
		"scope":"Isolated art review: no campaign or camp service implementation."}
	FileAccess.open(OUT + "godot-validation.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  ")+"\n")
	print("CAMPSITE_ART_CHECKS: ", checks," failures: ",failures.size()," captures: ",captures)
	quit(0 if failures.is_empty() else 1)

func _click(at: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = at
	root.push_input(motion)
	for pressed in [true,false]:
		var click := InputEventMouseButton.new()
		click.position = at
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = pressed
		root.push_input(click)
	await process_frame

func _capture(label: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(OUT + label + ".png") == OK,"Capture " + label)
	captures += 1

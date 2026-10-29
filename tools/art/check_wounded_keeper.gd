extends SceneTree
## Isolated art check: no Main, settings or save files loaded.
const VIEW = preload("res://scripts/portrait_view.gd")
const OUT := "res://art/concepts/wounded-keeper-v1/"
var checks := 0
var failures: Array[String] = []
var captures: Array[String] = []
var canvas: Control

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		failures.append(description)
		push_error(description)

func run() -> void:
	canvas = Control.new()
	root.add_child(canvas)
	var views: Array = []
	for emotion in ["neutral", "pained", "defiant", "map-reading"]:
		var p = load("res://data/portraits/wounded-keeper-v1/"+emotion+".tres")
		check(p != null and p.rig_kind == "Unique", emotion+" resource loads as unique")
		check(p.face_id == &"wounded-keeper", emotion+" identity")
		check(p.head.get_size() == Vector2(192,192), emotion+" native canvas")
		var view = VIEW.new()
		canvas.add_child(view)
		view.size = Vector2(192,192)
		view.show_portrait(p)
		views.append(view)
		if emotion == "map-reading":
			view.blink()
			view.talk(0.2)
			check(p.blink_frames.is_empty() and p.talk_frames.is_empty(), "Map pose stays static")
			check(view._eyes.texture == null and view._mouth.texture == null, "Map has no borrowed features")
		else:
			check(p.blink_frames.size() == 2 and p.talk_frames.size() == 2, emotion+" own animation")
			view.blink()
			await view._eye_tween.finished
			check(view._eyes.texture == p.eyes, emotion+" blink restores own expression")
			view.talk(0.3)
			await create_timer(0.03).timeout
			check(view._mouth.texture == p.talk_frames[0], emotion+" starts own speech")
			await view._talk_tween.finished
			check(view._mouth.texture == p.mouth, emotion+" speech restores own mouth")
			view.talk(1.0)
			view.blink()
			view.hide()
			check(view._eyes.texture == p.eyes and view._mouth.texture == p.mouth, emotion+" hiding cancels animation")
			view.show()
		view.set_animated(false)
		view.set_illumination("warm")
		check(is_equal_approx(view._light_shadow.modulate.a,0.26), emotion+" separate warm shadow")
		view.set_illumination("dim")
		check(view._character.modulate == Color(0.60,0.64,0.68), emotion+" dim character modulation")
		view.set_illumination("neutral")
	# Replace an actively speaking expression: no old callback may reset the new face.
	views[0].set_animated(true)
	views[0].talk(0.5)
	views[0].blink()
	var defiant = load("res://data/portraits/wounded-keeper-v1/defiant.tres")
	views[0].show_portrait(defiant)
	await create_timer(0.6).timeout
	check(views[0]._eyes.texture == defiant.eyes and views[0]._mouth.texture == defiant.mouth, "Expression swap cancels old callbacks")
	views[0].show_portrait(load("res://data/portraits/wounded-keeper-v1/neutral.tres"))
	views[0].set_animated(false)
	if "--shots" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless":
		root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
		var bg := ColorRect.new()
		bg.color = Color("252d28")
		bg.size = Vector2(1280,720)
		canvas.add_child(bg)
		canvas.move_child(bg,0)
		for viewport in [Vector2i(1280,720),Vector2i(1278,590)]:
			root.size = viewport
			for state in ["rest", "half", "closed", "small", "open", "warm", "dim"]:
				for i in 4:
					var v = views[i]
					var p: PortraitSet = v.portrait_set
					v.position = Vector2(48+i*290,42)
					v.set_illumination(state if state in ["warm","dim"] else "neutral")
					if i < 3:
						v._eyes.texture = p.blink_frames[0] if state == "half" else (p.blink_frames[1] if state == "closed" else p.eyes)
						v._mouth.texture = p.talk_frames[0] if state == "small" else (p.talk_frames[1] if state == "open" else p.mouth)
					var card = VIEW.new()
					canvas.add_child(card)
					card.position = v.position+Vector2(48,240)
					card.size = Vector2(96,96)
					card.show_portrait(p)
					card.set_animated(false)
					card.set_illumination(state if state in ["warm","dim"] else "neutral")
					card._eyes.texture = v._eyes.texture
					card._mouth.texture = v._mouth.texture
					card.set_meta("review_card",true)
				await process_frame
				await RenderingServer.frame_post_draw
				var name: String = "godot-"+state+"-"+str(viewport.x)+".png"
				check(root.get_texture().get_image().save_png(OUT+name) == OK, name)
				captures.append(name)
				for child in canvas.get_children():
					if child.has_meta("review_card"):
						canvas.remove_child(child)
						child.queue_free()
	canvas.queue_free()
	views.clear()
	await process_frame
	await process_frame
	var report := {"checks":checks,"failures":failures,"captures":captures,"display":DisplayServer.get_name(),"physical_iphone_test":false,"scope":"Isolated PortraitView and resource tests; not live event/conversation integration"}
	FileAccess.open(OUT+("render-validation.json" if not captures.is_empty() else "godot-validation.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  ")+"\n")
	print("KEEPER_CHECKS ",checks," failures=",failures.size()," captures=",captures.size())
	quit(0 if failures.is_empty() else 1)

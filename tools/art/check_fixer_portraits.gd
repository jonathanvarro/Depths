extends SceneTree
## #163: actual recruit selection/save representation and real portrait/card renderer.
const Recruits = preload("res://scripts/recruits.gd")
const Save = preload("res://scripts/save_game.gd")
const VIEW = preload("res://scripts/portrait_view.gd")
const CARD = preload("res://scripts/party_card.gd")
const OUT := "res://art/concepts/fixer-v1/"
var checks := 0
var failures: Array[String] = []
var captures: Array[String] = []
var heroes: Array[Companion] = []
var views: Array = []
var cards: Array = []
var canvas: Control
var caption: Label

func _initialize() -> void:
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		push_error(label)

func label(text: String, at: Vector2, font_size := 20) -> Label:
	var node := Label.new()
	node.text = text
	node.position = at
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", Color("dfd4bc"))
	canvas.add_child(node)
	return node

func run() -> void:
	var profiles := Recruits.faces_for("Fixer")
	check(profiles.size() == 3, "Recruit model sees all three Fixer faces")
	check(Recruits.ROLES.Fixer.portrait.ends_with("/fixer.png"), "Dedicated silhouette is connected")
	var rng := RandomNumberGenerator.new()
	rng.seed = 163
	var used: Array = []
	for i in 3:
		var hero := Recruits.make(rng, [], used, 1, "Fixer")
		check(hero.portrait_set != null, "Generated recruit has animated art")
		check(hero.portrait_set.resource_path not in used, "Free face selection avoids duplicates")
		used.append(hero.portrait_set.resource_path)
		check(hero.row == "back" and hero.dialogue != null, "Role and dialogue remain authoritative")
		var restored := Companion.new()
		Save.unpack_into(restored, Save.pack_object(hero))
		check(restored.portrait_set == hero.portrait_set and restored.portrait == hero.portrait, "Save representation retains exact selected art")
		check(restored.strength == hero.strength and restored.attack_max == hero.attack_max, "Save representation retains role statistics")
	for profile in profiles:
		var hero := Recruits.make(rng, [], [], 1, "Fixer")
		hero.portrait = load(profile.portrait)
		hero.portrait_set = load(profile.portrait_set)
		heroes.append(hero)
		var p := hero.portrait_set
		check(p.rig_kind == "Unique" and p.rig_family == StringName("unique-"+profile.id+"-v1"), "Explicit concept-specific rig "+profile.id)
		check(p.face_id == StringName(profile.id), "Face identity "+profile.id)
		check(p.body.resource_path.contains("fixer-v1/"+profile.id), "Own clothed lower bust")
		check(p.head.resource_path.contains("fixer-v1/"+profile.id), "Own cleaned upper bust")
		check(p.clothing.is_empty() and p.front.is_empty(), "Full concept retained without standard-jerkin substitution")
		check(p.blink_frames.size() == 2 and p.talk_frames.size() == 2, "Actual authored frame counts")
		check(p.conditions.size() == 4 and p.light_shadow != null and p.light_highlight != null, "Conditions and separate lighting")
		for texture in [p.body,p.head,p.eyes,p.mouth,p.light_shadow,p.light_highlight]+Array(p.blink_frames)+Array(p.talk_frames)+p.conditions.values():
			check(texture.get_size() == Vector2(192,192), "Full registered canvas")
			check(texture.get_image().get_pixel(0,0).a == 0, "Transparent exterior")
	canvas = Control.new()
	root.add_child(canvas)
	var background := ColorRect.new()
	background.color = Color("202821")
	background.size = Vector2(1500,900)
	canvas.add_child(background)
	label("Fixer portraits · actual Godot 4.7.2 renderer", Vector2(56,24),24)
	caption = label("Native 192px bust · real 96px party card · paused frames",Vector2(56,58),18)
	for i in 3:
		var at := Vector2(64+i*384,110)
		label(String(heroes[i].portrait_set.face_id), at-Vector2(0,25))
		var view = VIEW.new()
		canvas.add_child(view)
		view.position = at
		view.size = Vector2(192,192)
		view.show_portrait(heroes[i].portrait_set)
		view.set_animated(false)
		views.append(view)
		var card = CARD.new()
		canvas.add_child(card)
		card.position = at+Vector2(212,0)
		card.show_companion(heroes[i])
		card.show_row = true
		card.refresh()
		card._portrait.set_animated(false)
		cards.append(card)
	# Exercise actual timed playback and interruption on all three identities.
	for view in views:
		view.set_animated(true)
		view.blink()
		await view._eye_tween.finished
		check(view._eyes.texture == view.portrait_set.eyes, "Blink restores correct resting eye")
		view.talk(0.5)
		await create_timer(0.035).timeout
		check(view._mouth.texture == view.portrait_set.talk_frames[0], "Speech starts with own small mouth")
		await view._talk_tween.finished
		check(view._mouth.texture == view.portrait_set.mouth, "Speech restores correct resting mouth")
		view.talk(1.0);view.blink();view.hide()
		check(view._eyes.texture == view.portrait_set.eyes and view._mouth.texture == view.portrait_set.mouth, "Hide cancels both drawings")
		view.show();view.set_animated(false)
	# Reference-size and landscape-phone captures with real cards, not HTML mocks.
	for viewport in [Vector2i(1280,720),Vector2i(1278,590)]:
		root.size = viewport
		await process_frame
		await process_frame
		for state in ["neutral","eyes-half","eyes-closed","mouth-small","mouth-open","warm-bandage","dim-pallor","blood","dirt"]:
			caption.text = state+" · native 192px bust and real 96px card · no campaign save loaded"
			for i in 3:
				var view = views[i]
				var p: PortraitSet = heroes[i].portrait_set
				for current in [view,cards[i]._portrait]:
					current.set_animated(false)
					current._eyes.texture = p.blink_frames[0] if state == "eyes-half" else (p.blink_frames[1] if state == "eyes-closed" else p.eyes)
					current._mouth.texture = p.talk_frames[0] if state == "mouth-small" else (p.talk_frames[1] if state == "mouth-open" else p.mouth)
					current.set_illumination("warm" if state == "warm-bandage" else ("dim" if state == "dim-pallor" else "neutral"))
					for condition in p.conditions:
						current.set_condition(condition, state == condition or (state == "warm-bandage" and condition == "bandage") or (state == "dim-pallor" and condition == "pallor"))
					check(current._light_shadow.get_index() > current._overlays.pallor.get_index(), "Light stays above condition layers")
					check(current.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "Native pixel filtering")
				check(Rect2(Vector2(48,12),Vector2(viewport)-Vector2(96,24)).encloses(view.get_global_rect()), "Bust stays inside simulated phone margins")
				check(Rect2(Vector2(48,12),Vector2(viewport)-Vector2(96,24)).encloses(cards[i].get_global_rect()), "Real card stays inside simulated phone margins")
			await process_frame
			await RenderingServer.frame_post_draw
			var name: String = "godot-"+state+"-"+str(viewport.x)+".png"
			check(root.get_texture().get_image().save_png(OUT+name) == OK, "Capture "+name)
			captures.append(name)
	canvas.queue_free()
	views.clear();cards.clear();heroes.clear()
	await process_frame
	await process_frame
	var report := {"godot":"4.7.2 Mobile D3D12","checks":checks,"failures":failures,"captures":captures,"physical_iphone_test":false,"save_scope":"In-memory pack/unpack; no disk saves or player preferences touched"}
	FileAccess.open(OUT+"godot-validation.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  ")+"\n")
	print("FIXER_CHECKS ",checks," failures=",failures.size()," captures=",captures.size())
	quit(0 if failures.is_empty() else 1)

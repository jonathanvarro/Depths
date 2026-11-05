extends SceneTree
## The restaged commander scene (#228): narration on its own, his portrait
## right of centre with his bubble left of centre near the top, the party's
## reply in a bubble near the bottom that stays, greyed, while he answers;
## short reply buttons with a spoken line for each starting hero, and the
## accept reply marked. Plays it once as each hero. Args: tag, screenshot dir.

const Quests := preload("res://scripts/quests.gd")
const HEROES := ["res://data/companions/mara.tres", "res://data/companions/corin.tres", "res://data/companions/alwen.tres"]

var fails := 0
var dir := ""
var tag := "desk"


func check(label: String, ok: bool, detail = "") -> void:
	if not ok: fails += 1
	print("PASS " if ok else "FAIL ", label, "  ", detail)


func _snap(name: String) -> void:
	if dir == "":
		return
	for i in 6:
		await process_frame
	var shot := root.get_texture().get_image()
	if shot:
		shot.save_png("%s/conversation_%s_%s.png" % [dir, tag, name])


func _settle() -> void:
	for i in 3:
		await process_frame


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	tag = args[0] if args.size() > 0 else "desk"
	dir = args[1] if args.size() > 1 else ""
	var main = load("res://scenes/main.tscn").instantiate()
	main.play_opening = false
	main.floor_seed = 11
	main.simulate_phone_safe_area = tag == "phone"
	root.add_child(main)
	await create_timer(0.5).timeout
	var talk: Conversation = main.COMMANDER_FIRST
	var screen = main._conversation
	var view: Vector2 = root.get_visible_rect().size

	# Every summary reply has a line for each starting hero.
	var names: Array = HEROES.map(func(p): return load(p).display_name)
	var missing := []
	for page in talk.pages:
		for reply in page.replies:
			if reply.label != "Go on" and not names.all(func(n): return reply.said_by.has(n)):
				missing.append(reply.label)
	check("each reply has a spoken line for Mara, Corin and Alwen", missing.is_empty(), missing)

	# Every story talk: pages link up, quoted replies have a line for each
	# starting hero, and accept marks name real quests.
	var problems := []
	for file in DirAccess.get_files_at("res://data/conversations"):
		file = file.trim_suffix(".remap")
		if not file.ends_with(".tres"):
			continue
		var each: Conversation = load("res://data/conversations/" + file)
		for i in each.pages.size():
			var page: ConversationPage = each.pages[i]
			if page.speaker == "hero" and not names.all(func(n): return page.text_by.has(n)):
				problems.append("%s p%d: hero text" % [file, i])
			for reply in page.replies:
				if reply.next >= each.pages.size() or reply.next == i:
					problems.append("%s p%d: next %d" % [file, i, reply.next])
				if reply.label != "Go on" and reply.spoken_by(null) == "" and reply.said_by.is_empty() and reply.accepts == "":
					pass  # an action, not words (e.g. "Keep the feather")
				elif reply.label != "Go on" and reply.accepts == "" and not names.all(func(n): return reply.said_by.has(n)):
					problems.append("%s p%d: %s" % [file, i, reply.label])
				if reply.accepts != "" and not Quests.INFO.has(reply.accepts):
					problems.append("%s p%d: accepts %s" % [file, i, reply.accepts])
				if reply.label.begins_with("\""):
					problems.append("%s p%d: quoted label %s" % [file, i, reply.label])
	check("every story talk: summary buttons, a line per hero, pages that link up", problems.is_empty(), problems)

	for path in HEROES:
		var hero: Companion = load(path).duplicate()
		var camp = main.CampState.new()
		var short: String = hero.display_name.split(" ")[-1].to_lower()
		screen.play(talk, hero, camp, [hero])
		await _settle()
		check("%s: the scene opens with narration alone, no name or tail" % short, screen._say.visible and not screen._name.visible and not screen._say_tail.visible and not screen._said.visible and screen._text.text.begins_with("Soldiers"))
		await _snap(short + "_narration")
		screen.choose("Go on")
		await _settle()
		var say: Rect2 = screen._say.get_global_rect()
		var frame: Rect2 = screen._frames["npc"].get_global_rect()
		check("%s: then he speaks, in his own bubble pointing at him" % short, screen._name.text.contains("Vael") and screen._say_tail.visible and screen._text.text.begins_with("\"Edric Vael"))
		check("%s: his portrait stands just right of centre" % short, frame.get_center().x > view.x * 0.5 and frame.end.x < view.x - 24, frame)
		check("%s: his bubble sits left of centre, near the top, clear of him" % short, say.get_center().x < view.x * 0.5 and say.position.y < view.y * 0.2 and say.end.x < frame.position.x, say)
		check("%s: ...sized to his words, not the narration before" % short, say.size.y < view.y * 0.3, say.size)
		check("%s: three short replies along the bottom" % short, screen._replies.get_child_count() == 3 and screen._box.get_global_rect().end.y > view.y - 40)
		await _snap(short + "_question")
		screen.choose("We were ambushed")
		await _settle()
		var line: String = talk.pages[1].replies[0].said_by[hero.display_name]
		var said: Rect2 = screen._said.get_global_rect()
		check("%s: the hero says it in their own words, near the bottom" % short, screen._said.visible and screen._said_text.text == line and said.position.y > view.y * 0.5, screen._said_text.text)
		check("%s: ...kept on screen, greyed, while he answers" % short, screen._said.modulate.r < 0.8 and screen._say.modulate == Color.WHITE and screen._text.text.contains("Ambushed"))
		check("%s: his bubble and yours don't overlap" % short, not screen._say.get_global_rect().intersects(said) and not frame.intersects(said))
		await _snap(short + "_answer")
		screen.choose("Go on")
		await _settle()
		var accept: Button = screen._replies.get_child(0)
		check("%s: 'I'll find them' is marked as taking the quest" % short, accept.text.begins_with("I'll find them") and accept.text.contains("Accept: Those Left Behind"), accept.text)
		await _snap(short + "_accept")
		screen.choose("I'll find them")
		await create_timer(0.4).timeout
		check("%s: ...and accepting it starts the quest" % short, Quests.is_active(camp, "left_behind") and Quests.has_flag(camp, "story", "told_ambush") and not screen.visible)
	print("fails=", fails)
	quit()

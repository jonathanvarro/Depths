extends SceneTree
## Recruits as people (#118): each role has a few lines in its own voice;
## the hero a line is about says it (the hurt one, the frightened one), once
## a trip; and everyone who makes it back says a word on the results -
## naming anyone who didn't. Args: tag, screenshot dir.

const Recruits := preload("res://scripts/recruits.gd")

var fails := 0


func check(label: String, ok: bool, detail = "") -> void:
	if not ok: fails += 1
	print("PASS " if ok else "FAIL ", label, "  ", detail)


func _unquoted(text: String) -> String:
	return text.trim_prefix("“").trim_suffix("”")


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var tag: String = args[0] if args.size() > 0 else "desk"
	var dir: String = args[1] if args.size() > 1 else ""
	# Every role can speak to every situation the game asks of a recruit.
	var rng := RandomNumberGenerator.new()
	rng.seed = 4
	for role in Recruits.ROLES:
		var recruit: Companion = Recruits.make(rng, [], [], 1, role)
		var missing := []
		for situation in ["fight_start", "fight_won", "hurt", "shaken", "panic", "camp_return", "camp_hurt", "camp_grief"]:
			if recruit.dialogue == null or recruit.dialogue.pick(situation) == "":
				missing.append(situation)
		check("a %s has lines for every situation" % role, missing.is_empty(), str(missing))
	var old := Recruits.make(rng, [], [], 1, "Scout")
	old.dialogue = null  # a recruit from a save made before they could talk
	check("a recruit from an older save speaks in their role's voice", Recruits.lines_for(old) != null and Recruits.lines_for(old).pick("hurt") != "")

	var main = load("res://scenes/main.tscn").instantiate()
	main.play_opening = false
	main.floor_seed = 11
	root.add_child(main)
	await create_timer(0.5).timeout
	var camp = main._camp_state
	for recruit in camp.candidates.duplicate():
		camp.hire(main._party_state, recruit)
	main._refresh_cards()
	main._expedition = main.Expedition.new(main._party_state, 2)  # they set out together
	main._go_to_floor(1, main.Arrival.FROM_ABOVE)
	await process_frame
	var members: Array = main._party_state.members
	check("a party of the hero and recruits", members.size() >= 3, members.size())
	var lead: Companion = members[0]
	var hurt: Companion = members[1]
	var frightened: Companion = members[2]
	# The hurt recruit warns, not the lead.
	main._last_spoke_at = -100.0
	hurt.health = 1
	hurt.emit_changed()
	await process_frame
	var box = main._dialogue_box
	check("the hurt recruit warns about it themself", box._name.text == hurt.display_name and Recruits.lines_for(hurt).lines["hurt"].has(_unquoted(box._text.text)), "%s: %s" % [box._name.text, box._text.text])
	var first: String = box._text.text
	main._last_spoke_at = -100.0
	hurt.emit_changed()
	await process_frame
	check("...once a trip, not every time", box._text.text == first)
	# Nerves fraying: the frightened one says so.
	main._last_spoke_at = -100.0
	frightened.strain = 55.0
	frightened.emit_changed()
	await process_frame
	check("the frightened recruit speaks of it", box._name.text == frightened.display_name and Recruits.lines_for(frightened).lines["shaken"].has(_unquoted(box._text.text)), "%s: %s" % [box._name.text, box._text.text])
	# A fight: anyone standing may call out.
	var voices := {}
	for i in 30:
		voices[main._any_voice()] = true
	check("anyone standing may call out in a fight", voices.size() >= 2, voices.size())
	# Home, without one of them.
	hurt.health = 0
	var said: Dictionary = main._homecoming_lines()
	check("the fallen say nothing", not said.has(hurt))
	var grief: String = said.get(frightened, "")
	check("a recruit who made it back names the one who didn't", grief.contains(hurt.display_name), grief)
	check("the lead's line is theirs or none", not said.has(lead) or said[lead] != "")
	main._end_expedition(main.Expedition.Ending.RETURNED)
	await create_timer(0.3).timeout
	var quotes: Array = main._results._heroes.find_children("*", "Label", true, false).filter(func(l): return l.text.begins_with("“"))
	check("the results show what they said", not quotes.is_empty(), quotes.size())
	if dir != "":
		root.get_texture().get_image().save_png(dir + "/reactions_" + tag + "_results.png")
	main._results.continue_pressed.emit()
	await create_timer(0.5).timeout
	main._camp.cave_chosen.emit(1)  # off again
	await create_timer(0.5).timeout
	check("a new trip clears each hero's once-a-trip remarks", not main._said.keys().any(func(k): return k.contains(":")))
	print("fails=", fails)
	quit()

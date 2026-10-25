extends SceneTree
## Hearing them first (#73, owner 2026-10-25): some ordinary fights are
## heard before they notice the party; the warning names what's ahead and
## offers Fight, Strike first or Back away - and Slip past, a Scout's
## level-2 talent. Striking first puts the party first in round one (or,
## caught out, the foes); backing away keeps the same foes waiting; a
## slip costs time and nerves, and passes them for the trip.
## Args: tag, screenshot dir.

const Progression := preload("res://scripts/progression.gd")
const CS := preload("res://scripts/combat_state.gd")

var fails := 0


func check(label: String, ok: bool, detail = "") -> void:
	if not ok: fails += 1
	print("PASS " if ok else "FAIL ", label, "  ", detail)


func _party(ids := ["mara", "corin"]):
	var party = load("res://scripts/party_state.gd").new()
	for id in ids:
		party.add_member(load("res://data/companions/%s.tres" % id))
	return party


func _labels(main) -> Array:
	return main._prompt_choices.get_children().filter(func(b): return b.visible and not b.is_queued_for_deletion()).map(func(b): return b.text)


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var tag: String = args[0] if args.size() > 0 else "desk"
	var dir: String = args[1] if args.size() > 1 else ""

	# Who goes first in round one.
	var types: Array[EnemyType] = [load("res://data/enemies/goblin_archer.tres"), load("res://data/enemies/goblin.tres")]
	var fight = CS.new(_party(), types)
	fight.set_opening("party")
	check("striking first: the whole party goes first", fight._order.slice(0, 2).all(func(a): return a is Companion), str(fight._order.map(func(a): return a.display_name if a is Companion else a.name)))
	fight.set_opening("foes")
	check("caught out: the foes go first", fight._order.slice(0, 2).all(func(a): return not a is Companion))

	# The Scout's talent.
	var scout_options: Array = Progression.TALENTS["Scout"][2].map(func(t): return t[0])
	var rogue_options: Array = Progression.TALENTS["Rogue"][2].map(func(t): return t[0])
	check("slip past is a Scout's level-2 talent, in place of Deadeye", scout_options == ["slip_past", "quick_hands"], str(scout_options))
	check("Mara the Rogue keeps Deadeye and doesn't get it", "slip_past" not in rogue_options and "deadeye" in rogue_options)

	# In the game.
	var main = load("res://scenes/main.tscn").instantiate()
	main.play_opening = false
	main.floor_seed = 21
	root.add_child(main)
	await create_timer(0.5).timeout
	main._go_to_floor(2, main.Arrival.FROM_ABOVE)
	await process_frame
	var map = main._map
	var fight_cell := Vector2i(-1, -1)
	var door := Vector2i(-1, -1)
	var outside := Vector2i(-1, -1)
	for c in map.encounter_zones:
		var f: Vector2i = map.encounter_zones[c]
		if map.lairs.has(f) or map.fight_groups.has(f):
			continue
		for side in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			if map.is_passable(c + side) and not map.encounter_zones.has(c + side):
				fight_cell = f
				door = c
				outside = c + side
		if fight_cell != Vector2i(-1, -1):
			break
	map.heard[fight_cell] = true
	main._party.place(map, outside)
	main._cell_before = outside
	main._on_party_entered_cell(door)
	check("heard first: a warning, not a fight", main._prompt.visible and not main._in_combat and main._prompt_label.text.begins_with("Ahead, unaware of you:"), main._prompt_label.text)
	check("...naming what's ahead", map.fight_groups.has(fight_cell) and main._prompt_label.text.contains(map.fight_groups[fight_cell][0].display_name.to_lower()))
	check("...Fight, Strike first or Back away; no Scout, no slipping past", _labels(main) == ["Fight", "Strike first", "Back away"], str(_labels(main)))
	var words: String = main._prompt_label.text
	main._answer_prompt(false)  # Escape: back away
	check("backing away: out again, still unaware", not main._in_combat and main._party.cell == outside and not map.triggered.has(fight_cell))
	main._on_party_entered_cell(door)
	check("...and the same foes when you return", main._prompt.visible and main._prompt_label.text == words)
	main._answer_prompt(false)

	# A Scout who has learned to slip past.
	var scout: Companion = load("res://data/companions/corin.tres").duplicate()
	scout.display_name = "Wren"
	scout.role = "Scout"
	scout.talents.assign(["slip_past"])
	main._party_state.add_member(scout)
	main._on_party_entered_cell(door)
	var labels: Array = _labels(main)
	check("with a Scout: Slip past, with its odds", labels.size() == 4 and labels[2].begins_with("Slip past ("), str(labels))
	if dir != "":
		for i in 6:
			await process_frame
		root.get_texture().get_image().save_png("%s/heard_%s.png" % [dir, tag])
	var seed := 1
	while true:  # dice that let them through
		main._rng.seed = seed
		if main._rng.randf() < main._slip_chance():
			break
		seed += 1
	main._rng.seed = seed
	var time: int = main._party_state.time_elapsed
	var strain: float = main._party_state.members[0].strain
	main._prompt.visible = false
	main._party.locked = false
	main._slip_past(fight_cell, scout)
	check("slipping past: through unseen, no fight, gone for the trip", not main._in_combat and map.triggered.has(fight_cell))
	check("...for time and nerves", main._party_state.time_elapsed >= time + main.SLIP_TIME and main._party_state.members[0].strain > strain)
	print("fails=", fails)
	quit()

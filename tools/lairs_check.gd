extends SceneTree
## Mini-boss lairs (#145, owner 2026-10-25): the Broodmother and the gate
## captain are out of the ordinary fight tables for every party size; about
## half of floors 2-4 hold one lair as a side room; its threshold warns,
## and backing away costs nothing; the fight scales only lightly (a full
## party meets one more foe); a win pays magic-or-better gear and gold.
## Args: tag, screenshot dir.

const Packages := preload("res://scripts/packages.gd")
const SaveGame := preload("res://scripts/save_game.gd")

var fails := 0


func check(label: String, ok: bool, detail = "") -> void:
	if not ok: fails += 1
	print("PASS " if ok else "FAIL ", label, "  ", detail)


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var tag: String = args[0] if args.size() > 0 else "desk"
	var dir: String = args[1] if args.size() > 1 else ""
	var main_script = load("res://scripts/main.gd")

	# Out of the ordinary tables, for every party size.
	var bosses := ["Broodmother", "Gate captain"]
	var found := []
	for depth in [1, 2, 3, 4]:
		for size in [1, 2, 3]:
			for group in main_script.encounter_pool(depth, size):
				for type in group:
					if type.display_name in bosses:
						found.append("%d/%d %s" % [depth, size, type.display_name])
	check("no mini-boss in any ordinary fight, any party size", found.is_empty(), str(found))

	# How often, and where.
	var counts := {1: 0, 2: 0, 3: 0, 4: 0}
	var kinds := {2: {}, 3: {}, 4: {}}
	for seed in 400:
		for depth in [1, 2, 3, 4]:
			var lairs: Array = Packages.lairs(depth, seed * 31 + depth)
			counts[depth] += lairs.size()
			if not lairs.is_empty() and depth > 1:
				kinds[depth][lairs[0].lair] = true
	check("never on floor 1", counts[1] == 0)
	check("about half of floors 2-4 hold one", [2, 3, 4].all(func(d): return counts[d] > 160 and counts[d] < 240), str(counts))
	check("a nest on 2, either on 3, a post on 4", kinds[2].keys() == ["brood"] and kinds[3].size() == 2 and kinds[4].keys() == ["captain"], str(kinds))
	check("the story's packages never include a lair", Packages.active(load("res://scripts/camp_state.gd").new(), 3).all(func(p): return p.lair == ""))

	# In the game: a floor 2 with a nest.
	var site := 0
	for s in range(1, 500):
		if not Packages.lairs(2, s + 2 * 7919 + 29).is_empty():
			site = s
			break
	var main = load("res://scenes/main.tscn").instantiate()
	main.play_opening = false
	main.floor_seed = site
	root.add_child(main)
	await create_timer(0.5).timeout
	main._go_to_floor(2, main.Arrival.FROM_ABOVE)
	await process_frame
	var map = main._map
	check("the nest is on the floor", map.lairs.size() == 1, str(map.lairs))
	var nest: Vector2i = map.lairs.keys()[0]
	var lair: QuestPackage = Packages.find(map.lairs[nest])
	var zone: Array = map.encounter_zones.keys().filter(func(c): return map.encounter_zones[c] == nest)
	var door: Vector2i = zone[0]
	var outside := Vector2i(-1, -1)
	for side in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		if map.is_passable(door + side) and not map.encounter_zones.has(door + side):
			outside = door + side
			break
	if outside == Vector2i(-1, -1):  # the room's own edge: step in from its corridor
		for c in zone:
			for side in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
				if map.is_passable(c + side) and not map.encounter_zones.has(c + side):
					door = c
					outside = c + side
	main._party.place(map, outside)
	main._cell_before = outside
	main._on_party_entered_cell(door)
	check("its threshold warns first", main._prompt.visible and main._prompt_label.text == lair.warning and not main._in_combat, main._prompt_label.text)
	check("...with Go in or Back away", main._prompt_buttons.map(func(b): return b.text) == ["Go in", "Back away"])
	if dir != "":
		for i in 6:
			await process_frame
		root.get_texture().get_image().save_png("%s/lairs_%s_warning.png" % [dir, tag])
	main._answer_prompt(false)
	check("backing away costs nothing: out again, the nest untouched", not main._in_combat and main._party.cell == outside and not map.triggered.has(nest), str(main._party.cell))

	# Solo: the Broodmother as she is, no elites.
	main._lair_fight(nest, lair)
	var state = main._combat._state
	check("solo: the Broodmother alone, no elites", state.foes.size() == 1 and state.foes[0].type.display_name == "Broodmother" and state.foes[0].elite == "")
	var CS = load("res://scripts/combat_state.gd")
	check("...and she still calls both hatchlings", state.foes[0].intent == CS.Intent.BROOD and CS.BROOD_HATCHLINGS == 2, str(state.foes[0].intent))
	check("a lair fight resumes as one after loading", main._fight_kind == "lair")

	# The reward.
	var gold: int = main._party_state.supplies.gold
	var gear_before: int = main._party_state.supplies.gear.size()
	main._lair_won()
	var prize: Equipment = main._party_state.supplies.gear.back() if main._party_state.supplies.gear.size() > gear_before else (main._overflow.keys().back() if not main._overflow.is_empty() else null)
	check("its hoard: magic or rare gear, and gold", prize != null and prize.tier in ["magic", "rare"] and main._party_state.supplies.gold == gold + main.LAIR_GOLD + 10, "%s %s" % [prize.display_name if prize else "none", main._party_state.supplies.gold - gold])
	check("the nest is remembered in the save", SaveGame.pack_object(map).has("lairs"))
	main.queue_free()
	await process_frame

	# A full party: one more foe, no more.
	var types: Array[EnemyType] = []
	var full_main = load("res://scenes/main.tscn").instantiate()
	full_main.play_opening = false
	full_main.floor_seed = site
	root.add_child(full_main)
	await create_timer(0.5).timeout
	for id in ["corin", "alwen"]:
		full_main._party_state.add_member(load("res://data/companions/%s.tres" % id))
	full_main._go_to_floor(2, full_main.Arrival.FROM_ABOVE)
	await process_frame
	var cell: Vector2i = full_main._map.lairs.keys()[0]
	full_main._lair_fight(cell, Packages.find(full_main._map.lairs[cell]))
	var names: Array = full_main._combat._state.foes.map(func(f): return f.type.display_name)
	check("a full party: the Broodmother and one spider", names == ["Broodmother", "Spider"], str(names))
	var captain: QuestPackage = Packages.find("lair_captain")
	check("the captain's post: captain and goblin, an archer for a full party", captain.fight.map(func(t): return t.display_name) == ["Gate captain", "Goblin"] and captain.full_party_extra.map(func(t): return t.display_name) == ["Goblin archer"])
	print("fails=", fails)
	quit()

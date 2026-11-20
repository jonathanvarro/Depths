extends SceneTree
## Bodies after a full wipe (#180, owner 2026-11-18): only the main hero
## wakes at camp; the others lie on the floor where they fell until a later
## trip finds them and carries them home to the nurse. Named companions are
## the better hires: two strengths, and gear only they can use.
## Args: tag, screenshot dir.

const NamedCast := preload("res://scripts/named_cast.gd")
const Recruits := preload("res://scripts/recruits.gd")
const Classes := preload("res://scripts/classes.gd")

var fails := 0


func check(label: String, ok: bool, detail = "") -> void:
	if not ok: fails += 1
	print("PASS " if ok else "FAIL ", label, "  ", detail)


func _initialize() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	main.play_opening = false
	main.floor_seed = 11
	main.wandering = false
	main.starting_hero = load("res://data/companions/corin.tres")
	root.add_child(main)
	await create_timer(0.5).timeout
	var ps = main._party_state
	var camp = main._camp_state
	var rng := RandomNumberGenerator.new()
	rng.seed = 5

	# Named against random.
	var branna: Companion = NamedCast.make(camp, "branna")
	var soldier: Companion = Recruits.make(rng, [], [], 1, "Melee")
	check("a named companion has two strengths, a random soldier one", branna.strength.split("; ").size() == 2 and soldier.strength.split("; ").size() == 1, [branna.strength, soldier.strength])
	var own := Equipment.new()
	own.display_name = "Branna's lamp"
	own.named_for = "branna"
	check("...and gear of her own only she can use", Classes.refuses(branna, own) == "" and Classes.refuses(soldier, own) != "", Classes.refuses(soldier, own))

	ps.add_member(branna)
	ps.add_member(soldier)
	var b: Companion = ps.members[1]
	var s: Companion = ps.members[2]
	var corin: Companion = ps.members[0]
	main._go_to_floor(1, main.Arrival.FROM_ABOVE)
	main._go_to_floor(2, main.Arrival.FROM_ABOVE)
	await process_frame
	for hero in ps.members:
		hero.health = 0
	main._end_expedition(main.Expedition.Ending.WIPED)
	await create_timer(0.3).timeout
	main._results.continue_pressed.emit()
	await create_timer(0.5).timeout
	check("a wipe: the main hero wakes at camp, alone", ps.members.size() == 1 and ps.members[0] == corin and corin.health > 0)
	check("...the others lie on floor 2", camp.bodies_on(2).size() == 2 and b in camp.bodies_on(2) and s in camp.bodies_on(2) and camp.fallen.is_empty())
	var data: Dictionary = main._save_data()
	check("a save keeps where they lie", data["lost_bodies"].size() == 2 and data["lost_bodies"].all(func(p): return p[1] == 2))

	# A later trip goes down to floor 2.
	main._camp.visible = false
	main._ending = false
	main._party.locked = false
	main._go_to_floor(2, main.Arrival.FROM_ABOVE)
	await process_frame
	var lying: Dictionary = main._map.marks.get("bodies", {})
	check("floor 2 has both bodies, lying in the way", lying.size() == 2 and lying.keys().all(func(c): return main._map.solid.has(c)), lying)
	check("...with something to see", lying.keys().all(func(c): return main._level.get_node_or_null("Body_%d_%d" % [c.x, c.y]) != null))
	main._go_to_floor(1, main.Arrival.FROM_BELOW)
	check("floor 1 has none", main._map.marks.get("bodies", {}).is_empty())
	main._go_to_floor(2, main.Arrival.FROM_ABOVE)
	check("...and they're still there on the way back", main._map.marks.get("bodies", {}).size() == 2)
	var first: Vector2i = main._map.marks["bodies"].keys()[0]
	main._on_party_interacted(first)
	check("walking into one: wrapped and carried", camp.carried.size() == 1 and camp.bodies_on(2).size() == 1 and not main._map.solid.has(first))

	# Wiped again while carrying: that body lies here too.
	camp.drop_carried(2)
	check("wiped while carrying: they fall with the party", camp.carried.is_empty() and camp.bodies_on(2).size() == 2)
	main._go_to_floor(1, main.Arrival.FROM_BELOW)
	main._go_to_floor(2, main.Arrival.FROM_ABOVE)
	for cell in main._map.marks.get("bodies", {}).keys():
		main._on_party_interacted(cell)
	check("both picked up", camp.carried.size() == 2 and camp.bodies_on(2).is_empty())
	main._start_new_expedition()
	await create_timer(0.3).timeout
	check("home: both go to the nurse's tent", camp.fallen.size() == 2 and camp.carried.is_empty())
	print("fails=", fails)
	quit()

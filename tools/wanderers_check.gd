extends SceneTree
## Wandering monsters (owner, 2026-10-26): quiet on arrival, then likelier
## the longer the party lingers, sooner and more often deeper down, none in
## the fortress; a sound gives a few steps' warning; noisy events stir them
## at once; they're the floor's usual foes, never elites, and find a party
## in the dark first. Args: tag, screenshot dir.

const Wanderers := preload("res://scripts/wanderers.gd")
const RoomEvents := preload("res://scripts/room_events.gd")
const Supplies := preload("res://scripts/supplies.gd")
const DungeonMap := preload("res://scripts/dungeon_map.gd")

var fails := 0


func check(label: String, ok: bool, detail = "") -> void:
	if not ok: fails += 1
	print("PASS " if ok else "FAIL ", label, "  ", detail)


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var tag: String = args[0] if args.size() > 0 else "desk"
	var dir: String = args[1] if args.size() > 1 else ""

	# The rule.
	check("quiet on arrival", Wanderers.chance(1, -1) == 0.0 and Wanderers.chance(1, 0) > 0.0)
	check("deeper stirs sooner and more often", Wanderers.WANDER[3][0] < Wanderers.WANDER[1][0] and Wanderers.chance(3, 0) > Wanderers.chance(1, 0) and Wanderers.chance(3, 999) > Wanderers.chance(1, 999))
	check("likelier the longer you linger, up to a cap", Wanderers.chance(2, 40) > Wanderers.chance(2, 0) and Wanderers.chance(2, 999) == Wanderers.WANDER[2][2])
	check("nothing wanders the fortress", not Wanderers.roams(4) and Wanderers.chance(4, 999) == 0.0)

	# The clock.
	var w := Wanderers.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	w.arrive_on(1, 100)
	var stirred_at := -1
	for t in range(101, 400):
		if w.step(t, rng) == "stir":
			stirred_at = t - 100
			break
	check("nothing in the quiet spell; something before long", stirred_at > Wanderers.WANDER[1][0], stirred_at)
	check("...they arrive a few steps after you hear them", w.step(400, rng) == "" and w.step(401, rng) == "" and w.step(402, rng) == "arrive")
	check("...then a breather", w.quiet == Wanderers.BREATHER and w.coming == -1)
	w.arrive_on(2, 500)
	check("a noise stirs them at once", w.stir() and w.coming == Wanderers.WARNING_STEPS and not w.stir())
	w.coming = 1
	check("not on a room's content: a step later", w.step(501, rng, false) == "" and w.step(502, rng, true) == "arrive")
	w.arrive_on(4, 600)
	check("the fortress stays still", not w.stir() and w.step(9999, rng) == "")

	# Noisy events.
	var stones: RoomEvent = load("res://data/events/trap_tripwire.tres")
	var bell: RoomEvent = load("res://data/events/trap_bell_wire.tres")
	check("falling stones and a rung bell stir them", stones.sprung.stirs and bell.sprung.alarm)
	var party = load("res://scripts/party_state.gd").new()
	party.add_member(load("res://data/companions/mara.tres"))
	var rules := RoomEvents.new()
	var choice := EventChoice.new()
	choice.outcomes.assign([stones.sprung])
	rules.resolve(party, choice)
	check("...the event says so", rules.stirred)

	# In the game.
	var main = load("res://scenes/main.tscn").instantiate()
	main.play_opening = false
	main.floor_seed = 11
	root.add_child(main)
	await create_timer(0.5).timeout
	main._go_to_floor(2, main.Arrival.FROM_ABOVE)
	await process_frame
	check("a new floor starts the clock", main._wanderers.depth == 2 and main._wanderers.quiet == Wanderers.WANDER[2][0])
	main._wanderers.coming = 2
	main._wanderers.since = 17
	var saved: Dictionary = main._save_data()
	var restored := Wanderers.new()
	load("res://scripts/save_game.gd").unpack_into(restored, saved.get("wanderers", {}))
	check("the clock is saved with the game", restored.coming == 2 and restored.since == 17 and restored.depth == 2)
	main._wanderers.coming = -1
	main._room_events.stirred = true
	main._wanderers_stirred()
	check("a noisy event: they're coming, and you hear it", main._wanderers.coming == Wanderers.WARNING_STEPS and main._message_label.text.contains("heard that"), main._message_label.text)
	var clear := Vector2i(-1, -1)
	for c in main._map.walking_distances(main._party.cell):
		if main._map.content_at(c) == DungeonMap.Content.NONE and not main._map.encounter_zones.has(c) and c != main._party.cell:
			clear = c
			break
	main._party.place(main._map, clear)
	main._wanderers.coming = 1
	main._on_party_entered_cell(clear)
	await process_frame
	check("they find you: a fight where you stand", main._in_combat and main._fight_kind == "wander")
	var state = main._combat._state
	check("...the floor's usual foes, never elites", state != null and state.foes.all(func(f): return f.elite == ""))
	if dir != "":
		for i in 8:
			await process_frame
		root.get_texture().get_image().save_png("%s/wanderers_%s.png" % [dir, tag])
	print("fails=", fails)
	quit()

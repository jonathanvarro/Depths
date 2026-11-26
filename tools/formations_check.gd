extends SceneTree
## Party formations (#305, owner 2026-11-26): named at the fire with their
## bonus and blind spots, set when the party leaves camp, stepping down when
## a hero falls and back when they get up. Args: tag, screenshot dir.

const Formations := preload("res://scripts/formations.gd")
const Recruits := preload("res://scripts/recruits.gd")
const PartyState := preload("res://scripts/party_state.gd")

var fails := 0
var rng := RandomNumberGenerator.new()


func check(label: String, ok: bool, detail = "") -> void:
	if not ok: fails += 1
	print("PASS " if ok else "FAIL ", label, "  ", detail)


func _snap(path: String) -> void:
	for i in 4:
		await process_frame
	var image := root.get_texture().get_image()
	if image:
		image.save_png(path)


func hero(role: String) -> Companion:
	return Recruits.make(rng, [], [], 1, role)


func party_of(roles: Array):
	var party = PartyState.new()
	for role in roles:
		party.add_member(hero(role))
	return party


func _initialize() -> void:
	rng.seed = 305
	# Naming.
	check("three Soldiers make a Shield Wall", Formations.of([hero("Melee"), hero("Melee"), hero("Melee")]).get("name") == "Shield Wall")
	check("three Scouts are Pathfinders, three Sappers a Tunnel Crew, three Acolytes a Vigil",
			Formations.of([hero("Scout"), hero("Scout"), hero("Scout")]).get("name") == "Pathfinders"
			and Formations.of([hero("Fixer"), hero("Fixer"), hero("Fixer")]).get("name") == "Tunnel Crew"
			and Formations.of([hero("Mage"), hero("Mage"), hero("Mage")]).get("name") == "Vigil")
	check("two of a kind make a pair", Formations.of([hero("Melee"), hero("Melee"), hero("Scout")]).get("id") == "pair:Melee")
	check("three different classes are a Survey Party", Formations.of([hero("Melee"), hero("Scout"), hero("Fixer")]).get("name") == "Survey Party")
	check("two different classes make none", Formations.of([hero("Melee"), hero("Scout")]).is_empty())
	var wall: Array = Formations.describe([hero("Melee"), hero("Melee"), hero("Melee")])
	check("the fire shows a Shield Wall's bonus and its blind spots", wall[0] == "Shield Wall" and wall[1].contains("lighter") and wall[2].contains("No Scout") and wall[2].contains("No Sapper") and wall[2].contains("No Acolyte") and not wall[2].contains("No Soldier"), wall)

	# Set out, step down, step back up.
	var party = party_of(["Melee", "Melee", "Melee"])
	check("no formation before setting out", party.formation().is_empty())
	party.set_out_formation()
	check("set out as a Shield Wall", party.formation().get("name") == "Shield Wall")
	check("...every blow lands 1 lighter", party.members.all(func(h): return party.formation_guard(h) == 1))
	var fallen: Companion = party.members[2]
	fallen.main_hero = true
	fallen.health = 0
	check("a hero knocked out steps it down to the pair", party.formation().get("id") == "pair:Melee", party.formation())
	party.members[0].row = "front"
	party.members[1].row = "back"
	check("...a Spearhead guards the front row only", party.formation_guard(party.members[0]) == 1 and party.formation_guard(party.members[1]) == 0)
	fallen.health = 5
	check("back on their feet: the Shield Wall again", party.formation().get("name") == "Shield Wall")
	fallen.main_hero = false
	fallen.health = 0
	check("a death steps it down for good", party.formation().get("id") == "pair:Melee" and not fallen.is_with_party())
	var newcomer: Companion = hero("Melee")
	party.remove_member(fallen)
	party.add_member(newcomer)
	check("someone taken on below doesn't restore it", party.formation().get("id") == "pair:Melee")

	# Vigil, Survey Party.
	var vigil = party_of(["Mage", "Mage", "Mage"])
	var before: int = vigil.members[0].casts
	vigil.set_out_formation()
	check("a Vigil's Acolytes set out with an extra prayer", vigil.members.all(func(h): return h.casts == before + 1), [before, vigil.members[0].casts])
	check("...and nerves fray a quarter slower", is_equal_approx(vigil.members[0].party_calm, 0.75))
	var survey = party_of(["Melee", "Scout", "Fixer"])
	survey.set_out_formation()
	check("a Survey Party's nerves and lantern oil last longer", is_equal_approx(survey.members[0].party_calm, 0.9) and is_equal_approx(survey.oil_rate(), 0.9))
	var gang = party_of(["Fixer", "Fixer", "Scout"])
	gang.set_out_formation()
	check("a Work Gang finds an extra treasure", gang.formation_finds() == 1 and not gang.tunnel_crew())
	var lookouts = party_of(["Scout", "Scout", "Melee"])
	lookouts.set_out_formation()
	check("Lookouts map rooms but aren't Pathfinders", lookouts.maps_rooms() and not lookouts.pathfinders())

	# In the game.
	var main = load("res://scenes/main.tscn").instantiate()
	main.play_opening = false
	main.wandering = false
	main.floor_seed = 305
	root.add_child(main)
	await create_timer(0.5).timeout
	var ps = main._party_state
	for m in ps.members.duplicate():
		ps.remove_member(m)
	for role in ["Scout", "Scout", "Scout"]:
		ps.add_member(hero(role))
	ps.set_out_formation()
	main._formation_id = ps.formation()["id"]
	check("Pathfinders hear every fight first", ps.pathfinders())
	var room_cell := Vector2i(-1, -1)
	for y in main._map.height:
		for x in main._map.width:
			var c := Vector2i(x, y)
			if room_cell.x < 0 and main._map._is_room_cell(c) and main._map.room_around(c).size() > 12 and not main._map.explored.has(c):
				room_cell = c
	main._map_room(room_cell)
	check("...and a room maps in full on entering", main._map.room_around(room_cell).all(func(c): return main._map.explored.has(c)), room_cell)
	check("...and wandering packs show on the map", main._sensed_cells().size() == main._groups.size())
	# Stepping down underground is announced.
	ps.members[0].main_hero = true
	ps.members[0].health = 0
	main._note_formation()
	check("a fall is noticed: Lookouts now", main._formation_id == "pair:Scout")
	ps.members[0].health = 6
	main._note_formation()
	check("...and getting up restores the Pathfinders", main._formation_id == "pure:Scout")

	# A Tunnel Crew forces the Jail's cell without its key.
	for m in ps.members.duplicate():
		ps.remove_member(m)
	for role in ["Fixer", "Fixer", "Fixer"]:
		ps.add_member(hero(role))
	ps.set_out_formation()
	main._go_to_area("jail", main.Arrival.FROM_ABOVE)
	var lock: Dictionary = {}
	for p in main._map.marks.get("puzzles", []):
		if p["kind"] == "key":
			lock = p
	var t: int = ps.time_elapsed
	main._work_puzzle(lock["door"])
	check("a Tunnel Crew forces a locked door without the key, at a cost in time", lock["open"] and not lock["held"] and ps.time_elapsed == t + Formations.PICK_TIME)

	# The preparation screen names it.
	main._preparation.show_for(2, ps)
	var shown: Array = main._preparation._formation.get_children().map(func(l): return l.text)
	check("the preparation screen names the formation and its blind spots", shown.size() == 3 and shown[0] == "Tunnel Crew" and shown[2].contains("No Soldier"), shown)
	var args := OS.get_cmdline_user_args()
	if args.size() > 1:
		await _snap(args[1] + "/formation_prep.png")
	main._preparation.visible = false
	# At the fire: the lineup names the formation; a picked recruit previews theirs.
	ps.remove_member(ps.members[2])
	main._camp.open(main._camp_state, ps)
	main._camp.open_activity("fire")
	await process_frame
	var recruit: Companion = main._camp_state.candidates[0] if not main._camp_state.candidates.is_empty() else null
	if recruit:
		main._camp._picked_recruit = recruit
		main._camp._refresh_activity()
		await process_frame
		var hint: String = main._camp._lineup_hint()
		check("picking a recruit at the fire previews the formation they'd make", hint.contains("Together: " + Formations.of(ps.members + [recruit]).get("name", "?")) or Formations.of(ps.members + [recruit]).is_empty(), hint)
	if args.size() > 1:
		await create_timer(2.5).timeout  # past the camp's arrival message
		await _snap(args[1] + "/formation_fire.png")
	print("fails=", fails)
	quit()

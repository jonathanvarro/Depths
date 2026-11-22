extends SceneTree
## Named elite packs (owner, 2026-11-22; scripts/elites.gd): a floor's
## chance of one named pack that patrols with its own glow, fights far
## harder than the floor's other monsters and leaves a hoard. Ordinary fights
## no longer roll random elites. Args: tag, screenshot dir.

const Elites := preload("res://scripts/elites.gd")
const CombatState := preload("res://scripts/combat_state.gd")
const PartyState := preload("res://scripts/party_state.gd")

var fails := 0
var shots := ""


func check(label: String, ok: bool, detail = "") -> void:
	if not ok: fails += 1
	print("PASS " if ok else "FAIL ", label, "  ", detail)


func _snap(name: String) -> void:
	if shots == "":
		return
	await create_timer(1.0).timeout
	var image := root.get_texture().get_image()
	if image:
		image.save_png(shots + "/elite_" + name + ".png")


func _all_kinds() -> Dictionary:
	var book := {}
	for file in DirAccess.get_files_at("res://data/enemies"):
		if file.ends_with(".tres"):
			book[load("res://data/enemies/" + file).display_name] = {"killed": 1}
	return book


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	shots = args[1] if args.size() > 1 else ""
	# --- Rules ---------------------------------------------------------------
	var rng := RandomNumberGenerator.new()
	var found := {}
	var floor_hits := {}
	for depth in [1, 2, 3, 4, 5]:
		floor_hits[depth] = 0
		for s in 400:
			rng.seed = s * 31 + depth
			var id: String = Elites.pick(depth, rng, null)
			if id != "":
				found[id] = true
				floor_hits[depth] += 1
				if depth not in Elites.PACKS[id]["floors"]:
					check("a pack only on its own floors", false, [id, depth])
	check("every pack turns up somewhere", found.size() == Elites.PACKS.size(), found.keys())
	check("some floors have one, most don't", floor_hits.values().all(func(n): return n > 40 and n < 260), floor_hits)
	rng.seed = 3
	var none_beaten := 0
	for s in 200:
		if Elites.pick(1, rng, []) != "":
			none_beaten += 1
	check("no named pack before its kinds have been beaten (#226)", none_beaten == 0)

	var party = PartyState.new()
	party.add_member(load("res://data/companions/mara.tres"))
	var plain = CombatState.new(party, Elites.types("whisker"))
	plain.prepare(1)
	var named = CombatState.new(party, Elites.types("whisker"))
	named.prepare(1, "elite")
	Elites.empower(named, "whisker")
	var leader = named.foes[0]
	check("the leader takes its name", leader.name == "Old Whisker", leader.name)
	check("...is far tougher than its kind", leader.type.max_health >= plain.foes[0].type.max_health * 1.9 and leader.type.damage_max > plain.foes[0].type.damage_max, [leader.type.max_health, plain.foes[0].type.max_health])
	check("...and its brood carry a mark each", named.foes.slice(1).all(func(f): return f.elite != ""))
	var random_elites := 0
	for s in 200:
		var fight = CombatState.new(party, Elites.types("skarn"))
		fight.rng.seed = s
		fight.beaten = null
		fight.prepare(4)
		random_elites += fight.foes.filter(func(f): return f.elite != "").size()
	check("ordinary fights no longer roll random elites", random_elites == 0, random_elites)

	# --- In the game -------------------------------------------------------
	var main = load("res://scenes/main.tscn").instantiate()
	main.play_opening = false
	main.wandering = false
	main.floor_seed = 900
	root.add_child(main)
	await create_timer(0.5).timeout
	main._camp_state.bestiary = _all_kinds()
	var seed_found := -1
	for s in 200:
		main._site_seed = 900 + s
		main._floors.clear()
		main._go_to_floor(2, main.Arrival.FROM_ABOVE)
		if not main._map.marks.get("elite", {}).is_empty():
			seed_found = main._site_seed
			break
	check("a floor 2 with a named pack", seed_found != -1)
	if seed_found == -1:
		print("fails=", fails)
		quit()
		return
	await create_timer(0.3).timeout
	var groups: Array = main._groups.filter(func(g): return g.named != "")
	check("it stands on the map", groups.size() == 1)
	var group = groups[0]
	check("...glowing in its own colour", is_instance_valid(group.node) and group.node.get_node_or_null("EliteGlow") != null)
	var start: Vector2i = group.cell
	main._party.place(main._map, main._map.find_content(main.DungeonMap.Content.STAIRS_UP))
	for i in 12:
		if group.noticed:
			break
		main._map_beat(main._party.cell)
	check("...and walks its patrol while it hasn't seen you", group.cell != start or group.noticed, [start, group.cell])
	if shots != "":
		main._party.place(main._map, group.cell + Vector2i(0, 0))
		var near: Vector2i = group.cell
		for n in [Vector2i(2, 0), Vector2i(-2, 0), Vector2i(0, 2), Vector2i(0, -2)]:
			if main._map.is_passable(group.cell + n) and main._map.is_passable(group.cell + n / 2):
				near = group.cell + n
				break
		main._party.place(main._map, near)
		main._face_toward(near + (group.cell - near) / 2)
		main._map.reveal_around(near, 3)
		await _snap("glow")

	# Run from it: it walks on. Beat it: it's gone, with its hoard.
	main._engaged = group
	main._map_fight_over(false)
	check("run from it, and it walks on, not gone", group in main._groups and not group.noticed)
	main._elite_id = group.named
	main._engaged = group
	var chests_before: Array = main._map.contents.keys()
	main._elite_won()
	main._map_fight_over(true)
	var left: Array = main._map.contents.keys().filter(func(c): return c not in chests_before)
	check("beaten: its hoard, a gilded chest, is left where it fell", left.size() == 1 and load("res://scripts/chest_tiers.gd").tier_at(main._map, left[0]) == "gold", left)
	check("...and it doesn't come back on this floor today", main._map.marks["elite"]["beaten"] and not main._groups.any(func(g): return g.named != ""))
	main._spawn_room_groups()
	check("...even when the floor's monsters are set out again", not main._groups.any(func(g): return g.named != ""))
	print("fails=", fails)
	quit()

extends SceneTree
## Fights on the map, phase 1 (#171, owner 2026-10-30/31): room monsters
## stand in their rooms; they notice the party by sight or when it walks in;
## noticed, they close a cell each beat (a step or a Wait; turning is free);
## beside the party the fight begins; walking up to one that hasn't seen
## you strikes first; wanderers appear out of sight and hunt; beaten groups
## are gone, ones you ran from go home. Args: tag, screenshot dir.

const Roamers := preload("res://scripts/roamers.gd")
const DungeonMap := preload("res://scripts/dungeon_map.gd")

var fails := 0


func check(label: String, ok: bool, detail = "") -> void:
	if not ok: fails += 1
	print("PASS " if ok else "FAIL ", label, "  ", detail)


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var tag: String = args[0] if args.size() > 0 else "desk"
	var dir: String = args[1] if args.size() > 1 else ""

	# The rules on a small map.
	var map = DungeonMap.new(PackedStringArray([
		"#########",
		"#<......#",
		"#.#####.#",
		"#.......#",
		"#########"]), 2)
	check("sight runs along an open line", Roamers.sees(map, Vector2i(1, 1), Vector2i(5, 1), 5))
	check("...not round corners", not Roamers.sees(map, Vector2i(1, 1), Vector2i(3, 3), 9))
	check("...and only as far as the light", not Roamers.sees(map, Vector2i(1, 1), Vector2i(7, 1), Roamers.SIGHT[0]))
	var g := Roamers.Group.new()
	g.cell = Vector2i(7, 3)
	g.noticed = true
	check("a hunter closes one cell", Roamers.step_toward(map, g, Vector2i(1, 1), {}) and g.cell in [Vector2i(6, 3), Vector2i(7, 2)], g.cell)
	g.cell = Vector2i(2, 1)
	check("...and stops beside the party", not Roamers.step_toward(map, g, Vector2i(1, 1), {}))

	# Phase 2's rules: the party as one unit, facing a way.
	var party = load("res://scripts/party_state.gd").new()
	party.add_member(load("res://data/companions/mara.tres").duplicate())
	party.add_member(load("res://data/companions/alwen.tres").duplicate())
	var mara: Companion = party.members[0]
	var alwen: Companion = party.members[1]
	mara.row = "front"
	alwen.row = "back"
	var hit_hard: EnemyType = load("res://data/enemies/breach_hound.tres").duplicate()
	hit_hard.damage_min = 4
	hit_hard.damage_max = 4
	hit_hard.accuracy = 1.0
	var three: Array[EnemyType] = [hit_hard, hit_hard, hit_hard]
	var state = load("res://scripts/combat_state.gd").new(party, three)
	state.field = true
	state.party_cell = Vector2i(5, 5)
	state.facing = Vector2i.UP
	var ahead = state.foes[0]
	var beside = state.foes[1]
	var behind = state.foes[2]
	ahead.cell = Vector2i(5, 4)
	beside.cell = Vector2i(6, 5)
	behind.cell = Vector2i(5, 6)
	check("sides: ahead, beside, behind", state.side_of(ahead) == "front" and state.side_of(beside) == "side" and state.side_of(behind) == "rear")
	check("a blow from ahead finds the front row", state.foe_can_reach(ahead, mara) and not state.foe_can_reach(ahead, alwen))
	check("...from the side or behind, the back row", state.foe_can_reach(beside, alwen) and not state.foe_can_reach(beside, mara) and state.foe_can_reach(behind, alwen))
	behind.intent = load("res://scripts/combat_state.gd").Intent.BITE
	behind.marked_cell = Vector2i(-1, -1)
	var before_hp: int = alwen.health
	var out: Dictionary = state.enemy_act(behind)
	check("...and harder from behind", out.get("behind", false) and before_hp - alwen.health >= 5, "%d damage" % (before_hp - alwen.health))
	alwen.health = alwen.max_health
	ahead.intent = load("res://scripts/combat_state.gd").Intent.HEAVY
	ahead.marked_cell = state.party_cell
	state.party_cell = Vector2i(5, 6) + Vector2i(1, 0)  # stepped aside
	out = state.enemy_act(ahead)
	check("stepping off a marked tile dodges the blow", out.get("dodged", false), out.get("text", ""))
	state.party_cell = Vector2i(5, 5)
	var strikes: Array = state.unit_strike()
	check("Strike: the front row hits the one it faces", strikes.size() == 1 and strikes[0]["hero"] == mara)
	alwen.weapon = null  # her own reach, not her weapon's
	alwen.reach = true
	ahead.health = 0
	behind.cell = Vector2i(5, 3)
	check("Shoot: the back row's reach carries along the line ahead", state.shooters(behind).has(alwen))
	var far: EnemyType = load("res://data/enemies/rat.tres")
	var lone: Array[EnemyType] = [far]
	var far_state = load("res://scripts/combat_state.gd").new(party, lone)
	far_state.field = true
	far_state.party_cell = Vector2i(5, 5)
	far_state.foes[0].cell = Vector2i(5, 2)
	far_state.foes[0].intent = load("res://scripts/combat_state.gd").Intent.LUNGE
	check("a foe out of reach must close in first", not far_state.foe_in_range(far_state.foes[0]))

	# In the game.
	var main = load("res://scenes/main.tscn").instantiate()
	main.play_opening = false
	main.floor_seed = 11
	main.wandering = false
	root.add_child(main)
	await create_timer(0.5).timeout
	main._go_to_floor(2, main.Arrival.FROM_ABOVE)
	await process_frame
	var groups: Array = main._groups
	check("a floor's room fights stand on the map", not groups.is_empty() and groups.all(func(gr): return gr.cell == gr.home and is_instance_valid(gr.node)), groups.size())
	if dir != "":
		var first = groups[0]
		for side in [Vector2i.DOWN, Vector2i.UP, Vector2i.LEFT, Vector2i.RIGHT]:
			var at: Vector2i = first.cell + side * 2
			if main._map.is_passable(at) and Roamers.sees(main._map, at, first.cell, 3):
				main._party.place(main._map, at)
				main._party.facing = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT].find(-side)
				main._party.rotation.y = -main._party.facing * PI / 2.0
				break
		for i in 8:
			await process_frame
		var image := root.get_texture().get_image()
		if image:
			image.save_png("%s/map_fights_%s.png" % [dir, tag])

	# Ran from, beaten.
	var group = groups[0]
	var home: Vector2i = group.home
	group.cell = home + Vector2i(0, 0)
	main._engaged = group
	group.noticed = true
	main._map_fight_over(false)
	check("a group you ran from goes home, unaware", group.cell == home and not group.noticed and main._groups.has(group))
	main._engaged = group
	main._map_fight_over(true)
	check("a beaten group is gone", not main._groups.has(group))

	# Wanderers.
	main._spawn_wanderer()
	var wanderer = main._groups[-1]
	var walk: Dictionary = main._map.walking_distances(main._party.cell)
	check("a wanderer appears a few steps off, already hunting", wanderer.is_wanderer() and wanderer.noticed and walk.get(wanderer.cell, 99) >= Roamers.SPAWN_DISTANCE.x, walk.get(wanderer.cell, 99))

	# Hunting: each Wait brings it a step closer, then the fight.
	for gr in main._groups.duplicate():
		if gr != wanderer:
			main._groups.erase(gr)
			gr.node.queue_free()
	var time_before: int = main._party_state.time_elapsed
	var before: int = walk.get(wanderer.cell, 99)
	main._wait()
	walk = main._map.walking_distances(main._party.cell)
	check("Wait lets a beat pass", main._party_state.time_elapsed > time_before)
	check("...and the hunter closes in", walk.get(wanderer.cell, 99) == before - 1, "%d -> %d" % [before, walk.get(wanderer.cell, 99)])
	var beats := 0
	while not main._in_combat and beats < 20:
		main._wait()
		beats += 1
	check("beside the party, the fight begins", main._in_combat and main._fight_kind == "wander", beats)
	var fight = main._combat._state
	check("...right there on the map, not on the stage", fight.field and not main._stage.visible if "visible" in main._stage else fight.field)
	check("...its foes standing in cells of their own", fight.foes.all(func(f): return f.cell != Vector2i(-1, -1)) and fight.foes.map(func(f): return f.cell).size() == fight.foes.size())
	check("...the one that reached you, ahead", fight.side_of(fight.foes[0]) == "front")
	for i in 40:
		if main._combat.awaiting_field_action:
			break
		await process_frame
	check("the party's one action: Strike, Shoot, Brace, Item, Wait, Retreat", main._combat.awaiting_field_action and main._combat._field_buttons.visible and main._touch_pad.visible)
	if dir != "":
		for i in 20:
			await process_frame
		var shot := root.get_texture().get_image()
		if shot:
			shot.save_png("%s/map_fights_%s_fight.png" % [dir, tag])
	var round_before: int = fight.round
	main._combat._action_chosen.emit({"kind": "wait"})
	for i in 80:  # up to 8 s: the foes' turns play their animations
		if main._combat.awaiting_field_action or fight.result != 0:
			break
		await create_timer(0.1).timeout
	check("...then the foes act or close in, and a new round", fight.round == round_before + 1 or fight.result != 0)
	print("fails=", fails)
	quit()

extends SceneTree
## The goblin fortress and its queen (#44): new enemies' rules, floor 4's
## gate and hall, the queen fight (no retreat, guards, rage), victory, the
## bounty, and lasting progress across days. Args: tag, screenshot dir.

var fails := 0
var main
var dir := ""
var tag := "desk"


func check(label: String, ok: bool, detail = "") -> void:
	if not ok: fails += 1
	print("PASS " if ok else "FAIL ", label, "  ", detail)


func _press(node, label: String) -> bool:
	for b in node.find_children("*", "Button", true, false):
		if b.text.begins_with(label) and b.is_visible_in_tree() and not b.disabled:
			b.pressed.emit()
			return true
	return false


func _snap(name: String) -> void:
	if dir == "":
		return
	for i in 4:
		await process_frame
	root.get_texture().get_image().save_png(dir + "/fortress_" + tag + "_" + name + ".png")


## Wins the fight in progress: every foe falls, then one Attack ends it.
func _win_fight() -> void:
	var guard := 0
	while main._in_combat and guard < 200:
		guard += 1
		if main._combat._actions.visible:
			for foe in main._combat._state.foes:
				foe.health = 0
			main._combat._state._check_end()
			main._combat._action_chosen.emit({"kind": "defend"})
		await create_timer(0.1).timeout


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	tag = args[0] if args.size() > 0 else "desk"
	dir = args[1] if args.size() > 1 else ""
	# The hall never swallows the stairs up, where parties arrive, nor turns
	# a room's contents into a gate (found by the campaign playtest).
	var FG = load("res://scripts/floor_generator.gd")
	var DM = load("res://scripts/dungeon_map.gd")
	var lost := 0
	for s in 400:
		var layout: PackedStringArray = FG.generate(s * 7919 + 1, false, 4)
		var before = DM.new(layout, 4)
		var fortified: Dictionary = load("res://scripts/fortress.gd").fortify(layout, false)
		var after = DM.new(fortified["layout"], 4)
		var gone: bool = after.find_content(DM.Content.STAIRS_UP) != before.find_content(DM.Content.STAIRS_UP) or fortified["hall"].is_empty()
		for gate in fortified["gates"]:
			if before.contents.has(gate):
				gone = true
		if gone:
			lost += 1
	check("over 400 caves, floor 4 keeps its stairs up and a hall", lost == 0, "%d lost" % lost)
	var CS = load("res://scripts/combat_state.gd")
	var PS = load("res://scripts/party_state.gd")
	var queen: EnemyType = load("res://data/enemies/goblin_queen.tres")
	var guard: EnemyType = load("res://data/enemies/goblin_guard.tres")
	var archer: EnemyType = load("res://data/enemies/goblin_archer.tres")

	# Rules.
	var p = PS.new()
	for name in ["A", "B"]:
		var h := Companion.new(); h.display_name = name; h.max_health = 40; h.health = 40; h.accuracy = 1.0
		p.add_member(h)
	p.members[1].row = "back"
	var c = CS.new(p, [queen, archer] as Array[EnemyType])
	var q = c.foes[0]
	var a = c.foes[1]
	var joined := []
	c.foe_joined.connect(func(f): joined.append(f))
	q.intent = CS.Intent.CALL
	c.enemy_act(q)
	check("the queen calls a guard into the fight", joined.size() == 1 and joined[0].type == guard and c.foes.size() == 3)
	check("guards stand in front, the queen and archers behind", not joined[0].in_back() and q.in_back() and a.in_back())
	var hits_back := 0
	for i in 100:
		a.intent = CS.Intent.SHOOT
		if c.enemy_act(a).get("target") == p.members[1]: hits_back += 1
		for h in p.members: h.health = 40
	check("archers reach the back row", hits_back > 20, "%d/100" % hits_back)
	var front: Companion = p.members[0]
	front.weapon = load("res://data/gear/simple_spear.tres")  # reach, to hit the back row
	front.strain = 0.0  # the archer's hits rattled them; measure the wall, not nerves
	var walled := []
	var open := []
	for i in 40:
		a.health = a.type.max_health
		var out: Dictionary = c.hero_attack(front, a)
		if out["hit"]: walled.append(out["damage"])
	joined[0].health = 0  # the guard falls
	for i in 40:
		a.health = a.type.max_health
		var out: Dictionary = c.hero_attack(front, a)
		if out["hit"]: open.append(out["damage"])
	check("the guard wall halves damage to those behind it", not walled.is_empty() and walled.max() <= 2 and open.max() >= 4, "walled %s, open %s" % [walled.max(), open.max()])
	joined[0].health = joined[0].type.max_health
	q.health = q.type.max_health / 2
	c.plan(q)
	check("at half health the queen is enraged and steps forward", q.enraged and not q.in_back())
	var cleavers := 0
	for i in 400:
		q.intent = CS.Intent.SWING
		c.plan(q)
		if q.intent == CS.Intent.CLEAVER: cleavers += 1
	check("an enraged queen swings the cleaver often", cleavers > 100, "%d/400" % cleavers)

	# In game: floor 4.
	main = load("res://scenes/main.tscn").instantiate()
	main.play_opening = false
	main.floor_seed = 23
	main.simulate_phone_safe_area = tag == "phone"
	root.add_child(main)
	await create_timer(0.5).timeout
	check("the cave has four floors", main.floors_in_site == 4)
	main._go_to_floor(3, main.Arrival.FROM_ABOVE)
	check("floor 3: marks and drums", main._message_label.text.contains("drums"))
	await _snap("outskirts")
	main._go_to_floor(4, main.Arrival.FROM_ABOVE)
	var map = main._map
	check("floor 4 looks like the fortress", main.environment_theme.display_name == "Goblin fortress")
	var gates: Array = map.marks.get("gates", [])
	var hall: Array = map.marks.get("hall", [])
	check("a hall behind barred gates", hall.size() >= 6 and not gates.is_empty() and gates.all(func(g): return map.door_at(g) == main.DungeonMap.Door.BLOCKED))
	check("the hall can't be reached past the gates", not map.reachable_from(map.start_cell).has(hall[0]))

	# The gate fight.
	main._on_party_blocked(gates[0])
	check("walking into the gate asks to break it", main._prompt.visible and main._prompt_label.text.contains("Break it down"))
	main._answer_prompt(true)
	await create_timer(0.3).timeout
	check("the gate's guards fight", main._in_combat and main._combat._state.foes.size() == 3)
	await _snap("gate_fight")
	await _win_fight()
	await create_timer(0.3).timeout
	check("the gate stays broken", main._camp_state.gate_broken and gates.all(func(g): return map.door_at(g) == main.DungeonMap.Door.OPEN))

	# The hall: warned, may step back, then the queen.
	var door: Vector2i = gates[0]
	var inside: Vector2i = hall.filter(func(h): return (h - door).length() == 1)[0]
	main._party.place(map, door)
	main._party.place(map, inside)
	main._on_party_entered_cell(inside)
	check("entering the hall warns: no turning back", main._prompt.visible and main._prompt_label.text.contains("no turning back"))
	main._answer_prompt(false)
	check("declining steps back out", main._party.cell == door)
	main._party.place(map, inside)
	main._on_party_entered_cell(inside)
	main._answer_prompt(true)
	await create_timer(0.3).timeout
	var state = main._combat._state
	check("the queen and two guards", main._in_combat and state.foes.size() == 3 and state.foes[0].type.display_name == queen.display_name)
	var guarded := 0.0
	while not main._combat._actions.visible and guarded < 50:
		await create_timer(0.1).timeout
		guarded += 1
	check("no retreat from her", main._combat._action_buttons.get_children().any(func(b): return b.text == "Retreat" and b.disabled))
	await _snap("queen")
	await _win_fight()
	await create_timer(0.3).timeout
	check("victory: the queen is dead", main._camp_state.queen_defeated and main._results.visible and main._results._title.text == "The goblin queen is dead")
	await _snap("victory")
	main._results.continue_pressed.emit()
	await create_timer(0.2).timeout
	check("exploring goes on afterwards", not main._party.locked)
	main._on_party_entered_cell(inside)
	check("the empty hall asks nothing", not main._prompt.visible)

	# Camp: the bounty, no more contracts, the camp talks.
	main._end_expedition(main.Expedition.Ending.RETURNED)
	await process_frame
	main._results.continue_pressed.emit()
	await create_timer(0.3).timeout
	var gold_before: int = main._party_state.supplies.gold
	check("the bounty is paid at camp", main._camp_state.bounty_paid and main._camp._note.text.contains("50 gold"))
	check("no more contracts", main._camp_state.contract.is_empty())
	main._camp_state.rest(main._party_state)
	check("contracts stay gone on new days", main._camp_state.contract.is_empty())
	await _snap("camp")
	print("fails=", fails)
	quit()

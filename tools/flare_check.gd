extends SceneTree
## Flare (#74, owner 2026-10-25): spends 10 oil or 15 of a torch; beasts
## that fear fire lose their next action (a bat in the air drops), goblins
## and miners aim worse, lamp-eaters drink it, gas-bloats ignore it. Not
## offered in the dark. In the fight's Item menu. Args: tag, screenshot dir.

const CS := preload("res://scripts/combat_state.gd")
const Supplies := preload("res://scripts/supplies.gd")

var fails := 0


func check(label: String, ok: bool, detail = "") -> void:
	if not ok: fails += 1
	print("PASS " if ok else "FAIL ", label, "  ", detail)


func _e(id: String) -> EnemyType:
	return load("res://data/enemies/%s.tres" % id)


func _party(ids := ["mara", "corin"]):
	var party = load("res://scripts/party_state.gd").new()
	for id in ids:
		party.add_member(load("res://data/companions/%s.tres" % id))
	return party


func _fight(party, ids: Array):
	var types: Array[EnemyType] = []
	for id in ids:
		types.append(_e(id))
	return CS.new(party, types)


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var tag: String = args[0] if args.size() > 0 else "desk"
	var dir: String = args[1] if args.size() > 1 else ""

	# Who takes it how.
	var party = _party()
	var fight = _fight(party, ["rat", "goblin", "lamp_eater", "gas_bloat", "cave_bat"])
	var kinds: Array = fight.foes.map(func(f): return CS.flare_effect(f))
	check("rat blinded, goblin squints, lamp-eater drinks, bloat shrugs, bat blinded", kinds == ["dazzle", "squint", "drink", "", "dazzle"], str(kinds))

	# The cost, from the lantern.
	party.supplies.has_lantern = true
	party.supplies.source = Supplies.Source.LANTERN
	party.supplies.oil = 50.0
	var bat = fight.foes[4]
	check("(the bat starts in the air)", bat.in_back())
	var out: Dictionary = fight.hero_flare(party.members[0])
	check("a flare costs 10 oil", is_equal_approx(party.supplies.oil, 40.0), str(party.supplies.oil))
	check("...blinds the beasts and makes the goblin squint", fight.is_dazzled(fight.foes[0]) and fight.is_dazzled(bat) and fight.is_squinting(fight.foes[1]) and not fight.is_dazzled(fight.foes[2]) and not fight.is_dazzled(fight.foes[3]))
	check("...and knocks the bat out of the air", not bat.in_back())
	var rat_act: Dictionary = fight.enemy_act(fight.foes[0])
	check("a blinded beast loses its turn", rat_act["damage"] == 0 and rat_act["text"].contains("reels") and not fight.is_dazzled(fight.foes[0]))
	# Squinting: worse aim, once.
	var gob = fight.foes[1]
	var sure: EnemyType = gob.type.duplicate()
	sure.accuracy = 0.15  # below the squint: it can't hit
	gob.type = sure
	gob.intent = CS.Intent.ATTACK
	var hits := 0
	for i in 20:
		fight._squinting[gob] = true
		gob.intent = CS.Intent.ATTACK  # a plain swing each time (not a coin-flip lunge)
		if fight.enemy_act(gob)["hit"]:
			hits += 1
	check("a squinting goblin aims 20% worse", hits == 0, hits)
	check("...and its eyes clear after one action", not fight.is_squinting(gob))

	# The cost, from a torch; none in the dark.
	party = _party(["mara"])
	party.supplies.has_lantern = false
	party.supplies.source = Supplies.Source.TORCH
	party.supplies.torch_left = 40.0
	fight = _fight(party, ["rat"])
	fight.hero_flare(party.members[0])
	check("with a torch: 15 of its time", is_equal_approx(party.supplies.torch_left, 25.0), str(party.supplies.torch_left))
	party.supplies.torch_left = 0.0
	party.supplies.source = Supplies.Source.NONE
	check("in the dark, no flare", not party.supplies.can_flare())
	party.supplies.has_lantern = true
	party.supplies.source = Supplies.Source.LANTERN
	party.supplies.oil = 6.0
	check("...nor with too little oil", not party.supplies.can_flare())

	# In the game: the Item menu.
	var main = load("res://scenes/main.tscn").instantiate()
	main.play_opening = false
	main.floor_seed = 11
	root.add_child(main)
	await create_timer(0.5).timeout
	main._go_to_floor(2, main.Arrival.FROM_ABOVE)
	await process_frame
	main._party_state.supplies.oil = 60.0
	main._start_combat(main._party.cell, [_e("rat"), _e("goblin")] as Array[EnemyType])
	var w := 0
	while not main._combat._actions.visible and w < 80:
		await create_timer(0.1).timeout
		w += 1
	main._combat._show_items()
	await process_frame
	var labels: Array = main._combat._item_buttons.get_children().filter(func(b): return not b.is_queued_for_deletion()).map(func(b): return b.text)
	check("Flare is in the Item menu, with its cost", labels.any(func(t): return t.begins_with("Flare (")), str(labels))
	var cstate = main._combat._state
	cstate._dazzled[cstate.foes[0]] = true
	main._combat._select_target(cstate.foes[0])
	await process_frame
	check("a blinded foe says so on its line", main._combat._intent_label.text.contains("Blinded"), main._combat._intent_label.text)
	main._combat._rules_button.button_pressed = true
	main._combat._select_target(main._combat._state.foes[0])
	await process_frame
	check("the ? card says how it takes a flare", main._combat._rules_label.text.contains("A flare blinds it"), main._combat._rules_label.text)
	if dir != "":
		for i in 6:
			await process_frame
		root.get_texture().get_image().save_png("%s/flare_%s.png" % [dir, tag])
	print("fails=", fails)
	quit()

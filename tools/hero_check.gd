extends SceneTree
## Choosing a starting hero (#95): the title's hero screen, the chosen hero
## waking, and each main hero's trait. Args: tag, screenshot dir.

const SaveGame := preload("res://scripts/save_game.gd")

var fails := 0


func check(label: String, ok: bool, detail = "") -> void:
	if not ok: fails += 1
	print("PASS " if ok else "FAIL ", label, "  ", detail)


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var tag: String = args[0] if args.size() > 0 else "desk"
	var dir: String = args[1] if args.size() > 1 else ""
	SaveGame.delete()

	# The title: New game opens the hero screen.
	var title = load("res://scenes/title.tscn").instantiate()
	root.add_child(title)
	current_scene = title
	await process_frame
	title._begin.pressed.emit()
	await process_frame
	var screen = title._hero_select
	check("New game opens the hero choice", screen.visible)
	var cards: Array = screen.find_children("*", "Button", true, false).filter(func(b): return b.text.begins_with("Wake as"))
	check("three heroes to choose from", cards.size() == 3, str(cards.map(func(b): return b.text)))
	var text: String = " | ".join(screen.find_children("*", "Label", true, false).map(func(l): return l.text))
	check("each shows a role and a trait", text.contains("Rogue") and text.contains("Brawler") and text.contains("Healer") and text.contains("Keen eyes") and text.contains("Grudge") and text.contains("Field medic"))
	if dir != "":
		for i in 4: await process_frame
		root.get_texture().get_image().save_png(dir + "/hero_" + tag + "_choice.png")
	cards.filter(func(b): return b.text == "Wake as Corin")[0].pressed.emit()
	for i in 30:
		await process_frame
	var main = current_scene
	check("Corin wakes in the cave", main != null and main.has_method("save_and_exit") and main._party_state.members[0].display_name == "Corin")
	check("only Corin: no one else", main._party_state.members.size() == 1)
	await create_timer(1.0).timeout

	# Traits.
	var CS = load("res://scripts/combat_state.gd")
	var PS = load("res://scripts/party_state.gd")
	var corin: Companion = load("res://data/companions/corin.tres")
	var p = PS.new()
	p.add_member(corin)
	var hero: Companion = p.members[0]
	hero.weapon = null; hero.attack_min = 3; hero.attack_max = 3; hero.accuracy = 1.0; hero.strain = 0.0
	var c = CS.new(p, [load("res://data/enemies/goblin.tres"), load("res://data/enemies/rat.tres")] as Array[EnemyType])
	var hits := {"goblin": 0, "rat": 0}
	for i in 30:
		c.foes[0].health = 10; c.foes[0].shielded = false
		c.foes[1].health = 4
		var g: Dictionary = c.hero_attack(hero, c.foes[0])
		if g["hit"]: hits["goblin"] = maxi(hits["goblin"], g["damage"])
		var r: Dictionary = c.hero_attack(hero, c.foes[1])
		if r["hit"]: hits["rat"] = maxi(hits["rat"], r["damage"])
	check("Grudge: +1 against goblins only", hits["goblin"] == 4 and hits["rat"] == 3, str(hits))

	var q = PS.new()
	q.add_member(load("res://data/companions/alwen.tres"))
	var mara := Companion.new(); mara.display_name = "Test"; mara.max_health = 20; mara.health = 5
	q.add_member(mara)
	var draught: SupplyItem = load("res://data/items/restorative_draught.tres")
	q.supplies.add(draught)
	q.use_item(draught)
	var effect: Dictionary = q.members[1].pending_effects[0]
	check("Field medic: a draught heals half again as much", roundi(effect["per_unit"] * draught.duration) == 15)
	q.members[1].add_injury(load("res://data/injuries/limp.tres"))
	check("Field medic: binds an injury without a dressing", q.field_bind(q.members[1]) and q.members[1].hindering_injuries().is_empty())
	q.members[1].add_injury(load("res://data/injuries/deep_wound.tres"))
	check("...but only once a trip", not q.can_field_bind(q.members[1]))

	# Keen eyes: Mara spots traps; others don't.
	var trap: RoomEvent = load("res://data/events/trap_tripwire.tres")
	var cell: Vector2i = main._party.cell + main.Party.DIRECTIONS[main._party.facing]
	main._map.events[cell] = trap
	main._build_level()
	check("without keen eyes, traps stay hidden", not main._props.has(cell))
	main._party_state.members[0].trait_id = "keen_eyes"
	main._build_level()
	check("keen eyes spot the trap", main._props.has(cell))
	SaveGame.delete()
	print("fails=", fails)
	quit()

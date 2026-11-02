extends SceneTree
## Magic, the first prayers (#170, owner 2026-11-02): only a Mage casts, a
## few casts a trip (a votive candle gives one back), prayers learned from
## tomes and kept all campaign, and a Shaken or Panicking caster can find
## nothing answers. Mend, Holy light, Bind and Watchful eye.
## Args: tag, screenshot dir.

const Spells := preload("res://scripts/spells.gd")
const CS := preload("res://scripts/combat_state.gd")
const Supplies := preload("res://scripts/supplies.gd")
const Progression := preload("res://scripts/progression.gd")
const SaveGame := preload("res://scripts/save_game.gd")

var fails := 0


func check(label: String, ok: bool, detail = "") -> void:
	if not ok: fails += 1
	print("PASS " if ok else "FAIL ", label, "  ", detail)


func _hero(id: String) -> Companion:
	var hero: Companion = load("res://data/companions/%s.tres" % id).duplicate(true)
	load("res://scripts/classes.gd").migrate(hero)
	return hero


func _party(ids: Array):
	var party = load("res://scripts/party_state.gd").new()
	for id in ids:
		party.add_member(_hero(id))
	return party


func _item(id: String) -> SupplyItem:
	return load("res://data/items/%s.tres" % id)


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var tag: String = args[0] if args.size() > 0 else "desk"
	var dir: String = args[1] if args.size() > 1 else ""
	var rng := RandomNumberGenerator.new()
	rng.seed = 170

	# Who casts, and what they know.
	var party = _party(["alwen", "corin"])
	var alwen: Companion = party.members[0]
	var corin: Companion = party.members[1]
	check("Alwen is a Mage and knows Mend from the start", Spells.is_caster(alwen) and Spells.known(alwen) == ["mend"])
	check("...Corin (Melee) knows no prayers", Spells.known(corin).is_empty() and Spells.cannot_cast(corin, "mend", false) != "")
	check("a Mage sets out with %d casts" % Spells.CASTS, alwen.casts == Spells.CASTS)

	# Mend, outside a fight.
	alwen.strain = 0
	for hero: Companion in party.members:
		hero.health = hero.effective_max_health()
	check("no one hurt: no Mend", Spells.cast_in_field(party, alwen, "mend", rng) == "" and alwen.casts == Spells.CASTS)
	corin.health = 5
	var text := Spells.cast_in_field(party, alwen, "mend", rng)
	check("Mend heals the most hurt at once, for a cast", corin.health == 5 + Spells.MEND and alwen.casts == Spells.CASTS - 1, text)
	check("...Bind can't be cast outside a fight", Spells.cannot_cast(alwen, "bind", false) != "")

	# Miscasts.
	var falters := 0
	for i in 400:
		alwen.casts = 3
		alwen.strain = 90
		if Spells.spend(alwen, rng) != "":
			falters += 1
	check("a Panicking caster's prayer falters about 3 times in 10", falters > 90 and falters < 150, falters)
	alwen.strain = 10
	alwen.casts = 3
	var calm := 0
	for i in 200:
		alwen.casts = 3
		alwen.strain = 10
		if Spells.spend(alwen, rng) != "":
			calm += 1
	check("...a steady one's never does", calm == 0)
	alwen.strain = 0
	alwen.casts = 3

	# Holy light: bright, and no oil burns while it lasts.
	check("an unread prayer can't be cast", Spells.cannot_cast(alwen, "light", false) == "Not known")
	alwen.spells.assign(["light", "bind"])  # as if read from their tomes
	party.supplies.oil = 20.0
	check("a low lantern is dim", party.supplies.light_band() == Supplies.Light.DIM)
	Spells.cast_in_field(party, alwen, "light", rng)
	var oil: float = party.supplies.oil
	check("Holy light: bright", party.supplies.light_band() == Supplies.Light.BRIGHT)
	party.advance_time(Spells.LIGHT_TIME - 2)
	check("...and no oil burns while it lasts", is_equal_approx(party.supplies.oil, oil), party.supplies.oil)
	party.advance_time(5)
	check("...then it fades", party.supplies.light_band() == Supplies.Light.DIM and party.supplies.oil < oil)

	# Tomes and candles.
	var mage_free = _party(["corin"])
	mage_free.supplies.add(_item("tome_bind"))
	check("no Mage: a tome can't be read", mage_free.cannot_use_reason(_item("tome_bind")) == "Needs a Mage")
	party.supplies.add(_item("tome_watch"), 2)
	check("a Mage reads a tome and learns its prayer", party.use_item(_item("tome_watch")) != "" and "watch" in Spells.known(alwen))
	check("...a second copy: already known", party.cannot_use_reason(_item("tome_watch")) == "Already known")
	alwen.casts = 1
	party.supplies.add(_item("votive_candle"), 2)
	check("a votive candle gives a cast back", party.use_item(_item("votive_candle")) != "" and alwen.casts == 2)
	alwen.casts = Spells.CASTS
	check("...not past full", party.cannot_use_reason(_item("votive_candle")) == "Casts are full")
	check("the merchant sells candles", _item("votive_candle") in load("res://scripts/camp_state.gd").MERCHANT_STOCK)

	# Watchful eye.
	Spells.cast_in_field(party, alwen, "watch", rng)
	check("Watchful eye lasts a while", party.watch_left == Spells.WATCH_TIME)
	party.advance_time(Spells.WATCH_TIME)
	check("...then ends", party.watch_left == 0)

	# A new trip: casts back, prayers kept.
	alwen.casts = 0
	Progression.reset(alwen)
	check("leaving camp: casts come back, prayers are kept", alwen.casts == Spells.CASTS and "watch" in Spells.known(alwen))
	var packed: Dictionary = SaveGame.pack_object(alwen)
	check("prayers and casts are saved with the hero", packed.has("spells") and packed.has("casts"))
	check("...the glow and the watch with the party", SaveGame.pack_object(party.supplies).has("glow_left") and SaveGame.pack_object(party).has("watch_left"))

	# In a fight.
	var fight = CS.new(party, [load("res://data/enemies/goblin.tres"), load("res://data/enemies/rat.tres")] as Array[EnemyType])
	fight.rng.seed = 4
	fight.prepare(1)
	var goblin = fight.foes[0]
	var bound: Dictionary = fight.hero_cast(alwen, "bind", goblin)
	check("Bind holds the chosen foe", fight.is_bound(goblin), bound["text"])
	var first: Dictionary = fight.enemy_act(goblin)
	var second: Dictionary = fight.enemy_act(goblin)
	check("...for two of its turns: no blow, no move", first["target"] == null and second["target"] == null and not fight.is_bound(goblin), second["text"])
	var queen_fight = CS.new(party, [load("res://data/enemies/goblin_queen.tres")] as Array[EnemyType])
	queen_fight.prepare(4, "queen")
	queen_fight.hero_cast(alwen, "bind", queen_fight.foes[0])
	queen_fight.enemy_act(queen_fight.foes[0])
	check("...the queen shakes it off after one", not queen_fight.is_bound(queen_fight.foes[0]))
	alwen.casts = 3
	var lit: Dictionary = fight.hero_cast(alwen, "light")
	check("Holy light in a fight blinds the beasts, like a flare", fight.foes[1] in lit["dazzled"], lit["text"])
	corin.health = 4
	alwen.casts = 1
	fight.hero_cast(alwen, "mend")
	check("Mend in a fight", corin.health == 4 + Spells.MEND and alwen.casts == 0)
	check("...and with no casts left, nothing", fight.hero_cast(alwen, "mend")["text"] == "")
	check("Watchful eye isn't a fighting prayer", Spells.cannot_cast(alwen, "watch", true) != "")

	# In the game: the Cast button on the map, and the monsters on the map.
	var main = load("res://scenes/main.tscn").instantiate()
	main.play_opening = false
	main.floor_seed = 11
	main.wandering = false
	root.add_child(main)
	await create_timer(0.5).timeout
	main._go_to_floor(2, main.Arrival.FROM_ABOVE)
	await process_frame
	var mage := _hero("alwen")
	main._party_state.add_member(mage)
	check("no prayer: the map shows no monsters", main._sensed_cells().is_empty())
	main._party_state.watch_left = Spells.WATCH_TIME
	check("Watchful eye: the map marks every group on the floor", main._sensed_cells().size() == main._groups.size() and not main._groups.is_empty(), main._sensed_cells().size())
	var group = main._groups[0]
	main._engage(group)
	for i in 60:
		if main._combat.awaiting_field_action:
			break
		await create_timer(0.1).timeout
	var cast_button: Button = main._combat._field_buttons.get_children().filter(func(b): return b.text == "Cast")[0]
	check("with a Mage in the party, fights offer Cast", main._combat.awaiting_field_action and cast_button.visible and not cast_button.disabled)
	if dir != "":
		for i in 10:
			await process_frame
		var buttons := root.get_texture().get_image()
		if buttons:
			buttons.save_png("%s/magic_%s_buttons.png" % [dir, tag])
	cast_button.pressed.emit()
	var names: Array = main._combat._item_buttons.get_children().map(func(b): return b.text)
	check("...listing the fighting prayers she knows, with casts left", names.any(func(n): return n.begins_with("Mend (")), names)
	if dir != "":
		for i in 10:
			await process_frame
		var shot := root.get_texture().get_image()
		if shot:
			shot.save_png("%s/magic_%s_fight.png" % [dir, tag])
	print("fails=", fails)
	quit()

extends SceneTree
## Trinkets (#135, owner 2026-10-21): one per hero; jewellery can be worn
## or sold; common ones trade a benefit for a drawback, uniques reward a
## playstyle; cursed ones bite once worn and won't come off until holy
## water or the nurse cleanses them. Args: tag, screenshot dir.

const Trinkets := preload("res://scripts/trinkets.gd")

var fails := 0


func check(label: String, ok: bool, detail = "") -> void:
	if not ok: fails += 1
	print("PASS " if ok else "FAIL ", label, "  ", detail)


func _t(id: String) -> Equipment:
	return load("res://data/trinkets/%s.tres" % id)


func _item(id: String) -> SupplyItem:
	return load("res://data/items/%s.tres" % id)


func _party(heroes := ["mara"]):
	var party = load("res://scripts/party_state.gd").new()
	for id in heroes:
		party.add_member(load("res://data/companions/%s.tres" % id))
	return party


## Damage from one blow that's sure to land, with the same dice each time.
func _blow(party, hero: Companion) -> int:
	var CS = load("res://scripts/combat_state.gd")
	var combat = CS.new(party, [load("res://data/enemies/goblin_guard.tres")] as Array[EnemyType])
	combat.rng.seed = 7
	hero.accuracy = 5.0
	var foe = combat.foes[0]
	foe.type = foe.type.duplicate()
	foe.health = 99
	return combat.hero_attack(hero, foe)["damage"]


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var tag: String = args[0] if args.size() > 0 else "desk"
	var dir: String = args[1] if args.size() > 1 else ""
	var all := Trinkets.all()
	var tiers := {}
	for t in all:
		if t.curse == null:
			tiers[t.tier] = tiers.get(t.tier, 0) + 1
	var jewels := all.filter(func(t): return t.treasure != null and t.tier == "magic").size()
	check("a first set: magic jewellery, a rare, uniques", jewels == 5 and tiers.get("unique") == 6 and tiers.get("rare") == 1 and not tiers.has("common") and not tiers.has("fine"), str(tiers))
	check("three cursed trinkets, each with a cleansed form", all.filter(func(t): return t.curse != null and t.cleansed != null).size() == 3)
	for jewel in ["silver_trinket", "military_medal", "silver_locket", "amber_pendant", "gold_signet_ring", "small_reliquary"]:
		if Trinkets.for_treasure(_item(jewel)) == null:
			check("%s can be worn" % jewel, false)

	# Wearing jewellery, swapping, taking it off.
	var party = _party()
	var mara: Companion = party.members[0]
	var brooch := _item("silver_trinket")
	party.supplies.add(brooch)
	var aim := mara.hit_accuracy()
	var said: String = party.wear_treasure(mara, brooch)
	check("a brooch from the pack is worn", mara.trinket == _t("leaf_brooch") and party.supplies.count(brooch) == 0, said)
	check("...+6% to hit", is_equal_approx(mara.hit_accuracy(), aim + 0.06))
	check("...nerves fray 20% faster", is_equal_approx(mara.boon_product("strain_rate"), 1.2))
	party.supplies.add(_item("gold_signet_ring"))
	party.wear_treasure(mara, _item("gold_signet_ring"))
	check("wearing another puts the first back in the pack", mara.trinket == _t("gold_signet") and party.supplies.count(brooch) == 1)
	check("taken off, it goes back as treasure to sell", party.take_off_trinket(mara) and mara.trinket == null and party.supplies.count(_item("gold_signet_ring")) == 1)

	# Cursed.
	var pearl := _t("black_pearl_ring_cursed")
	check("a cursed ring looks fine: only its good side shows", pearl.effect.effects_text() == "+1 damage", pearl.effect.effects_text())
	party.supplies.gear.append(pearl)
	said = party.wear(mara, pearl)
	check("put on, the curse shows itself", said.contains("Cursed") and mara.is_cursed() and party.draws_ambush(), said)
	check("...and it won't come off", not party.take_off_trinket(mara) and mara.trinket == pearl)
	party.supplies.add(brooch)
	check("...nor be swapped", party.wear_treasure(mara, brooch) == "" and mara.trinket == pearl)
	party.supplies.add(_item("holy_water"))
	party.use_item(_item("holy_water"))
	check("holy water cleanses it: the ring stays, the curse goes", mara.trinket == _t("black_pearl_ring") and not mara.is_cursed() and not party.draws_ambush())
	party.take_off_trinket(mara)
	party.supplies.gear.append(_t("bone_charm_cursed"))
	party.wear(mara, _t("bone_charm_cursed"))
	check("a cursed charm withers: 4 less maximum health", mara.effective_max_health() == mara.max_health - 4)
	var camp = load("res://scripts/camp_state.gd").new()
	party.supplies.gold = 30
	check("the nurse can cleanse it too", camp.lift_bane(party, mara) != null and mara.trinket == _t("bone_charm") and party.supplies.gold == 10)

	# Uniques: playstyle buffs.
	party = _party()
	mara = party.members[0]
	var plain := _blow(party, mara)
	mara.trinket = _t("bloodstone")
	check("bloodstone: nothing extra while healthy", _blow(party, mara) == plain)
	mara.health = 3
	check("bloodstone: +2 damage below half health", _blow(party, mara) == plain + 2, "%d vs %d" % [_blow(party, mara), plain])
	mara.health = mara.max_health
	mara.trinket = _t("slingers_thumb_ring")
	mara.row = "back"
	var CS = load("res://scripts/combat_state.gd")
	mara.trinket = null
	var back_plain := _blow(party, mara)
	mara.trinket = _t("slingers_thumb_ring")
	check("slinger's ring: +1 damage from the back row", _blow(party, mara) == back_plain + 1)
	mara.row = "front"
	mara.trinket = _t("moth_wing_brooch")
	var combat = CS.new(party, [load("res://data/enemies/rat.tres")] as Array[EnemyType])
	mara.accuracy = 0.5
	party.supplies.oil = 100.0
	var bright: float = combat.hero_hit_chance(mara)
	mara.trinket = null
	var bright_plain: float = combat.hero_hit_chance(mara)
	party.supplies.oil = 10.0
	var dim_plain: float = combat.hero_hit_chance(mara)
	mara.trinket = _t("moth_wing_brooch")
	check("moth-wing brooch: better in bright light, worse in dim", is_equal_approx(bright, bright_plain + 0.1) and is_equal_approx(combat.hero_hit_chance(mara), dim_plain - 0.1))
	mara.trinket = _t("gamblers_knucklebone")
	check("knucklebone: coin flips favour you, ambushes come more", is_equal_approx(party.luck()[0], 0.15) and party.draws_ambush())
	party = _party(["mara", "corin"])
	var corin: Companion = party.members[1]
	party.members[0].trinket = _t("shield_bearers_token")
	corin.strain = 30.0
	combat = CS.new(party, [load("res://data/enemies/rat.tres")] as Array[EnemyType])
	combat.hero_defend(party.members[0])
	check("shield-bearer's token: defending steadies everyone", corin.strain < 30.0, corin.strain)
	party.members[0].trinket = _t("ember_ring")
	party.supplies.add(_item("torch"))
	party.supplies.light_torch(_item("torch"))
	combat = CS.new(party, [load("res://data/enemies/goblin.tres")] as Array[EnemyType])
	var out: Dictionary = combat.hero_throw_torch(party.members[0], combat.foes[0])
	check("ember ring: a thrown torch burns 3 more", out["damage"] >= 6 and out["damage"] <= 8, out["damage"])

	# Where they come from.
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var weak_drops := 0
	var drops := []
	for i in 2000:
		if Trinkets.drop(rng, 1, 5) != null:
			weak_drops += 1
		var find = Trinkets.drop(rng, 1, 14)
		if find:
			drops.append(find)
	check("weak foes leave nothing", weak_drops == 0)
	check("tougher foes sometimes leave magic jewellery, never cursed on floor 1", drops.size() > 70 and drops.size() < 180 and drops.all(func(d): return d is SupplyItem), drops.size())
	var deep := []
	for i in 2000:
		var find = Trinkets.drop(rng, 3, 14)
		if find:
			deep.append(find)
	check("deeper, some are cursed", deep.any(func(d): return d is Equipment and d.curse != null))
	check("no uniques from ordinary fights", not deep.any(func(d): return d is Equipment and d.tier == "unique"))
	var owned := [_t("bloodstone"), _t("ember_ring")]
	var prize: Equipment = Trinkets.unique_reward(rng, owned)
	check("the queen's hoard: a unique you don't have yet", prize != null and prize.tier == "unique" and prize not in owned)

	# In the game: the Pack offers to wear jewellery, the card shows it.
	var main = load("res://scenes/main.tscn").instantiate()
	main.play_opening = false
	main.floor_seed = 11
	root.add_child(main)
	await create_timer(0.5).timeout
	var ps = main._party_state
	ps.supplies.add(_item("amber_pendant"))
	ps.supplies.gear.append(_t("goblin_torc_cursed"))
	main._set_pack(true)
	await process_frame
	main._pack.inspect_item(_item("amber_pendant"))
	var buttons: Array = main._pack._list.find_children("*", "Button", true, false)
	check("the Pack offers to wear jewellery", buttons.any(func(b): return b.text == "Wear"))
	var lead: Companion = ps.members[0]
	main._pack.used.emit(ps.wear_treasure(lead, _item("amber_pendant")))
	main._pack.refresh()
	main._pack.inspect_item(lead.trinket,true,"trinket")
	await process_frame
	var lines: Array = main._pack._list.find_children("*", "Label", true, false).map(func(l): return l.text)
	check("the Pack shows what the worn trinket does", lines.any(func(t): return t.contains("+3 maximum health")) and main._pack._from_slot == "trinket", str(lines.slice(0, 8)))
	if dir != "":
		for i in 4:
			await process_frame
		root.get_texture().get_image().save_png(dir + "/trinkets_" + tag + "_pack.png")
	main._set_pack(false)
	await process_frame
	var tips: Array = main._cards[0]._icons.get_children().map(func(c): return c.tooltip_text)
	check("the card shows the trinket", tips.any(func(t): return t.begins_with("Wears the amber tear pendant")), str(tips))
	print("fails=", fails)
	quit()

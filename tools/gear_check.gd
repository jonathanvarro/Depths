extends SceneTree
## Finer weapons and armour (owner, 2026-10-21): fine pieces have slightly
## better base numbers, magic adds a modifier, rare a prefix and a suffix;
## they drop from chests and tougher foes by floor, sell for more, count on
## the hero, and survive a save. Args: tag, screenshot dir.

const GearGen := preload("res://scripts/gear_gen.gd")
const Quality := preload("res://scripts/quality.gd")
const SaveGame := preload("res://scripts/save_game.gd")
const CampState := preload("res://scripts/camp_state.gd")

var fails := 0


func check(label: String, ok: bool, detail = "") -> void:
	if not ok: fails += 1
	print("PASS " if ok else "FAIL ", label, "  ", detail)


func _gear(id: String) -> Equipment:
	return load("res://data/gear/%s.tres" % id)


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var tag: String = args[0] if args.size() > 0 else "desk"
	var dir: String = args[1] if args.size() > 1 else ""
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	var sword := _gear("iron_sword")
	check("bases are the smith's weapons and armour, no back gear", GearGen.bases().size() == 7 and GearGen.bases().all(func(b): return b.slot in ["weapon", "body"]))

	# Fine.
	var fine := GearGen.make(sword, "fine", rng)
	var better: bool = fine.attack_max == sword.attack_max + 1 or is_equal_approx(fine.accuracy_bonus, sword.accuracy_bonus + 0.05)
	check("a fine sword is slightly better", better and fine.tier == "fine" and fine.effect == null, "%s %d-%d %+.2f" % [fine.display_name, fine.attack_min, fine.attack_max, fine.accuracy_bonus])
	check("...named for it", fine.display_name in ["Sharpened iron sword", "Balanced iron sword"], fine.display_name)
	check("...and the smith's own isn't changed", sword.attack_max == 5 and is_equal_approx(sword.accuracy_bonus, 0.05))
	var coat := GearGen.make(_gear("padded_coat"), "fine", rng)
	check("fine armour: reinforced, +2 maximum health", coat.display_name == "Reinforced quilted coat" and coat.effect.max_health == 2)
	check("fine sells for half again as much", CampState.sale_price(fine) == floori(roundi(sword.price * 1.5) * CampState.GEAR_RESALE))

	# Magic and rare.
	var magic := GearGen.make(sword, "magic", rng)
	check("a magic sword has a modifier, and is named for it", magic.effect != null and magic.display_name != "Iron sword" and not magic.display_name.begins_with("Sharpened") and not magic.display_name.begins_with("Balanced"), magic.display_name + ": " + magic.effect.effects_text())
	var rare := GearGen.make(sword, "rare", rng)
	check("a rare sword: a prefix and a suffix", rare.display_name.contains(" of ") and rare.display_name.split(" ")[0] in ["Keen", "Heavy"], rare.display_name)
	var back_rank := false
	var mole_magic := false
	for i in 300:
		var r := GearGen.make(sword, "rare", rng)
		if r.display_name.contains("back rank"):
			back_rank = true
		var m := GearGen.make(_gear("leather_jerkin"), "magic", rng)
		if m.display_name.contains("mole"):
			mole_magic = true
	check("a sword never rolls 'of the back rank' (reach weapons only)", not back_rank)
	check("'of the mole' only on rare armour", not mole_magic)
	var spear_rank := false
	for i in 300:
		if GearGen.make(_gear("simple_spear"), "rare", rng).display_name.contains("back rank"):
			spear_rank = true
	check("a spear can", spear_rank)

	# Drops by floor.
	var counts := {1: {}, 4: {}}
	var chests := {1: 0, 4: 0}
	for depth in [1, 4]:
		for i in 4000:
			var find := GearGen.drop(rng, depth, "chest")
			if find:
				chests[depth] += 1
				counts[depth][find.tier] = counts[depth].get(find.tier, 0) + 1
	check("floor 1 chests: about 1 in 10, all fine", chests[1] > 300 and chests[1] < 500 and counts[1].keys() == ["fine"], "%d %s" % [chests[1], counts[1]])
	check("floor 4 chests: about 15 in 100, magic and rare", chests[4] > 480 and chests[4] < 720 and not counts[4].has("fine") and counts[4].get("rare", 0) > 100, "%d %s" % [chests[4], counts[4]])
	var weak := 0
	for i in 2000:
		if GearGen.drop(rng, 3, "foe", 5):
			weak += 1
	check("weak foes leave no gear", weak == 0)

	# On a hero.
	var party = load("res://scripts/party_state.gd").new()
	party.add_member(load("res://data/companions/mara.tres"))
	var mara: Companion = party.members[0]
	var keen := GearGen.make(sword, "magic", rng)
	while not keen.display_name.begins_with("Keen"):
		keen = GearGen.make(sword, "magic", rng)
	mara.weapon = sword
	var aim := mara.hit_accuracy()
	party.supplies.gear.append(keen)
	party.equip(mara, keen)
	check("a keen sword's aim counts: its base and its modifier", mara.hit_accuracy() > aim + 0.04, "%.2f vs %.2f" % [mara.hit_accuracy(), aim])
	var warded := GearGen.make(_gear("padded_coat"), "magic", rng)
	while not warded.display_name.begins_with("Warded"):
		warded = GearGen.make(_gear("padded_coat"), "magic", rng)
	party.supplies.gear.append(warded)
	party.equip(mara, warded)
	check("warded, reinforced armour: +4 maximum health", mara.effective_max_health() == mara.max_health + 4)
	var copy := Companion.new()
	SaveGame.unpack_into(copy, SaveGame.pack_object(mara))
	check("a generated weapon survives a save", copy.weapon != null and copy.weapon.display_name == keen.display_name and copy.weapon.tier == "magic" and copy.weapon.effect != null and is_equal_approx(copy.hit_accuracy(), mara.hit_accuracy()))
	check("its border is blue", Quality.tier_of(keen) == "magic")

	# In the game: the Pack shows the quality and the modifier.
	var main = load("res://scenes/main.tscn").instantiate()
	main.play_opening = false
	main.floor_seed = 11
	root.add_child(main)
	await create_timer(0.5).timeout
	main._party_state.supplies.gear.append(GearGen.make(sword, "rare", rng))
	main._found_gear(GearGen.make(_gear("leather_jerkin"), "magic", rng), "Underneath: a test.")
	main._set_pack(true)
	await process_frame
	var shown: Array[String] = []
	for candidate: Equipment in main._party_state.supplies.gear:
		if candidate.tier not in ["rare", "magic"]: continue
		main._pack.inspect_item(candidate)
		var labels: Array = main._pack._detail_text.get_children().map(func(l): return l.text)
		if labels.any(func(t): return t.begins_with(candidate.tier.capitalize()+" · ")) and labels.any(func(t): return t.contains(candidate.effect.effects_text())):
			shown.append(candidate.tier)
	check("the Pack names the quality and what the modifiers do", "rare" in shown and "magic" in shown, str(shown))
	if dir != "":
		for i in 4:
			await process_frame
		root.get_texture().get_image().save_png(dir + "/gear_" + tag + "_pack.png")
	print("fails=", fails)
	quit()

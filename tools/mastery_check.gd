extends SceneTree
## Gear mastery and enemy armour in the fight (#192/#193; owner decisions
## 2026-10-31): blows earn a weapon mastery, blows taken earn armour
## mastery, scaled by the foe's threat and capped per fight; mastery levels
## add the item's growth; practised hands double a lagging item's gain; a
## trip home grants nothing. Enemy armour: blunt ignores 1, blades do +1 to
## the unarmoured, goblin-bane bites goblins, a shield guards the front.
## Args: tag, screenshot dir.

const GearModel := preload("res://scripts/gear_model.gd")
const CombatState := preload("res://scripts/combat_state.gd")

var fails := 0


func check(label: String, ok: bool, detail = "") -> void:
	if not ok: fails += 1
	print("PASS " if ok else "FAIL ", label, "  ", detail)


func _item(base_id: String, mods := []) -> Equipment:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2
	var item := GearModel.generate(rng, base_id, "ordinary")
	item.damage_roll = 0
	item.accuracy_roll = 0.0
	item.health_roll = 0
	var g := {}
	for stat in item.growth:
		g[stat] = "steady"
	item.growth = g
	item.mods = PackedStringArray(mods)
	GearModel.apply(item)
	return item


func _fight(weapon: Equipment, enemy: String):
	var party = load("res://scripts/party_state.gd").new()
	party.add_member(load("res://data/companions/mara.tres"))
	party.members[0].weapon = weapon
	var types: Array[EnemyType] = [load("res://data/enemies/%s.tres" % enemy)]
	var state = CombatState.new(party, types)
	state.prepare(4)
	return state


## Mean damage of many hits, by swapping in a fixed roll range.
func _mean_hit(weapon: Equipment, enemy: String) -> float:
	var total := 0
	var hits := 0
	for i in 400:
		var state = _fight(weapon, enemy)
		state.party.members[0].accuracy = 1.0
		state.foes[0].health = 999
		var out: Dictionary = state.hero_attack(state.party.members[0], state.foes[0])
		if out["hit"]:
			total += out["damage"]
			hits += 1
	return float(total) / maxf(1.0, hits)


func _initialize() -> void:
	# Enemy armour and the strike types.
	check("armour on the goblin guard 2, brute 1, miner 1, the queen 1", load("res://data/enemies/goblin_guard.tres").armour == 2 and load("res://data/enemies/goblin_brute.tres").armour == 1 \
			and load("res://data/enemies/hollow_miner.tres").armour == 1 and load("res://data/enemies/goblin_queen.tres").armour == 1)
	var sword := _item("iron_sword")
	var mace := _item("light_mace")
	var sword_guard := _mean_hit(sword, "goblin_guard")
	var mace_guard := _mean_hit(mace, "goblin_guard")
	check("against a guard's armour, a blunt mace does better than a blade", mace_guard > sword_guard, "%.1f vs %.1f" % [mace_guard, sword_guard])
	var sword_goblin := _mean_hit(sword, "goblin")
	var mace_goblin := _mean_hit(mace, "goblin")
	check("against an unarmoured goblin, the blade does +1", sword_goblin > mace_goblin, "%.1f vs %.1f" % [sword_goblin, mace_goblin])
	var bane := _item("iron_sword", ["goblin_bane"])
	check("a goblin-bane blade bites goblins harder", _mean_hit(bane, "goblin") > sword_goblin + 1.5)

	# Mastery credit.
	var state
	var mara: Companion
	for i in 20:  # hit chance is capped below 100%: try until the first blow lands
		state = _fight(_item("iron_sword"), "goblin")
		mara = state.party.members[0]
		mara.accuracy = 1.0
		state.foes[0].health = 999
		if state.hero_attack(mara, state.foes[0])["hit"]:
			break
	var first: float = state.mastery_gain.get(mara.weapon, 0.0)
	check("a hit teaches the weapon, scaled by the foe's threat", first > 0.5 and first < 2.0, first)
	for i in 30:
		state.hero_attack(mara, state.foes[0])
	check("...capped per fight", is_equal_approx(state.mastery_gain[mara.weapon], 8.0), state.mastery_gain[mara.weapon])
	mara.body = _item("studded_jerkin")
	state.foes[0].intent = CombatState.Intent.ATTACK
	state.foes[0].type = state.foes[0].type.duplicate()
	state.foes[0].type.accuracy = 1.0
	state.enemy_act(state.foes[0])
	check("a blow taken teaches the armour", state.mastery_gain.get(mara.body, 0.0) > 0.0)

	var no_bonus = _fight(_item("iron_sword"), "goblin")
	no_bonus._credit(no_bonus.party.members[0].weapon, "miss", no_bonus.foes[0])
	no_bonus._credit(no_bonus.party.members[0].weapon, "kill", no_bonus.foes[0])
	check("no miss or kill bonus", no_bonus.mastery_gain.get(no_bonus.party.members[0].weapon, 0.0) == 0.0)

	# Levels and growth; practised hands.
	var blade := _item("iron_sword")
	check("mastery 3 adds the growth: 3-5 becomes 4-6", GearModel.award(blade, 54.0) == 3 and blade.attack_min == 4 and blade.attack_max == 6, "%d-%d" % [blade.attack_min, blade.attack_max])
	var fresh := _item("light_mace")
	GearModel.award(fresh, 6.0, [blade])
	check("practised hands: a new item 2+ levels behind learns double", is_equal_approx(fresh.mastery, 12.0) and GearModel.level_of(fresh) == 1, fresh.mastery)

	# Passive participation and returning grant no mastery.
	var main = load("res://scenes/main.tscn").instantiate()
	main.play_opening = false
	root.add_child(main)
	await create_timer(0.5).timeout
	var hero: Companion = main._party_state.members[0]
	hero.weapon = _item("iron_sword")
	hero.body = _item("studded_jerkin")
	var idle = CombatState.new(main._party_state, [])
	main._award_mastery(idle, CombatState.Result.VICTORY)
	check("participation alone teaches neither weapon nor armour", hero.weapon.mastery == 0.0 and hero.body.mastery == 0.0)
	check("no return-home bonus or award path", GearModel.tables()["mastery"]["extraction"]["worn_item"] == 0 and not main.has_method("_bring_home_mastery"))
	# Tempering at the smith (#173).
	var camp = main._camp_state
	camp.set_site_present("smith", true)
	var ps = main._party_state
	var worn: Equipment = hero.weapon
	GearModel.award(worn, 60.0)
	check("mastery 3: a temper is due, with weapon choices", GearModel.temper_due(worn) == 3 and GearModel.temper_options(worn).map(func(o): return o["id"]) == ["edge", "weight"])
	ps.supplies.gold = 100
	var cost := GearModel.temper_cost(worn)
	check("...it needs the item's own region's material", camp.temper(ps, worn, "weight").begins_with("Needs"), cost)
	ps.supplies.add(load("res://data/items/%s.tres" % cost["material_id"]), 1)
	var top := worn.attack_max
	check("...with it, the smith tempers: +1 to the top of the damage", camp.temper(ps, worn, "weight") == "" and worn.attack_max == top + 1 and ps.supplies.gold == 100 - cost["gold"] and "weight" in worn.tempers)
	check("...and not again until mastery 6", GearModel.temper_due(worn) == 0)
	print("fails=", fails)
	quit()

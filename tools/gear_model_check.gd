extends SceneTree
## Equipment as individual items (#192/#193; owner decisions 2026-10-31):
## the game's gear_model.gd follows the tables in data/equipment/ as the
## balance probe does: the worked examples reproduce, thousands of finds are
## valid, an item saves and loads exactly, and older gear (the heroes' own,
## the smith's stock, earlier generated finds) becomes items once.
## Args: tag, screenshot dir.

const GearModel := preload("res://scripts/gear_model.gd")
const GearGen := preload("res://scripts/gear_gen.gd")
const SaveGame := preload("res://scripts/save_game.gd")

var fails := 0


func check(label: String, ok: bool, detail = "") -> void:
	if not ok: fails += 1
	print("PASS " if ok else "FAIL ", label, "  ", detail)


func _fixed(base_id: String, quality: String, growth: String) -> Equipment:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var item := GearModel.generate(rng, base_id, quality)
	item.damage_roll = 0
	item.accuracy_roll = 0.0
	item.health_roll = 0
	var g := {}
	for stat in item.growth:
		g[stat] = growth
	item.growth = g
	item.mods = PackedStringArray()
	return item


func _at(item: Equipment, points: float) -> Vector2i:
	item.mastery = points
	GearModel.apply(item)
	return Vector2i(item.attack_min, item.attack_max)


func _initialize() -> void:
	check("the tables load from data/equipment", GearModel.tables()["bases"]["bases"].size() >= 20 and not GearModel.base("iron_sword").is_empty())

	# The worked examples (#193), in the game's own code.
	var cases := {"exceptional": ["slow", [Vector2i(4, 6), Vector2i(4, 6), Vector2i(5, 7)]],
			"ordinary": ["steady", [Vector2i(3, 5), Vector2i(4, 6), Vector2i(6, 8)]],
			"cracked": ["steady", [Vector2i(2, 4), Vector2i(3, 5), Vector2i(5, 7)]]}
	for quality in cases:
		var sword := _fixed("iron_sword", quality, cases[quality][0])
		var got := [_at(sword, 0), _at(sword, 54), _at(sword, 162)]
		check("%s sword (3-5): mastery 0, 3, 6" % quality, got == cases[quality][1], got)
	var sword := _fixed("iron_sword", "ordinary", "steady")
	sword.mastery = 41
	check("mastery levels and the next threshold", GearModel.level_of(sword) == 2 and GearModel.next_points(sword) == 54.0)
	check("named by quality: 'Cracked iron sword'; ordinary has no word", _fixed("iron_sword", "cracked", "steady").display_name == "Cracked iron sword" and sword.display_name == "Iron sword", _fixed("iron_sword", "cracked", "steady").display_name)

	# Thousands of finds are valid.
	var rng := RandomNumberGenerator.new()
	rng.seed = 193
	var bad := []
	var regions := {}
	for depth in [1, 3, 5]:
		for i in 1500:
			var item := GearModel.random_find(rng, depth)
			regions[GearModel.base(item.base_id)["region"]] = true
			var ids := Array(item.mods)
			var budget := 0
			for id in ids:
				budget += int(GearModel.modifier(id)["cost"])
			if item.slot == "weapon" and (item.attack_min < 1 or item.attack_min > item.attack_max):
				bad.append("damage " + item.display_name)
			if ids.size() != PackedStringArray(ids).size() or budget > 3:
				bad.append("modifiers " + item.display_name)
			for id in ids:
				for c in GearModel.modifier(id).get("conflicts", []):
					if c in ids:
						bad.append("conflict " + item.display_name)
			if not ids.is_empty() and ids.all(func(id): return GearModel.modifier(id)["kind"] == "drawback"):
				bad.append("drawback alone " + item.display_name)
			if item.initiative_penalty < 0:
				bad.append("slowing " + item.display_name)
	check("4500 finds across three regions are all valid", bad.is_empty() and regions.size() == 3, bad.slice(0, 5))
	var deep := GearModel.random_find(rng, 3)
	check("a floor-3 find is goblin-marches gear", int(GearModel.base(deep.base_id)["region"]) == 2, deep.base_id)

	var uncompensated := 0
	for i in 500:
		var pair := GearModel.generate(rng, "iron_sword", "ordinary", 2)
		if pair.mods.size() != 2 or Array(pair.mods).any(func(id): return GearModel.modifier(id)["kind"] == "drawback"):
			uncompensated += 1
	check("two-property prizes retain two strengths", uncompensated == 0, uncompensated)
	var legacy_drawback := _fixed("iron_sword", "ordinary", "steady")
	legacy_drawback.mods = PackedStringArray(["keen", "brittle"])
	legacy_drawback.mastery = 12.0
	GearModel.apply(legacy_drawback)
	check("existing drawbacks still work", GearModel.level_of(legacy_drawback) == 0 and GearModel.next_points(legacy_drawback) == 15.0)

	# Saving: exactly the same item after a load.
	var found := GearModel.random_find(rng, 4, 2)
	found.mastery = 33.5
	found.tempers = PackedStringArray(["edge"]) if found.slot == "weapon" else PackedStringArray(["refit"])
	GearModel.apply(found)
	var back: Equipment = SaveGame.unpack_value(SaveGame.pack_value(found))
	var same := back.base_id == found.base_id and back.quality == found.quality and back.mods == found.mods and back.growth == found.growth \
			and back.mastery == found.mastery and back.tempers == found.tempers and back.instance_id == found.instance_id and back.damage_roll == found.damage_roll \
			and back.display_name == found.display_name and back.attack_min == found.attack_min and back.attack_max == found.attack_max
	check("an item saves and loads exactly (rolls, growth, mastery, tempering)", same, found.display_name)

	# Older gear becomes items, once.
	var stock: Equipment = load("res://data/gear/iron_sword.tres")
	var mine := GearModel.ensure_instance(stock)
	check("the smith's stock becomes your own item, not the shared one", mine != stock and mine.resource_path == "" and mine.base_id == "iron_sword" and stock.base_id == "")
	check("...and only once", GearModel.ensure_instance(mine) == mine)
	var old_rng := RandomNumberGenerator.new()
	old_rng.seed = 4
	var legacy: Equipment = GearGen.make(stock, "magic", old_rng)
	while not (legacy.display_name.begins_with("Keen") or legacy.display_name.begins_with("Heavy")):
		legacy = GearGen.make(stock, "magic", old_rng)
	var converted := GearModel.ensure_instance(legacy)
	check("an older magic find keeps its modifier", converted.base_id == "iron_sword" and converted.mods.size() == 1, "%s -> %s" % [legacy.display_name, converted.display_name])
	check("a broken knife stays as it is", GearModel.ensure_instance(load("res://data/gear/broken_knife.tres")).base_id == "")
	var party = load("res://scripts/party_state.gd").new()
	party.add_member(load("res://data/companions/corin.tres"))
	var corin: Companion = party.members[0]
	check("a hero's own weapon becomes an item with mastery", corin.weapon == null or corin.weapon.base_id != "" or GearModel._base_for(load("res://data/companions/corin.tres").weapon) == "", corin.weapon.display_name if corin.weapon else "none")
	print("fails=", fails)
	quit()

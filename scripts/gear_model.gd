extends RefCounted
## Equipment as individual items (#192/#193; owner decisions 2026-10-31, see
## docs/equipment-model.md). Each weapon, armour or back piece rolls, once,
## its quality (cracked, bent, ordinary, fine, exceptional), a small stat
## roll, how fast it grows with mastery, and up to two modifiers. Mastery
## builds on the item itself; its numbers are recomputed from the rolls,
## mastery and tempering whenever they change. Lose it, lose all of that.
## The rules live in data/equipment/*.json (shared with
## tools/balance/equipment_probe.py); this script only applies them.
## Static helpers only; the tables are cached in engine metadata (#100).

const DIR := "res://data/equipment/"
const VERSION := 1
const STATE := "depths_gear_tables"
const NOWHERE := ""
## Quality words, as names and prices see them.
const QUALITY_PRICE := {"cracked": 0.5, "bent": 0.7, "ordinary": 1.0, "fine": 1.3, "exceptional": 2.0}
## Old generated gear (before 2026-10-31) named its modifiers; these become
## the new ones on load.
const LEGACY_MODS := {"Keen": "keen", "Heavy": "heavy", "of steady nerves": "steady", "of the lamplighter": "lamplighter",
		"of the back rank": "back_rank", "Warded": "warded", "Lamp-hooked": "lamplighter", "of calm": "steady",
		"of mending": "mending", "of the mole": "mole"}


static func tables() -> Dictionary:
	if not Engine.has_meta(STATE):
		var t := {}
		for name in ["bases", "rolls", "modifiers", "mastery", "region_marches"]:
			t[name] = JSON.parse_string(FileAccess.get_file_as_string(DIR + name + ".json"))
		var by_id := {}
		for b in t["bases"]["bases"]:
			by_id[b["id"]] = b
		t["base_by_id"] = by_id
		var mods := {}
		for m in t["modifiers"]["modifiers"]:
			mods[m["id"]] = m
		t["mod_by_id"] = mods
		Engine.set_meta(STATE, t)
	return Engine.get_meta(STATE)


static func base(id: String) -> Dictionary:
	return tables()["base_by_id"].get(id, {})


static func modifier(id: String) -> Dictionary:
	return tables()["mod_by_id"].get(id, {})


## Region tier of a floor: the Old Workings, the Goblin Marches and Hold,
## the Drowned Galleries.
static func region_of(depth: int) -> int:
	return 1 if depth <= 2 else (2 if depth <= 4 else 3)


static func _weighted(rng: RandomNumberGenerator, table: Dictionary) -> String:
	var roll := rng.randf()
	for key in table:
		if key.begins_with("_"):
			continue
		roll -= float(table[key])
		if roll < 0.0:
			return key
	return table.keys()[-1]


# --- Making items --------------------------------------------------------

## A new item of `base_id`, rolled by the tables. `quality` and
## `min_mods` can force a result (a lair's prize has at least one).
static func generate(rng: RandomNumberGenerator, base_id: String, quality := "", min_mods := 0) -> Equipment:
	var b := base(base_id)
	var rolls: Dictionary = tables()["rolls"]
	var item := _template(b)
	item.base_id = base_id
	item.gear_version = VERSION
	item.instance_id = rng.randi()
	item.quality = quality if quality != "" else _weighted(rng, rolls["quality"]["weights"])
	if b["slot"] == "weapon":
		item.damage_roll = int(_weighted(rng, rolls["stat_roll"]["weapon_damage_max"]))
		item.accuracy_roll = int(_weighted(rng, rolls["stat_roll"]["weapon_accuracy_points"])) / 100.0
	else:
		item.health_roll = int(_weighted(rng, rolls["stat_roll"]["body_health"]))
	var growth := {}
	for stat in b["grows"]:
		growth[stat] = _weighted(rng, rolls["growth"]["weights_by_quality"][item.quality])
	item.growth = growth
	var count := maxi(min_mods, int(_weighted(rng, rolls["modifier_count"][str(int(b["region"]))])))
	item.mods = PackedStringArray(_pick_mods(rng, b, count))
	apply(item)
	return item


## The base's look and feel: its live .tres, or a stand-in's until new art.
static func _template(b: Dictionary) -> Equipment:
	var file: String = b.get("live", b.get("template", ""))
	var item: Equipment = load("res://data/gear/%s.tres" % file).duplicate() if file != "" else Equipment.new()
	item.slot = b["slot"]
	if b.has("description"):
		item.description = b["description"]
	if b["slot"] == "weapon":
		item.reach = b.get("reach", false)
		item.light = b.get("light", false)
		item.force = b.get("force", true)
		item.strike = b.get("strike", "slash")
	item.effect = null
	item.curse = null
	return item


static func _pick_mods(rng: RandomNumberGenerator, b: Dictionary, count: int) -> Array:
	var pool: Array = []
	for m in tables()["modifiers"]["modifiers"]:
		if b["slot"] not in m["slots"]:
			continue
		if m.has("regions") and int(b["region"]) not in m["regions"].map(func(r): return int(r)):
			continue
		if m.get("reach_only", false) and not b.get("reach", false):
			continue
		if int(b["region"]) < int(m.get("min_region", 0)):
			continue
		pool.append(m)
	var strengths: Array = pool.filter(func(m): return m["kind"] != "drawback")
	var chosen: Array = []
	_shuffle(rng, strengths)
	for m in strengths:
		if chosen.size() >= count:
			break
		if _fits(chosen, m):
			chosen.append(m)
	if count >= 2 and chosen.size() >= 1 and rng.randf() < 0.25:  # a drawback buys a stronger strength
		var drawbacks: Array = pool.filter(func(m): return m["kind"] == "drawback")
		_shuffle(rng, drawbacks)
		for d in drawbacks:
			if _fits(chosen.slice(0, 1), d):
				chosen = chosen.slice(0, 1) + [d]
				break
	return chosen.map(func(m): return m["id"])


static func _fits(chosen: Array, m: Dictionary) -> bool:
	for c in chosen:
		if c["id"] == m["id"] or m["id"] in c.get("conflicts", []) or c["id"] in m.get("conflicts", []):
			return false
	var budget := 0
	for c in chosen:
		budget += int(c["cost"])
	return budget + int(m["cost"]) <= int(tables()["modifiers"]["max_budget"])


static func _shuffle(rng: RandomNumberGenerator, list: Array) -> void:
	for i in range(list.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t = list[i]
		list[i] = list[j]
		list[j] = t


## A find for a floor: a random base of the floor's region (not the heroes'
## own starting pieces), rolled.
static func random_find(rng: RandomNumberGenerator, depth: int, min_mods := 0) -> Equipment:
	var region := region_of(depth)
	var pool: Array = tables()["bases"]["bases"].filter(func(b): return int(b["region"]) == region and not b.get("no_drop", false))
	return generate(rng, pool[rng.randi_range(0, pool.size() - 1)]["id"], "", min_mods)


# --- An item's numbers ----------------------------------------------------

static func level_of(item: Equipment) -> int:
	var need := 1.25 if "brittle" in item.mods else 1.0
	var level := 0
	for row in tables()["mastery"]["levels"]:
		if item.mastery >= float(row["points"]) * need:
			level = int(row["level"])
	return level


## Points to reach the next level (0 at the cap).
static func next_points(item: Equipment) -> float:
	var need := 1.25 if "brittle" in item.mods else 1.0
	for row in tables()["mastery"]["levels"]:
		if item.mastery < float(row["points"]) * need:
			return float(row["points"]) * need
	return 0.0


static func _rate(item: Equipment, stat: String) -> float:
	var tier: String = item.growth.get(stat, "")
	return float(tables()["rolls"]["growth"]["rates"][stat][tier]) if tier != "" else 0.0


## Recomputes the item's numbers, name, border and effect from its rolls,
## mastery, tempering and modifiers.
static func apply(item: Equipment) -> void:
	var b := base(item.base_id)
	if b.is_empty():
		return
	var rolls: Dictionary = tables()["rolls"]
	var level := level_of(item)
	var effects: Dictionary = {}
	for key in b.get("effect", {}):
		effects[key] = b["effect"][key]
	var traits := {}
	var extra_damage := 0
	var extra_accuracy := 0.0
	for id in item.mods:
		var m := modifier(id)
		for key in m.get("effect", {}):
			var value = m["effect"][key]
			match key:
				"damage":
					extra_damage += int(value)
				"accuracy":
					extra_accuracy += float(value)
				"max_health", "back_row_damage":
					effects[key] = int(effects.get(key, 0)) + int(value)
				"strain_rate", "oil_rate", "healing":
					effects[key] = float(effects.get(key, 1.0)) * float(value)
				"reveals_traps":
					effects[key] = true
				_:
					traits[key] = value  # used by the fight rules (#192 phase 3)
	var shift := 0
	if b["slot"] == "weapon":
		var q: Dictionary = rolls["quality"]["weapon"][item.quality]
		var grow := floori(level * _rate(item, "damage") + 0.000001)
		var top := 1 if "weight" in item.tempers else 0
		shift = int(q["damage"]) + grow + extra_damage
		item.attack_min = maxi(1, int(b["damage"][0]) + shift)
		item.attack_max = maxi(item.attack_min, int(b["damage"][1]) + shift + item.damage_roll + top)
		item.accuracy_bonus = float(b["accuracy"]) + float(q["accuracy"]) + item.accuracy_roll + level * _rate(item, "accuracy") \
				+ extra_accuracy + (0.03 if "edge" in item.tempers else 0.0)
	else:
		var q: Dictionary = rolls["quality"]["body"][item.quality]
		var health: int = int(q["health"]) + item.health_roll + floori(level * _rate(item, "health") + 0.000001)
		if health != 0:
			effects["max_health"] = int(effects.get("max_health", 0)) + health
		var handling := floori(level * _rate(item, "handling") + 0.000001) + (1 if "refit" in item.tempers else 0)
		item.initiative_penalty = maxi(0, int(b.get("initiative_penalty", 0)) + int(q["initiative_penalty"]) - handling)
		item.armour = int(b.get("armour", 0)) + (1 if "plate" in item.tempers else 0)
		item.guard = int(b.get("guard", 0))
		item.pack_slots = int(b.get("pack_slots", 0))
		if extra_accuracy != 0.0:
			effects["accuracy"] = extra_accuracy
	item.traits = traits
	item.display_name = name_of(item)
	item.tier = ["common", "magic", "rare"][mini(2, item.mods.size())]
	var base_price: int = int(b.get("price", item.price))
	item.price = roundi(base_price * QUALITY_PRICE.get(item.quality, 1.0) * (1.0 + 0.5 * item.mods.size()))
	if effects.is_empty():
		item.effect = null
	else:
		var boon := Boon.new()
		boon.display_name = item.display_name
		for key in effects:
			boon.set(key, effects[key])
		boon.description = boon.effects_text()
		item.effect = boon


## "Cracked keen iron sword of the goblin-bane": quality (none for
## ordinary), then its modifiers around the base.
static func name_of(item: Equipment) -> String:
	var b := base(item.base_id)
	var name: String = b.get("name", item.display_name)
	for id in item.mods:
		var m_name: String = modifier(id).get("name", "")
		if m_name.begins_with("of "):
			name = "%s %s" % [name, m_name]
		elif m_name != "":
			name = "%s %s" % [m_name, name.substr(0, 1).to_lower() + name.substr(1)]
	if item.quality != "ordinary":  # the quality word leads: "Cracked keen iron sword"
		name = "%s %s" % [item.quality.capitalize(), name.substr(0, 1).to_lower() + name.substr(1)]
	return name


# --- Old gear -------------------------------------------------------------

## An item the new rules can track: the heroes' own pieces, the smith's
## stock and older generated finds become items with a base, quality and
## mastery (once). Items with no base (a broken knife, trinkets) are kept
## as they are.
static func ensure_instance(item: Equipment) -> Equipment:
	if item == null or item.base_id != NOWHERE or item.slot == "trinket":
		return item
	var id := _base_for(item)
	if id == NOWHERE:
		return item
	var inst: Equipment = item.duplicate() if item.resource_path != "" else item
	var b := base(id)
	inst.base_id = id
	inst.gear_version = VERSION
	inst.quality = "fine" if item.tier == "fine" else "ordinary"
	var growth := {}
	for stat in b["grows"]:
		growth[stat] = "steady"
	inst.growth = growth
	var mods := PackedStringArray()
	for word in LEGACY_MODS:
		if item.resource_path == "" and item.tier in ["magic", "rare"] and item.display_name.contains(word):
			mods.append(LEGACY_MODS[word])
	inst.mods = mods
	apply(inst)
	return inst


static func _base_for(item: Equipment) -> String:
	var file := item.resource_path.get_file().get_basename()
	for b in tables()["bases"]["bases"]:
		if file != "" and b.get("live", "") == file:
			return b["id"]
	if item.resource_path != "":
		return NOWHERE
	# An older generated find: named after its base ("Keen iron sword").
	var lower := item.display_name.to_lower()
	var best := NOWHERE
	for b in tables()["bases"]["bases"]:
		if b["slot"] != item.slot:
			continue
		var live: String = b.get("live", "")
		if live == "":
			continue
		var noun: String = (load("res://data/gear/%s.tres" % live) as Equipment).display_name.trim_prefix("Companion's ").to_lower()
		if lower.contains(noun) and (best == NOWHERE or noun.length() > base(best)["name"].length()):
			best = b["id"]
	return best


## Everyone's worn pieces as items (a new hero, or a save from before).
static func instance_hero(hero: Companion) -> void:
	hero.weapon = ensure_instance(hero.weapon)
	hero.body = ensure_instance(hero.body)
	hero.back = ensure_instance(hero.back)

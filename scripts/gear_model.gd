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


## The base's own price: bases.json, else its live or stand-in .tres. Never
## the item's current price, which already counts quality and modifiers
## (each apply() would multiply it again).
static func _base_price(b: Dictionary, item: Equipment) -> int:
	if b.has("price"):
		return int(b["price"])
	var file: String = b.get("live", b.get("template", ""))
	return load("res://data/gear/%s.tres" % file).price if file != "" else item.price


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
	# #219: keep strengths until drawbacks buy a genuinely stronger benefit.
	# Saved drawbacks retain their existing effects.
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

## The mastery thresholds for `item`: armour and shields have their own,
## lower ones, as they learn only from blows taken (#219, owner 2026-11-11).
static func level_rows(item: Equipment) -> Array:
	var t: Dictionary = tables()["mastery"]
	if item.slot != "weapon" and t.has("armour_levels"):
		return t["armour_levels"]
	return t["levels"]


static func level_of(item: Equipment) -> int:
	var need := 1.25 if "brittle" in item.mods else 1.0
	var level := 0
	for row in level_rows(item):
		if item.mastery >= float(row["points"]) * need:
			level = int(row["level"])
	return level


## How much more `item` sells for thanks to its mastery: a share of its
## value, capped low (mastery.json "resale"; owner, 2026-11-03).
static func mastery_value(item: Equipment) -> float:
	var r: Dictionary = tables()["mastery"]["resale"]
	return float(r["per_level"]) * mini(level_of(item), int(r["max_levels"]))


## Points to reach the next level (0 at the cap).
static func next_points(item: Equipment) -> float:
	var need := 1.25 if "brittle" in item.mods else 1.0
	for row in level_rows(item):
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
	refresh_art(item)
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
	var base_price := _base_price(b, item)
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
	for id in (item.mods if item.identified else PackedStringArray()):
		var m_name: String = modifier(id).get("name", "")
		if m_name.begins_with("of "):
			name = "%s %s" % [name, m_name]
		elif m_name != "":
			name = "%s %s" % [m_name, name.substr(0, 1).to_lower() + name.substr(1)]
	if item.quality != "ordinary":  # the quality word leads: "Cracked keen iron sword"
		name = "%s %s" % [item.quality.capitalize(), name.substr(0, 1).to_lower() + name.substr(1)]
	if not item.identified:  # "Unidentified fine iron sword"
		name = "Unidentified %s" % (name.substr(0, 1).to_lower() + name.substr(1))
	return name


# --- Identification (owner, 2026-11-03) -----------------------------------

## A found piece with modifiers starts unidentified: its type, quality and
## border show, its modifiers and any curse don't. It works in full anyway.
static func conceal(item: Equipment) -> Equipment:
	if item != null and item.base_id != NOWHERE and not item.mods.is_empty():
		item.identified = false
		apply(item)
	return item


## What the party can tell of `item`: the piece itself once identified,
## else the same piece with no modifiers and no curse (for its numbers,
## effect and resale price).
static func known(item: Equipment) -> Equipment:
	if item == null or item.identified:
		return item
	var plain: Equipment = item.duplicate()
	plain.mods = PackedStringArray()
	plain.curse = null
	apply(plain)
	return plain


## Reads `item`: its modifiers and any curse show. Returns what it turned
## out to be, or "" if there was nothing to read.
static func identify(item: Equipment) -> String:
	if item == null or item.identified:
		return ""
	item.identified = true
	apply(item)
	var parts := PackedStringArray()
	for id in item.mods:
		parts.append(modifier(id).get("text", ""))
	var text := "Identified: %s (%s)." % [item.display_name, ", ".join(parts)]
	if item.curse:
		text += " It carries a curse: %s." % item.curse.display_name.to_lower()
	return text


# --- Mastery (#192/#193) --------------------------------------------------

## How much a foe teaches: its threat against the region's usual, from a
## quarter (trivial) to double.
static func threat_factor(threat: int, region: int) -> float:
	var t: Dictionary = tables()["mastery"]
	var usual: float = float(t["region_threat"].get(str(region), 3.0))
	return clampf(threat / usual, float(t["trivial_foes"]["threat_factor_floor"]), 2.0)


## Adds mastery to `item`; practised hands double it while the item is 2+
## levels behind the best of its slot among `owned`. Returns the new level
## if it rose, else -1.
static func award(item: Equipment, points: float, owned: Array = []) -> int:
	if item == null or item.base_id == "" or points <= 0.0:
		return -1
	var t: Dictionary = tables()["mastery"]
	var before := level_of(item)
	var best := 0
	for other in owned:
		if other is Equipment and other != item and other.slot == item.slot and other.base_id != "":
			best = maxi(best, level_of(other))
	if best - before >= int(t["catch_up"]["levels_behind"]):
		points *= float(t["catch_up"]["multiplier"])
	item.mastery += points
	var after := level_of(item)
	if after != before:
		apply(item)
		return after
	return -1


## The smith's tempering (#173): at mastery 3, then 6, one chosen
## improvement each. Returns 3 or 6 when one is due, else 0.
static func temper_due(item: Equipment) -> int:
	if item == null or item.base_id == "":
		return 0
	var level := level_of(item)
	if level >= 6 and item.tempers.size() == 1:
		return 6
	if level >= 3 and item.tempers.is_empty():
		return 3
	return 0


## The choices for `item` at that step: [{id, text}].
static func temper_options(item: Equipment) -> Array:
	var due := temper_due(item)
	var out: Array = []
	for o in tables()["mastery"]["smith_temper"]["options"]:
		if item.slot in o["slots"] and due >= int(o.get("min_level", 0)) and o["id"] not in item.tempers:
			out.append(o)
	return out


## Gold and material for that step, and which material (its own region's).
static func temper_cost(item: Equipment) -> Dictionary:
	var t: Dictionary = tables()["mastery"]["smith_temper"]
	var cost: Dictionary = t["cost"].get(str(temper_due(item)), {"gold": 0, "material": 0})
	var region := str(int(base(item.base_id).get("region", 1)))
	return {"gold": int(cost["gold"]), "material": int(cost["material"]), "material_id": t["materials"][region]}


## After a wipe (#174, owner 2026-10-30): the camp's plain spare kit for
## `hero`: an ordinary weapon like the one they started with, and a quilted
## coat. No modifiers, middling rolls, no mastery.
static func fallback_kit(hero: Companion) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([hero.display_name, "spare kit"])
	var weapon_base := "oak_club"
	if hero.companion_weapon and hero.companion_weapon.base_id != "":
		weapon_base = hero.companion_weapon.base_id
	elif hero.companion_weapon:
		weapon_base = _base_for(hero.companion_weapon)
	var kit: Array = []
	for id in [weapon_base, "quilted_coat"]:
		var item := generate(rng, id, "ordinary")
		item.damage_roll = 0
		item.accuracy_roll = 0.0
		item.health_roll = 0
		var g := {}
		for stat in item.growth:
			g[stat] = "steady"
		item.growth = g
		item.mods = PackedStringArray()
		apply(item)
		kit.append(item)
	return kit


## Every weapon, armour and back piece the party holds, worn or carried.
static func owned_by(party) -> Array:
	var out: Array = party.supplies.gear.duplicate()
	for hero in party.members:
		for item in [hero.weapon, hero.body, hero.back]:
			if item:
				out.append(item)
	return out


# --- The item card (#192 phase 4; owner-approved layout 2026-10-31) --------

const GROWTH_WORDS := {"damage": "damage", "accuracy": "to hit", "health": "health", "handling": "handling"}

## What an item's card adds: mastery and progress, growth and what the next
## level brings, modifiers and tempering in words, and whether the smith can
## temper it. Plain text lines (the cards wrap them); no special glyphs, so
## the web build's fonts can show them.
static func card_lines(item: Equipment) -> PackedStringArray:
	var lines := PackedStringArray()
	if item == null or item.base_id == "":
		return lines
	var level := level_of(item)
	var next := next_points(item)
	if next > 0.0:
		lines.append("Mastery %d · %s / %d to mastery %d" % [level, _num(item.mastery), roundi(next), level + 1])
	else:
		lines.append("Mastery %d: as far as it goes" % level)
	var growth := PackedStringArray()
	for stat in item.growth:
		var rate := _rate(item, stat)
		var every := "" if rate <= 0.0 else ("+%s per level" % _num(rate * (100.0 if stat == "accuracy" else 1.0)) if rate >= 1.0 or stat == "accuracy" else ("+1 every %d levels" if is_equal_approx(1.0 / rate, roundf(1.0 / rate)) else "+1 about every %d levels") % roundi(1.0 / rate))
		growth.append("%s %s%s" % [item.growth[stat], GROWTH_WORDS.get(stat, stat), " (" + every + ("%" if stat == "accuracy" else "") + ")" if every != "" else ""])
	if not growth.is_empty():
		lines.append("Growth: " + ", ".join(growth))
	if next > 0.0:
		var ahead: Equipment = item.duplicate()
		ahead.mastery = next
		apply(ahead)
		var change := _change(item, ahead)
		if change != "":
			lines.append("At mastery %d: %s" % [level + 1, change])
	if not item.identified:
		var hidden := item.mods.size()
		lines.append("Unidentified: %d hidden propert%s. The smith, a touchstone or the Discern prayer can read it." % [hidden, "y" if hidden == 1 else "ies"])
	for id in (item.mods if item.identified else PackedStringArray()):
		var m := modifier(id)
		lines.append("%s: %s" % [m.get("name", id).trim_prefix("of ").capitalize() if m.get("name", "").begins_with("of ") else m.get("name", id), m.get("text", "")])
	for id in item.tempers:
		for o in tables()["mastery"]["smith_temper"]["options"]:
			if o["id"] == id:
				lines.append("Tempered: " + o["text"])
	if mastery_value(item) > 0.0:
		var r: Dictionary = tables()["mastery"]["resale"]
		lines.append("Mastery adds %d%% to its sale price (up to %d%%)" % [roundi(mastery_value(item) * 100), roundi(float(r["per_level"]) * int(r["max_levels"]) * 100)])
	if temper_due(item) > 0:
		lines.append("Ready to temper at the smith")
	return lines


static func _num(x: float) -> String:
	return str(roundi(x)) if is_equal_approx(x, roundf(x)) else "%.1f" % x


## What changed between two copies of an item, in words.
static func _change(a: Equipment, b: Equipment) -> String:
	var parts := PackedStringArray()
	if a.slot == "weapon":
		if a.attack_min != b.attack_min or a.attack_max != b.attack_max:
			parts.append("damage %d-%d" % [b.attack_min, b.attack_max])
		if not is_equal_approx(a.accuracy_bonus, b.accuracy_bonus):
			parts.append("%+d%% to hit" % roundi(b.accuracy_bonus * 100))
	else:
		var ha: int = a.effect.max_health if a.effect else 0
		var hb: int = b.effect.max_health if b.effect else 0
		if ha != hb:
			parts.append("%+d health in all" % hb)
		if a.initiative_penalty != b.initiative_penalty:
			parts.append("slower by %d" % b.initiative_penalty if b.initiative_penalty > 0 else "no slowing")
	return ", ".join(parts)


# --- Old gear -------------------------------------------------------------

## An item the new rules can track: the heroes' own pieces, the smith's
## stock and older generated finds become items with a base, quality and
## mastery (once). Items with no base (a broken knife, trinkets) are kept
## as they are.
static func ensure_instance(item: Equipment) -> Equipment:
	if item != null and item.base_id != NOWHERE:
		refresh_art(item)  # existing saves keep their rolls, but get current base art
		if item.slot != "weapon":
			apply(item)  # armour/shield thresholds fell (#219): saved points may now mean a higher level
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


## Presentation only: template resources may be shared by several bases.
static func refresh_art(item: Equipment) -> void:
	var b := base(item.base_id)
	if b.has("icon"):
		item.icon = load(b["icon"]) as Texture2D
		item.description = b.get("description", item.description)


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

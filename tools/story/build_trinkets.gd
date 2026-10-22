extends SceneTree
## Writes the first trinkets (#135, owner 2026-10-21) into data/trinkets.
## Rerun to rebuild:
##   Godot --headless --path . --script tools/story/build_trinkets.gd
##
## Magic: a modifier (here a benefit with a drawback). Rare: two benefits.
## Unique: a playstyle buff. Cursed ones pose as magic until worn. A trinket
## has no base numbers to improve, so none are common or fine (owner,
## 2026-10-21). Unique and curse-pair icons use #142; other jewellery reuses its treasure art.

const DIR := "res://data/trinkets"


func _effect(name: String, effects: Dictionary) -> Boon:
	var b := Boon.new()
	b.display_name = name
	for key in effects:
		b.set(key, effects[key])
	var text := b.effects_text()
	b.description = text.substr(0, 1).to_upper() + text.substr(1) + "."
	return b


func _icon(item: String) -> Texture2D:
	return (load("res://data/items/%s.tres" % item) as SupplyItem).icon


func _trinket(id: String, name: String, about: String, tier: String, effects: Dictionary, icon: String, extra := {}) -> Equipment:
	var t := Equipment.new()
	t.slot = "trinket"
	t.display_name = name
	t.description = about
	t.tier = tier
	t.effect = _effect(name, effects)
	var art_id: String = id.trim_suffix("_cursed").replace("_", "-")
	art_id = {"bone-charm": "bone-white-charm", "goblin-torc": "goblin-gold-torc"}.get(art_id, art_id)
	var art_path := "res://art/items/trinkets-v1/%s.png" % art_id
	t.icon = load(art_path) if ResourceLoader.exists(art_path) else _icon(icon)
	t.attack_min = 0
	t.attack_max = 0
	for key in extra:
		t.set(key, extra[key])
	var path := DIR.path_join(id + ".tres")
	print(path, " ", "ok" if ResourceSaver.save(t, path) == OK else "FAILED")
	return load(path)


## Jewellery from the treasure tables, now wearable (sold as treasure still).
func _jewel(id: String, item: String, name: String, about: String, tier: String, effects: Dictionary) -> void:
	_trinket(id, name, about, tier, effects, item, {"treasure": load("res://data/items/%s.tres" % item)})


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	# Magic: a benefit and a drawback.
	_jewel("leaf_brooch", "silver_trinket", "Silver leaf brooch", "A light thing to wear. The eye goes to it, and from it.", "magic", {"accuracy": 0.06, "strain_rate": 1.2})
	_jewel("campaign_medal", "military_medal", "Faded campaign medal", "Someone else's courage, pinned on. It helps, a little. It weighs, a little.", "magic", {"strain_rate": 0.75, "max_health": -2})
	_jewel("sprig_locket", "silver_locket", "Silver sprig locket", "A pressed sprig of herb inside. The smell is a comfort; the clasp catches your sleeve.", "magic", {"healing": 1.25, "accuracy": -0.05})
	# Magic too: a clearer benefit, a smaller drawback.
	_jewel("amber_pendant", "amber_pendant", "Amber tear pendant", "Warm against the skin, as if it kept a little of the sun.", "magic", {"max_health": 3, "oil_rate": 1.1})
	_jewel("gold_signet", "gold_signet_ring", "Worn gold signet", "A noble's seal, heavy on the hand. Your blows land heavier too.", "magic", {"damage": 1, "strain_rate": 1.1})
	# Rare: two benefits.
	_jewel("gilt_reliquary", "small_reliquary", "Gilt reliquary", "A saint's knuckle in gold. Whoever's it was, they were steady.", "rare", {"strain_rate": 0.75, "max_health": 2})
	# Unique: a playstyle buff. Only from quests, the fortress and below.
	var unique := {"price": 50}
	_trinket("bloodstone", "Bloodstone", "A red stone that warms as you bleed.", "unique", {"low_health_damage": 2}, "garnet", unique)
	_trinket("moth_wing_brooch", "Moth-wing brooch", "Dust-grey wings in silver. It loves the light, and hates the dark.", "unique", {"light_accuracy": 0.10}, "silver_trinket", unique)
	_trinket("slingers_thumb_ring", "Slinger's thumb-ring", "Horn, worn smooth by a thousand releases.", "unique", {"back_row_damage": 1}, "gold_signet_ring", unique)
	_trinket("ember_ring", "Ember ring", "A coal-dark ring, always faintly warm.", "unique", {"torch_burn": 3}, "amber_pendant", unique)
	_trinket("gamblers_knucklebone", "Gambler's knucklebone", "Rolled in a hundred taverns. It wins more than it should, and draws the wrong eyes.", "unique", {"luck": 0.15, "draws_ambush": true}, "old_coin_purse", unique)
	_trinket("shield_bearers_token", "Shield-bearer's token", "A tin badge of the king's shield line.", "unique", {"defend_steadies": 6.0}, "military_medal", unique)
	# Cursed: they look fine until worn. Cleansing leaves the good part.
	var cursed := {"price": 40}
	var pearl := _trinket("black_pearl_ring", "Black pearl ring", "A black pearl, perfect, set in old silver.", "magic", {"damage": 1}, "pearl_necklace", cursed)
	var charm := _trinket("bone_charm", "Bone-white charm", "A carved bone, smooth and pale, on a cord.", "magic", {"strain_rate": 0.75}, "silver_locket", cursed)
	var torc := _trinket("goblin_torc", "Goblin gold torc", "Crude, heavy and gold. Goblin work, but good gold.", "magic", {"accuracy": 0.08}, "gold_nuggets", cursed)
	_trinket("black_pearl_ring_cursed", "Black pearl ring", pearl.description, "magic", {"damage": 1}, "pearl_necklace",
			{"price": 40, "curse": load("res://data/boons/marked.tres"), "cleansed": pearl})
	_trinket("bone_charm_cursed", "Bone-white charm", charm.description, "magic", {"strain_rate": 0.75}, "silver_locket",
			{"price": 40, "curse": load("res://data/boons/withering.tres"), "cleansed": charm})
	_trinket("goblin_torc_cursed", "Goblin gold torc", torc.description, "magic", {"accuracy": 0.08}, "gold_nuggets",
			{"price": 40, "curse": load("res://data/boons/sickness.tres"), "cleansed": torc})
	print("done")
	quit()

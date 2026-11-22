extends RefCounted
## Chest tiers (owner, 2026-11-22): common, silver and gold, the rarer the
## richer. Common chests are the floor's ordinary ones (their own contents,
## and now and then a finer piece). Silver sits behind a puzzle or in a
## lair's hoard; gold is kept for exceptionally hard things: a named elite
## pack and the Goblin King.
##   common - its event's contents; a chance of a gear find (as before).
##   silver - plus one certain find with a modifier, some gold, and a fair
##            chance of a trinket.
##   gold   - plus a rarer find (two modifiers), a second find, more gold
##            and a likely trinket.
## A chest's tier lives in map.marks["chest_tiers"] (cell -> tier); cells
## without one are common. Art: ChatGPT's chests (art/props/chests-v1/
## <tier>.tscn) when they land; until then the strongbox with a glint.
## Static helpers only (no static variables: see #100).

const GearGen := preload("res://scripts/gear_gen.gd")
const GearModel := preload("res://scripts/gear_model.gd")
const Trinkets := preload("res://scripts/trinkets.gd")

const TIERS := ["common", "silver", "gold"]
const ART := "res://art/props/chests-v1/%s.tscn"
## The chest a fight or a hoard leaves behind, by tier.
const HOARD_EVENT := "res://data/events/chest_%s_hoard.tres"

## What each tier adds on top of the chest's own contents.
const LOOT := {
	"silver": {"finds": [1], "gold": 10, "gold_per_floor": 5, "trinket": 0.35},
	"gold": {"finds": [2, 1], "gold": 30, "gold_per_floor": 12, "trinket": 0.7},
}
## How it reads when found and opened.
const NAMES := {"common": "chest", "silver": "silver-bound chest", "gold": "gilded chest"}
## A glint for the stand-in art, so the tier shows in the dark.
const GLINT := {"silver": Color(0.78, 0.86, 1.0), "gold": Color(1.0, 0.8, 0.4)}


static func tier_at(map, cell: Vector2i) -> String:
	if map == null:
		return "common"
	return map.marks.get("chest_tiers", {}).get(cell, "common")


static func set_tier(map, cell: Vector2i, tier: String) -> void:
	if not map.marks.has("chest_tiers"):
		map.marks["chest_tiers"] = {}
	map.marks["chest_tiers"][cell] = tier


## The tier's extra loot on floor `depth`: {"gear": [Equipment], "gold": int,
## "trinket": Equipment or null}. Common: maybe one piece, as before.
static func loot(rng: RandomNumberGenerator, tier: String, depth: int) -> Dictionary:
	var out := {"gear": [], "gold": 0, "trinket": null}
	if not LOOT.has(tier):
		var find: Equipment = GearGen.drop(rng, depth, "chest")
		if find:
			out["gear"].append(find)
		return out
	var spec: Dictionary = LOOT[tier]
	for mods: int in spec["finds"]:
		out["gear"].append(GearModel.conceal(GearModel.random_find(rng, depth, mods)))  # read later (#223)
	out["gold"] = int(spec["gold"]) + int(spec["gold_per_floor"]) * depth
	if rng.randf() < float(spec["trinket"]):
		out["trinket"] = Trinkets.drop(rng, depth, 999, true)
	return out


## The chest's look: the tier's own art if it exists, else `fallback` (the
## event's prop) with a glint in the tier's colour.
static func prop(tier: String, fallback: PackedScene) -> Node3D:
	var path := ART % tier
	if ResourceLoader.exists(path):
		return load(path).instantiate()
	if fallback == null:
		return null
	var node: Node3D = fallback.instantiate()
	if GLINT.has(tier):
		var light := OmniLight3D.new()
		light.name = "TierGlint"
		light.light_color = GLINT[tier]
		light.light_energy = 0.9 if tier == "gold" else 0.6
		light.omni_range = 1.6
		light.position = Vector3(0, 0.7, 0)
		node.add_child(light)
		if tier == "gold":
			node.scale *= 1.12
	return node

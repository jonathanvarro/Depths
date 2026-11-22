extends RefCounted
## Art lookup only. Rarity distribution/rewards stay with the game's controllers.
const SCENES := {
	"common":"res://art/props/loot-chests-v2/common.tscn",
	"silver":"res://art/props/loot-chests-v2/silver.tscn",
	"gold":"res://art/props/loot-chests-v2/gold.tscn",
}

static func scene(kind: String) -> PackedScene:
	return load(SCENES[kind]) if SCENES.has(kind) else null

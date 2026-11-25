extends RefCounted
## Named elite packs (owner, 2026-11-22): instead of a random elite foe in
## an ordinary fight, each floor has a chance of one named pack, like the
## puzzles and lairs. It patrols the floor between rooms with its own low
## glow, so it can be seen coming (or avoided). Its leader carries two
## elite marks and its followers one each: an especially hard fight, with
## a hoard for the winners. Beaten, it stays beaten for that floor's day.
## The old random elites in ordinary fights are switched off
## (CombatState.RANDOM_ELITES); a killer's taste for blood (#177) remains.
## Static helpers only (no static variables: see #100).

const ENEMIES := "res://data/enemies/%s.tres"
const LEADER_MODELS := {
	"whisker": preload("res://art/enemies/named-leaders-v1/whisker.tscn"),
	"spinner": preload("res://art/enemies/named-leaders-v1/spinner.tscn"),
	"skarn": preload("res://art/enemies/named-leaders-v1/skarn.tscn"),
	"foreman": preload("res://art/enemies/named-leaders-v1/foreman.tscn"),
	"gristle": preload("res://art/enemies/named-leaders-v1/gristle.tscn"),
}

## id -> the pack. `floors`: where it can turn up. `types`: leader first.
## `marks`: the leader's two elite marks; followers take the second.
## `light`: the colour of its glow on the map.
const PACKS := {
	"whisker": {"name": "Old Whisker's brood", "leader": "Old Whisker", "floors": [1, 2],
		# Tougher (owner, 2026-11-24: easy and uneventful for a gold chest): a
		# second great rat, and Whisker herself quick and much harder to kill.
		"types": ["great_rat", "great_rat", "rat", "rat"], "marks": ["Hardened", "Savage"], "light": Color(0.62, 0.86, 0.42),
		"leader_marks": ["Swift"], "leader_health": 1.8,
		"seen": "A sickly green glow moves between the rooms: Old Whisker, grey as ash and big as a dog, and her brood."},
	"spinner": {"name": "The Pale Spinner", "leader": "The Pale Spinner", "floors": [2, 3],
		"types": ["webspinner", "spider", "spider"], "marks": ["Venomous", "Hardened"], "light": Color(0.62, 0.78, 1.0),
		"seen": "Something pale crawls the ceiling in a cold blue glow, trailing silk: the Pale Spinner and her young."},
	"skarn": {"name": "Skarn's raiders", "leader": "Skarn", "floors": [3, 4],
		"types": ["goblin_brute", "goblin", "goblin_archer"], "marks": ["Savage", "Hardened"], "light": Color(1.0, 0.55, 0.25),
		"seen": "Torchlight and laughter: Skarn's raiders, out hunting for trophies."},
	"foreman": {"name": "The Hollow Foreman's crew", "leader": "The Hollow Foreman", "floors": [3, 4, 5],
		"types": ["hollow_miner", "hollow_miner", "gas_bloat"], "marks": ["Hardened", "Swift"], "light": Color(0.95, 0.85, 0.45),
		"seen": "A miner's lamp swings in the dark, carried by something that stopped being a miner long ago: the Hollow Foreman, still walking his shift."},
	"gristle": {"name": "Gristle's pack", "leader": "Gristle", "floors": [3, 5],
		"types": ["breach_hound", "breach_hound", "breach_hound"], "marks": ["Swift", "Savage"], "light": Color(1.0, 0.3, 0.25),
		"seen": "Red eyes, low to the ground, and a smell of the breach: Gristle's pack is running the halls."},
}
## The chance a floor has a named pack today.
const CHANCE := {1: 0.25, 2: 0.4, 3: 0.5, 4: 0.5, 5: 0.5}
## The leader is tougher still.
const LEADER_HEALTH := 1.3
## The hoard: a rarer find than a lair's, and gold.
const HOARD_GOLD := 20
const HOARD_GOLD_PER_FLOOR := 10


## The pack (id) for floor `depth` today, or "". Only packs whose every kind
## the party has beaten before (`beaten`: display names; null for any), so
## a named rat-mother never comes before a plain rat (#226).
static func pick(depth: int, rng: RandomNumberGenerator, beaten = null) -> String:
	if rng.randf() >= CHANCE.get(depth, 0.0):
		return ""
	var ids: Array = PACKS.keys().filter(func(id): return depth in PACKS[id]["floors"] and (beaten == null or types(id).all(func(t: EnemyType): return t.display_name in beaten)))
	if ids.is_empty():
		return ""
	return ids[rng.randi_range(0, ids.size() - 1)]


static func types(id: String) -> Array[EnemyType]:
	var out: Array[EnemyType] = []
	for name: String in PACKS[id]["types"]:
		out.append(load(ENEMIES % name))
	# Both patrol and combat ask here. Only the leader gets a private art binding;
	# shared definitions, followers and the Settings sprite fallback stay intact.
	out[0]=out[0].duplicate(false)
	out[0].model=LEADER_MODELS[id]
	return out


## Where it starts: an empty room cell as far from `from` (the stairs) as the
## floor allows, outside any room fight.
static func start_cell(map, from: Vector2i) -> Vector2i:
	var distances: Dictionary = map.walking_distances(from)
	var best := Vector2i(-1, -1)
	for cell: Vector2i in distances:
		if not map._is_room_cell(cell) or map.content_at(cell) != map.Content.NONE or map.encounter_zones.has(cell) or map.solid.has(cell):
			continue
		if best == Vector2i(-1, -1) or distances[cell] > distances[best]:
			best = cell
	return best


## A room cell to walk to next on patrol.
static func patrol_target(map, rng: RandomNumberGenerator, from: Vector2i) -> Vector2i:
	var rooms: Array = map.walking_distances(from).keys().filter(func(c): return map._is_room_cell(c) and not map.solid.has(c) and c.distance_to(from) > 4)
	if rooms.is_empty():
		return from
	return rooms[rng.randi_range(0, rooms.size() - 1)]


## Makes the fight's foes the named pack: the leader takes both marks, its
## name and more health; the followers take the second mark.
static func empower(state, id: String) -> void:
	var pack: Dictionary = PACKS[id]
	for i in state.foes.size():
		var foe = state.foes[i]
		if i == 0:
			state.make_elite(foe, pack["marks"][1])
			state.make_elite(foe, pack["marks"][0])
			for mark: String in pack.get("leader_marks", []):
				state.make_elite(foe, mark)
			var type: EnemyType = foe.type.duplicate()
			type.max_health = roundi(type.max_health * float(pack.get("leader_health", LEADER_HEALTH)))
			foe.type = type
			foe.health = type.max_health
			foe.name = pack["leader"]
		else:
			state.make_elite(foe, pack["marks"][1])
		state.plan(foe)
	state._build_order()  # a Swift pack acts sooner


## A low glow for the pack on the map, in its own colour.
static func glow(id: String) -> OmniLight3D:
	var light := OmniLight3D.new()
	light.name = "EliteGlow"
	light.light_color = PACKS[id]["light"]
	light.light_energy = 1.4
	light.omni_range = 4.0
	light.position = Vector3(0, 1.1, 0)
	light.shadow_enabled = false
	return light

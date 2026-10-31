extends RefCounted
## Fights on the map, phase 1 (#171; owner 2026-10-30/31, DESIGN.md "The
## expedition loop" and "The party as one unit"). Monsters stand on the map
## as groups: a room's fight waits in its room, a wanderer comes looking.
## A group notices the party when it sees it (a straight, open line, as far
## as the party's light reaches) or when the party walks into its room.
## Once it has noticed, it closes in one cell every beat - a step or a Wait;
## turning and looking are free. Next to the party, the fight begins. Walk up
## to one that hasn't noticed you, and you strike first.
## Phase 1 still fights on the battle stage; phase 2 keeps it in the corridor.
## Static helpers plus the Group record (no static variables: see #100).

const Supplies := preload("res://scripts/supplies.gd")

## How far a group sees the party, in cells, by the party's light: a bright
## lamp is seen from further off.
const SIGHT := {
	Supplies.Light.OUT: 1,
	Supplies.Light.DIM: 2,
	Supplies.Light.STEADY: 4,
	Supplies.Light.BRIGHT: 5,
}
## Where a wanderer appears: this many steps away, out of sight if possible.
const SPAWN_DISTANCE := Vector2i(5, 8)
const NOWHERE := Vector2i(-1, -1)


class Group:
	var home := NOWHERE  # its room fight's cell; NOWHERE for a wanderer
	var cell := NOWHERE
	var types: Array[EnemyType] = []
	var noticed := false
	var rested := false  # a slow group rests every other beat
	var node: Node3D  # its sprite on the map, set by main.gd

	func is_wanderer() -> bool:
		return home == NOWHERE


## The room fights on `map` that stand on the map: not ones already fought,
## not lairs or a quest's own fight (those keep their old trigger).
## `pick`: Callable(fight_cell) -> Array[EnemyType].
static func room_groups(map, pick: Callable) -> Array:
	var groups := []
	var seen := {}
	for zone_cell in map.encounter_zones:
		var fight_cell: Vector2i = map.encounter_zones[zone_cell]
		if seen.has(fight_cell) or map.triggered.has(fight_cell) or map.lairs.has(fight_cell) or map.fight_groups.has(fight_cell):
			continue
		seen[fight_cell] = true
		var group := Group.new()
		group.home = fight_cell
		group.cell = fight_cell
		group.types.assign(pick.call(fight_cell))
		groups.append(group)
	return groups


static func adjacent(a: Vector2i, b: Vector2i) -> bool:
	return absi(a.x - b.x) + absi(a.y - b.y) <= 1


## A straight, open line from `from` to `to`, at most `reach` cells.
static func sees(map, from: Vector2i, to: Vector2i, reach: int) -> bool:
	if from.x != to.x and from.y != to.y:
		return false
	var distance := absi(to.x - from.x) + absi(to.y - from.y)
	if distance > reach:
		return false
	var step := Vector2i(signi(to.x - from.x), signi(to.y - from.y))
	var cell := from + step
	while cell != to:
		if not map.is_passable(cell) or map.door_at(cell) == 1:  # a shut door hides you
			return false
		cell += step
	return true


## Whether `group` notices the party at `party_cell`, lit to `band`.
static func notices(map, group: Group, party_cell: Vector2i, band: int) -> bool:
	if group.noticed:
		return true
	if group.home != NOWHERE and map.encounter_zones.get(party_cell, NOWHERE) == group.home:
		return true  # walked into its room
	return sees(map, group.cell, party_cell, SIGHT.get(band, 3))


## One cell toward `target`, unless that cell is taken (`blocked`) or it's
## already beside it.
static func step_toward(map, group: Group, target: Vector2i, blocked: Dictionary) -> bool:
	if adjacent(group.cell, target):
		return false
	if not group.types.is_empty() and group.types[0].slow:
		group.rested = not group.rested  # slow: every other beat (#171)
		if group.rested:
			return false
	var path: Array[Vector2i] = map.walking_path(group.cell, target)
	if path.size() < 3:
		return false
	var next: Vector2i = path[1]
	if blocked.has(next) or next == target:
		return false
	group.cell = next
	return true


## Where a wanderer appears: walkable, empty, a few steps away and out of
## the party's sight if any cell allows; NOWHERE if the floor has no room.
static func spawn_cell(map, party_cell: Vector2i, rng: RandomNumberGenerator, taken: Dictionary) -> Vector2i:
	var distances: Dictionary = map.walking_distances(party_cell)
	var hidden: Array[Vector2i] = []
	var any: Array[Vector2i] = []
	for cell: Vector2i in distances:
		var d: int = distances[cell]
		if d < SPAWN_DISTANCE.x or d > SPAWN_DISTANCE.y or taken.has(cell) or map.content_at(cell) != 0:
			continue
		any.append(cell)
		if not sees(map, cell, party_cell, SPAWN_DISTANCE.y):
			hidden.append(cell)
	var pool := hidden if not hidden.is_empty() else any
	return pool[rng.randi_range(0, pool.size() - 1)] if not pool.is_empty() else NOWHERE

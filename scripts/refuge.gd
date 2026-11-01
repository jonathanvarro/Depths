extends RefCounted
## The scouts' refuge (owner choice 2026-11-01): a sheltered fire on floor
## 3, near the stairs down to the fortress, where the party can make camp
## once a trip before facing the gate and the queen. It's an underground
## camp (DESIGN "Underground camps preserve the expedition"): resting there
## keeps the expedition and its levels. It's a rest spot ('R') with its own
## event, data/events/refuge_scouts.tres; the floor's cave shifts each day,
## so a new trip finds it fresh.

const DungeonMap := preload("res://scripts/dungeon_map.gd")
const EVENT := preload("res://data/events/refuge_scouts.tres")
const DEPTH := 3


## Marks the refuge on `layout`: the empty room cell closest to the stairs
## down, outside any fight's room. Returns {"layout", "cell"}; cell is
## (-1, -1) when the floor has no room for it.
static func place(layout: PackedStringArray, depth: int) -> Dictionary:
	var map = DungeonMap.new(layout, depth)
	var down: Vector2i = map.find_content(DungeonMap.Content.STAIRS_DOWN)
	var out := {"layout": layout, "cell": Vector2i(-1, -1)}
	if down == Vector2i(-1, -1):
		return out
	var distances: Dictionary = map.walking_distances(down)
	var best := Vector2i(-1, -1)
	for cell: Vector2i in distances:
		if cell == down or cell == map.start_cell or not map._is_room_cell(cell):
			continue
		if map.content_at(cell) != DungeonMap.Content.NONE or map.encounter_zones.has(cell):
			continue
		if best == Vector2i(-1, -1) or distances[cell] < distances[best]:
			best = cell
	if best == Vector2i(-1, -1):
		return out
	var rows := PackedStringArray(layout)
	var row := rows[best.y]
	rows[best.y] = row.substr(0, best.x) + "R" + row.substr(best.x + 1)
	out["layout"] = rows
	out["cell"] = best
	return out

extends RefCounted
## Lights on the walls (owner playtest, 2026-11-23). The bigger floors are
## fun to explore, so the cave gives a little light back:
## - "torch": a spare torch left in an old bracket. Walking up to it takes
##   it (if the pack has room). Torches as loot.
## - "lantern": a miners' lantern with a little oil still in it. Lit, it
##   burns for a while (BURN time units) and lights its room, or a short
##   stretch of corridor: standing there counts as being in the light, so
##   the map works again and nerves ease very slightly.
## Placed once per floor layout and kept on `map.marks["wall_lights"]`
## (saved with the map): cell -> {"side", "kind", "taken", "lit_until"}.
## Rules only here; main.gd builds the art and asks the questions.

const Dressing := preload("res://scripts/dressing.gd")
const DungeonMap := preload("res://scripts/dungeon_map.gd")

const TORCHES := Vector2i(1, 2)  # spare torches per floor (least, most)
const LANTERNS := Vector2i(2, 3)  # old lanterns per floor
const SPACING := 8  # cells apart, at least (across the grid)
const AWAY_FROM_STAIRS := 4
const BURN := 200  # time units a lit lantern lasts (a step is 1)
const CORRIDOR_REACH := 9  # cells a lantern lights along a corridor
const LIGHTING_RELIEF := -3.0  # strain, once, for each hero when one is lit


## Chooses this floor's wall lights (seeded, so a layout keeps them).
static func place(map, depth: int, seed: int) -> void:
	var lights := {}
	map.marks["wall_lights"] = lights
	if depth < 1:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([seed, depth, "wall_lights"])
	var stairs: Array = [map.find_content(DungeonMap.Content.STAIRS_UP), map.find_content(DungeonMap.Content.STAIRS_DOWN)]
	var spots: Array[Vector2i] = []
	for y in map.height:
		for x in map.width:
			var cell := Vector2i(x, y)
			if _usable(map, cell, stairs):
				spots.append(cell)
	for i in range(spots.size() - 1, 0, -1):  # shuffle with our own generator
		var j := rng.randi_range(0, i)
		var swap := spots[i]
		spots[i] = spots[j]
		spots[j] = swap
	var wanted: Array = []
	for i in rng.randi_range(TORCHES.x, TORCHES.y):
		wanted.append("torch")
	for i in rng.randi_range(LANTERNS.x, LANTERNS.y):
		wanted.append("lantern")
	for cell in spots:
		if wanted.is_empty():
			break
		if lights.keys().any(func(c): return absi(c.x - cell.x) + absi(c.y - cell.y) < SPACING):
			continue
		var sides: Array = Dressing._wall_sides(map, cell)
		lights[cell] = {"side": sides[rng.randi_range(0, sides.size() - 1)], "kind": wanted.pop_front(), "taken": false, "lit_until": -1}


static func _usable(map, cell: Vector2i, stairs: Array) -> bool:
	if not map.is_passable(cell) or map.content_at(cell) != DungeonMap.Content.NONE or map.door_at(cell) != DungeonMap.Door.NONE:
		return false
	if map.events.has(cell) or map.solid.has(cell) or map.water.has(cell) or cell == map.start_cell or Dressing._wall_sides(map, cell).is_empty():
		return false
	for s: Vector2i in stairs:
		if s != Vector2i(-1, -1) and absi(s.x - cell.x) + absi(s.y - cell.y) < AWAY_FROM_STAIRS:
			return false
	for site: Rect2i in map.marks.get("quests", {}).values():
		if site.grow(1).has_point(cell):
			return false
	for p: Dictionary in map.marks.get("puzzles", []):
		for value in p.values():
			if value is Vector2i and absi(value.x - cell.x) + absi(value.y - cell.y) <= 1:
				return false
	return not cell in map.marks.get("hall", []) and not cell in map.marks.get("gates", []) \
			and cell != map.marks.get("refuge", Vector2i(-1, -1))


static func at(map, cell: Vector2i) -> Dictionary:
	return map.marks.get("wall_lights", {}).get(cell, {})


static func is_lit(light: Dictionary, time: int) -> bool:
	return light.get("kind") == "lantern" and time < int(light.get("lit_until", -1))


## Lights the lantern at `cell` until `time` + BURN.
static func light(map, cell: Vector2i, time: int) -> void:
	at(map, cell)["lit_until"] = time + BURN


## The cells a lit lantern lights: its room, or a short stretch of corridor.
static func lit_area(map, cell: Vector2i) -> Array[Vector2i]:
	return map.area_around(cell, CORRIDOR_REACH)


## True if `cell` is lit by any burning lantern on this floor.
static func lights_cell(map, cell: Vector2i, time: int) -> bool:
	var lights: Dictionary = map.marks.get("wall_lights", {})
	for spot in lights:
		if is_lit(lights[spot], time) and (spot == cell or cell in lit_area(map, spot)):
			return true
	return false

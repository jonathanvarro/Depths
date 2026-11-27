extends RefCounted
## The Buried City's floor (owner asked to start it, 2026-11-26; reached over
## the Sappers' bridge from the Black Reservoir, #305). Streets carved under
## the rock in a grid, houses on the blocks between them, some lanes fallen
## in. Unlike the cave's rooms and corridors, the streets all look alike:
## the area leans on Scouts (challenges.gd).
##
## Layout symbols are the cave's (dungeon_map.gd): ',' house or plaza floor,
## '.' street, '<' the stair back up to the bridge, 'D' a house's shut door,
## 'B' fallen stone across a street (only where another way round exists),
## and room contents. No way further down yet.
##
## Static helpers only (no static variables: see #100).

const Challenges := preload("res://scripts/challenges.gd")
const FloorGenerator := preload("res://scripts/floor_generator.gd")

const WIDTH := 35
const HEIGHT := 35
## Streets run along these rows and columns; blocks lie between them.
const LINES := [2, 9, 16, 23, 30]
## A street segment (between two crossings) falls in with this chance.
const FALLEN_CHANCE := 0.22
## A house's doorway is shut with this chance.
const SHUT_CHANCE := 0.45
## A standing street segment is choked with fallen stone with this chance
## (kept only if the city stays connected without it).
const CHOKED_CHANCE := 0.12
## Chance that a house holds something.
const CONTENT_CHANCE := 0.75

const NEIGHBOURS: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]


static func generate(seed_value: int, depth := 7, area := "city") -> PackedStringArray:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var grid := {}  # Vector2i -> symbol; absent = rock
	# Streets.
	for line in LINES:
		for i in range(LINES[0], LINES[-1] + 1):
			grid[Vector2i(i, line)] = "."
			grid[Vector2i(line, i)] = "."
	# Fallen lanes: whole segments between crossings turn back to rock, as
	# long as every crossing still joins up.
	var segments: Array = []
	for a in LINES.size():
		for b in LINES.size() - 1:
			segments.append([Vector2i(LINES[b], LINES[a]), Vector2i(LINES[b + 1], LINES[a])])  # along a row
			segments.append([Vector2i(LINES[a], LINES[b]), Vector2i(LINES[a], LINES[b + 1])])  # along a column
	for seg in segments:
		if rng.randf() >= FALLEN_CHANCE:
			continue
		var inner := _segment_cells(seg)
		for c in inner:
			grid.erase(c)
		if not _joined(grid):
			for c in inner:
				grid[c] = "."
	# The threshold plaza: the bottom middle block, where the stair from
	# the bridge comes in.
	var plaza := Rect2i(LINES[2] - 4, LINES[-1] + 1, 9, 3)
	for y in range(plaza.position.y, plaza.end.y):
		for x in range(plaza.position.x, plaza.end.x):
			grid[Vector2i(x, y)] = ","
	var stair := Vector2i(LINES[2], plaza.end.y - 1)
	grid[stair] = "<"
	# Houses: one per block, with a doorway onto a standing street.
	var content_weights: Dictionary = Challenges.content_weights(area, FloorGenerator.ROOM_CONTENT_WEIGHTS[-1])
	var houses: Array[Rect2i] = []
	for by in LINES.size() - 1:
		for bx in LINES.size() - 1:
			var block := Rect2i(LINES[bx] + 1, LINES[by] + 1, LINES[bx + 1] - LINES[bx] - 1, LINES[by + 1] - LINES[by] - 1)  # 6x6 inside the streets
			var size := Vector2i(rng.randi_range(3, 4), rng.randi_range(3, 4))
			var pos := block.position + Vector2i(rng.randi_range(1, block.size.x - size.x - 1), rng.randi_range(1, block.size.y - size.y - 1))
			var house := Rect2i(pos, size)
			var door := _doorway(grid, house, block, rng)
			if door.is_empty():
				continue  # every street round it has fallen: a sealed block
			for y in range(house.position.y, house.end.y):
				for x in range(house.position.x, house.end.x):
					grid[Vector2i(x, y)] = ","
			for c: Vector2i in door["path"]:
				grid[c] = "."
			if rng.randf() < SHUT_CHANCE:
				grid[door["path"][0]] = "D"
			houses.append(house)
			if rng.randf() < CONTENT_CHANCE:
				var cell := house.position + Vector2i(rng.randi_range(0, size.x - 1), rng.randi_range(0, size.y - 1))
				grid[cell] = FloorGenerator._pick_weighted(rng, content_weights)
	# Choked streets: fallen stone a Sapper (or a tool, or sore hands) can
	# clear, never the only way through.
	for c: Vector2i in grid.keys():
		if grid[c] != "." or c.x in LINES and c.y in LINES:
			continue  # not at crossings
		if not (c.x in LINES or c.y in LINES):
			continue  # streets only, not doorways
		if rng.randf() >= Challenges.blocked_chance(area, CHOKED_CHANCE):
			continue
		if NEIGHBOURS.any(func(n): return grid.get(c + n, "") in ["B", "D"]):
			continue
		grid[c] = "B"
		if not _joined(grid, true):
			grid[c] = "."
	var layout := PackedStringArray()
	for y in HEIGHT:
		var row := ""
		for x in WIDTH:
			row += grid.get(Vector2i(x, y), "#")
		layout.append(row)
	return layout


## The cells strictly between a segment's two crossings.
static func _segment_cells(seg: Array) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var a: Vector2i = seg[0]
	var b: Vector2i = seg[1]
	var step := (b - a).sign()
	var c := a + step
	while c != b:
		out.append(c)
		c += step
	return out


## A house's way out: a short path from the middle of one of its sides
## straight to a standing street. {"path": [cells from the house outward]}
## or {} if none.
static func _doorway(grid: Dictionary, house: Rect2i, block: Rect2i, rng: RandomNumberGenerator) -> Dictionary:
	var sides := NEIGHBOURS.duplicate()
	for i in range(sides.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t: Vector2i = sides[i]
		sides[i] = sides[j]
		sides[j] = t
	for d: Vector2i in sides:
		var start: Vector2i
		match d:
			Vector2i.UP: start = Vector2i(house.position.x + house.size.x / 2, house.position.y - 1)
			Vector2i.DOWN: start = Vector2i(house.position.x + house.size.x / 2, house.end.y)
			Vector2i.LEFT: start = Vector2i(house.position.x - 1, house.position.y + house.size.y / 2)
			_: start = Vector2i(house.end.x, house.position.y + house.size.y / 2)
		var path: Array[Vector2i] = []
		var c := start
		while block.has_point(c):
			path.append(c)
			c += d
		if grid.get(c, "") == ".":
			return {"path": path}
	return {}


## Every open cell joins up (fallen stone counts as shut when `strict`).
static func _joined(grid: Dictionary, strict := false) -> bool:
	var open: Array = grid.keys().filter(func(c): return not (strict and grid[c] == "B"))
	if open.is_empty():
		return true
	var seen := {open[0]: true}
	var queue: Array = [open[0]]
	while not queue.is_empty():
		var c: Vector2i = queue.pop_back()
		for n in NEIGHBOURS:
			var next: Vector2i = c + n
			if grid.has(next) and not seen.has(next) and not (strict and grid[next] == "B"):
				seen[next] = true
				queue.append(next)
	return seen.size() == open.size()

extends RefCounted
## Builds the opening escape (#30): the small room where Mara wakes among her
## companions' bodies, and one long, winding hallway out of it.
##
## The hallway is longer than anyone needs: the escape ends when Mara is
## weak enough, not at a fixed place (main.gd puts the daylight exit just
## ahead of her then). There's no map during the opening, so the layout
## only has to feel continuous.
##
## Output uses the dungeon_map.gd layout format plus the hallway's cells in
## walking order.

const SIZE := 71
const HALLWAY_LENGTH := 220  # cells; far more than the escape uses
const RUN_LENGTH := Vector2i(2, 6)  # straight stretches between turns
## Where along the hallway (cells from the room) things sit.
const WEB_AT: Array[int] = [6, 40]
const FIGHTS_AT: Array[int] = [10, 22, 34]

const DIRECTIONS: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]


## Returns {"layout": PackedStringArray, "hallway": Array[Vector2i],
## "fights": Array[Vector2i], "start": Vector2i, "room": Rect2i}.
static func generate(seed_value: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var center := Vector2i(SIZE / 2, SIZE / 2)
	var room := Rect2i(center - Vector2i(2, 1), Vector2i(4, 3))
	var start := room.position + Vector2i(1, 1)
	var hallway: Array[Vector2i] = []
	var used := {}
	for y in range(room.position.y, room.end.y):
		for x in range(room.position.x, room.end.x):
			used[Vector2i(x, y)] = true

	# Leave the room eastward, then wander: straight runs and 90° turns,
	# never touching earlier hallway (so walls always separate the bends).
	var cell := Vector2i(room.end.x, start.y)
	var heading := 1  # east
	var attempts := 0
	while hallway.size() < HALLWAY_LENGTH and attempts < 5000:
		attempts += 1
		var run := rng.randi_range(RUN_LENGTH.x, RUN_LENGTH.y)
		var trial: Array[Vector2i] = []
		var c := cell
		var ok := true
		for i in run:
			if not _free(c, used, hallway, trial):
				ok = false
				break
			trial.append(c)
			c += DIRECTIONS[heading]
		if ok and not trial.is_empty():
			for t in trial:
				hallway.append(t)
				used[t] = true
			cell = c
		elif hallway.size() > 4 and not ok:
			# Boxed in: back up a few cells and try another way.
			for i in 3:
				used.erase(hallway.pop_back())
			cell = hallway[-1] + DIRECTIONS[heading]
		heading = wrapi(heading + (1 if rng.randf() < 0.5 else -1), 0, 4)
		if not hallway.is_empty():
			cell = hallway[-1] + DIRECTIONS[heading]

	var symbols := {start: "S"}
	for i in WEB_AT:
		var web := _straight_cell_near(hallway, i)
		if web != Vector2i(-1, -1):
			symbols[web] = "D"
	var fights: Array[Vector2i] = []
	for i in FIGHTS_AT:
		var fight := _straight_cell_near(hallway, i)
		if fight != Vector2i(-1, -1) and not symbols.has(fight):
			symbols[fight] = "E"
			fights.append(fight)

	var on_hallway := {}
	for h in hallway:
		on_hallway[h] = true
	var layout := PackedStringArray()
	for y in SIZE:
		var row := ""
		for x in SIZE:
			var p := Vector2i(x, y)
			if symbols.has(p):
				row += symbols[p]
			elif room.has_point(p):
				row += ","
			elif on_hallway.has(p):
				row += "."
			else:
				row += "#"
		layout.append(row)
	return {"layout": layout, "hallway": hallway, "fights": fights, "start": start, "room": room}


## A cell can join the hallway if it's inside the grid, unused, and touches
## no earlier hallway except the cell it continues from.
static func _free(c: Vector2i, used: Dictionary, hallway: Array[Vector2i], trial: Array[Vector2i]) -> bool:
	if c.x < 2 or c.y < 2 or c.x >= SIZE - 2 or c.y >= SIZE - 2 or used.has(c):
		return false
	var previous: Vector2i = trial[-1] if not trial.is_empty() else (hallway[-1] if not hallway.is_empty() else Vector2i(-99, -99))
	for d in DIRECTIONS:
		var n := c + d
		if n == previous:
			continue
		if used.has(n) or trial.has(n):
			# Touching the room is fine only for the very first cell.
			if hallway.is_empty() and trial.is_empty():
				continue
			return false
	return true


## The hallway cell nearest index `i` whose neighbours along the hallway are
## in a straight line (so a web or fight sits mid-corridor, not on a bend).
static func _straight_cell_near(hallway: Array[Vector2i], i: int) -> Vector2i:
	for offset in [0, 1, -1, 2, -2, 3, -3]:
		var k: int = i + offset
		if k >= 1 and k < hallway.size() - 1:
			var a := hallway[k - 1]
			var b := hallway[k + 1]
			if a.x == b.x or a.y == b.y:
				return hallway[k]
	return Vector2i(-1, -1)

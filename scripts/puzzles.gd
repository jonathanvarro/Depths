extends RefCounted
## Simple floor puzzles (owner, 2026-11-21): three kinds, laid into a
## generated floor and always checked to be solvable.
##   oneway - a door bolted on one side. Met from the barred side first, it
##            sends the party round another way; from the bolt side it opens
##            as a shortcut back. Only placed on a loop, so it never cuts
##            anything off.
##   lever  - an iron gate shutting a dead-end side room; a lever elsewhere on
##            the floor raises it. From floor 3 a nest waits behind it.
##   key    - a locked door shutting a dead-end side room; its key lies with
##            a dead explorer somewhere else on the floor, so getting in means
##            exploring further.
## Behind a lever gate or locked door there is always a chest.
##
## Solvable means (see solve()): from either staircase, with the puzzles
## shut, the party can reach both staircases and every quest site; and
## working the puzzles from there opens the whole floor. Movement is two-way
## except a shut one-way door, which only opens, so the party can never be
## trapped. A puzzle that would break this is not placed.
## Static helpers only (no static variables: see #100).

const NEIGHBOURS: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
## Floors that get puzzles, and the chance of each kind there.
const MAX_DEPTH := 4
const CHANCE := {"oneway": 0.6, "key": 0.5, "lever": 0.5}
## A nest behind the lever's gate from this floor on.
const NEST_FROM := 3
## A one-way door is only worth it as a real shortcut: the way round is at
## least this many steps longer than going straight through.
const MIN_DETOUR := 6
## Symbols a side room must not hold (it has to stay optional).
const REQUIRED := ["<", ">", "S", "R"]


## Lays puzzles into `layout`. `avoid`: cells to keep clear (quest sites,
## their events, the refuge, the fortress hall and gates). Returns
## {"layout": rows, "puzzles": [ {kind, door, ...}, ... ]}.
## `chances`: each kind's chance (CHANCE by default; the Jail always has a
## locked cell and its key, 2026-11-26).
static func place(layout: PackedStringArray, depth: int, seed_value: int, avoid: Array = [], chances: Dictionary = CHANCE) -> Dictionary:
	var out := {"layout": layout, "puzzles": []}
	if depth < 1 or depth > MAX_DEPTH:
		return out
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var rows := PackedStringArray(layout)
	var puzzles: Array = []
	var used := {}  # cells already taken by a puzzle (and their neighbours)
	for cell in avoid:
		used[cell] = true
	for kind in ["oneway", "key", "lever"]:
		if rng.randf() >= chances.get(kind, 0.0):
			continue
		var before := PackedStringArray(rows)
		var puzzle: Dictionary = _oneway(rows, rng, used) if kind == "oneway" else _side_room(rows, rng, used, kind, depth)
		if puzzle.is_empty():
			rows = before
			continue
		puzzles.append(puzzle)
		if not solve(rows, puzzles)["ok"]:
			puzzles.pop_back()  # never keep one that leaves the floor unsolvable
			rows = before
			continue
		for key in ["door", "lever", "key", "bolt"]:
			if puzzle.has(key):
				for n in NEIGHBOURS + [Vector2i.ZERO]:
					used[puzzle[key] + n] = true
	out["layout"] = rows
	out["puzzles"] = puzzles
	return out


## Marks a built map's shut doors, levers and key spots as solid: the party
## walks into them (Party.interacted) rather than onto them.
static func make_solid(map) -> void:
	for p: Dictionary in map.marks.get("puzzles", []):
		if not p["open"]:
			map.solid[p["door"]] = true
		for key in ["lever", "key"]:
			if p.has(key):
				map.solid[p[key]] = true


# --- Reading the rows -----------------------------------------------------

static func _at(rows: PackedStringArray, cell: Vector2i) -> String:
	if cell.y < 0 or cell.y >= rows.size() or cell.x < 0 or cell.x >= rows[cell.y].length():
		return "#"
	return rows[cell.y][cell.x]


static func _open(rows: PackedStringArray, cell: Vector2i) -> bool:
	return _at(rows, cell) != "#"


static func _put(rows: PackedStringArray, cell: Vector2i, symbol: String) -> void:
	var row: String = rows[cell.y]
	rows[cell.y] = row.substr(0, cell.x) + symbol + row.substr(cell.x + 1)


static func _find(rows: PackedStringArray, symbol: String) -> Vector2i:
	for y in rows.size():
		var x: int = rows[y].find(symbol)
		if x != -1:
			return Vector2i(x, y)
	return Vector2i(-1, -1)


## Where the party can arrive: the stairs up (or the survivor's start) and
## the stairs down.
static func starts(rows: PackedStringArray) -> Array:
	var found := []
	for symbol in ["<", "S", ">"]:
		var cell := _find(rows, symbol)
		if cell != Vector2i(-1, -1):
			found.append(cell)
	return found


## Steps from `from` to every open cell, never entering `shut`.
static func _distances(rows: PackedStringArray, from: Vector2i, shut: Dictionary) -> Dictionary:
	var distance := {from: 0}
	var queue: Array[Vector2i] = [from]
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_front()
		for n in NEIGHBOURS:
			var next: Vector2i = cell + n
			if not distance.has(next) and _open(rows, next) and not shut.has(next):
				distance[next] = distance[cell] + 1
				queue.append(next)
	return distance


## A corridor cell between two walls, open ahead and behind: where a door fits.
static func _is_passage(rows: PackedStringArray, cell: Vector2i) -> bool:
	if _at(rows, cell) not in [".", "D"]:
		return false
	var ns := _open(rows, cell + Vector2i.UP) and _open(rows, cell + Vector2i.DOWN) and not _open(rows, cell + Vector2i.LEFT) and not _open(rows, cell + Vector2i.RIGHT)
	var ew := _open(rows, cell + Vector2i.LEFT) and _open(rows, cell + Vector2i.RIGHT) and not _open(rows, cell + Vector2i.UP) and not _open(rows, cell + Vector2i.DOWN)
	return ns or ew


static func _clear(used: Dictionary, cell: Vector2i) -> bool:
	return not used.has(cell) and NEIGHBOURS.all(func(n): return not used.has(cell + n))


# --- Placing --------------------------------------------------------------

## A one-way door on a loop: the side nearer the stairs is barred.
static func _oneway(rows: PackedStringArray, rng: RandomNumberGenerator, used: Dictionary) -> Dictionary:
	var start: Vector2i = starts(rows)[0]
	var all := _distances(rows, start, {})
	var options := []
	for cell: Vector2i in all:
		if not _is_passage(rows, cell) or not _clear(used, cell):
			continue
		if NEIGHBOURS.any(func(n): return _at(rows, cell + n) in REQUIRED + ["D", "B"]):
			continue
		var around := _distances(rows, start, {cell: true})
		if around.size() != all.size() - 1:
			continue  # not on a loop: it would cut part of the floor off
		var sides: Array = NEIGHBOURS.map(func(n): return cell + n).filter(func(c): return _open(rows, c))
		var near: Vector2i = sides[0] if around[sides[0]] <= around[sides[1]] else sides[1]
		var far: Vector2i = sides[1] if near == sides[0] else sides[0]
		if around[far] - around[near] < MIN_DETOUR:
			continue
		options.append({"kind": "oneway", "door": cell, "bolt": far, "open": false})
	if options.is_empty():
		return {}
	var picked: Dictionary = options[rng.randi_range(0, options.size() - 1)]
	_put(rows, picked["door"], ".")
	return picked


## A gate or locked door on the one way into a dead-end side room, with the
## lever or key out in the rest of the floor, as far from it as can be.
static func _side_room(rows: PackedStringArray, rng: RandomNumberGenerator, used: Dictionary, kind: String, depth: int) -> Dictionary:
	var start: Vector2i = starts(rows)[0]
	var all := _distances(rows, start, {})
	var options := []
	for cell: Vector2i in all:
		if not _is_passage(rows, cell) or not _clear(used, cell):
			continue
		var outside := _distances(rows, start, {cell: true})
		var inside: Array = all.keys().filter(func(c): return c != cell and not outside.has(c))
		if inside.size() < 6 or not inside.any(func(c): return _at(rows, c) == ","):
			continue
		if inside.any(func(c): return _at(rows, c) in REQUIRED or used.has(c) or _at(rows, c).is_valid_int()):
			continue  # stairs, the refuge and quest sites stay outside
		options.append({"door": cell, "inside": inside, "outside": outside})
	if options.is_empty():
		return {}
	var room: Dictionary = options[rng.randi_range(0, options.size() - 1)]
	var door: Vector2i = room["door"]
	# The lever or key: an empty room cell outside, far from the door (and,
	# for a lever, against a wall to be mounted on).
	var from_door := _distances(rows, door, {})
	var best := Vector2i(-1, -1)
	for c: Vector2i in room["outside"]:
		if _at(rows, c) != "," or not _clear(used, c) or c.distance_to(door) < 3:
			continue
		if NEIGHBOURS.any(func(n): return _at(rows, c + n) not in [",", "#"]):
			continue  # keep doorways, stairs and contents free around it
		if kind == "lever" and not NEIGHBOURS.any(func(n): return _at(rows, c + n) == "#"):
			continue
		if best == Vector2i(-1, -1) or from_door.get(c, 0) > from_door.get(best, 0):
			best = c
	if best == Vector2i(-1, -1):
		return {}
	_put(rows, door, ".")
	# Something worth the trouble inside: a chest, and on deeper floors the
	# lever's gate keeps a nest shut in with it.
	var cells: Array = room["inside"].filter(func(c): return _at(rows, c) == ",")
	cells.sort_custom(func(a, b): return from_door.get(a, 0) > from_door.get(b, 0))
	# The chest behind it is silver (chest_tiers.gd): an existing one, or a new one.
	var chests: Array = room["inside"].filter(func(c): return _at(rows, c) == "C")
	var chest: Vector2i = chests[0] if not chests.is_empty() else cells[0]
	if chests.is_empty():
		_put(rows, chest, "C")
	var nest: bool = kind == "lever" and depth >= NEST_FROM and cells.size() > 2
	if nest and not room["inside"].any(func(c): return _at(rows, c) == "E"):
		_put(rows, cells[cells.size() / 2], "E")
	var puzzle := {"kind": kind, "door": door, "open": false, "chest": chest}
	if kind == "lever":
		puzzle["lever"] = best
		puzzle["nest"] = nest
	else:
		puzzle["key"] = best
		puzzle["held"] = false
	return puzzle


# --- Solving --------------------------------------------------------------

## Plays the floor out from each start. ok is true when, from every start,
## the stairs, the refuge and quest sites are reachable with every puzzle
## still shut, and working the puzzles then reaches every open cell.
## `why` says what failed.
static func solve(rows: PackedStringArray, puzzles: Array) -> Dictionary:
	var props := {}  # lever and key cells: walked up to, never stood on
	for p in puzzles:
		for key in ["lever", "key"]:
			if p.has(key):
				props[p[key]] = true
	var open_cells := []
	for y in rows.size():
		for x in rows[y].length():
			var cell := Vector2i(x, y)
			if _open(rows, cell) and not props.has(cell) and _at(rows, cell) != "B":
				open_cells.append(cell)
	for start in starts(rows):
		# With every puzzle shut (one-way doors only from their bolt side).
		var first := _reach(rows, puzzles, start, false)
		for c in open_cells:
			var symbol := _at(rows, c)
			if (symbol in REQUIRED or symbol.is_valid_int()) and not first.has(c):
				return {"ok": false, "why": "%s at %s can't be reached from %s with the puzzles shut" % [symbol, c, start]}
		var full := _reach(rows, puzzles, start, true)
		for c in open_cells:
			if not full.has(c):
				return {"ok": false, "why": "%s never reached from %s" % [c, start]}
	return {"ok": true, "why": ""}


## Cells the party can reach from `start`. With `work` false, only one-way
## doors open (from their bolt side); with it true, levers pulled and keys
## found open their doors too, until nothing more opens.
static func _reach(rows: PackedStringArray, puzzles: Array, start: Vector2i, work: bool) -> Dictionary:
	var opened := {}
	for i in puzzles.size():
		opened[i] = puzzles[i].get("open", false)
	var reach := {}
	while true:
		var shut := {}
		var bolts := {}  # door -> the only cell it opens from
		for i in puzzles.size():
			var p: Dictionary = puzzles[i]
			if p.has("lever"):
				shut[p["lever"]] = true
			if p.has("key"):
				shut[p["key"]] = true
			if not opened[i]:
				if p["kind"] == "oneway":
					bolts[p["door"]] = p["bolt"]
				else:
					shut[p["door"]] = true
		reach = {start: true}
		var queue: Array[Vector2i] = [start]
		while not queue.is_empty():
			var cell: Vector2i = queue.pop_front()
			for n in NEIGHBOURS:
				var next: Vector2i = cell + n
				if reach.has(next) or not _open(rows, next) or shut.has(next) or _at(rows, next) == "B":
					continue  # rubble is never the only way (as the generator keeps it, #305)
				if bolts.has(next) and bolts[next] != cell:
					continue  # barred from this side
				reach[next] = true
				queue.append(next)
		var more := false
		for i in puzzles.size():
			if opened[i]:
				continue
			var p: Dictionary = puzzles[i]
			var item: Vector2i = p.get("lever", p.get("key", p.get("bolt")))
			var at_hand: bool = reach.has(item) if p["kind"] == "oneway" else NEIGHBOURS.any(func(n): return reach.has(item + n))
			if at_hand and (work or p["kind"] == "oneway"):
				opened[i] = true
				more = true
		if not more:
			break
	return reach

extends RefCounted
## Places quest packages into generated floors (#123). Packages go into
## solid rock and are joined by a short dug corridor, so they're always a
## side branch: never on the only way to the stairs, and the generated
## floor around them is unchanged. Static helpers only (see #100).

const Quests := preload("res://scripts/quests.gd")
const DIR := "res://data/packages"
const KIND_SYMBOL := {2: "C", 3: "T", 4: "O", 5: "R"}
const SIDES: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]


static func library() -> Array[QuestPackage]:
	var found: Array[QuestPackage] = []
	for file in DirAccess.get_files_at(DIR):
		file = file.trim_suffix(".remap")
		if file.ends_with(".tres"):
			var package := load(DIR.path_join(file)) as QuestPackage
			if package:
				found.append(package)
	return found


## Packages the story wants on floor `depth` right now.
static func active(camp, depth: int) -> Array[QuestPackage]:
	return library().filter(func(p: QuestPackage):
		return p.lair == "" and depth >= p.min_depth and depth <= p.max_depth \
				and Quests.stage(camp, p.quest) in p.stages \
				and not Array(p.unless_flags).any(func(f): return Quests.has_flag(camp, p.quest, f)))


## How often a floor that can hold a mini-boss lair has one (#145).
const LAIR_CHANCE := 0.5

## This floor's mini-boss lair, if the dice give it one (#145): [] or one
## package. A new site seed each day re-rolls it.
static func lairs(depth: int, seed_value: int) -> Array[QuestPackage]:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var fitting := library().filter(func(p: QuestPackage): return p.lair != "" and depth >= p.min_depth and depth <= p.max_depth)
	var out: Array[QuestPackage] = []
	if not fitting.is_empty() and rng.randf() < LAIR_CHANCE:
		out.append(fitting[rng.randi_range(0, fitting.size() - 1)])
	return out


static func find(id: String) -> QuestPackage:
	for package in library():
		if package.id == id:
			return package
	return null


## Stamps `packages` into `layout`. Returns {"layout", "events": {cell:
## RoomEvent}, "fights": {cell: Array[EnemyType]}, "placed": [ids],
## "failed": [ids]}.
## `avoid`: cells a corridor must not dig into or join (the queen's hall).
## `join`: if given, the only open cells a corridor may join (those reached
## from the stairs without passing the queen's gates).
static func place(layout: PackedStringArray, packages: Array, seed_value: int, avoid: Array = [], join: Dictionary = {}) -> Dictionary:
	var rows := Array(layout)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var out := {"events": {}, "fights": {}, "lairs": {}, "placed": [], "failed": []}
	for package: QuestPackage in packages:
		var spots := _spots(rows, package)
		if spots.is_empty():
			# No room in the rock: widen the floor with fresh rock on the
			# east side rather than drop a package the story needs.
			var extra: String = "#".repeat(package.rows[0].length() + 1)
			for y in rows.size():
				rows[y] = rows[y] + extra
			spots = _spots(rows, package)
		# Try spots in random order; keep the first whose way in connects.
		var placed := false
		while not spots.is_empty() and not placed:
			var at: Vector2i = spots.pop_at(rng.randi_range(0, spots.size() - 1))
			var area := Rect2i(at, Vector2i(package.rows[0].length(), package.rows.size())).grow(1)
			if avoid.any(func(c): return area.has_point(c)):
				continue  # not right against the queen's hall
			var trial := rows.duplicate()
			var found := {"events": {}, "fights": {}, "lairs": {}}
			if _stamp(trial, package, at, found, avoid, join):
				rows.assign(trial)
				out["events"].merge(found["events"])
				out["fights"].merge(found["fights"])
				out["lairs"].merge(found["lairs"])
				placed = true
		if not placed:
			out["failed"].append(package.id)
			push_warning("Quest package %s didn't fit this floor" % package.id)
			continue
		out["placed"].append(package.id)
	out["layout"] = PackedStringArray(rows)
	return out


## Top-left corners where the package fits entirely in solid rock. Its
## own outer walls keep it apart from what's around it.
static func _spots(rows: Array, package: QuestPackage) -> Array[Vector2i]:
	var h: int = package.rows.size()
	var w: int = package.rows[0].length()
	var height: int = rows.size()
	var width: int = rows[0].length()
	var spots: Array[Vector2i] = []
	for y in range(0, height - h + 1):
		for x in range(0, width - w + 1):
			var clear := true
			for yy in range(y, y + h):
				if rows[yy].substr(x, w).replace("#", "") != "":
					clear = false
					break
			if clear:
				spots.append(Vector2i(x, y))
	return spots


static func _put(rows: Array, cell: Vector2i, symbol: String) -> void:
	var row: String = rows[cell.y]
	rows[cell.y] = row.substr(0, cell.x) + symbol + row.substr(cell.x + 1)


## Returns false if a way in couldn't be dug to the rest of the floor.
static func _stamp(rows: Array, package: QuestPackage, at: Vector2i, out: Dictionary, avoid: Array = [], join: Dictionary = {}) -> bool:
	var h: int = package.rows.size()
	var w: int = package.rows[0].length()
	var rect := Rect2i(at, Vector2i(w, h))
	var entrances: Array[Vector2i] = []
	for y in h:
		for x in w:
			var symbol: String = package.rows[y][x]
			var cell := at + Vector2i(x, y)
			if symbol == "#":
				continue
			if symbol.is_valid_int():
				var event: RoomEvent = package.events[int(symbol) - 1]
				out["events"][cell] = event
				symbol = KIND_SYMBOL.get(event.kind, "C")
			elif symbol == "E":
				out["fights"][cell] = package.fight
				if package.lair != "":
					out["lairs"][cell] = package.id
			_put(rows, cell, symbol)
			if symbol == "." and (x == 0 or y == 0 or x == w - 1 or y == h - 1):
				entrances.append(cell)
	for entrance in entrances:
		if not _dig(rows, entrance, rect, avoid, join):
			return false
	return not entrances.is_empty()


## Digs a corridor from `entrance` through rock to the nearest open cell
## outside the package.
static func _dig(rows: Array, entrance: Vector2i, rect: Rect2i, avoid: Array = [], join: Dictionary = {}) -> bool:
	var height: int = rows.size()
	var width: int = rows[0].length()
	var previous := {}
	var queue: Array[Vector2i] = []
	for side in SIDES:
		var first: Vector2i = entrance + side
		if not rect.has_point(first):
			previous[first] = entrance
			queue.append(first)
	var i := 0
	var reached := Vector2i(-1, -1)
	while i < queue.size():
		var cell: Vector2i = queue[i]
		i += 1
		if cell.x < 1 or cell.y < 1 or cell.x >= width - 1 or cell.y >= height - 1:
			continue
		var here: String = rows[cell.y][cell.x]
		if here == "B" or cell in avoid or (here == "#" and SIDES.any(func(s): return (cell + s) in avoid)):
			continue  # never end at (or dig through) a blocked passage
		if here != "#":
			if join.is_empty() or join.has(cell):
				reached = cell
				break
			continue  # open, but cut off from the stairs: look elsewhere
		for side in SIDES:
			var next: Vector2i = cell + side
			if not previous.has(next) and not rect.has_point(next):
				previous[next] = cell
				queue.append(next)
	if reached == Vector2i(-1, -1):
		return false
	var at: Vector2i = previous[reached]
	while at != entrance:
		_put(rows, at, ".")
		at = previous[at]
	return true

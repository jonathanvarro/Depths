extends RefCounted
## Builds a random floor: rectangular rooms joined by corridors, with a way
## up where the party arrives, a way down in the farthest room, passages at
## some room entrances, and contents in most rooms. On the deepest floor the
## farthest room instead holds 'S': where the lone survivor wakes (#8).
##
## Output uses the same text format as dungeon_map.gd, so a generated floor
## and a hand-drawn debug layout are interchangeable.
## The same seed always produces the same floor.

const WIDTH := 31
const HEIGHT := 31
const MAX_ROOMS := 9
const ROOM_ATTEMPTS := 80
const ROOM_MIN := 3
const ROOM_MAX := 6
## Chance per room of one extra corridor, so the floor has loops rather than
## only dead ends (gives the player alternative routes back).
const EXTRA_CORRIDOR_CHANCE := 0.35
## Chance that a room (other than the start room) holds something.
const ROOM_CONTENT_CHANCE := 0.75
## Layout symbols (see dungeon_map.gd) and how often each is picked.
## Stairs are placed separately (issue #4).
const ROOM_CONTENT_WEIGHTS := {"E": 3, "C": 2, "T": 2, "O": 1, "R": 1}
## Chances for each room entrance to get a closed or blocked passage.
const CLOSED_PASSAGE_CHANCE := 0.3
const BLOCKED_PASSAGE_CHANCE := 0.12

const NEIGHBOURS: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]


## has_descent: false on a site's deepest floor, which has no way further down.
static func generate(seed_value: int, has_descent := true) -> PackedStringArray:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var open := PackedByteArray()
	open.resize(WIDTH * HEIGHT)  # 0 = wall, 1 = floor

	var rooms: Array[Rect2i] = []
	for attempt in ROOM_ATTEMPTS:
		if rooms.size() >= MAX_ROOMS:
			break
		var size := Vector2i(rng.randi_range(ROOM_MIN, ROOM_MAX), rng.randi_range(ROOM_MIN, ROOM_MAX))
		var pos := Vector2i(rng.randi_range(1, WIDTH - size.x - 1), rng.randi_range(1, HEIGHT - size.y - 1))
		var room := Rect2i(pos, size)
		# grow(1) keeps at least one wall between rooms.
		if rooms.any(func(other: Rect2i): return other.grow(1).intersects(room)):
			continue
		rooms.append(room)
		_carve_rect(open, room)

	# Join each new room to the nearest earlier one. Every room links into the
	# set before it, so the whole floor is connected by construction.
	for i in range(1, rooms.size()):
		var nearest := rooms[0]
		for j in i:
			if _center(rooms[j]).distance_squared_to(_center(rooms[i])) < _center(nearest).distance_squared_to(_center(rooms[i])):
				nearest = rooms[j]
		_carve_corridor(open, rng, _center(rooms[i]), _center(nearest))
		if rng.randf() < EXTRA_CORRIDOR_CHANCE:
			_carve_corridor(open, rng, _center(rooms[i]), _center(rooms[rng.randi_range(0, i - 1)]))

	# Everything below is placed after the corridors, so it never changes a
	# seed's walls.
	var start := _center(rooms[0])
	var symbols := {start: "<"}  # Vector2i -> layout symbol

	if rooms.size() > 1:
		var distance := _walking_distances(open, start, {})
		var farthest := rooms[1]
		for room: Rect2i in rooms.slice(1):
			if distance.get(_center(room), 0) > distance.get(_center(farthest), 0):
				farthest = room
		symbols[_center(farthest)] = ">" if has_descent else "S"

	for room: Rect2i in rooms.slice(1):
		if rng.randf() < ROOM_CONTENT_CHANCE:
			var cell := room.position + Vector2i(rng.randi_range(0, room.size.x - 1), rng.randi_range(0, room.size.y - 1))
			var content := _pick_weighted(rng, ROOM_CONTENT_WEIGHTS)
			if not symbols.has(cell):
				symbols[cell] = content

	_place_passages(open, rng, rooms, start, symbols)

	var layout := PackedStringArray()
	for y in HEIGHT:
		var row := ""
		for x in WIDTH:
			var cell := Vector2i(x, y)
			if symbols.has(cell):
				row += symbols[cell]
			else:
				row += "." if open[y * WIDTH + x] else "#"
		layout.append(row)
	return layout


## Puts closed ('D') and blocked ('B') passages in doorways: corridor cells
## just outside a room, with wall on both sides. A blocked passage is only
## kept if every other floor cell is still reachable from the start.
static func _place_passages(open: PackedByteArray, rng: RandomNumberGenerator, rooms: Array[Rect2i], start: Vector2i, symbols: Dictionary) -> void:
	var floor_count := open.count(1)
	var blocked := {}
	for y in HEIGHT:
		for x in WIDTH:
			var cell := Vector2i(x, y)
			if not _is_doorway(open, rooms, cell) or symbols.has(cell):
				continue
			if NEIGHBOURS.any(func(n): return symbols.get(cell + n, "") in ["D", "B"]):
				continue  # no passages side by side
			var roll := rng.randf()
			if roll < BLOCKED_PASSAGE_CHANCE:
				blocked[cell] = true
				if _walking_distances(open, start, blocked).size() == floor_count - blocked.size():
					symbols[cell] = "B"
					continue
				blocked.erase(cell)  # it would cut part of the floor off
			if roll < BLOCKED_PASSAGE_CHANCE + CLOSED_PASSAGE_CHANCE:
				symbols[cell] = "D"


static func _is_doorway(open: PackedByteArray, rooms: Array[Rect2i], cell: Vector2i) -> bool:
	if not _is_open(open, cell) or rooms.any(func(r: Rect2i): return r.has_point(cell)):
		return false
	var next_to_room := NEIGHBOURS.any(func(n): return rooms.any(func(r: Rect2i): return r.has_point(cell + n)))
	var walls_east_west := not _is_open(open, cell + Vector2i.LEFT) and not _is_open(open, cell + Vector2i.RIGHT)
	var walls_north_south := not _is_open(open, cell + Vector2i.UP) and not _is_open(open, cell + Vector2i.DOWN)
	return next_to_room and (walls_east_west != walls_north_south)


static func _is_open(open: PackedByteArray, cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < WIDTH and cell.y < HEIGHT and open[cell.y * WIDTH + cell.x] == 1


## Steps needed to reach each open cell from `from`, treating `closed` cells
## as walls (breadth-first search).
static func _walking_distances(open: PackedByteArray, from: Vector2i, closed: Dictionary) -> Dictionary:
	var distance := {from: 0}
	var queue: Array[Vector2i] = [from]
	var i := 0
	while i < queue.size():
		var cell := queue[i]
		i += 1
		for n in NEIGHBOURS:
			var next := cell + n
			if _is_open(open, next) and not closed.has(next) and not distance.has(next):
				distance[next] = distance[cell] + 1
				queue.append(next)
	return distance


static func _pick_weighted(rng: RandomNumberGenerator, weights: Dictionary) -> String:
	var total := 0
	for key in weights:
		total += weights[key]
	var roll := rng.randi_range(1, total)
	for key in weights:
		roll -= weights[key]
		if roll <= 0:
			return key
	return weights.keys()[0]


static func _center(room: Rect2i) -> Vector2i:
	return room.position + room.size / 2


static func _carve_rect(open: PackedByteArray, rect: Rect2i) -> void:
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			open[y * WIDTH + x] = 1


## L-shaped corridor; randomly goes horizontal-first or vertical-first.
static func _carve_corridor(open: PackedByteArray, rng: RandomNumberGenerator, from: Vector2i, to: Vector2i) -> void:
	var corner := Vector2i(to.x, from.y) if rng.randi() % 2 == 0 else Vector2i(from.x, to.y)
	for segment in [[from, corner], [corner, to]]:
		var a: Vector2i = segment[0]
		var b: Vector2i = segment[1]
		_carve_rect(open, Rect2i(a.min(b), (a - b).abs() + Vector2i.ONE))

extends RefCounted
## Builds a random floor: rectangular rooms joined by corridors.
##
## Output uses the same text format as dungeon_map.gd ('#', '.', 'S'), so a
## generated floor and a hand-drawn debug layout are interchangeable.
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


static func generate(seed_value: int) -> PackedStringArray:
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

	var start := _center(rooms[0])
	var layout := PackedStringArray()
	for y in HEIGHT:
		var row := ""
		for x in WIDTH:
			if Vector2i(x, y) == start:
				row += "S"
			else:
				row += "." if open[y * WIDTH + x] else "#"
		layout.append(row)
	return layout


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

extends RefCounted
## The goblin fortress floor (#44): an ordinary generated floor with its
## farthest room turned into the queen's hall, every way into it barred by a
## gate ('B'). Once the gate is broken (a campaign flag) the hall's ways in
## are left open on every later layout, even as the cave shifts each day.
##
## Output: {"layout": PackedStringArray, "hall": Array[Vector2i],
## "gates": Array[Vector2i]}.

const DungeonMap := preload("res://scripts/dungeon_map.gd")
const DIRECTIONS: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
const MIN_HALL_CELLS := 6


static func fortify(layout: PackedStringArray, gate_broken: bool) -> Dictionary:
	var map = DungeonMap.new(layout, 4)
	# Parties arrive by the stairs up (the start mark is only for a fresh
	# floor): measure from there, and never build the hall over them.
	var arrival: Vector2i = map.find_content(DungeonMap.Content.STAIRS_UP)
	if arrival == Vector2i(-1, -1):
		arrival = map.start_cell
	var distances: Dictionary = map.walking_distances(arrival)
	var seen := {}
	var hall: Array[Vector2i] = []
	var hall_distance := -1
	for cell: Vector2i in distances:
		if seen.has(cell) or not map._is_room_cell(cell):
			continue
		var room: Array[Vector2i] = map.room_around(cell)
		for c in room:
			seen[c] = true
		if room.size() < MIN_HALL_CELLS or map.start_cell in room or arrival in room:
			continue
		if not _gates_clear(map, room):
			continue  # a gate would cover the stairs or a room's contents
		var nearest := 1 << 30
		for c in room:
			nearest = mini(nearest, distances.get(c, 1 << 30))
		if nearest > hall_distance:
			hall_distance = nearest
			hall = room
	var rows := PackedStringArray(layout)
	var gates: Array[Vector2i] = []
	if hall.is_empty():
		return {"layout": rows, "hall": hall, "gates": gates}
	var in_hall := {}
	for c in hall:
		in_hall[c] = true
	for c in hall:
		_put(rows, c, ",")  # the hall holds the queen, nothing else
		for d in DIRECTIONS:
			var way: Vector2i = c + d
			if not in_hall.has(way) and not map.is_wall(way) and way not in gates:
				gates.append(way)
	for gate in gates:
		_put(rows, gate, "." if gate_broken else "B")
	return {"layout": rows, "hall": hall, "gates": gates}


## True if none of the hall's way-in cells holds anything (stairs above
## all): gating them would erase it and could strand the party.
static func _gates_clear(map, room: Array[Vector2i]) -> bool:
	var in_room := {}
	for c in room:
		in_room[c] = true
	for c in room:
		for d in DIRECTIONS:
			var way: Vector2i = c + d
			if in_room.has(way) or map.is_wall(way):
				continue
			if map.contents.has(way) or way == map.start_cell:
				return false
	return true


static func _put(rows: PackedStringArray, cell: Vector2i, symbol: String) -> void:
	var row := rows[cell.y]
	rows[cell.y] = row.substr(0, cell.x) + symbol + row.substr(cell.x + 1)

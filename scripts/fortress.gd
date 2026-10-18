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
	var distances: Dictionary = map.walking_distances(map.start_cell)
	var seen := {}
	var hall: Array[Vector2i] = []
	var hall_distance := -1
	for cell: Vector2i in distances:
		if seen.has(cell) or not map._is_room_cell(cell):
			continue
		var room: Array[Vector2i] = map.room_around(cell)
		for c in room:
			seen[c] = true
		if room.size() < MIN_HALL_CELLS or map.start_cell in room:
			continue
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


static func _put(rows: PackedStringArray, cell: Vector2i, symbol: String) -> void:
	var row := rows[cell.y]
	rows[cell.y] = row.substr(0, cell.x) + symbol + row.substr(cell.x + 1)

extends RefCounted
## Grid layout of one dungeon floor, plus which cells the party has seen.
##
## Layout legend: '#' wall, '.' floor, 'S' party start (a floor cell).
## Grid coordinates are Vector2i(x, y): x grows east, y grows south.

const WALL := "#"
const START := "S"

var width: int
var height: int
var start_cell := Vector2i.ZERO
var explored := {}  # Vector2i -> true

var _rows: PackedStringArray


func _init(layout: PackedStringArray) -> void:
	_rows = layout
	height = layout.size()
	width = layout[0].length()
	for y in height:
		var x := layout[y].find(START)
		if x != -1:
			start_cell = Vector2i(x, y)


func is_wall(cell: Vector2i) -> bool:
	if cell.x < 0 or cell.y < 0 or cell.x >= width or cell.y >= height:
		return true
	return _rows[cell.y][cell.x] == WALL


## True if a floor cell borders this wall; buried walls never need drawing.
func is_exposed_wall(cell: Vector2i) -> bool:
	for offset in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
		if not is_wall(cell + offset):
			return true
	return false


## All floor cells reachable on foot from `from` (flood fill).
func reachable_from(from: Vector2i) -> Dictionary:
	var seen := {from: true}
	var queue: Array[Vector2i] = [from]
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_back()
		for offset in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
			var next: Vector2i = cell + offset
			if not seen.has(next) and not is_wall(next):
				seen[next] = true
				queue.append(next)
	return seen


func floor_cell_count() -> int:
	var count := 0
	for row in _rows:
		count += row.length() - row.count(WALL)
	return count


## Marks a cell and its eight neighbours as seen, so nearby walls show on the map.
func reveal_around(cell: Vector2i) -> void:
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			explored[cell + Vector2i(dx, dy)] = true

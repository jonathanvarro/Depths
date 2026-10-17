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


## Marks a cell and its eight neighbours as seen, so nearby walls show on the map.
func reveal_around(cell: Vector2i) -> void:
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			explored[cell + Vector2i(dx, dy)] = true

extends RefCounted
## Grid layout of one dungeon floor: walls, what each cell contains, and
## which cells the party has seen.
##
## Layout legend: '#' wall, '.' floor, 'S' party start (a floor cell).
## Any letter in CONTENT_SYMBOLS is a floor cell holding that content.
## Grid coordinates are Vector2i(x, y): x grows east, y grows south.

enum Content { NONE, ENCOUNTER, CHEST, TRAP, STRANGE_OBJECT, REST_SPOT, STAIRS_DOWN, STAIRS_UP }

const WALL := "#"
const START := "S"
const CONTENT_SYMBOLS := {
	"E": Content.ENCOUNTER,
	"C": Content.CHEST,
	"T": Content.TRAP,
	"O": Content.STRANGE_OBJECT,
	"R": Content.REST_SPOT,
	">": Content.STAIRS_DOWN,
	"<": Content.STAIRS_UP,
}
## Contents that trigger every time the party enters; the rest trigger once.
const REPEATABLE: Array[Content] = [Content.STAIRS_DOWN, Content.STAIRS_UP]

var width: int
var height: int
var start_cell := Vector2i.ZERO
var explored := {}  # Vector2i -> true
var contents := {}  # Vector2i -> Content (empty cells are absent)
var triggered := {}  # Vector2i -> true, for one-time contents already used
var discovered := {}  # Vector2i -> true, for any contents the party has entered

var _rows: PackedStringArray


func _init(layout: PackedStringArray) -> void:
	_rows = layout
	height = layout.size()
	width = layout[0].length()
	for y in height:
		for x in width:
			var symbol := layout[y][x]
			if symbol == START:
				start_cell = Vector2i(x, y)
			elif CONTENT_SYMBOLS.has(symbol):
				contents[Vector2i(x, y)] = CONTENT_SYMBOLS[symbol]


func is_wall(cell: Vector2i) -> bool:
	if cell.x < 0 or cell.y < 0 or cell.x >= width or cell.y >= height:
		return true
	return _rows[cell.y][cell.x] == WALL


func content_at(cell: Vector2i) -> Content:
	return contents.get(cell, Content.NONE)


## Called when the party steps into a cell. Returns the content that should
## happen now, or NONE if the cell is empty or its one-time content is used up.
func enter(cell: Vector2i) -> Content:
	var content := content_at(cell)
	if content == Content.NONE or triggered.has(cell):
		return Content.NONE
	discovered[cell] = true
	if content not in REPEATABLE:
		triggered[cell] = true
	return content


static func content_name(content: Content) -> String:
	return Content.keys()[content].capitalize()


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

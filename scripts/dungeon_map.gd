extends RefCounted
## Grid layout of one dungeon floor: walls, what each cell contains, and
## which cells the party has seen.
##
## Layout legend: '#' wall, '.' floor, 'S' party start (a floor cell).
## Any letter in CONTENT_SYMBOLS is a floor cell holding that content.
## 'D' is a closed passage and 'B' a blocked one (see Door). How they look
## depends on the environment theme: a door, a web, roots...
## Without an 'S', the party starts on the way up ('<').
## Grid coordinates are Vector2i(x, y): x grows east, y grows south.

enum Content { NONE, ENCOUNTER, CHEST, TRAP, STRANGE_OBJECT, REST_SPOT, STAIRS_DOWN, STAIRS_UP }
## A passage in a corridor cell. CLOSED opens when the party steps into it;
## BLOCKED can't be passed (unlocking comes later).
enum Door { NONE, CLOSED, OPEN, BLOCKED }

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
const DOOR_SYMBOLS := {"D": Door.CLOSED, "B": Door.BLOCKED}
## Contents that trigger every time the party enters; the rest trigger once.
const REPEATABLE: Array[Content] = [Content.STAIRS_DOWN, Content.STAIRS_UP]

## 1 for the first floor of a site, growing deeper. Later systems scale
## difficulty from this.
var depth := 1
var width: int
var height: int
var start_cell := Vector2i.ZERO
var explored := {}  # Vector2i -> true
var contents := {}  # Vector2i -> Content (empty cells are absent)
var triggered := {}  # Vector2i -> true, for one-time contents already used
var discovered := {}  # Vector2i -> true, for any contents the party has entered
var doors := {}  # Vector2i -> Door

var _rows: PackedStringArray


func _init(layout: PackedStringArray, floor_depth := 1) -> void:
	_rows = layout
	depth = floor_depth
	var has_start := false
	height = layout.size()
	width = layout[0].length()
	for y in height:
		for x in width:
			var symbol := layout[y][x]
			var cell := Vector2i(x, y)
			if symbol == START:
				start_cell = cell
				has_start = true
			elif CONTENT_SYMBOLS.has(symbol):
				contents[cell] = CONTENT_SYMBOLS[symbol]
			elif DOOR_SYMBOLS.has(symbol):
				doors[cell] = DOOR_SYMBOLS[symbol]
	if not has_start:
		start_cell = find_content(Content.STAIRS_UP)


func is_wall(cell: Vector2i) -> bool:
	if cell.x < 0 or cell.y < 0 or cell.x >= width or cell.y >= height:
		return true
	return _rows[cell.y][cell.x] == WALL


## True if the party can stand in this cell (walls and blocked passages can't).
## A closed door is passable: stepping into it opens it first.
func is_passable(cell: Vector2i) -> bool:
	return not is_wall(cell) and door_at(cell) != Door.BLOCKED


func door_at(cell: Vector2i) -> Door:
	return doors.get(cell, Door.NONE)


func open_door(cell: Vector2i) -> void:
	if door_at(cell) == Door.CLOSED:
		doors[cell] = Door.OPEN


## First cell holding this content, or (-1, -1) if there is none.
func find_content(content: Content) -> Vector2i:
	for cell in contents:
		if contents[cell] == content:
			return cell
	return Vector2i(-1, -1)


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


## All cells reachable on foot from `from` (flood fill). Blocked passages
## stop the fill; closed ones don't.
func reachable_from(from: Vector2i) -> Dictionary:
	var seen := {from: true}
	var queue: Array[Vector2i] = [from]
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_back()
		for offset in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
			var next: Vector2i = cell + offset
			if not seen.has(next) and is_passable(next):
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

extends RefCounted
## Grid layout of one dungeon floor: walls, what each cell contains, and
## which cells the party has seen.
##
## Layout legend: '#' wall, '.' corridor floor, ',' room floor, 'S' party
## start (a floor cell).
## Any letter in CONTENT_SYMBOLS is a floor cell holding that content.
## 'D' is a closed passage and 'B' a blocked one (see Door). How they look
## depends on the environment theme: a door, a web, roots...
## 'S' marks where the game opens (the survivor's start on the deepest
## floor); without one, start_cell is the way up ('<').
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
var events := {}  # Vector2i -> RoomEvent, assigned by main.gd (#16)
## Every cell of a room holding a fight -> that fight's cell. Entering any
## of them starts the fight ("entering a room commits the party").
var encounter_zones := {}
## Cells holding something you can't walk onto (a body, a fire, a chest).
## Walking into one interacts with it instead (#69).
var solid := {}  # Vector2i -> true
## What preparation has already done in a room (#114): cell -> flag names.
var event_flags := {}
## Fixed fights (#123): a quest package's 'E' cell -> its enemies.
var fight_groups := {}
## Quest packages on this floor (#123): ids placed.
var packages: Array = []
## Mini-boss lairs (#145): the lair's 'E' cell -> its package id.
var lairs := {}
## Traps someone has spotted, or missed (#94): cell -> true/false, rolled
## once as the party comes near.
var spotted := {}
## A bell wire rang (#94): the next fight here was waiting for the party.
var alarmed := false
## Fights heard before they noticed you (#73): fight cell -> true/false,
## rolled once, so backing away and coming back finds them as they were.
var heard := {}
## Floor-specific places, e.g. the fortress's "hall" and "gates" (#44).
var marks := {}
## This floor's landmarks (#117, landmarks.gd): [{id, name, cells, centre, seen}].
var landmarks: Array = []
## Deep water the party has to wade (floor 5, galleries.gd): cell -> true.
var water := {}


func is_water(cell: Vector2i) -> bool:
	return water.has(cell)

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
	for cell in contents:
		if contents[cell] == Content.ENCOUNTER:
			for zone_cell in room_around(cell):
				if not encounter_zones.has(zone_cell):
					encounter_zones[zone_cell] = cell


## The room a cell belongs to: the connected room floor around it (',' in
## the layout, plus contents placed in rooms). Passages and corridor floor
## ('.') bound a room, and generated rooms never touch, so this is exactly
## one room. A cell outside any room (e.g. a corridor) is its own "room".
func room_around(cell: Vector2i) -> Array[Vector2i]:
	var found: Array[Vector2i] = [cell]
	if not _is_room_cell(cell):
		return found
	var seen := {cell: true}
	var i := 0
	while i < found.size():
		var c := found[i]
		i += 1
		for offset in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
			var next: Vector2i = c + offset
			if not seen.has(next) and _is_room_cell(next):
				seen[next] = true
				found.append(next)
	return found


func _is_room_cell(cell: Vector2i) -> bool:
	if is_wall(cell):
		return false
	var symbol := _rows[cell.y][cell.x]
	return symbol != "." and not DOOR_SYMBOLS.has(symbol)


func is_wall(cell: Vector2i) -> bool:
	if cell.x < 0 or cell.y < 0 or cell.x >= width or cell.y >= height:
		return true
	return _rows[cell.y][cell.x] == WALL


## True if the party can stand in this cell (walls and blocked passages can't).
## A closed door is passable: stepping into it opens it first.
func is_passable(cell: Vector2i) -> bool:
	return not is_wall(cell) and door_at(cell) != Door.BLOCKED and not solid.has(cell)


## Changes one cell of the layout (e.g. sealing a passage with '#', or
## opening an alcove with ','). The caller rebuilds the level.
func set_symbol(cell: Vector2i, symbol: String) -> void:
	var row := _rows[cell.y]
	_rows[cell.y] = row.substr(0, cell.x) + symbol + row.substr(cell.x + 1)
	doors.erase(cell)
	if DOOR_SYMBOLS.has(symbol):
		doors[cell] = DOOR_SYMBOLS[symbol]


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


## Steps from `from` to every cell reachable on foot (breadth-first).
func walking_distances(from: Vector2i) -> Dictionary:
	var distance := {from: 0}
	var queue: Array[Vector2i] = [from]
	var i := 0
	while i < queue.size():
		var cell := queue[i]
		i += 1
		for offset in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
			var next: Vector2i = cell + offset
			if not distance.has(next) and is_passable(next):
				distance[next] = distance[cell] + 1
				queue.append(next)
	return distance


## Cells on a shortest walk from `from` to `to`, both included (empty if
## there's no way).
func walking_path(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	var previous := {from: from}
	var queue: Array[Vector2i] = [from]
	var i := 0
	while i < queue.size() and not previous.has(to):
		var cell := queue[i]
		i += 1
		for offset in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
			var next: Vector2i = cell + offset
			if not previous.has(next) and is_passable(next):
				previous[next] = cell
				queue.append(next)
	var path: Array[Vector2i] = []
	if not previous.has(to):
		return path
	var at := to
	while at != from:
		path.push_front(at)
		at = previous[at]
	path.push_front(from)
	return path


func floor_cell_count() -> int:
	var count := 0
	for row in _rows:
		count += row.length() - row.count(WALL)
	return count


## Marks a cell and its eight neighbours as seen, so nearby walls show on
## the map. With a light (owner playtest, 2026-10-25), one tile further -
## past open neighbours only, never through a wall.
func reveal_around(cell: Vector2i, lit := false) -> void:
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			explored[cell + Vector2i(dx, dy)] = true
	if not lit:
		return
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var near := cell + Vector2i(dx, dy)
			if near == cell or not is_passable(near):
				continue
			for ey in range(-1, 2):
				for ex in range(-1, 2):
					explored[near + Vector2i(ex, ey)] = true

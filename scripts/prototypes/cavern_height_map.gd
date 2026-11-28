extends "res://scripts/dungeon_map.gd"
## Authored walking study, deliberately separate from campaign maps/saves.
## One elevation per cell. Only declared edges join; adjacent ledges may not.
const TILE := 2.0
const HALF_PAD := 0.6
const CARDINALS := [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
var heights: Dictionary = {}
var links: Dictionary = {}
var bridge_cells: Dictionary = {}
var arrival := Vector2i(1, 7)
var destination := Vector2i(8, 2)
var junction := Vector2i(1, 5)
var loop: Array[Vector2i] = []

func _init() -> void:
	super(PackedStringArray([
		"##########", "##########", "##########", "##########", "##########",
		"##########", "##########", "##########", "##########", "##########"
	]))
	# Clockwise loop: upper bridge, eastern descent, lower ledge, western ascent.
	var authored := [
		[1,5,0.0], [1,4,0.0], [1,3,0.0], [2,3,0.0], [3,3,0.0],
		[4,3,0.0], [5,3,0.0], [6,3,0.0], [7,3,0.0], [8,3,0.0],
		[8,4,-0.4], [8,5,-0.8], [8,6,-1.2], [8,7,-1.6], [8,8,-2.0],
		[7,8,-2.4], [6,8,-2.4], [5,8,-2.4], [4,8,-2.4], [3,8,-2.0],
		[2,8,-1.6], [2,7,-1.2], [2,6,-0.8], [2,5,-0.4]
	]
	for row in authored:
		var c := Vector2i(row[0], row[1])
		add_cell(c, row[2]); loop.append(c)
	for i in loop.size():
		join(loop[i], loop[(i+1) % loop.size()])
	add_cell(Vector2i(1,6), 0); add_cell(arrival, 0)
	join(junction, Vector2i(1,6)); join(Vector2i(1,6), arrival)
	add_cell(destination, 0); join(Vector2i(8,3), destination)
	for x in range(2,8): bridge_cells[Vector2i(x,3)] = true
	start_cell = arrival

func add_cell(c: Vector2i, elevation: float) -> void:
	heights[c] = elevation; links[c] = []
	set_symbol(c, ".")

func join(a: Vector2i, b: Vector2i) -> void:
	assert(abs(a.x-b.x)+abs(a.y-b.y) == 1)
	links[a].append(b); links[b].append(a)

func can_step(a: Vector2i, b: Vector2i) -> bool:
	return b in links.get(a, [])

func world(c: Vector2i) -> Vector3:
	return Vector3(c.x*TILE, heights[c], c.y*TILE)

## Flat pads at turns, a straight ramp between their edges. Same profile is
## used by the geometry and the player, including backwards/downhill travel.
func step_position(a: Vector2i, b: Vector2i, progress: float, _size := TILE) -> Vector3:
	var p := clampf(progress, 0, 1)
	var flat := HALF_PAD / TILE
	var rise := clampf((p-flat)/(1.0-2.0*flat), 0, 1)
	var result := world(a).lerp(world(b), p)
	result.y = lerpf(heights[a], heights[b], rise)
	return result

func place_name(c: Vector2i) -> String:
	if c == arrival: return "Arrival from Damp Caves"
	if c == destination: return "Way toward the Rest Area"
	if bridge_cells.has(c): return "Timber bridge"
	if heights[c] <= -2.39: return "Lower ledge"
	if heights[c] < -0.01: return "Sloping ledge"
	return "Upper ledge"

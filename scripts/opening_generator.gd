extends RefCounted
## Builds the opening escape (#30, #56): the small room where Mara wakes
## among her companions' bodies, and a winding maze around it full of
## left / straight / right choices, dead ends and a few loops. The feeling
## should be 1) lost and 2) a race against the clock.
##
## The maze has no exit of its own: the escape ends when Mara is weak enough
## (main.gd opens daylight just ahead of her then), and fights come after
## set distances walked, so no branch avoids them. There's no map during the
## opening, so the maze only has to feel continuous.
##
## Output uses the dungeon_map.gd layout format.

## Maze nodes sit on odd coordinates; walls between them on even ones.
const NODES := 20
const SIZE := NODES * 2 + 1
## Chance of knocking through a wall between two already-joined passages,
## which makes loops (so dead ends aren't the only way to get lost).
const LOOP_CHANCE := 0.08

const DIRECTIONS: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]


## Returns {"layout": PackedStringArray, "start": Vector2i, "room": Rect2i,
## "web": Vector2i}.
static func generate(seed_value: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var center := Vector2i(NODES - 1, NODES - 1)  # odd (NODES is even), so it sits on the maze grid
	var room := Rect2i(center - Vector2i(2, 1), Vector2i(5, 3))
	var start := center + Vector2i(-1, 0)
	var doorway := Vector2i(room.end.x, center.y)  # the room's only way out
	var first_node := doorway + Vector2i.RIGHT

	var open := {}  # Vector2i -> true for carved cells
	for y in range(room.position.y, room.end.y):
		for x in range(room.position.x, room.end.x):
			open[Vector2i(x, y)] = true
	open[doorway] = true

	# Randomized Prim's: grow the maze from the doorway by repeatedly joining
	# a random frontier node. This gives many short branches: lots of
	# junctions and dead ends.
	var in_maze := {first_node: true}
	open[first_node] = true
	var frontier: Array[Vector2i] = []
	_add_frontier(first_node, room, in_maze, frontier)
	while not frontier.is_empty():
		var node: Vector2i = frontier.pop_at(rng.randi_range(0, frontier.size() - 1))
		if in_maze.has(node):
			continue
		var joined: Array[Vector2i] = []
		for d in DIRECTIONS:
			if in_maze.has(node + d * 2):
				joined.append(node + d * 2)
		var neighbour: Vector2i = joined[rng.randi_range(0, joined.size() - 1)]
		open[(node + neighbour) / 2] = true
		open[node] = true
		in_maze[node] = true
		_add_frontier(node, room, in_maze, frontier)

	# A few extra openings between passages make loops.
	for node in in_maze:
		for d in [Vector2i.RIGHT, Vector2i.DOWN]:
			var other: Vector2i = node + d * 2
			var wall: Vector2i = node + d
			if in_maze.has(other) and not open.has(wall) and rng.randf() < LOOP_CHANCE:
				open[wall] = true

	var layout := PackedStringArray()
	for y in SIZE:
		var row := ""
		for x in SIZE:
			var p := Vector2i(x, y)
			if p == start:
				row += "S"
			elif p == doorway:
				row += "D"  # a web across the doorway: the first thing to learn
			elif room.has_point(p):
				row += ","
			elif open.has(p):
				row += "."
			else:
				row += "#"
		layout.append(row)
	return {"layout": layout, "start": start, "room": room, "web": doorway}


static func _add_frontier(node: Vector2i, room: Rect2i, in_maze: Dictionary, frontier: Array[Vector2i]) -> void:
	for d in DIRECTIONS:
		var next: Vector2i = node + d * 2
		if next.x < 1 or next.y < 1 or next.x >= SIZE - 1 or next.y >= SIZE - 1:
			continue
		if in_maze.has(next) or room.grow(1).has_point(next):
			continue
		frontier.append(next)

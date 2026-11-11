extends RefCounted
## The goblin fortress floor in 3D (#246, owner 2026-11-11): ChatGPT's
## structures placed around the queen's hall without touching the way in.
##
## - The throne at the hall's far end, facing the gates.
## - Palisades along the hall walls; broken once the gate has been broken.
## - A watch post in a corner, iron brackets on the walls.
## - A walkway overhead across the hall (a ceiling prop, nothing to climb).
## - Empty cages hung in dead-end side passages, out of the way.
##
## Looks only: nothing blocks, and no gate, passage or stairs cell is used.
## Seeded, so a floor looks the same on every visit.

const Dressing := preload("res://scripts/dressing.gd")
const DIR := "res://art/props/fortress-waterworks-3d-v1/"
const PALISADES := 2
const BRACKETS := 2
const CAGES := 2


## The throne's cell: the hall cell farthest from every gate (also where the
## Goblin King waits when his fight begins, #257).
static func throne_seat(map) -> Vector2i:
	var hall: Array = map.marks.get("hall", [])
	if hall.is_empty():
		return Vector2i(-1, -1)
	var gates: Array = map.marks.get("gates", [])
	var seat: Vector2i = hall[0]
	var best := -1.0
	for cell: Vector2i in hall:
		if map.is_wall(cell) or map.content_at(cell) != 0:
			continue
		var distance := 1e9
		for gate: Vector2i in gates:
			distance = minf(distance, Vector2(cell).distance_squared_to(Vector2(gate)))
		if distance > best:
			best = distance
			seat = cell
	return seat


## Where the King stands at the start of his fight: on the tile in front of
## his throne (toward the nearest gate), or on the throne's own tile.
static func king_cell(map) -> Vector2i:
	var seat := throne_seat(map)
	if seat == Vector2i(-1, -1):
		return seat
	var front: Vector2i = seat + _toward_nearest(seat, map.marks.get("gates", []))
	return front if front in map.marks.get("hall", []) and map.is_passable(front) else seat


static func dress(level: Node3D, map, seed: int, cell_size: float, wall_height: float, gate_broken: bool) -> int:
	var hall: Array = map.marks.get("hall", [])
	if hall.is_empty():
		return 0
	var gates: Array = map.marks.get("gates", [])
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([seed, "fortress 3d"])
	var root := Node3D.new()
	root.name = "Fortress3D"
	level.add_child(root)
	var at := func(cell: Vector2i) -> Vector3: return Vector3(cell.x * cell_size, 0.0, cell.y * cell_size)

	# The throne: the hall cell farthest from every gate, facing the nearest.
	var seat: Vector2i = throne_seat(map)
	var toward: Vector2i = _toward_nearest(seat, gates)
	_put(root, "throne", at.call(seat), Dressing._yaw_facing(toward), "")

	# Cells beside a wall, away from the throne and the ways in.
	var near_gate := func(cell: Vector2i) -> bool:
		return gates.any(func(g): return absi(g.x - cell.x) + absi(g.y - cell.y) <= 1)
	var edges: Array = hall.filter(func(c): return c != seat and not near_gate.call(c) and not Dressing._wall_sides(map, c).is_empty())
	_shuffle(edges, rng)
	# A watch post in a corner first (two walls), then palisades on the rest.
	for cell: Vector2i in edges:
		var sides: Array[Vector2i] = Dressing._wall_sides(map, cell)
		if sides.size() >= 2:
			var corner := Vector3(sides[0].x + sides[1].x, 0, sides[0].y + sides[1].y) * cell_size * 0.28
			_put(root, "watch-post", at.call(cell) + corner, Dressing._yaw_facing(-sides[0]), "")
			edges.erase(cell)
			break
	var placed := 0
	for cell: Vector2i in edges:
		if placed >= PALISADES:
			break
		var side: Vector2i = Dressing._wall_sides(map, cell)[0]
		_put(root, "palisade", at.call(cell) + Vector3(side.x, 0, side.y) * cell_size * 0.3, Dressing._yaw_facing(-side), "empty" if gate_broken else "closed")
		placed += 1
	# Brackets on the hall's walls.
	var walls := 0
	for cell: Vector2i in hall:
		if walls >= BRACKETS or cell == seat:
			continue
		for side in Dressing._wall_sides(map, cell):
			if walls >= BRACKETS or rng.randi() % 3 != 0:
				continue
			var face: Vector3 = at.call(cell) + Vector3(side.x, 0, side.y) * (cell_size / 2.0 - 0.01) + Vector3(0, 1.6, 0)
			_put(root, "hanging-bracket", face, Dressing._yaw_facing(-side), "")
			walls += 1
	# A walkway across the middle of the hall, overhead.
	var middle: Vector2i = _centre(hall)
	var wide: bool = _span(hall).x >= _span(hall).y
	_put(root, "overhead-walkway", at.call(middle) + Vector3(0, wall_height - 0.01, 0), 0.0 if wide else PI / 2.0, "")

	# Empty cages in side passages that lead nowhere.
	var cages := 0
	for y in map.height:
		for x in map.width:
			var cell := Vector2i(x, y)
			if cages >= CAGES or not Dressing._clear(map, cell) or map._is_room_cell(cell) or cell in gates or near_gate.call(cell):
				continue
			var open: Array = Dressing.SIDES.filter(func(s): return map.is_passable(cell + s))
			if open.size() != 1 or rng.randi() % 2 != 0:
				continue
			var back: Vector2i = -open[0]  # hang it toward the passage's end
			_put(root, "hanging-cage", at.call(cell) + Vector3(back.x, 0, back.y) * cell_size * 0.3 + Vector3(0, wall_height - 0.01, 0), rng.randf() * TAU, "")
			cages += 1
	return root.get_child_count()


static func _put(root: Node3D, id: String, position: Vector3, yaw: float, state: String) -> Node3D:
	var node: Node3D = load(DIR + id + ".tscn").instantiate()
	if state != "" and "state" in node:
		node.set("state", state)  # before it's added: restored at once, no motion
	node.position = position
	node.rotation.y = yaw
	node.set_meta("fortress_piece", id)
	root.add_child(node)
	return node


static func _toward_nearest(from: Vector2i, gates: Array) -> Vector2i:
	var best: Vector2i = Vector2i.DOWN
	var distance := 1e9
	for gate: Vector2i in gates:
		var d := Vector2(gate - from)
		if d.length_squared() < distance:
			distance = d.length_squared()
			best = Vector2i(signi(int(d.x)), 0) if absf(d.x) >= absf(d.y) else Vector2i(0, signi(int(d.y)))
	return best


static func _centre(cells: Array) -> Vector2i:
	var sum := Vector2.ZERO
	for c: Vector2i in cells:
		sum += Vector2(c)
	var mean := sum / cells.size()
	var best: Vector2i = cells[0]
	for c: Vector2i in cells:
		if Vector2(c).distance_to(mean) < Vector2(best).distance_to(mean):
			best = c
	return best


static func _span(cells: Array) -> Vector2i:
	var low: Vector2i = cells[0]
	var high: Vector2i = cells[0]
	for c: Vector2i in cells:
		low = Vector2i(mini(low.x, c.x), mini(low.y, c.y))
		high = Vector2i(maxi(high.x, c.x), maxi(high.y, c.y))
	return high - low


static func _shuffle(cells: Array, rng: RandomNumberGenerator) -> void:
	for i in range(cells.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var swap = cells[i]
		cells[i] = cells[j]
		cells[j] = swap

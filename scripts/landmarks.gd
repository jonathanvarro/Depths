extends RefCounted
## Landmarks (#117): a few set pieces per floor that make a place
## recognisable from the first-person view alone - "the dripping hall",
## "the old working face" - instead of one more brown corridor.
##
## Built from the mine dressing (cave-v1), mood lights and decorative
## fortress props; nothing here can be searched or used, so it never looks
## like an event. Seeded like the dressing, so a floor keeps its landmarks.
## Each one is named on screen the first time the party walks into it, and
## marked on the map from then on.

const Dressing := preload("res://scripts/dressing.gd")
const DungeonMap := preload("res://scripts/dungeon_map.gd")
const GOBLIN_MARK := preload("res://art/props/fortress-v1/goblin-mark.tscn")

## id -> name, floors, the kind of spot it needs, and how likely it is to be
## picked (weight, default 3). More, rarer floor-1 places (owner,
## 2026-11-10): the new ones weigh 1, so a floor's pair varies far more.
const KINDS := {
	"working_face": {"name": "The old working face", "floors": [1, 2], "spot": "dead_end"},
	"dripping_hall": {"name": "The dripping hall", "floors": [1, 3], "spot": "room"},
	"collapsed_shaft": {"name": "The collapsed shaft", "floors": [1, 1], "spot": "dead_end", "weight": 1},
	"timbered_drift": {"name": "The timbered drift", "floors": [1, 1], "spot": "drift", "weight": 1},
	"flooded_sump": {"name": "The flooded sump", "floors": [1, 1], "spot": "room", "weight": 1},
	"old_cave_in": {"name": "The old cave-in", "floors": [1, 2], "spot": "room", "weight": 1},
	"pale_grotto": {"name": "The pale grotto", "floors": [2, 3], "spot": "room"},
	"trophy_crossing": {"name": "The trophy crossing", "floors": [3, 4], "spot": "junction"},
	# #132's art: roots that broke through, and the king's buried supplies.
	"root_junction": {"name": "The root-choked junction", "floors": [2, 3], "spot": "junction"},
	"lost_cache": {"name": "The king's lost cache", "floors": [1, 2], "spot": "room"},
}
const ART := "res://art/dressing/landmarks-v1/"
const PER_FLOOR := 2
const MIN_ROOM := 6  # cells
const AWAY_FROM_START := 4  # steps: not where the party arrives


## Places this floor's landmarks and records them on `map.landmarks`.
## Returns the cells they use, which the dressing then leaves alone.
static func place(level: Node3D, map, depth: int, seed: int, cell_size: float, wall_height: float) -> Dictionary:
	var seen_before: Array = map.landmarks.filter(func(l): return l["seen"]).map(func(l): return l["id"])
	map.landmarks = []
	var used := {}
	if depth < 1:
		return used
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([seed, depth, "landmarks"])
	var kinds := KINDS.keys().filter(func(k): return depth >= KINDS[k]["floors"][0] and depth <= KINDS[k]["floors"][1])
	# A weighted order, drawn with our own generator so it's seeded too:
	# common places come up first more often, rare ones now and then.
	var ordered := []
	while not kinds.is_empty():
		var total := 0
		for k in kinds:
			total += int(KINDS[k].get("weight", 3))
		var roll := rng.randi_range(1, total)
		for k in kinds:
			roll -= int(KINDS[k].get("weight", 3))
			if roll <= 0:
				ordered.append(k)
				kinds.erase(k)
				break
	kinds = ordered
	var distances: Dictionary = map.walking_distances(map.start_cell)
	var root := Node3D.new()
	root.name = "Landmarks"
	level.add_child(root)
	for id: String in kinds:
		if map.landmarks.size() >= PER_FLOOR:
			break
		var spots := _spots(map, KINDS[id]["spot"], distances, used)
		if spots.is_empty():
			continue
		var cells: Array = spots[rng.randi_range(0, spots.size() - 1)]
		for cell in cells:
			used[cell] = true
		var piece := Node3D.new()
		piece.name = id
		root.add_child(piece)
		match id:
			"working_face": _build_working_face(piece, map, cells, rng, cell_size, wall_height)
			"dripping_hall": _build_dripping_hall(piece, map, cells, rng, cell_size, wall_height)
			"pale_grotto": _build_pale_grotto(piece, map, cells, rng, cell_size, wall_height)
			"trophy_crossing": _build_trophy_crossing(piece, map, cells, rng, cell_size, wall_height)
			"root_junction": _build_root_junction(piece, map, cells, rng, cell_size, wall_height)
			"lost_cache": _build_lost_cache(piece, map, cells, rng, cell_size, wall_height)
			"collapsed_shaft": _build_collapsed_shaft(piece, map, cells, rng, cell_size, wall_height)
			"timbered_drift": _build_timbered_drift(piece, map, cells, rng, cell_size, wall_height)
			"flooded_sump": _build_flooded_sump(piece, map, cells, rng, cell_size, wall_height)
			"old_cave_in": _build_old_cave_in(piece, map, cells, rng, cell_size, wall_height)
		map.landmarks.append({"id": id, "name": KINDS[id]["name"], "cells": cells, "centre": _centre(cells), "seen": id in seen_before})
	return used


## Places a landmark can go: each an array of cells.
## The landmark `cell` is part of, or an empty dictionary.
static func at_cell(map, cell: Vector2i) -> Dictionary:
	for landmark: Dictionary in map.landmarks:
		if cell in landmark["cells"]:
			return landmark
	return {}


## Places a landmark can go: each an array of cells.
static func _spots(map, kind: String, distances: Dictionary, used: Dictionary) -> Array:
	var spots := []
	var rooms_seen := {}
	for y in map.height:
		for x in map.width:
			var cell := Vector2i(x, y)
			if used.has(cell) or not Dressing._clear(map, cell) or distances.get(cell, 0) < AWAY_FROM_START:
				continue
			var open := Dressing.SIDES.filter(func(s): return map.is_passable(cell + s))
			match kind:
				"dead_end":
					if not map._is_room_cell(cell) and open.size() == 1:
						# The end of a drift and the two cells leading to it.
						var cells := [cell]
						var back: Vector2i = cell + open[0]
						for i in 2:
							if Dressing._clear(map, back) and not map._is_room_cell(back) and not used.has(back):
								cells.append(back)
								back += open[0]
						spots.append(cells)
				"junction":
					if not map._is_room_cell(cell) and open.size() >= 3:
						spots.append([cell])
				"drift":  # three cells of straight corridor in a row
					var axis: Vector2i = Dressing._corridor_axis(map, cell)
					if axis == Vector2i.ZERO or map._is_room_cell(cell):
						continue
					var run := [cell]
					for i in 2:
						var next: Vector2i = run[-1] + axis
						if Dressing._clear(map, next) and not used.has(next) and Dressing._corridor_axis(map, next) == axis and distances.get(next, 0) >= AWAY_FROM_START:
							run.append(next)
					if run.size() == 3:
						spots.append(run)
				"room":
					if not map._is_room_cell(cell) or rooms_seen.has(cell):
						continue
					var room: Array = map.room_around(cell)
					for c in room:
						rooms_seen[c] = true
					var stairs := room.any(func(c): return map.content_at(c) in [DungeonMap.Content.STAIRS_DOWN, DungeonMap.Content.STAIRS_UP])
					var clear := room.filter(func(c): return Dressing._clear(map, c) and not used.has(c))
					if not stairs and clear.size() >= MIN_ROOM:
						spots.append(clear)
	return spots


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


static func _at(cell: Vector2i, cell_size: float) -> Vector3:
	return Vector3(cell.x * cell_size, 0.0, cell.y * cell_size)


## A soft coloured glow for mood only: it isn't the party's light.
static func _glow(parent: Node3D, at: Vector3, colour: Color, energy: float, reach: float) -> void:
	var light := OmniLight3D.new()
	light.position = at
	light.light_color = colour
	light.light_energy = energy
	light.omni_range = reach
	light.shadow_enabled = false
	light.set_meta("mood_only", true)
	parent.add_child(light)


## Where the drift ends: rails running in, timber frames, the face itself
## hacked into rubble, and the miners' tallies on the wall.
static func _build_working_face(piece: Node3D, map, cells: Array, rng: RandomNumberGenerator, cell_size: float, wall_height: float) -> void:
	var end: Vector2i = cells[0]
	var inward: Vector2i = Dressing.SIDES.filter(func(s): return map.is_passable(end + s))[0]
	var axis := Vector2i(absi(inward.x), absi(inward.y))
	for cell: Vector2i in cells:
		Dressing._put(piece, "mine-rails", _at(cell, cell_size), Dressing._yaw_facing(axis))  # 3D rails run along local Z
		Dressing._put(piece, "mine-support", _at(cell, cell_size) + Vector3(inward.x, 0, inward.y) * cell_size * 0.3, Dressing._yaw_across(axis))
	var face := _at(end, cell_size) - Vector3(inward.x, 0, inward.y) * (cell_size / 2.0 - 0.01)
	for h in [0.5, 1.4]:
		Dressing._put(piece, "cracks-rubble", face + Vector3(0, h, 0), Dressing._yaw_facing(inward))
	Dressing._put(piece, "floor-gravel", _at(end, cell_size) - Vector3(inward.x, 0, inward.y) * 0.4, 0.0)
	Dressing._put(piece, "stalagmite-broken", _at(end, cell_size) - Vector3(inward.x, 0, inward.y) * 0.6 + Dressing._along_wall(inward) * 0.5, 0.0)
	var side := Vector2i(inward.y, inward.x)  # a side wall of the drift
	for cell: Vector2i in cells.slice(0, 2):
		if map.is_wall(cell + side):
			var wall := _at(cell, cell_size) + Vector3(side.x, 0, side.y) * (cell_size / 2.0 - 0.01)
			Dressing._put(piece, "chalk-tally", wall + Vector3(0, 1.3, 0), Dressing._yaw_facing(-side))
	_glow(piece, _at(end, cell_size) + Vector3(0, 1.6, 0), Color(1.0, 0.7, 0.4), 0.25, cell_size * 1.4)


## A room where the roof weeps: stalactites and drips everywhere, wide
## puddles, flowstone down the walls and a cold blue-green light.
static func _build_dripping_hall(piece: Node3D, map, cells: Array, rng: RandomNumberGenerator, cell_size: float, wall_height: float) -> void:
	var stalactites := ["stalactite-single", "stalactite-pair", "stalactite-cluster"]
	for cell: Vector2i in cells:
		var at := _at(cell, cell_size)
		var drop := Dressing._put(piece, stalactites[rng.randi() % 3], at + Vector3(rng.randf_range(-0.4, 0.4), wall_height - 0.01, rng.randf_range(-0.4, 0.4)), 0.0)
		if rng.randi() % 2 == 0:
			Dressing._effect(drop, "drip", Vector3(0, -0.95, 0), 0.006, true, 0.85)
		if rng.randi() % 3 != 0:
			Dressing._put(piece, "puddle-wide" if rng.randi() % 2 == 0 else "puddle-small", at + Vector3(rng.randf_range(-0.3, 0.3), 0, rng.randf_range(-0.3, 0.3)), rng.randi_range(0, 3) * PI / 2.0)
		for side in Dressing._wall_sides(map, cell):
			if rng.randi() % 2 == 0:
				var wall := at + Vector3(side.x, 0, side.y) * (cell_size / 2.0 - 0.01)
				Dressing._put(piece, "flowstone", wall + Vector3(0, 1.2, 0) + Dressing._along_wall(side) * rng.randf_range(-0.4, 0.4), Dressing._yaw_facing(-side))
	_glow(piece, _at(_centre(cells), cell_size) + Vector3(0, wall_height - 0.4, 0), Color(0.45, 0.75, 0.85), 0.6, cell_size * 3.2)


## A shaft that came down long ago (2026-11-10): rubble choking the end of
## the drift, a split frame, roots hanging through, and a thin grey light
## from somewhere far above.
static func _build_collapsed_shaft(piece: Node3D, map, cells: Array, rng: RandomNumberGenerator, cell_size: float, wall_height: float) -> void:
	var end: Vector2i = cells[0]
	var inward: Vector2i = Dressing.SIDES.filter(func(s): return map.is_passable(end + s))[0]
	var axis := Vector2i(absi(inward.x), absi(inward.y))
	var at := _at(end, cell_size)
	var back := -Vector3(inward.x, 0, inward.y)
	Dressing._put(piece, "rubble-cluster", at + back * 0.45, rng.randf() * TAU)
	Dressing._put(piece, "rubble-cluster", at + back * 0.1 + Dressing._along_wall(inward) * 0.4, rng.randf() * TAU)
	Dressing._put(piece, "mine-support-damaged", _at(cells[min(1, cells.size() - 1)], cell_size), Dressing._yaw_across(axis))
	for i in 2:
		Dressing._put(piece, "hanging-roots", at + Vector3(rng.randf_range(-0.4, 0.4), wall_height - 0.01, rng.randf_range(-0.4, 0.4)), rng.randf() * TAU)
	Dressing._put(piece, "scattered-bones", at + Vector3(inward.x, 0, inward.y) * 0.3, rng.randf() * TAU)
	_glow(piece, at + Vector3(0, wall_height - 0.2, 0), Color(0.72, 0.8, 0.95), 0.9, cell_size * 1.8)


## A straight drift the miners shored up properly (2026-11-10): a frame in
## every cell, rails underfoot, and their old lanterns, one still burning.
static func _build_timbered_drift(piece: Node3D, map, cells: Array, rng: RandomNumberGenerator, cell_size: float, wall_height: float) -> void:
	var axis: Vector2i = Dressing._corridor_axis(map, cells[0])
	var lit := rng.randi_range(0, cells.size() - 1)
	for i in cells.size():
		var cell: Vector2i = cells[i]
		var at := _at(cell, cell_size)
		Dressing._put(piece, "mine-support-damaged" if i == 1 else "mine-support", at, Dressing._yaw_across(axis))
		Dressing._put(piece, "mine-rails-broken" if i == 2 else "mine-rails", at, Dressing._yaw_facing(axis))
		var sides := Dressing._wall_sides(map, cell)
		if not sides.is_empty():
			var side: Vector2i = sides[i % sides.size()]
			var lantern := Dressing._put(piece, "lantern-hanging", at + Vector3(side.x, 0, side.y) * (cell_size / 2.0 - 0.01) + Vector3(0, 1.9, 0), Dressing._yaw_facing(-side))
			if "lit" in lantern:
				lantern.lit = i == lit
	_glow(piece, _at(cells[lit], cell_size) + Vector3(0, 1.6, 0), Color(1.0, 0.72, 0.4), 0.45, cell_size * 1.6)


## A room where the groundwater rose and stayed (2026-11-10): black water
## pooled over part of the floor under dripping formations. It's only
## water: it doesn't slow or hurt anyone.
static func _build_flooded_sump(piece: Node3D, map, cells: Array, rng: RandomNumberGenerator, cell_size: float, wall_height: float) -> void:
	var Galleries = load("res://scripts/galleries.gd")
	var pool := cells.duplicate()
	for i in range(pool.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var swap = pool[i]
		pool[i] = pool[j]
		pool[j] = swap
	var wet := pool.slice(0, maxi(2, pool.size() / 3))
	for cell: Vector2i in wet:
		piece.add_child(Galleries.water_surface(cell, cell_size, false))
		var drop := Dressing._put(piece, "stalactite-cluster" if rng.randi() % 3 == 0 else "stalactite-single", _at(cell, cell_size) + Vector3(rng.randf_range(-0.4, 0.4), wall_height - 0.01, rng.randf_range(-0.4, 0.4)), rng.randf() * TAU)
		Dressing._effect(drop, "drip", Vector3(0, -0.8, 0), 0.006, true, 0.85)
	for cell: Vector2i in cells:
		for side in Dressing._wall_sides(map, cell):
			if rng.randi() % 3 == 0:
				var wall := _at(cell, cell_size) + Vector3(side.x, 0, side.y) * (cell_size / 2.0 - 0.01)
				Dressing._put(piece, "flowstone", wall + Vector3(0, 1.2, 0), Dressing._yaw_facing(-side))
	_glow(piece, _at(_centre(cells), cell_size) + Vector3(0, wall_height - 0.5, 0), Color(0.4, 0.6, 0.75), 0.55, cell_size * 3.0)


## Where the roof came in on someone (2026-11-10): rubble heaped along one
## wall, a skeleton half under it, broken stone everywhere.
static func _build_old_cave_in(piece: Node3D, map, cells: Array, rng: RandomNumberGenerator, cell_size: float, wall_height: float) -> void:
	var edge_cells: Array = cells.filter(func(c): return not Dressing._wall_sides(map, c).is_empty())
	if edge_cells.is_empty():
		edge_cells = cells
	var heap: Vector2i = edge_cells[rng.randi_range(0, edge_cells.size() - 1)]
	var sides := Dressing._wall_sides(map, heap)
	var side: Vector2i = sides[0] if not sides.is_empty() else Vector2i.UP
	var at := _at(heap, cell_size)
	for offset in [0.3, -0.25]:
		Dressing._put(piece, "rubble-cluster", at + Vector3(side.x, 0, side.y) * cell_size * 0.28 + Dressing._along_wall(side) * offset, rng.randf() * TAU)
	Dressing._put(piece, "fallen-skeleton", at - Vector3(side.x, 0, side.y) * 0.15, Dressing._yaw_facing(-side))
	for i in 3:
		var c: Vector2i = cells[rng.randi_range(0, cells.size() - 1)]
		Dressing._put(piece, "stalagmite-broken" if i == 0 else "scattered-bones" if i == 1 else "rubble-cluster", _at(c, cell_size) + Vector3(rng.randf_range(-0.4, 0.4), 0, rng.randf_range(-0.4, 0.4)), rng.randf() * TAU)
	_glow(piece, at + Vector3(0, 1.4, 0), Color(0.85, 0.75, 0.6), 0.35, cell_size * 2.0)


## Fungus over every wall, its glow pulsing, pale mushrooms underfoot.
static func _build_pale_grotto(piece: Node3D, map, cells: Array, rng: RandomNumberGenerator, cell_size: float, wall_height: float) -> void:
	for cell: Vector2i in cells:
		var at := _at(cell, cell_size)
		var sides := Dressing._wall_sides(map, cell)
		for side in sides:
			var wall := at + Vector3(side.x, 0, side.y) * (cell_size / 2.0 - 0.01)
			var fungus := Dressing._put(piece, "wall-fungus", wall + Vector3(0, rng.randf_range(0.6, 1.5), 0) + Dressing._along_wall(side) * rng.randf_range(-0.4, 0.4), Dressing._yaw_facing(-side))
			Dressing._effect(fungus, "fungus-pulse", Vector3(0, 0, 0.03), 0.0065, false, 1.0)
		if rng.randi() % 3 != 0:
			var toward: Vector2i = sides[rng.randi() % sides.size()] if not sides.is_empty() else Vector2i(1, 1)
			Dressing._put(piece, "pale-mushrooms", at + Vector3(toward.x, 0, toward.y) * cell_size * 0.3, 0.0)
	_glow(piece, _at(_centre(cells), cell_size) + Vector3(0, 1.0, 0), Color(0.55, 0.9, 0.6), 1.1, cell_size * 3.2)


static func _art(parent: Node3D, id: String, at: Vector3, yaw: float) -> Node3D:
	var node: Node3D = load(ART + id + ".tscn").instantiate()
	node.position = at
	node.rotation.y = yaw
	parent.add_child(node)
	return node


## Roots that broke through where passages meet (#132): curtains from the
## roof, roots down the walls, tangles at their feet, one across the floor.
## The way through stays open below the fringe.
static func _build_root_junction(piece: Node3D, map, cells: Array, rng: RandomNumberGenerator, cell_size: float, wall_height: float) -> void:
	var cell: Vector2i = cells[0]
	var around: Array = [cell] + Dressing.SIDES.map(func(s): return cell + s).filter(func(c): return map.is_passable(c))
	for c: Vector2i in around:
		var at := _at(c, cell_size)
		_art(piece, "root-curtain-a" if rng.randi() % 2 == 0 else "root-curtain-b", at + Vector3(rng.randf_range(-0.4, 0.4), wall_height - 0.01, rng.randf_range(-0.4, 0.4)), rng.randf_range(0, TAU))
		for side in Dressing._wall_sides(map, c):
			if rng.randi() % 2 == 0:
				var wall := at + Vector3(side.x, 0, side.y) * (cell_size / 2.0 - 0.01)
				_art(piece, "wall-roots", wall + Vector3(0, 1.3, 0), Dressing._yaw_facing(-side))
				_art(piece, "root-foot-tangle", at + Vector3(side.x, 0, side.y) * cell_size * 0.36, 0.0)
	_art(piece, "floor-crossing-root", _at(cell, cell_size), rng.randi_range(0, 3) * PI / 2.0)


## The king's earlier expedition stored supplies here, and the roof came
## down on them (#132): broken crates and a barrel by the walls, a torn
## banner, rubble and spilled grain. Nothing here can be taken.
static func _build_lost_cache(piece: Node3D, map, cells: Array, rng: RandomNumberGenerator, cell_size: float, wall_height: float) -> void:
	var edge_cells: Array = cells.filter(func(c): return not Dressing._wall_sides(map, c).is_empty())
	for i in mini(3, edge_cells.size()):
		var c: Vector2i = edge_cells.pop_at(rng.randi_range(0, edge_cells.size() - 1))  # seeded, so it's the same each visit
		var side: Vector2i = Dressing._wall_sides(map, c)[0]
		_art(piece, ["collapsed-crates", "split-barrel", "collapsed-crates"][i], _at(c, cell_size) + Vector3(side.x, 0, side.y) * cell_size * 0.3, 0.0)
	var centre := _at(_centre(cells), cell_size)
	_art(piece, "fallen-banner", centre + Vector3(rng.randf_range(-0.3, 0.3), 0, rng.randf_range(-0.3, 0.3)), rng.randi_range(0, 3) * PI / 2.0)
	for id in ["cache-rubble-planks", "cache-spilled-grain"]:
		var c: Vector2i = cells[rng.randi_range(0, cells.size() - 1)]
		_art(piece, id, _at(c, cell_size) + Vector3(rng.randf_range(-0.3, 0.3), 0, rng.randf_range(-0.3, 0.3)), rng.randi_range(0, 3) * PI / 2.0)
	_glow(piece, centre + Vector3(0, 1.2, 0), Color(0.95, 0.8, 0.55), 0.7, cell_size * 3.0)


## Where goblin tunnels meet: trophies strung overhead, a torch either
## side, their mark daubed and set up in the middle.
static func _build_trophy_crossing(piece: Node3D, map, cells: Array, rng: RandomNumberGenerator, cell_size: float, wall_height: float) -> void:
	var cell: Vector2i = cells[0]
	var at := _at(cell, cell_size)
	for offset in [Vector3(-0.45, 0, -0.3), Vector3(0.4, 0, 0.35), Vector3(0.1, 0, -0.1)]:
		Dressing._put(piece, "hanging-trophies", at + offset + Vector3(0, wall_height - 0.01, 0), 0.0)
	var mark := GOBLIN_MARK.instantiate()
	mark.position = at + Vector3(0.55, 0, 0.55)
	piece.add_child(mark)
	Dressing._put(piece, "goblin-litter", at, 0.0)
	# Torches and daubs on the walls of the passages around it.
	var lit := 0
	for side in Dressing.SIDES:
		var next: Vector2i = cell + side
		if not map.is_passable(next):
			continue
		for wall_side in Dressing._wall_sides(map, next):
			var wall := _at(next, cell_size) + Vector3(wall_side.x, 0, wall_side.y) * (cell_size / 2.0 - 0.01)
			var id := "goblin-torch-lit" if lit < 2 else "goblin-daubs"
			Dressing._put(piece, id, wall + Vector3(0, 1.45 if lit < 2 else 1.2, 0), Dressing._yaw_facing(-wall_side))
			lit += 1
			break

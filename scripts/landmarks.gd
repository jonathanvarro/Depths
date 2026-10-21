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

## id -> name, floors, and the kind of spot it needs.
const KINDS := {
	"working_face": {"name": "The old working face", "floors": [1, 2], "spot": "dead_end"},
	"dripping_hall": {"name": "The dripping hall", "floors": [1, 3], "spot": "room"},
	"pale_grotto": {"name": "The pale grotto", "floors": [2, 3], "spot": "room"},
	"trophy_crossing": {"name": "The trophy crossing", "floors": [3, 4], "spot": "junction"},
}
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
	# Shuffle with our own generator, so the choice is seeded too.
	for i in range(kinds.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var swap = kinds[i]
		kinds[i] = kinds[j]
		kinds[j] = swap
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
		Dressing._put(piece, "mine-rails", _at(cell, cell_size), Dressing._yaw_along(axis))
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

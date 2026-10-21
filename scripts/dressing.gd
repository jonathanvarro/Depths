extends RefCounted
## Mine dressing (#128): ChatGPT's cave-v1 pieces scattered sparsely over a
## floor so the walls, ceiling and floor read as a worked-out mine - pit
## props on the upper floor, then natural rock, damp and fungus, then
## goblin marks and lit torches near the fortress.
##
## Purely cosmetic: nothing here blocks, hides an enemy or changes light
## rules (the lit torch's glow is mood only, owner 2026-10-20). Placement is
## seeded by the site and depth, so a floor looks the same on every visit.
## Cells with anything on them (stairs, doors, events, packages' solid rock)
## are left clear.

const DungeonMap := preload("res://scripts/dungeon_map.gd")
const DIR := "res://art/dressing/cave-v1/"
const AMBIENT := "res://art/effects/ambient-v1/"
const SIDES: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

## id -> [first floor, last floor] (from the catalogue).
const WALL := {
	"flowstone": [1, 2], "cracks-rubble": [1, 4], "burnt-sconce": [1, 2],
	"goblin-torch-lit": [3, 4], "goblin-daubs": [3, 4], "wall-fungus": [2, 3],
	"chalk-arrow": [1, 2], "chalk-cross": [1, 2], "chalk-tally": [1, 2],
}
## How high each wall piece's centre sits, in metres (default 1.3).
const WALL_HEIGHTS := {"cracks-rubble": 0.5, "burnt-sconce": 1.6, "goblin-torch-lit": 1.45,
		"flowstone": 1.2, "wall-fungus": 0.9, "goblin-daubs": 1.2}
const CEILING := {
	"stalactite-single": [1, 3], "stalactite-pair": [1, 3], "stalactite-cluster": [1, 3],
	"web-strand": [1, 2], "hanging-trophies": [3, 4],
}
const EDGE := {
	"stalagmite-stub": [1, 3], "stalagmite-tall": [1, 3], "stalagmite-broken": [1, 3],
	"pale-mushrooms": [2, 3], "rat-nest": [1, 2],
}
const DECAL := {
	"puddle-small": [1, 2], "puddle-wide": [1, 2], "floor-gravel": [1, 4],
	"tracks-drag": [1, 3], "floor-crack": [1, 4], "goblin-litter": [3, 4], "old-scorch": [1, 3],
}

## One in this many eligible cells gets each kind of piece.
const WALL_ODDS := 6
const CEILING_ODDS := 7
const EDGE_ODDS := 9
const DECAL_ODDS := 7
const CORNER_ODDS := 4
const SUPPORT_EVERY := 4  # pit props along straight corridors (floor 1)


## Dresses `level` for `map` at `depth`. Returns how many pieces it placed.
## `avoid`: cells already dressed as a landmark.
static func dress(level: Node3D, map, depth: int, seed: int, cell_size: float, wall_height: float, avoid := {}) -> int:
	if depth < 1:
		return 0
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([seed, depth, "dressing"])
	var root := Node3D.new()
	root.name = "Dressing"
	level.add_child(root)
	var walls := _pool(WALL, depth)
	var ceiling := _pool(CEILING, depth)
	var edge := _pool(EDGE, depth)
	var decals := _pool(DECAL, depth)
	var since_support := SUPPORT_EVERY
	for y in map.height:
		for x in map.width:
			var cell := Vector2i(x, y)
			if not _clear(map, cell) or avoid.has(cell):
				continue
			var centre := Vector3(x * cell_size, 0.0, y * cell_size)
			var sides := _wall_sides(map, cell)
			var corridor := _corridor_axis(map, cell)
			# Floor 1 is the miners' level: timber frames along the drifts, rails underfoot.
			if depth == 1 and corridor != Vector2i.ZERO:
				since_support += 1
				if since_support >= SUPPORT_EVERY and rng.randf() < 0.6:
					since_support = 0
					_put(root, "mine-support", centre, _yaw_across(corridor))
				elif rng.randi() % 5 == 0:
					_put(root, "mine-rails", centre, _yaw_along(corridor))
			if not sides.is_empty() and not walls.is_empty() and rng.randi() % (WALL_ODDS * _thin(walls)) == 0:
				var side: Vector2i = sides[rng.randi() % sides.size()]
				var id: String = walls[rng.randi() % walls.size()]
				var at := centre + Vector3(side.x, 0, side.y) * (cell_size / 2.0 - 0.01)
				at.y = WALL_HEIGHTS.get(id, 1.3)
				at += _along_wall(side) * rng.randf_range(-0.45, 0.45)
				var piece := _put(root, id, at, _yaw_facing(-side))
				if id == "wall-fungus":
					_effect(piece, "fungus-pulse", Vector3(0, 0, 0.03), 0.0045, false, 0.8)
			if not ceiling.is_empty() and rng.randi() % (CEILING_ODDS * _thin(ceiling)) == 0:
				var id: String = ceiling[rng.randi() % ceiling.size()]
				var at := centre + Vector3(rng.randf_range(-0.5, 0.5), wall_height - 0.01, rng.randf_range(-0.5, 0.5))
				var piece := _put(root, id, at, 0.0)
				if id.begins_with("stalactite") and depth <= 2 and rng.randi() % 3 == 0:
					_effect(piece, "drip", Vector3(0, -0.95, 0), 0.006, true, 0.85)
			if not edge.is_empty() and rng.randi() % EDGE_ODDS == 0:
				var id: String = edge[rng.randi() % edge.size()]
				if id == "stalagmite-tall" and corridor != Vector2i.ZERO:
					id = "stalagmite-stub"  # keep narrow drifts walkable to the eye
				var toward: Vector2i = sides[rng.randi() % sides.size()] if not sides.is_empty() else Vector2i([-1, 1][rng.randi() % 2], [-1, 1][rng.randi() % 2])
				var at := centre + Vector3(toward.x, 0, toward.y) * cell_size * 0.36
				_put(root, id, at, 0.0)
			if not decals.is_empty() and rng.randi() % DECAL_ODDS == 0:
				var id: String = decals[rng.randi() % decals.size()]
				var at := centre + Vector3(rng.randf_range(-0.35, 0.35), 0, rng.randf_range(-0.35, 0.35))
				_put(root, id, at, rng.randi_range(0, 3) * PI / 2.0)
			if depth <= 2 and sides.size() >= 2 and rng.randi() % CORNER_ODDS == 0:
				_corner_web(root, centre, sides, cell_size, wall_height)
	return root.get_child_count()


## The ids allowed at `depth`.
static func _pool(table: Dictionary, depth: int) -> Array:
	var ids := []
	for id in table:
		if depth >= table[id][0] and depth <= table[id][1]:
			ids.append(id)
	return ids


## Fewer pieces when a floor has few kinds to choose from, so one piece
## isn't repeated everywhere (floor 4's only ceiling piece is trophies).
static func _thin(pool: Array) -> int:
	return maxi(1, 4 - pool.size())


## True for an open, empty floor cell that dressing may use.
static func _clear(map, cell: Vector2i) -> bool:
	return map.is_passable(cell) and map.content_at(cell) == DungeonMap.Content.NONE \
			and map.door_at(cell) == DungeonMap.Door.NONE and not map.events.has(cell) \
			and cell != map.start_cell and not cell in map.marks.get("hall", [])


## Directions from `cell` that have a wall face (inside the map).
static func _wall_sides(map, cell: Vector2i) -> Array[Vector2i]:
	var sides: Array[Vector2i] = []
	for side in SIDES:
		var next := cell + side
		if next.x >= 0 and next.y >= 0 and next.x < map.width and next.y < map.height and map.is_wall(next):
			sides.append(side)
	return sides


## (1,0) for a straight east-west corridor cell, (0,1) for north-south,
## ZERO otherwise.
static func _corridor_axis(map, cell: Vector2i) -> Vector2i:
	var ns: bool = map.is_wall(cell + Vector2i(0, 1)) and map.is_wall(cell + Vector2i(0, -1))
	var ew: bool = map.is_wall(cell + Vector2i(1, 0)) and map.is_wall(cell + Vector2i(-1, 0))
	if ns and not ew and map.is_passable(cell + Vector2i(1, 0)) and map.is_passable(cell + Vector2i(-1, 0)):
		return Vector2i(1, 0)
	if ew and not ns and map.is_passable(cell + Vector2i(0, 1)) and map.is_passable(cell + Vector2i(0, -1)):
		return Vector2i(0, 1)
	return Vector2i.ZERO


## Yaw that turns a piece's face (local +Z) toward `direction`.
static func _yaw_facing(direction: Vector2i) -> float:
	return atan2(float(direction.x), float(direction.y))


## A frame drawn in the local XY plane spans the corridor: faces along it.
static func _yaw_across(axis: Vector2i) -> float:
	return _yaw_facing(axis)


## A decal whose length runs along local X lies along the corridor.
static func _yaw_along(axis: Vector2i) -> float:
	return 0.0 if axis.x != 0 else PI / 2.0


## Unit vector along a wall face (perpendicular to `side`).
static func _along_wall(side: Vector2i) -> Vector3:
	return Vector3(side.y, 0, side.x).abs()


static func _put(root: Node3D, id: String, at: Vector3, yaw: float) -> Node3D:
	var node: Node3D = load(DIR + id + ".tscn").instantiate()
	node.position = at
	node.rotation.y = yaw
	root.add_child(node)
	return node


## A web strung across the top of a corner, on one wall, hanging away from
## the corner.
static func _corner_web(root: Node3D, centre: Vector3, sides: Array[Vector2i], cell_size: float, wall_height: float) -> void:
	var a: Vector2i = sides[0]
	var b := Vector2i.ZERO
	for side in sides:
		if side.x != a.x and side.y != a.y:
			b = side
			break
	if b == Vector2i.ZERO:
		return  # opposite walls only: a corridor, not a corner
	var corner := centre + Vector3(a.x + b.x, 0, a.y + b.y) * (cell_size / 2.0 - 0.02)
	corner.y = wall_height - 0.02
	var node := _put(root, "corner-web", corner, _yaw_facing(-a))
	var right := node.basis.x
	if right.dot(Vector3(b.x, 0, b.y)) > 0.0:
		node.scale.x = -1.0  # the web hangs from the corner outward


## A looping animated overlay (drip, fungus glow) on a dressing piece.
static func _effect(parent: Node3D, id: String, at: Vector3, pixel: float, billboard: bool, alpha: float) -> void:
	var sprite := AnimatedSprite3D.new()
	sprite.sprite_frames = load(AMBIENT + id + ".tres")
	sprite.animation = &"loop"
	sprite.pixel_size = pixel
	sprite.position = at
	sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y if billboard else BaseMaterial3D.BILLBOARD_DISABLED
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.shaded = false
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sprite.modulate.a = alpha
	parent.add_child(sprite)
	sprite.frame = randi() % sprite.sprite_frames.get_frame_count(&"loop")  # out of step with its neighbours
	sprite.play(&"loop")

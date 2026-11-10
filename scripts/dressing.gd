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
const Settings := preload("res://scripts/settings.gd")
## ChatGPT's 3D pieces (2026-11-08: #239, #241-#243) stand in for the
## matching 2D cut-outs, by id, and add new ones. Same mounts: floor pieces
## at floor level, wall pieces at the face with local +Z into the room,
## ceiling pieces at the roof.
const GROWTH := "res://art/dressing/cave-growth-3d-v1/"
const MINE := "res://art/dressing/mine-3d-v1/"
const EXPEDITION := "res://art/props/expedition-3d-v1/"
const BONES := "res://art/dressing/bone-decor-v1/"
const MODELS := {
	"mine-support": MINE + "support.tscn", "mine-support-damaged": MINE + "support-damaged.tscn",
	"mine-rails": EXPEDITION + "rails.tscn", "mine-rails-broken": EXPEDITION + "rails-broken.tscn",
	"lantern-hanging": MINE + "lantern-hanging.tscn", "lantern-standing": MINE + "lantern-standing.tscn",
	"stalactite-single": GROWTH + "stalactite-single.tscn", "stalactite-pair": GROWTH + "stalactite-single.tscn",
	"stalactite-cluster": GROWTH + "stalactite-cluster.tscn",
	"stalagmite-stub": GROWTH + "stalagmite-stub.tscn", "stalagmite-tall": GROWTH + "stalagmite-tall.tscn",
	"stalagmite-broken": GROWTH + "stalagmite-broken.tscn", "stalagmite-cluster": GROWTH + "stalagmite-cluster.tscn",
	"flowstone": GROWTH + "flowstone-wall.tscn", "wall-fungus": GROWTH + "shelf-fungus.tscn",
	"pale-mushrooms": GROWTH + "mushroom-clump.tscn", "fungal-mat": GROWTH + "fungal-mat.tscn",
	"rubble-cluster": GROWTH + "rubble-cluster.tscn",
	"wall-roots": GROWTH + "wall-roots.tscn", "hanging-roots": GROWTH + "hanging-roots.tscn",
	"floor-roots": GROWTH + "floor-roots.tscn",
	"scattered-bones": BONES + "scattered-bones.tscn", "small-remains": BONES + "small-remains.tscn",
	"fallen-skeleton": BONES + "fallen-skeleton.tscn", "seated-skeleton": BONES + "seated-skeleton.tscn",
}
## The fungal caverns' pieces by their 2D path (fungal_dressing.gd).
const MODELS_BY_PATH := {
	"cave-v1/wall-fungus": GROWTH + "shelf-fungus.tscn", "landmarks-v1/wall-roots": GROWTH + "wall-roots.tscn",
	"cave-v1/flowstone": GROWTH + "flowstone-wall.tscn", "landmarks-v1/root-curtain-b": GROWTH + "hanging-roots.tscn",
	"cave-v1/stalactite-single": GROWTH + "stalactite-single.tscn", "cave-v2/floor-fungus": GROWTH + "mushroom-clump.tscn",
	"cave-v2/floor-fungus-lit": GROWTH + "mushroom-clump.tscn",
	"cave-v1/stalagmite-stub": GROWTH + "stalagmite-stub.tscn", "cave-v1/stalagmite-broken": GROWTH + "stalagmite-broken.tscn",
}
## One in this many room corners (floors 2+) holds a skeleton.
const SKELETON_ODDS := 45

## id -> [first floor, last floor] (from the catalogue).
const WALL := {
	"flowstone": [1, 2], "cracks-rubble": [1, 4], "burnt-sconce": [1, 2],
	"goblin-torch-lit": [3, 4], "goblin-daubs": [3, 4], "wall-fungus": [2, 3],
	"chalk-arrow": [1, 2], "chalk-cross": [1, 2], "chalk-tally": [1, 2],
	"wall-roots": [1, 3], "lantern-hanging": [1, 1],
}
## How high each wall piece's centre sits, in metres (default 1.3).
const WALL_HEIGHTS := {"cracks-rubble": 0.5, "burnt-sconce": 1.6, "goblin-torch-lit": 1.45,
		"flowstone": 1.2, "wall-fungus": 0.9, "goblin-daubs": 1.2, "wall-roots": 1.15, "lantern-hanging": 1.9}
const CEILING := {
	"stalactite-single": [1, 3], "stalactite-pair": [1, 3], "stalactite-cluster": [1, 3],
	"web-strand": [1, 2], "hanging-trophies": [3, 4], "hanging-roots": [1, 3],
}
const EDGE := {
	"stalagmite-stub": [1, 3], "stalagmite-tall": [1, 3], "stalagmite-broken": [1, 3],
	"pale-mushrooms": [2, 3], "rat-nest": [1, 2],
	"stalagmite-cluster": [1, 3], "rubble-cluster": [1, 4], "floor-roots": [1, 3], "fungal-mat": [2, 3],
	"scattered-bones": [1, 4], "small-remains": [2, 4], "lantern-standing": [1, 1],
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
					_put(root, "mine-support-damaged" if rng.randi() % 3 == 0 else "mine-support", centre, _yaw_across(corridor))
				elif rng.randi() % 5 == 0:
					# 3D rails run along local Z; the 2D decal ran along X.
					_put(root, "mine-rails-broken" if rng.randi() % 4 == 0 else "mine-rails", centre, _yaw_facing(corridor))
			if not sides.is_empty() and not walls.is_empty() and rng.randi() % (WALL_ODDS * _thin(walls)) == 0:
				var side: Vector2i = sides[rng.randi() % sides.size()]
				var id: String = walls[rng.randi() % walls.size()]
				var at := centre + Vector3(side.x, 0, side.y) * (cell_size / 2.0 - 0.01)
				at.y = WALL_HEIGHTS.get(id, 1.3)
				at += _along_wall(side) * rng.randf_range(-0.45, 0.45)
				var piece := _put(root, id, at, _yaw_facing(-side))
				if id == "wall-fungus" and not MODELS.has(id):
					_effect(piece, "fungus-pulse", Vector3(0, 0, 0.03), 0.0045, false, 0.8)
				_light_lantern(piece, rng)
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
				_light_lantern(_put(root, id, at, rng.randf() * TAU if MODELS.has(id) else 0.0), rng)
			# Now and then the dead of an earlier party, in a room's corner (#239).
			if depth >= 2 and sides.size() >= 2 and map._is_room_cell(cell) and rng.randi() % SKELETON_ODDS == 0:
				var wall: Vector2i = sides[rng.randi() % sides.size()]
				if rng.randi() % 2 == 0:
					_put(root, "seated-skeleton", centre + Vector3(wall.x, 0, wall.y) * cell_size * 0.3, _yaw_facing(-wall))
				else:
					_put(root, "fallen-skeleton", centre, rng.randf() * TAU)
			if not decals.is_empty() and rng.randi() % DECAL_ODDS == 0:
				var id: String = decals[rng.randi() % decals.size()]
				var at := centre + Vector3(rng.randf_range(-0.35, 0.35), 0, rng.randf_range(-0.35, 0.35))
				_put(root, id, at, rng.randi_range(0, 3) * PI / 2.0)
			if depth <= 2 and sides.size() >= 2 and rng.randi() % CORNER_ODDS == 0:
				_corner_web(root, centre, sides, cell_size, wall_height)
	return root.get_child_count()


## The opening escape's caves (owner, 2026-11-09): a natural, lost-feeling
## cave below the workings - formations, roots, rubble, a few old bones and
## the odd broken frame where the miners once reached; no lanterns or rails,
## nobody comes this way. Sparse, seeded, and clear of the bodies, the fire,
## the chest and the way out (anything solid or with contents).
## [id, mount, one in how many eligible cells]
const OPENING := [
	["stalactite-single", "ceiling", 6], ["stalactite-cluster", "ceiling", 14], ["hanging-roots", "ceiling", 16],
	["wall-roots", "wall", 9], ["flowstone", "wall", 12],
	["stalagmite-stub", "edge", 10], ["stalagmite-broken", "edge", 16], ["rubble-cluster", "edge", 12],
	["scattered-bones", "edge", 14], ["floor-roots", "edge", 18],
]


static func dress_opening(level: Node3D, map, seed: int, cell_size: float, wall_height: float) -> int:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([seed, "opening dressing"])
	var root := Node3D.new()
	root.name = "Dressing"
	level.add_child(root)
	for y in map.height:
		for x in map.width:
			var cell := Vector2i(x, y)
			if not _clear(map, cell) or map.solid.has(cell) or SIDES.any(func(s): return map.solid.has(cell + s)):
				continue
			var centre := Vector3(x * cell_size, 0.0, y * cell_size)
			var sides := _wall_sides(map, cell)
			var corridor := _corridor_axis(map, cell)
			if corridor != Vector2i.ZERO and rng.randi() % 9 == 0:
				_put(root, "mine-support-damaged", centre, _yaw_across(corridor))  # where the miners gave up
				continue
			for entry in OPENING:
				if rng.randi() % int(entry[2]) != 0:
					continue
				var id: String = entry[0]
				match entry[1]:
					"ceiling":
						_put(root, id, centre + Vector3(rng.randf_range(-0.5, 0.5), wall_height - 0.01, rng.randf_range(-0.5, 0.5)), rng.randf() * TAU)
					"wall":
						if sides.is_empty():
							continue
						var side: Vector2i = sides[rng.randi() % sides.size()]
						var at := centre + Vector3(side.x, 0, side.y) * (cell_size / 2.0 - 0.01)
						at.y = WALL_HEIGHTS.get(id, 1.2)
						_put(root, id, at + _along_wall(side) * rng.randf_range(-0.4, 0.4), _yaw_facing(-side))
					"edge":
						if id == "stalagmite-stub" and corridor != Vector2i.ZERO and rng.randi() % 2 == 0:
							continue  # keep the narrow ways readable
						var toward: Vector2i = sides[rng.randi() % sides.size()] if not sides.is_empty() else Vector2i([-1, 1][rng.randi() % 2], [-1, 1][rng.randi() % 2])
						_put(root, id, centre + Vector3(toward.x, 0, toward.y) * cell_size * 0.36, rng.randf() * TAU)
				break  # one piece a cell at most
			if sides.size() >= 2 and rng.randi() % 5 == 0:
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


## An old mine lantern: mostly long dead, now and then still burning (its
## glow is mood only, no light; #241). Follows the effects setting.
static func _light_lantern(piece: Node3D, rng: RandomNumberGenerator) -> void:
	if piece == null or not str(piece.get_meta("dressing_id", "")).begins_with("lantern") or not "lit" in piece:
		return
	piece.lit = rng.randi() % 3 == 0
	if piece.has_method("set_motion"):
		piece.set_motion(Settings.get_value("flashes"))


static func _put(root: Node3D, id: String, at: Vector3, yaw: float) -> Node3D:
	var node: Node3D = load(MODELS.get(id, DIR + id + ".tscn")).instantiate()
	node.set_meta("dressing_id", id)
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

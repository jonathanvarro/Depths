extends Node3D
## The Damp Caves' dressing (#302 C, live 2026-11-27): wet limestone pieces
## from art/dressing/damp-dressing-v1, all 3D. Mostly bare wet rock and silt:
## flowstone, seeps, moss and pearl niches on the walls; straws, drip
## stalactites and wet roots on the roof; stalagmites, boulders, rimstone and
## drowned debris at the edges; puddles, ripples and gravel on the floor. The
## room holding the way to the Fungal Hollows gets its mushrooms and mold
## (only that room, per the art's contract). Seeded, cosmetic, outside fights
## and anything usable. Drips move only with the effects setting.

const BaseDressing := preload("res://scripts/dressing.gd")
const Settings := preload("res://scripts/settings.gd")
const DIR := "res://art/dressing/damp-dressing-v1/"

## id -> centre height on the wall (metres), kept clear of floor and roof.
const WALL := {"wet-flowstone": 1.15, "mineral-seep": 1.0, "dripping-crack": 1.2, "damp-moss": 0.9,
		"pearl-niche": 0.75, "cracks-rubble": 0.5, "chalk-arrow": 1.35, "chalk-cross": 1.35, "chalk-tally": 1.35}
const ROOF := ["soda-straws", "drip-stalactite-effect", "hanging-wet-roots", "root-curtain-a", "root-curtain-b", "web-strand"]
const EDGE := ["wet-stalagmite", "slick-boulder", "rimstone-edge", "drowned-debris", "root-foot-tangle", "rat-nest", "collapsed-crates", "split-barrel"]
const FLOOR := ["puddle-small", "puddle-wide", "silt-ripples", "wet-gravel", "mud-bootprints", "floor-crack", "tracks-drag", "floor-crossing-root"]
## How common each kind is (out of 10 rolls for a cell that's dressed).
const WALL_ROLLS := 4
const ROOF_ROLLS := 2
const EDGE_ROLLS := 2
## One in this many clear cells is dressed.
const CELL_ODDS := 3
## Old miners' marks and litter are rarer than the rock itself.
const RARE := ["cracks-rubble", "chalk-arrow", "chalk-cross", "chalk-tally", "rat-nest", "collapsed-crates", "split-barrel", "tracks-drag", "web-strand"]


static func clear_cell(map, cell: Vector2i, avoid: Dictionary) -> bool:
	return BaseDressing._clear(map, cell) and not avoid.has(cell) and not map.encounter_zones.has(cell) \
			and not map.water.has(cell) and not map.marks.get("shallow", {}).has(cell)


static func dress(level: Node3D, map, depth: int, seed: int, cell_size: float, wall_height: float, avoid: Dictionary = {}) -> int:
	var root = load("res://scripts/damp_dressing.gd").new()
	root.name = "Dressing"
	level.add_child(root)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([seed, depth, "damp-caves"])
	var exit_room := _exit_room(map)
	for y in map.height:
		for x in map.width:
			var cell := Vector2i(x, y)
			var sides := BaseDressing._wall_sides(map, cell)
			var centre := Vector3(x * cell_size, 0.0, y * cell_size)
			# The Hollows' cue goes in even where a fight starts: it's low
			# growth, and the room must read as the way to the Hollows.
			if exit_room.has(cell):
				if BaseDressing._clear(map, cell) and not avoid.has(cell):
					_dress_exit_cell(root, rng, centre, sides, cell_size, wall_height)
				continue
			if not clear_cell(map, cell, avoid):
				continue
			if rng.randi() % CELL_ODDS != 0 or sides.is_empty():
				continue
			var side: Vector2i = sides[rng.randi() % sides.size()]
			var roll := rng.randi() % 10
			if roll < WALL_ROLLS:
				var id := _pick(rng, WALL.keys())
				var at := centre + Vector3(side.x, 0, side.y) * (cell_size / 2.0 - 0.01)
				at.y = WALL[id]
				at += BaseDressing._along_wall(side) * rng.randf_range(-0.35, 0.35)
				root._place(id, at, BaseDressing._yaw_facing(-side), cell, "wall")
			elif roll < WALL_ROLLS + ROOF_ROLLS:
				var id := _pick(rng, ROOF)
				var at := centre + Vector3(side.x, 0, side.y) * cell_size * 0.3
				at.y = wall_height
				root._place(id, at, BaseDressing._yaw_facing(-side), cell, "ceiling")
			elif roll < WALL_ROLLS + ROOF_ROLLS + EDGE_ROLLS:
				var id := _pick(rng, EDGE)
				var at := centre + Vector3(side.x, 0, side.y) * cell_size * 0.32
				root._place(id, at, BaseDressing._yaw_facing(-side), cell, "edge")
			else:
				var id := _pick(rng, FLOOR)
				var at := centre + Vector3(rng.randf_range(-0.25, 0.25), 0.0, rng.randf_range(-0.25, 0.25))
				root._place(id, at, rng.randi_range(0, 3) * PI / 2.0, cell, "floor")
	root.set_motion(Settings.get_value("flashes"))
	return root.get_child_count()


## Picks an id, giving the rare ones (old marks, litter) a second chance to
## be passed over.
static func _pick(rng: RandomNumberGenerator, ids: Array) -> String:
	var id: String = ids[rng.randi() % ids.size()]
	if id in RARE and rng.randi() % 2 == 0:
		id = ids[rng.randi() % ids.size()]
	return id


## The cells of the room holding the way to the Fungal Hollows (or {}).
static func _exit_room(map) -> Dictionary:
	for cell: Vector2i in map.marks.get("exits", {}):
		if map.marks["exits"][cell] == "hollows":
			var room := {}
			for c in map.room_around(cell):
				room[c] = true
			return room
	return {}


## The Hollows exit room: mushrooms at the edges, mold on walls and floor,
## more of it than anywhere else (the cue that the growth starts here).
static func _dress_exit_cell(root, rng: RandomNumberGenerator, centre: Vector3, sides: Array[Vector2i], cell_size: float, _wall_height: float) -> void:
	if rng.randi() % 2 != 0:
		return
	if not sides.is_empty() and rng.randi() % 2 == 0:
		var side: Vector2i = sides[rng.randi() % sides.size()]
		if rng.randi() % 2 == 0:
			var at := centre + Vector3(side.x, 0, side.y) * (cell_size / 2.0 - 0.01)
			at.y = 0.6
			root._place("exit-wall-mold", at, BaseDressing._yaw_facing(-side), Vector2i.ZERO, "wall")
		else:
			root._place("exit-mushrooms", centre + Vector3(side.x, 0, side.y) * cell_size * 0.32, BaseDressing._yaw_facing(-side), Vector2i.ZERO, "edge")
	else:
		root._place("exit-floor-mold", centre + Vector3(rng.randf_range(-0.3, 0.3), 0, rng.randf_range(-0.3, 0.3)), rng.randf() * TAU, Vector2i.ZERO, "floor")


func _place(id: String, at: Vector3, yaw: float, cell: Vector2i, mount: String) -> Node3D:
	var node: Node3D = load(DIR + id + ".tscn").instantiate()
	node.position = at
	node.rotation.y = yaw
	node.set_meta("dressing_id", id)
	node.set_meta("cell", cell)
	node.set_meta("mount", mount)
	add_child(node)
	if mount == "ceiling":
		for child in node.find_children("*", "GeometryInstance3D", true, false):
			child.add_to_group("ceiling")  # hidden from above (tactical view)
	return node


## Drips move only with the effects setting (exact still when off).
func set_motion(enabled: bool) -> void:
	for node in get_children():
		if node.has_method("set_motion"):
			node.set_motion(enabled)


var _motion := false

func _process(_delta: float) -> void:
	var motion: bool = Settings.get_value("flashes")
	if motion != _motion:
		_motion = motion
		set_motion(motion)

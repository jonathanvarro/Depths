extends RefCounted
## Floor 5, the Drowned Galleries (story slice 2, docs/story-slice-2-plan.md;
## owner approved 2026-10-26). The fortress's old water system: some
## passages run deep with black water. Wading costs time and nerves and
## soaks a torch; a lantern rides above it. Opening the main sluice (The
## Dry Passage) drains the galleries for good. Placeholder art until #166.
## Static helpers only (no static variables: see #100).

const DEPTH := 5
## Floor 6, the Black Reservoir: deeper water still. The flow gate drains it.
const RESERVOIR := 6
## Of the corridor cells, about this share runs deep (floor 5, floor 6).
const FLOODED_SHARE := {5: 0.4, 6: 0.6}
## How far each flooded stretch runs, in cells.
const STRETCH := Vector2i(3, 7)
## A step through deep water: extra time, a little strain, and a torch
## burns this much more (it gutters and steams).
const WADE_TIME := 1
const WADE_STRAIN := 1.5
const WADE_TORCH_SOAK := 2
const WATER_COLOR := Color(0.05, 0.12, 0.16, 0.85)  # the placeholder pool
## ChatGPT's #166 art: deep water, wet slate walls, drowned masonry.
const DEEP_WATER := preload("res://art/textures/drowned-water-v1/deep.tscn")
const WET_WALL := preload("res://art/textures/waterworks-v1/wet-plain.tres")
const WET_WALL_VARIANT := preload("res://art/textures/waterworks-v1/wet-channelled.tres")
const DROWNED_FLOOR := preload("res://art/textures/descent-surfaces-v1/drowned-masonry-floor.tres")
const DROWNED_CEILING := preload("res://art/textures/descent-surfaces-v1/drowned-masonry-ceiling.tres")
## The reservoir's own matched surfaces and finish pieces (#168, ChatGPT;
## docs/descent-completion-art.md).
const RESERVOIR_WALL := preload("res://art/textures/reservoir-v1/reservoir-wall.tres")
const RESERVOIR_FLOOR := preload("res://art/textures/reservoir-v1/reservoir-floor.tres")
const RESERVOIR_CEILING := preload("res://art/textures/reservoir-v1/reservoir-ceiling.tres")
const WATER_EDGE := preload("res://art/props/reservoir-finish-v1/water-edge.tscn")
const RESERVOIR_STAIRS := preload("res://art/props/reservoir-finish-v1/stairs.tscn")
## One in this many wall faces beside deep water shows the black water beyond.
const WATER_EDGE_ODDS := 3
## The galleries' waterworks dressing (#166; docs/waterworks-art.md): wall
## pieces with the centre height each needs, and the dead lamp on dry floor.
const WATERWORKS := {
	"dripping-channel": [preload("res://art/dressing/waterworks-v1/dripping-channel.tscn"), 1.23],
	"broken-pipe": [preload("res://art/dressing/waterworks-v1/broken-pipe.tscn"), 0.9],
}
const SILTED_LAMP := preload("res://art/dressing/waterworks-v1/silted-lamp.tscn")
const WALL_PIECE_ODDS := 7  # one wall-side cell in this many
const LAMP_ODDS := 14  # one dry room cell against a wall in this many


## Floods stretches of the floor's passages (corridor cells, not rooms,
## doors or anything in them). `drained`: the sluice is open - none.
static func flood(map, seed_value: int, drained: bool, depth := DEPTH) -> void:
	map.water = {}
	if drained:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var corridor: Array[Vector2i] = []
	for y in map.height:
		for x in map.width:
			var cell := Vector2i(x, y)
			if _floodable(map, cell):
				corridor.append(cell)
	var target := int(corridor.size() * FLOODED_SHARE.get(depth, 0.4))
	var guard := 0
	while map.water.size() < target and guard < 200:
		guard += 1
		var cell: Vector2i = corridor[rng.randi_range(0, corridor.size() - 1)]
		var length := rng.randi_range(STRETCH.x, STRETCH.y)
		var run: Array[Vector2i] = [cell]
		var i := 0
		while i < run.size() and run.size() < length:
			for offset in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
				var next: Vector2i = run[i] + offset
				if run.size() < length and next not in run and _floodable(map, next):
					run.append(next)
			i += 1
		for c in run:
			map.water[c] = true


static func _floodable(map, cell: Vector2i) -> bool:
	if cell.x < 0 or cell.y < 0 or cell.x >= map.width or cell.y >= map.height:
		return false
	if map.is_wall(cell) or map._is_room_cell(cell) or map.doors.has(cell) or map.content_at(cell) != 0:
		return false
	return cell != map.start_cell


## The galleries' look (#166): wet slate walls, drowned masonry floors and
## ceilings, full-face wall tiles. The reservoir has its own slate set (#168).
static func theme_from(cave: EnvironmentTheme, depth := DEPTH) -> EnvironmentTheme:
	var theme: EnvironmentTheme = cave.duplicate()
	theme.display_name = "The Black Reservoir" if depth >= RESERVOIR else "The Drowned Galleries"
	theme.wall_material = WET_WALL
	theme.wall_variant_material = WET_WALL_VARIANT
	theme.floor_material = DROWNED_FLOOR
	theme.ceiling_material = DROWNED_CEILING
	theme.wall_face_uv = true
	theme.ambience = preload("res://audio/galleries-v1/galleries-loop.wav")
	if depth >= RESERVOIR:
		theme.wall_material = RESERVOIR_WALL
		theme.wall_variant_material = null  # one wall: its waterline must line up
		theme.floor_material = RESERVOIR_FLOOR
		theme.ceiling_material = RESERVOIR_CEILING
	return theme


## The reservoir's finish (#168): while it's flooded, some walls beside the
## deep water open on a worn lip over far black water; once the flow gate
## has diverted it, wet black stairs go down beside the gate - the shaft the
## ending speaks of. Looks only: the stairs lead nowhere yet (no floor 7).
static func dress_reservoir(level: Node3D, map, cell_size: float, seed: int, diverted: bool) -> int:
	const Dressing := preload("res://scripts/dressing.gd")
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([seed, "reservoir finish"])
	var root := Node3D.new()
	root.name = "ReservoirFinish"
	level.add_child(root)
	for cell in map.water:
		var sides: Array[Vector2i] = Dressing._wall_sides(map, cell)
		if sides.is_empty() or rng.randi() % WATER_EDGE_ODDS != 0:
			continue
		_mount(root, WATER_EDGE.instantiate(), cell, sides[rng.randi() % sides.size()], cell_size)
	if diverted:
		for cell in map.events:
			if not map.events[cell].resource_path.ends_with("quest_flow_gate.tres"):
				continue
			var sides: Array[Vector2i] = Dressing._wall_sides(map, cell)
			# The gate takes the first wall (main.gd's room props); the stairs the next.
			if sides.size() >= 2:
				_mount(root, RESERVOIR_STAIRS.instantiate(), cell, sides[1], cell_size)
			else:
				for step in Dressing.SIDES:
					var next: Vector2i = cell + step
					var beside: Array[Vector2i] = Dressing._wall_sides(map, next) if map.is_passable(next) else []
					if not beside.is_empty():
						_mount(root, RESERVOIR_STAIRS.instantiate(), next, beside[0], cell_size)
						break
	return root.get_child_count()


## The galleries' waterworks (#166): dripping channels and broken pipes on
## walls, sparse and never two alike side by side; dead lamps on dry floor
## against a wall, out of the walking line. Looks only: nothing blocks.
static func dress_galleries(level: Node3D, map, cell_size: float, seed: int) -> int:
	const Dressing := preload("res://scripts/dressing.gd")
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([seed, "waterworks"])
	var root := Node3D.new()
	root.name = "Waterworks"
	level.add_child(root)
	var ids: Array = WATERWORKS.keys()
	var last := ""
	for y in map.height:
		for x in map.width:
			var cell := Vector2i(x, y)
			if not Dressing._clear(map, cell):
				continue
			var sides: Array[Vector2i] = Dressing._wall_sides(map, cell)
			if sides.is_empty():
				continue
			var side: Vector2i = sides[rng.randi() % sides.size()]
			if rng.randi() % WALL_PIECE_ODDS == 0:
				var id: String = ids[rng.randi() % ids.size()]
				if id == last:
					id = ids[(ids.find(id) + 1) % ids.size()]  # no two alike in a row
				last = id
				var piece: Node3D = WATERWORKS[id][0].instantiate()
				_mount(root, piece, cell, side, cell_size)
				piece.position.y = WATERWORKS[id][1]
			elif not map.is_water(cell) and map._is_room_cell(cell) and rng.randi() % LAMP_ODDS == 0:
				var lamp: Node3D = SILTED_LAMP.instantiate()
				lamp.position = Vector3(cell.x, 0, cell.y) * cell_size + Vector3(side.x, 0, side.y) * cell_size * 0.32
				lamp.rotation.y = atan2(float(-side.x), float(-side.y))
				root.add_child(lamp)
	return root.get_child_count()


## Stands `node` against the wall on `side` of `cell`, facing into it.
static func _mount(root: Node3D, node: Node3D, cell: Vector2i, side: Vector2i, cell_size: float) -> void:
	node.position = Vector3(cell.x, 0, cell.y) * cell_size + Vector3(side.x, 0, side.y) * (cell_size / 2.0 - 0.025)
	node.rotation.y = atan2(float(-side.x), float(-side.y))
	root.add_child(node)


## ChatGPT's deep water over a flooded cell (#166). `animate` false holds it
## still (screen effects off).
static func water_surface(cell: Vector2i, cell_size: float, animate: bool) -> Node3D:
	var surface = DEEP_WATER.instantiate()
	surface.configure(cell, cell_size, animate)
	return surface


## The plain placeholder pool, kept for reference.
static func water_plane(cell: Vector2i, cell_size: float) -> MeshInstance3D:
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(cell_size, cell_size)
	var material := StandardMaterial3D.new()
	material.albedo_color = WATER_COLOR
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.roughness = 0.08
	material.metallic = 0.3
	mesh.material = material
	var plane := MeshInstance3D.new()
	plane.mesh = mesh
	plane.position = Vector3(cell.x * cell_size, 0.12, cell.y * cell_size)
	plane.name = "Water"
	return plane

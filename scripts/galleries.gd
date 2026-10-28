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
const WATER_COLOR := Color(0.05, 0.12, 0.16, 0.85)


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


## The galleries' look until #166/#168's art: the cave's surfaces, cold and
## wet; the reservoir darker still.
static func theme_from(cave: EnvironmentTheme, depth := DEPTH) -> EnvironmentTheme:
	var theme: EnvironmentTheme = cave.duplicate()
	theme.display_name = "The Black Reservoir" if depth >= RESERVOIR else "The Drowned Galleries"
	var tint := Color(0.55, 0.68, 0.8) if depth >= RESERVOIR else Color(0.7, 0.85, 0.95)
	for slot in ["wall_material", "wall_variant_material", "floor_material", "ceiling_material"]:
		var material = theme.get(slot)
		if material is BaseMaterial3D:
			var wet: BaseMaterial3D = material.duplicate()
			wet.albedo_color = wet.albedo_color * tint
			wet.roughness = minf(wet.roughness, 0.45)
			theme.set(slot, wet)
	return theme


## A placeholder pool surface over a flooded cell.
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

extends RefCounted
## Lights on the walls (owner playtest, 2026-11-23). The bigger floors are
## fun to explore, so the cave gives a little light back:
## - "torch": two spare torches leaning against a wall. Walking into that
##   wall takes one (if the pack has room). Torches as loot.
## - "lantern": a whole miners' lantern (the dressing's are broken) with a
##   little oil still in it; walking into its wall offers to light it. Lit, it
##   burns for a while (BURN time units) and lights its room, or a short
##   stretch of corridor: standing there counts as being in the light, so
##   the map works again and nerves ease very slightly.
## Placed once per floor layout and kept on `map.marks["wall_lights"]`
## (saved with the map): cell -> {"side", "kind", "taken", "lit_until"}.
## Rules only here; main.gd builds the art and asks the questions.

const Dressing := preload("res://scripts/dressing.gd")
const DungeonMap := preload("res://scripts/dungeon_map.gd")

const TORCHES := Vector2i(1, 2)  # spare torches per floor (least, most)
const LANTERNS := Vector2i(2, 3)  # old lanterns per floor
const SPACING := 8  # cells apart, at least (across the grid)
const AWAY_FROM_STAIRS := 4
const BURN := 200  # time units a lit lantern lasts (a step is 1)
const CORRIDOR_REACH := 9  # cells a lantern lights along a corridor
const LIGHTING_RELIEF := -3.0  # strain, once, for each hero when one is lit


## Two fresh torches leaning against the foot of a wall (+Z out of the
## wall, origin on the floor at the wall face), built like the held torch.
static func spare_torch_prop() -> Node3D:
	var root := Node3D.new()
	root.name = "SpareTorches"
	var mats := {}
	for texture in ["wood", "cloth", "leather"]:
		var material := StandardMaterial3D.new()
		material.albedo_texture = load("res://art/props/held-3d-v1/%s.png" % texture)
		material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		material.roughness = 0.9
		mats[texture] = material
	for i in 2:
		var torch := Node3D.new()
		torch.position = Vector3(-0.08 + i * 0.15, 0.0, 0.26 + i * 0.03)
		torch.rotation = Vector3(-0.3, 0.0, (i * 2 - 1) * 0.09)  # leaning back on the rock
		root.add_child(torch)
		# Long enough that the heads show when you face the wall up close.
		_cylinder(torch, 0.018, 0.024, 1.0, mats["wood"], 0.5)
		_cylinder(torch, 0.026, 0.026, 0.12, mats["leather"], 0.2)  # grip binding
		_cylinder(torch, 0.046, 0.038, 0.06, mats["cloth"], 0.98)  # the pitch-soaked head
		_cylinder(torch, 0.054, 0.047, 0.07, mats["cloth"], 1.045)
		_cylinder(torch, 0.038, 0.052, 0.055, mats["cloth"], 1.105)
	return root


static func _cylinder(parent: Node3D, top: float, bottom: float, height: float, material: Material, y: float) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top
	mesh.bottom_radius = bottom
	mesh.height = height
	mesh.radial_segments = 8
	mesh.rings = 1
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.material_override = material
	part.position = Vector3(0, y, 0)
	parent.add_child(part)


## Chooses this floor's wall lights (seeded, so a layout keeps them).
static func place(map, depth: int, seed: int) -> void:
	var lights := {}
	map.marks["wall_lights"] = lights
	if depth < 1:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([seed, depth, "wall_lights"])
	var stairs: Array = [map.find_content(DungeonMap.Content.STAIRS_UP), map.find_content(DungeonMap.Content.STAIRS_DOWN)]
	var spots: Array[Vector2i] = []
	for y in map.height:
		for x in map.width:
			var cell := Vector2i(x, y)
			if _usable(map, cell, stairs):
				spots.append(cell)
	for i in range(spots.size() - 1, 0, -1):  # shuffle with our own generator
		var j := rng.randi_range(0, i)
		var swap := spots[i]
		spots[i] = spots[j]
		spots[j] = swap
	var wanted: Array = []
	for i in rng.randi_range(TORCHES.x, TORCHES.y):
		wanted.append("torch")
	for i in rng.randi_range(LANTERNS.x, LANTERNS.y):
		wanted.append("lantern")
	for cell in spots:
		if wanted.is_empty():
			break
		if lights.keys().any(func(c): return absi(c.x - cell.x) + absi(c.y - cell.y) < SPACING):
			continue
		var sides: Array = Dressing._wall_sides(map, cell)
		lights[cell] = {"side": sides[rng.randi_range(0, sides.size() - 1)], "kind": wanted.pop_front(), "taken": false, "lit_until": -1}


static func _usable(map, cell: Vector2i, stairs: Array) -> bool:
	if not map.is_passable(cell) or map.content_at(cell) != DungeonMap.Content.NONE or map.door_at(cell) != DungeonMap.Door.NONE:
		return false
	if map.events.has(cell) or map.solid.has(cell) or map.water.has(cell) or cell == map.start_cell or Dressing._wall_sides(map, cell).is_empty():
		return false
	for s: Vector2i in stairs:
		if s != Vector2i(-1, -1) and absi(s.x - cell.x) + absi(s.y - cell.y) < AWAY_FROM_STAIRS:
			return false
	for site: Rect2i in map.marks.get("quests", {}).values():
		if site.grow(1).has_point(cell):
			return false
	for p: Dictionary in map.marks.get("puzzles", []):
		for value in p.values():
			if value is Vector2i and absi(value.x - cell.x) + absi(value.y - cell.y) <= 1:
				return false
	return not cell in map.marks.get("hall", []) and not cell in map.marks.get("gates", []) \
			and cell != map.marks.get("refuge", Vector2i(-1, -1))


static func at(map, cell: Vector2i) -> Dictionary:
	return map.marks.get("wall_lights", {}).get(cell, {})


static func is_lit(light: Dictionary, time: int) -> bool:
	return light.get("kind") == "lantern" and time < int(light.get("lit_until", -1))


## Lights the lantern at `cell` until `time` + BURN.
static func light(map, cell: Vector2i, time: int) -> void:
	at(map, cell)["lit_until"] = time + BURN


## The cells a lit lantern lights: its room, or a short stretch of corridor.
static func lit_area(map, cell: Vector2i) -> Array[Vector2i]:
	return map.area_around(cell, CORRIDOR_REACH)


## True if `cell` is lit by any burning lantern on this floor.
static func lights_cell(map, cell: Vector2i, time: int) -> bool:
	var lights: Dictionary = map.marks.get("wall_lights", {})
	for spot in lights:
		if is_lit(lights[spot], time) and (spot == cell or cell in lit_area(map, spot)):
			return true
	return false

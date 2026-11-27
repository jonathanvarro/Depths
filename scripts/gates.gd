extends RefCounted
## Formation gates (#305, owner 2026-11-26): rare places only a full party of
## one class can open. They are seen early and come back to later with the
## right party, so the fire has a long-term purpose and spare heroes are
## worth keeping.
##
## Where each gate sits is still open (owner: "doesn't have to be decided
## right now"). The chasm sits in the Black Reservoir for now, as the
## owner's example of a later-game bridge toward the Buried City, which isn't
## built yet. The temple portal is defined but placed nowhere (`area` "").
## Moving a gate is a change to its `area` here.
##
## A gate is one solid cell in a room, never one the floor needs to be
## walked (the rest of the floor stays reachable). Opened gates stay open
## for good: CampState.gates_open. Seen ones are remembered
## (CampState.gates_seen) so the fire can say which party opens them.
##
## Static helpers only (no static variables: see #100). Art is a stand-in:
## the chasm is a black shaft, and the bridge plain planks, until their own
## models are made.

const Areas := preload("res://scripts/areas.gd")
const DungeonMap := preload("res://scripts/dungeon_map.gd")

const GATES := {
	"bridge": {
		"formation": "pure:Fixer",
		"area": "reservoir",
		"name": "the chasm",
		"party": "a Tunnel Crew (three Sappers)",
		"seen": "A chasm splits the rock ahead, too wide to jump. Far across it, worked stone: steps cut by someone, going down. Three Sappers could bridge it.",
		"shut": "The chasm is too wide to cross. It would take three Sappers working together to bridge it.",
		"ask": "Your Tunnel Crew sizes up the chasm. They can bridge it with what they carry, but it will take a long while (%d). Build the bridge?",
		"opened": "Plank by plank, the bridge goes out over the dark, and holds. The far side is open now, for good.",
		"beyond": "Across the bridge, steps cut into the far wall drop toward something old: the Buried City. Cross?",
		"leads": "city",
		"time": 30,
	},
	"portal": {
		"formation": "pure:Mage",
		"area": "",  # not placed yet (owner, 2026-11-26)
		"name": "the sealed archway",
		"party": "a Vigil (three Acolytes)",
		"seen": "A sealed archway, carved with marks no one here can read. The air near it hums.",
		"shut": "The archway doesn't open to hands or tools. It hums louder when an Acolyte is near.",
		"ask": "The archway's hum rises to meet your Acolytes' prayers. Pray it open? (%d)",
		"opened": "Three voices, one prayer. The seal gives, and the archway stands open.",
		"beyond": "Beyond the archway the cave goes on, and it is wrong. That way isn't open yet.",
		"time": 20,
	},
}

## The gate's notice ("seen") shows when the party comes this close.
const NOTICE_RANGE := 2


static func info(id: String) -> Dictionary:
	return GATES.get(id, {})


## The gates that belong in `area`.
static func for_area(area: String) -> Array[String]:
	var out: Array[String] = []
	for id: String in GATES:
		if GATES[id]["area"] == area and area != "":
			out.append(id)
	return out


## Whether `party` (as it stands now) can open gate `id`.
static func can_open(id: String, party) -> bool:
	return party != null and party.formation().get("id", "") == info(id).get("formation", "?")


## Places `area`'s gates on `map` (after its contents and puzzles, before
## its wall lights): each on a room cell as far as can be from the way up,
## against a wall, with nothing on it, and never one whose loss cuts the
## floor. Records map.marks["formation_gates"] = {cell: id}.
static func place(map, area: String, seed_value: int) -> void:
	var ids := for_area(area)
	if ids.is_empty():
		return
	var gates := {}
	map.marks["formation_gates"] = gates
	var up: Vector2i = map.find_content(DungeonMap.Content.STAIRS_UP)
	var from_up: Dictionary = map.walking_distances(up)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([seed_value, area, "gates"])
	for id in ids:
		var spots: Array = []
		for cell: Vector2i in from_up:
			if _usable(map, cell, up):
				spots.append(cell)
		spots.sort_custom(func(a, b): return from_up[a] > from_up[b])
		for cell: Vector2i in spots.slice(0, 12 + rng.randi_range(0, 4)):
			map.solid[cell] = true
			var after: Dictionary = map.walking_distances(up)
			if after.size() == from_up.size() - 1 - gates.size():
				gates[cell] = id
				break
			map.solid.erase(cell)


static func _usable(map, cell: Vector2i, up: Vector2i) -> bool:
	if not map._is_room_cell(cell) or cell == up or cell == map.start_cell:
		return false
	if map.content_at(cell) != DungeonMap.Content.NONE or map.door_at(cell) != DungeonMap.Door.NONE:
		return false
	if map.events.has(cell) or map.solid.has(cell) or map.water.has(cell) or map.in_story_site(cell, 1):
		return false
	if map.marks.get("formation_gates", {}).has(cell):
		return false
	# Against a wall, so it reads as a crack in the floor running off into rock.
	return [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT].any(func(d): return map.is_wall(cell + d) and map.is_passable(cell - d))


## The area an open gate leads to ("" if none yet).
static func leads(id: String) -> String:
	return info(id).get("leads", "")


## The cell to stand on beside the gate on `map` that leads to `area`
## (coming back up from it), or (-1, -1).
static func landing(map, area: String) -> Vector2i:
	for cell: Vector2i in map.marks.get("formation_gates", {}):
		if leads(map.marks["formation_gates"][cell]) == area:
			return cell + approach(map, cell)
	return Vector2i(-1, -1)


## The gate at `cell` on `map`, or "".
static func at(map, cell: Vector2i) -> String:
	return map.marks.get("formation_gates", {}).get(cell, "") if map else ""


## The fire's line: seen gates this party would open, e.g. "Can open: the
## chasm in the Black Reservoir." ("" if none).
static func fire_line(heroes: Array, seen: Dictionary, opened: Dictionary) -> String:
	var Formations := load("res://scripts/formations.gd")
	var formation: Dictionary = Formations.of(heroes)
	var names: Array = []
	for id: String in GATES:
		if seen.has(id) and not opened.has(id) and formation.get("id", "") == GATES[id]["formation"]:
			names.append("%s in the %s" % [GATES[id]["name"], Areas.area_name(GATES[id]["area"])])
	return "" if names.is_empty() else "Can open: %s." % ", ".join(names)


## The side a gate faces: away from the wall it stands against (the far
## side, where the steps or the arch are). Its bridge runs along this.
static func approach(map, cell: Vector2i) -> Vector2i:
	for d in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		if map.is_wall(cell + d) and map.is_passable(cell - d):
			return -d
	return Vector2i.DOWN


## The stand-in look: a black shaft in the floor, bridged with planks once
## open. The bridge runs from the side the party comes from toward the far
## wall. `cell_size` metres per cell.
static func build_prop(map, cell: Vector2i, open: bool, cell_size: float) -> Node3D:
	var root := Node3D.new()
	root.name = "Gate_%d_%d" % [cell.x, cell.y]
	root.position = Vector3(cell.x * cell_size, 0.0, cell.y * cell_size)  # LevelBuilder._cell_center
	var from := approach(map, cell)
	root.rotation.y = atan2(float(from.x), float(from.y))  # local +Z toward the approach
	var id := at(map, cell)
	if id == "portal":
		var arch := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(cell_size * 0.8, 2.2, 0.3)
		var stone := StandardMaterial3D.new()
		stone.albedo_color = Color("4a4652") if not open else Color("1a1420")
		box.material = stone
		arch.mesh = box
		arch.position = Vector3(0.0, 1.1, -cell_size * 0.35)
		root.add_child(arch)
		return root
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color.BLACK
	dark.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var shaft := MeshInstance3D.new()
	var hole := BoxMesh.new()
	hole.size = Vector3(cell_size * 0.98, 6.0, cell_size * 0.98)
	hole.material = dark
	hole.flip_faces = true  # seen from inside: walls dropping into the dark
	shaft.mesh = hole
	shaft.position.y = -3.0
	shaft.name = "Chasm"
	root.add_child(shaft)
	if open:
		var wood := StandardMaterial3D.new()
		wood.albedo_color = Color("7a5636")
		wood.roughness = 0.9
		var deck := Node3D.new()
		deck.name = "Bridge"
		var boards := 7
		for i in boards:
			var plank := MeshInstance3D.new()
			var board := BoxMesh.new()
			board.size = Vector3(cell_size * 0.62, 0.06, cell_size * 0.12)
			board.material = wood
			plank.mesh = board
			plank.position = Vector3((i % 3 - 1) * 0.02, 0.02, (i - (boards - 1) / 2.0) * cell_size * 0.14)
			plank.rotation.y = (i % 3 - 1) * 0.04
			deck.add_child(plank)
		for side in [-1, 1]:
			for part in [["Beam", 0.0, 0.08], ["Rail", 0.75, 0.04]]:
				var beam := MeshInstance3D.new()
				var line := BoxMesh.new()
				line.size = Vector3(part[2], part[2], cell_size)
				line.material = wood
				beam.mesh = line
				beam.position = Vector3(side * cell_size * 0.33, part[1], 0.0)
				deck.add_child(beam)
			for z in [-1, 1]:
				var post := MeshInstance3D.new()
				var stick := BoxMesh.new()
				stick.size = Vector3(0.06, 0.8, 0.06)
				stick.material = wood
				post.mesh = stick
				post.position = Vector3(side * cell_size * 0.33, 0.4, z * cell_size * 0.46)
				deck.add_child(post)
		root.add_child(deck)
	return root

extends RefCounted
## The cave as a network of areas (owner direction 2026-11-25, #300): a
## floor can have several ways on, each to its own area. Static helpers
## only (no static variables: see #100).
##
## Each area has an id, a name, a `depth` (its difficulty tier: the content
## tables, encounter groups, packages and quests still read depth), the area
## it came from (`parent`, its way up) and the areas its ways down lead to:
## `main` (the floor's own way down, or the one a story package opens) and
## `side` (extra exits added to the layout).
##
## Main-path areas keep the old floor numbers as their key in main.gd's
## `_floors` (1-6), so saves from before the network still load; the rest
## are keyed by id. Art and exact branch lengths are still to come (#300):
## side areas borrow existing looks until theirs are made.

const AREAS := {
	"opening": {"name": "The escape", "depth": 0, "parent": "", "main": "", "side": [], "key": 0},
	"mines": {"name": "Abandoned Mines", "depth": 1, "parent": "", "main": "damp", "side": [], "key": 1, "theme": "cave"},
	"damp": {"name": "Damp Caves", "depth": 2, "parent": "mines", "main": "cavern", "side": ["hollows"], "key": 2, "theme": "damp"},
	"cavern": {"name": "Cavern", "depth": 3, "parent": "damp", "main": "rest", "side": [], "key": 3, "theme": "cavern", "outskirts": true},
	"rest": {"name": "Rest Area", "depth": 3, "parent": "cavern", "main": "fortress", "side": [], "theme": "cavern", "safe": true},
	"fortress": {"name": "Goblin Fortress", "depth": 4, "parent": "rest", "main": "galleries", "side": ["jail"], "key": 4, "theme": "fortress"},
	"jail": {"name": "Jail", "depth": 4, "parent": "fortress", "main": "", "side": ["execution"], "theme": "fortress", "small": true},
	"execution": {"name": "Execution Halls", "depth": 4, "parent": "jail", "main": "", "side": [], "theme": "fortress", "lair": "headsman"},
	"galleries": {"name": "Drowned Galleries", "depth": 5, "parent": "fortress", "main": "reservoir", "side": [], "key": 5, "theme": "galleries"},
	"reservoir": {"name": "Black Reservoir", "depth": 6, "parent": "galleries", "main": "", "side": [], "key": 6, "theme": "galleries"},
	"hollows": {"name": "Fungal Hollows", "depth": 3, "parent": "damp", "main": "", "side": ["grove"], "theme": "fungal", "groups": "hollows"},
	# The Buried City (2026-11-26, #305): over the Sappers' bridge from the
	# Black Reservoir, not down a stair. Its own street layout (city_generator.gd).
	"city": {"name": "Buried City", "depth": 7, "parent": "reservoir", "main": "", "side": [], "theme": "city", "groups": "city", "gate": "bridge"},
	"grove": {"name": "Grove", "depth": 3, "parent": "hollows", "main": "", "side": [], "theme": "fungal", "lair": "heartrot"},
}

## Ways between areas with art of their own (#302): the way down from an
## area to a child, and the way back up into a child from its parent.
const EXIT_ART := {
	"cavern": {"rest":"res://art/props/cavern-rest-v1/on-to-rest.tscn"},
	"rest": {"fortress":"res://art/props/cavern-rest-v1/rest-to-fortress.tscn"},
	"damp": {"cavern": "res://art/features/damp-passages-v1/cavern-onward.tscn",
		"hollows": "res://art/features/damp-passages-v1/hollows-onward.tscn"},
}
const RETURN_ART := {
	"rest": "res://art/props/cavern-rest-v1/rest-return.tscn",
	"cavern": "res://art/features/damp-passages-v1/cavern-return.tscn",
	"hollows": "res://art/features/damp-passages-v1/hollows-return.tscn",
}

## The boss lairs (placeholders until their art and bosses are made): who
## waits there, the warning at the way in, and the boss's own name.
const LAIRS := {
	"headsman": {"boss": "res://data/enemies/headsman.tres", "followers": ["res://data/enemies/goblin_guard.tres", "res://data/enemies/goblin.tres"],
		"warning": "The stair down reeks of old blood. Chains rattle below, and something heavy is dragged across stone. Whatever waits in the Execution Halls has killed everyone sent down. Go in?"},
	"heartrot": {"boss": "res://data/enemies/heartrot.tres", "followers": ["res://data/enemies/spider.tres", "res://data/enemies/spider.tres"],
		"warning": "The way into the grove is thick with spores, and the growth there moves when nothing touches it. Those who went in are still in there, somewhere in the rot. Go in?"},
}


static func info(id: String) -> Dictionary:
	return AREAS.get(id, AREAS["mines"])


static func area_name(id: String) -> String:
	return info(id)["name"]


static func depth(id: String) -> int:
	return int(info(id)["depth"])


## The key for main.gd's `_floors`: the old floor number on the main path,
## the id elsewhere.
static func key(id: String):
	return info(id).get("key", id)


## The main-path area at `depth` (old saves, routes, tests).
static func main_for(at_depth: int) -> String:
	for id: String in AREAS:
		if AREAS[id].get("key", -1) == at_depth:
			return id
	return "mines" if at_depth < 1 else "reservoir"


## Where a scouts' route from camp to `at_depth` arrives: the Rest Area is
## the route's destination past the Cavern (#300).
static func route_area(at_depth: int) -> String:
	return "rest" if at_depth == 3 else main_for(at_depth)


static func on_main_path(id: String) -> bool:
	return info(id).has("key")


## Every way down from `id`: the main one first.
static func children(id: String) -> Array:
	var out: Array = []
	if info(id)["main"] != "":
		out.append(info(id)["main"])
	out.append_array(info(id)["side"])
	return out


## The depth a floor's encounter groups are drawn for.
static func groups_depth(id: String) -> int:
	return int(info(id).get("groups", depth(id)))


static func is_safe(id: String) -> bool:
	return info(id).get("safe", false)


static func is_lair(id: String) -> bool:
	return info(id).has("lair")


## The theme name main.gd maps to a look: cave, damp, fungal, fortress,
## galleries, city.
static func theme(id: String) -> String:
	return info(id).get("theme", "cave")


## A floor's layout with a way down added for each side exit, each in its own
## room as far as can be from the way up and the other ways down. Returns
## {"layout", "exits": {cell: area id}}. The layout's own '>' (if any) is the
## main way down.
static func add_side_exits(layout: PackedStringArray, id: String, rng: RandomNumberGenerator, avoid: Array = []) -> Dictionary:
	var rows := Array(layout)
	var exits := {}
	var anchors: Array[Vector2i] = []
	for y in rows.size():
		for x in rows[y].length():
			if rows[y][x] in ["<", ">", "S"]:
				anchors.append(Vector2i(x, y))
	for side: String in info(id)["side"]:
		var best := Vector2i(-1, -1)
		var best_score := -1
		for y in range(1, rows.size() - 1):
			for x in range(1, rows[y].length() - 1):
				if rows[y][x] != ",":
					continue  # a plain room floor cell
				var cell := Vector2i(x, y)
				if avoid.any(func(a): return absi(a.x - cell.x) + absi(a.y - cell.y) <= 2):
					continue  # clear of the King's hall and its gates
				var score := 999
				for a in anchors:
					score = mini(score, absi(a.x - cell.x) + absi(a.y - cell.y))
				score = score * 10 + rng.randi_range(0, 9)
				if score > best_score:
					best_score = score
					best = cell
		if best == Vector2i(-1, -1):
			continue
		var row: String = rows[best.y]
		rows[best.y] = row.substr(0, best.x) + ">" + row.substr(best.x + 1)
		exits[best] = side
		anchors.append(best)
	return {"layout": PackedStringArray(rows), "exits": exits}


## A boss lair: a short winding approach from the way up to one arena room,
## the boss waiting at its heart. Returns {"layout", "boss": cell}.
static func lair_layout(rng: RandomNumberGenerator) -> Dictionary:
	var width := 19
	var height := 17
	var rows: Array = []
	for y in height:
		rows.append("#".repeat(width))
	var put := func(cell: Vector2i, c: String) -> void:
		var row: String = rows[cell.y]
		rows[cell.y] = row.substr(0, cell.x) + c + row.substr(cell.x + 1)
	# The arena: a 5x5 room in the upper middle.
	var arena := Rect2i(7, 2, 5, 5)
	for y in range(arena.position.y, arena.end.y):
		for x in range(arena.position.x, arena.end.x):
			put.call(Vector2i(x, y), ",")
	var boss := arena.get_center()
	put.call(boss, "E")
	# The approach: from the bottom, a corridor with a jog to one side.
	var start := Vector2i(rng.randi_range(3, width - 4), height - 2)
	var cell := start
	put.call(cell, "<")
	var jog := cell.y - rng.randi_range(4, 7)
	while cell.y > jog:
		cell.y -= 1
		put.call(cell, ".")
	while cell.x != boss.x:
		cell.x += signi(boss.x - cell.x)
		put.call(cell, ".")
	while cell.y > arena.end.y:
		cell.y -= 1
		put.call(cell, ".")
	return {"layout": PackedStringArray(rows), "boss": boss}

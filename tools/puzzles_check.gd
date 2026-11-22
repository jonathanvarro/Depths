extends SceneTree
## Floor puzzles (owner, 2026-11-21; scripts/puzzles.gd): one-way doors, a
## lever and gate, a key and locked door. Part 1 generates hundreds of floors
## and proves every one solvable from either staircase, and that the solver
## catches unsolvable ones. Part 2 plays each puzzle in the game.
## Args: tag, screenshot dir.

const Puzzles := preload("res://scripts/puzzles.gd")
const FloorGenerator := preload("res://scripts/floor_generator.gd")
const SEEDS := 300

var fails := 0
var shots := ""
var main_ref


## A picture of the view, when a screenshot folder is given (a real window).
func _snap(name: String) -> void:
	if shots == "":
		return
	await create_timer(1.2).timeout  # doors finish swinging, gates rising
	var image := root.get_texture().get_image()
	if image:
		image.save_png(shots + "/puzzle_" + name + ".png")


## Stand on `at`, look at `target`, and take a picture.
func _look(main, at: Vector2i, target: Vector2i, name: String) -> void:
	main._party.place(main._map, at)
	main._party.facing = (main._party.facing + 1) % 4
	main._face_toward(target)
	main._party.position = Vector3(at.x * main.CELL_SIZE, 0, at.y * main.CELL_SIZE) - Vector3(target.x - at.x, 0, target.y - at.y) * main.CELL_SIZE * 0.9
	main._party.position.y = 0.0
	main._map.reveal_around(at, 3)
	await _snap(name)


func check(label: String, ok: bool, detail = "") -> void:
	if not ok: fails += 1
	print("PASS " if ok else "FAIL ", label, "  ", detail)


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	shots = args[1] if args.size() > 1 else ""
	# --- Part 1: every generated floor is solvable ---------------------------
	var counts := {"oneway": 0, "key": 0, "lever": 0}
	var nests := 0
	var broken := []
	for depth in range(1, Puzzles.MAX_DEPTH + 1):
		for s in SEEDS:
			var seed_value := 1000 + s * 7919 + depth
			var layout := FloorGenerator.generate(seed_value, true, depth)
			var placed := Puzzles.place(layout, depth, seed_value + 53)
			var result := Puzzles.solve(placed["layout"], placed["puzzles"])
			if not result["ok"]:
				broken.append("depth %d seed %d: %s" % [depth, seed_value, result["why"]])
			for p in placed["puzzles"]:
				counts[p["kind"]] += 1
				if p.get("nest", false):
					nests += 1
				if p["kind"] != "oneway":
					var inside_chest := false
					var rows: PackedStringArray = placed["layout"]
					# the chest is behind the door: unreachable with it shut
					# Every other puzzle open, this one shut: what's left out is behind it.
					var only_this: Array = placed["puzzles"].map(func(q):
						if q == p:
							return q
						var o: Dictionary = q.duplicate()
						o["open"] = true
						return o)
					var shut_reach := Puzzles._reach(rows, only_this, Puzzles.starts(rows)[0], false)
					for y in rows.size():
						for x in rows[y].length():
							if rows[y][x] == "C" and not shut_reach.has(Vector2i(x, y)):
								inside_chest = true
					if not inside_chest:
						broken.append("depth %d seed %d: %s room without a chest behind it" % [depth, seed_value, p["kind"]])
	var total := Puzzles.MAX_DEPTH * SEEDS
	check("all %d generated floors (floors 1-%d) are solvable from both staircases" % [total, Puzzles.MAX_DEPTH], broken.is_empty(), broken.slice(0, 5))
	check("each kind turns up often", counts["oneway"] > total * 0.2 and counts["key"] > total * 0.2 and counts["lever"] > total * 0.2, counts)
	check("nests behind gates from floor %d" % Puzzles.NEST_FROM, nests > 0, nests)
	check("no puzzles below floor %d" % Puzzles.MAX_DEPTH, Puzzles.place(FloorGenerator.generate(5, true, 5), 5, 5)["puzzles"].is_empty())

	# The solver does catch a floor that can't be solved.
	var rows := PackedStringArray([
		"#########",
		"#<..,,,C#",
		"#.#######",
		"#.....>##",
		"#########"])
	var key_behind_door := [{"kind": "key", "door": Vector2i(3, 1), "key": Vector2i(6, 1), "held": false, "open": false}]
	check("the solver spots a key locked behind its own door", not Puzzles.solve(rows, key_behind_door)["ok"])
	var stairs_behind := [{"kind": "lever", "door": Vector2i(4, 3), "lever": Vector2i(5, 1), "open": false}]
	check("...and stairs behind a gate", not Puzzles.solve(rows, stairs_behind)["ok"])
	var loop := PackedStringArray([
		"#######",
		"#<....#",
		"#.###.#",
		"#.###.#",
		"#....>#",
		"#######"])
	check("...but accepts a one-way door on a loop", Puzzles.solve(loop, [{"kind": "oneway", "door": Vector2i(3, 1), "bolt": Vector2i(4, 1), "open": false}])["ok"])

	# --- Part 2: playing them ---------------------------------------------
	await _play()
	print("fails=", fails)
	quit()


## An open floor cell next to `cell` (to stand on and look from).
func _beside(map, cell: Vector2i) -> Vector2i:
	for n in Puzzles.NEIGHBOURS:
		if map.is_passable(cell + n):
			return cell + n
	return cell


## Finds a site seed whose floor 1 (as the game builds it) has all three,
## then works each in the game.
func _play() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	main.play_opening = false
	main.wandering = false
	main.floor_seed = 500
	root.add_child(main)
	await create_timer(0.5).timeout
	var found := -1
	for s in 400:
		main._site_seed = 500 + s
		main._floors.clear()
		main._go_to_floor(1, main.Arrival.FROM_ABOVE)
		if main._map.marks.get("puzzles", []).size() == 3:
			found = main._site_seed
			break
	check("a floor with all three puzzles exists", found != -1)
	if found == -1:
		return
	await create_timer(0.3).timeout
	var map = main._map
	var puzzles: Array = map.marks.get("puzzles", [])
	check("floor 1 is built with its three puzzles", puzzles.size() == 3, puzzles.map(func(p): return p["kind"]))
	var by_kind := {}
	for p in puzzles:
		by_kind[p["kind"]] = p
	for p in puzzles:
		check("%s: its door is shut and solid" % p["kind"], map.solid.has(p["door"]) and main._level.get_node_or_null("Puzzle_%d_%d" % [p["door"].x, p["door"].y]) != null)

	# One-way: barred from the near side, opens from the bolt side.
	var oneway: Dictionary = by_kind["oneway"]
	var door: Vector2i = oneway["door"]
	var near: Vector2i = door * 2 - oneway["bolt"]
	await _look(main, near, door, "oneway_barred_side")
	main._party.place(map, near)
	main._on_party_interacted(door)
	check("one-way: barred from the near side", map.solid.has(door) and not oneway["open"], main._message_label.text if main.get("_message_label") else "")
	await _look(main, oneway["bolt"], door, "oneway_bolt_side")
	main._party.place(map, oneway["bolt"])
	main._on_party_interacted(door)
	check("...and opened from the bolt side, both ways after", not map.solid.has(door) and oneway["open"])
	await _look(main, oneway["bolt"], door, "oneway_opened")

	# Key: locked until the key is found.
	var keyed: Dictionary = by_kind["key"]
	await _look(main, _beside(map, keyed["door"]), keyed["door"], "key_door")
	await _look(main, _beside(map, keyed["key"]), keyed["key"], "key_explorer")
	main._on_party_interacted(keyed["door"])
	check("key: locked without it", map.solid.has(keyed["door"]) and not keyed["open"])
	main._on_party_interacted(keyed["key"])
	check("...the key is found with the dead explorer", keyed["held"])
	main._on_party_interacted(keyed["door"])
	check("...and opens the door", not map.solid.has(keyed["door"]) and keyed["open"])

	# Lever: the gate rises when it's pulled.
	var lever: Dictionary = by_kind["lever"]
	await _look(main, _beside(map, lever["door"]), lever["door"], "lever_gate")
	await _look(main, _beside(map, lever["lever"]), lever["lever"], "lever")
	main._on_party_interacted(lever["door"])
	check("lever: the gate won't move by hand", map.solid.has(lever["door"]) and not lever["open"])
	main._on_party_interacted(lever["lever"])
	check("...pulling the lever raises it", not map.solid.has(lever["door"]) and lever["open"])
	await _look(main, _beside(map, lever["lever"]), lever["lever"], "lever_pulled")
	await _look(main, _beside(map, lever["door"]), lever["door"], "lever_gate_open")

	# Saved and restored, as left.
	var data: Dictionary = main._save_data()
	main._restore(data)
	await create_timer(0.3).timeout
	var again: Array = main._map.marks.get("puzzles", [])
	check("a save keeps what was opened and found", again.size() == 3 and again.all(func(p): return p["open"]) and not main._map.solid.has(lever["door"]))
	main.queue_free()

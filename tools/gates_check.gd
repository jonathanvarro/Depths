extends SceneTree
## Formation gates (#305, owner 2026-11-26): seen early, opened only by a
## full party of one class, open for good. The chasm sits in the Black
## Reservoir for now; the portal is defined but not placed. Args: tag,
## screenshot dir.

const Gates := preload("res://scripts/gates.gd")
const Recruits := preload("res://scripts/recruits.gd")

var fails := 0
var rng := RandomNumberGenerator.new()


func check(label: String, ok: bool, detail = "") -> void:
	if not ok: fails += 1
	print("PASS " if ok else "FAIL ", label, "  ", detail)


func hero(role: String) -> Companion:
	return Recruits.make(rng, [], [], 1, role)


## Sets the party's classes in place (emptying the party would read as a wipe).
func set_party(ps, roles: Array) -> void:
	while ps.members.size() < roles.size():
		ps.add_member(hero("Melee"))
	for i in roles.size():
		ps.members[i].role = roles[i]
	ps.set_out_formation()


func _snap(path: String) -> void:
	for i in 4:
		await process_frame
	var image := root.get_texture().get_image()
	if image:
		image.save_png(path)


func _initialize() -> void:
	rng.seed = 3052
	check("the chasm sits in the Black Reservoir for now", Gates.for_area("reservoir") == ["bridge"])
	check("the portal is defined but placed nowhere yet", Gates.GATES.has("portal") and not Gates.GATES.keys().any(func(id): return id == "portal" and Gates.for_area(Gates.info(id)["area"]).has("portal")))

	var main = load("res://scenes/main.tscn").instantiate()
	main.play_opening = false
	main.wandering = false
	main.floor_seed = 3052
	root.add_child(main)
	await create_timer(0.5).timeout
	var ps = main._party_state
	var args := OS.get_cmdline_user_args()

	# Every seed: the chasm fits, and never cuts the floor.
	var placed := 0
	var cut := 0
	for s in 12:
		main._site_seed = 9000 + s * 17
		main._floors.clear()
		main._go_to_area("reservoir", main.Arrival.FROM_ABOVE)
		var gates: Dictionary = main._map.marks.get("formation_gates", {})
		if gates.size() == 1:
			placed += 1
		var up: Vector2i = main._map.find_content(main.DungeonMap.Content.STAIRS_UP)
		var reach: Dictionary = main._map.walking_distances(up)
		for y in main._map.height:
			for x in main._map.width:
				var c := Vector2i(x, y)
				if main._map.is_passable(c) and not reach.has(c) and main._map.door_at(c) != main.DungeonMap.Door.BLOCKED:
					cut += 1
	check("the chasm is placed on every Reservoir floor", placed == 12, placed)
	check("...and never cuts any of the floor off", cut == 0, cut)
	main._go_to_area("damp", main.Arrival.FROM_ABOVE)
	check("other areas have none", main._map.marks.get("formation_gates", {}).is_empty())

	main._go_to_area("reservoir", main.Arrival.FROM_ABOVE)
	var cell: Vector2i = main._map.marks["formation_gates"].keys()[0]
	check("the chasm blocks the way and has its own ground", main._map.solid.has(cell) and main._level.get_node_or_null("Gate_%d_%d" % [cell.x, cell.y]) != null)

	# Seen early: a party that can't open it is told who could.
	set_party(ps, ["Melee", "Scout", "Fixer"])
	var near: Vector2i = cell + Gates.approach(main._map, cell)
	main._party.place(main._map, near)
	main._notice_gate(near)
	check("coming close, it's noticed and remembered", main._camp_state.gates_seen.has("bridge") and main._message_label.text.contains("Three Sappers"), main._message_label.text)
	main._on_party_interacted(cell)
	check("...and it won't open without a Tunnel Crew", not main._camp_state.gates_open.has("bridge") and main._message_label.text.contains("three Sappers"), main._message_label.text)
	set_party(ps, ["Fixer", "Fixer", "Scout"])
	main._on_party_interacted(cell)
	check("...nor for a Work Gang (two Sappers)", not main._camp_state.gates_open.has("bridge") and not main._prompt.visible)

	# The fire names it for the party that can open it.
	var crew := [hero("Fixer"), hero("Fixer"), hero("Fixer")]
	check("the fire names the gate for a Tunnel Crew", Gates.fire_line(crew, main._camp_state.gates_seen, main._camp_state.gates_open).contains("the chasm in the Black Reservoir"))
	check("...not for others", Gates.fire_line([hero("Melee"), hero("Melee"), hero("Melee")], main._camp_state.gates_seen, main._camp_state.gates_open) == "")

	# A Tunnel Crew builds the bridge.
	set_party(ps, ["Fixer", "Fixer", "Fixer"])
	main._on_party_interacted(cell)
	check("a Tunnel Crew is asked to build a bridge", main._prompt.visible and main._prompt_label.text.contains("bridge"), main._prompt_label.text)
	if args.size() > 1:
		main._party.facing = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT].find(cell - near)
		main._party.rotation.y = -main._party.facing * PI / 2.0
		await _snap(args[1] + "/gate_chasm.png")
	var t: int = ps.time_elapsed
	main._answer_prompt(true)
	await process_frame
	check("...building it takes a long while and opens it for good", main._camp_state.gates_open.has("bridge") and ps.time_elapsed == t + Gates.info("bridge")["time"])
	check("...the planks are laid", main._level.get_children().any(func(n): return n.name == "Gate_%d_%d" % [cell.x, cell.y] and n.get_node_or_null("Bridge") != null))
	check("...and the tent keeps the record", main._camp_state.records().any(func(r): return r[0] == "Formation gates opened" and r[1] == 1))
	if args.size() > 1:
		await _snap(args[1] + "/gate_bridge.png")
	main._on_party_interacted(cell)
	check("across it: the Buried City, offered", main._prompt.visible and main._prompt_label.text.contains("Buried City"), main._prompt_label.text)
	main._answer_prompt(false)
	check("the fire no longer names an opened gate", Gates.fire_line(crew, main._camp_state.gates_seen, main._camp_state.gates_open) == "")

	# A new day's floor keeps it built.
	main._floors.clear()
	main._go_to_area("reservoir", main.Arrival.FROM_ABOVE)
	var again: Vector2i = main._map.marks["formation_gates"].keys()[0]
	check("a new floor's chasm is already bridged", main._level.get_node_or_null("Gate_%d_%d" % [again.x, again.y]).get_node_or_null("Bridge") != null)
	print("fails=", fails)
	quit()

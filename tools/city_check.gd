extends SceneTree
## The Buried City (owner asked to start it, 2026-11-26): over the Sappers'
## bridge from the Black Reservoir, a grid of streets and houses, its own
## fights and challenge family, and the way back lands beside the bridge.
## Args: tag, screenshot dir.

const CityGenerator := preload("res://scripts/city_generator.gd")
const DungeonMap := preload("res://scripts/dungeon_map.gd")
const Recruits := preload("res://scripts/recruits.gd")
const Gates := preload("res://scripts/gates.gd")

var fails := 0
var rng := RandomNumberGenerator.new()


func check(label: String, ok: bool, detail = "") -> void:
	if not ok: fails += 1
	print("PASS " if ok else "FAIL ", label, "  ", detail)


func _snap(path: String) -> void:
	for i in 4:
		await process_frame
	var image := root.get_texture().get_image()
	if image:
		image.save_png(path)


func _initialize() -> void:
	rng.seed = 7
	# The layout, over many seeds.
	var joined := 0
	var housed := 0
	var choked_ok := 0
	for s in 40:
		var layout := CityGenerator.generate(1000 + s * 31)
		var map = DungeonMap.new(layout, 7)
		var up: Vector2i = map.find_content(DungeonMap.Content.STAIRS_UP)
		var reach: Dictionary = map.walking_distances(up)
		var open := 0
		var rooms := 0
		for y in map.height:
			for x in map.width:
				var c := Vector2i(x, y)
				if map.is_passable(c):
					open += 1
				if layout[y][x] == ",":
					rooms += 1
		# Shut doors open by walking into them: count them as passable here.
		var with_doors := 0
		var seen := {up: true}
		var queue: Array = [up]
		while not queue.is_empty():
			var c: Vector2i = queue.pop_back()
			with_doors += 1
			for n in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
				var next: Vector2i = c + n
				if not seen.has(next) and not map.is_wall(next) and map.door_at(next) != DungeonMap.Door.BLOCKED:
					seen[next] = true
					queue.append(next)
		if with_doors == open:
			joined += 1
		if rooms > 120:
			housed += 1
		choked_ok += 1 if layout.size() == CityGenerator.HEIGHT else 0
	check("every city joins up without clearing fallen stone", joined == 40, joined)
	check("...with houses on its blocks", housed == 40, housed)
	check("...and only a stair up (no way further down yet)", not "".join(CityGenerator.generate(5)).contains(">"))

	var main = load("res://scenes/main.tscn").instantiate()
	main.play_opening = false
	main.wandering = false
	main.floor_seed = 77
	root.add_child(main)
	await create_timer(0.5).timeout
	var ps = main._party_state
	while ps.members.size() < 3:
		ps.add_member(Recruits.make(rng, [], [], 1, "Fixer"))
	for m in ps.members:
		m.role = "Fixer"
	ps.set_out_formation()
	var args := OS.get_cmdline_user_args()

	# Over the bridge.
	main._go_to_area("reservoir", main.Arrival.FROM_ABOVE)
	var gate: Vector2i = main._map.marks["formation_gates"].keys()[0]
	main._camp_state.gates_open["bridge"] = true
	main._party.place(main._map, gate + Gates.approach(main._map, gate))
	main._on_party_interacted(gate)
	check("the bridge offers the Buried City", main._prompt.visible and main._prompt_label.text.contains("Buried City"))
	main._answer_prompt(true)
	await process_frame
	check("crossing arrives in the Buried City", main._area == "city" and main._depth == 7, main._area)
	check("...in its threshold plaza, by the stair up", main._party.cell == main._map.find_content(DungeonMap.Content.STAIRS_UP))
	check("...on worked stone", main.environment_theme == main.STONE_THEME)
	check("...and the card says it's Scout ground", main._message_label.text.contains("Buried City") and main._message_label.text.contains("Scout"), main._message_label.text)
	check("its fights are its own", main.encounter_pool(main._groups_depth(), 3).all(func(g): return g.all(func(t): return t in [main.CHOIR, main.UNFOLDING, main.HOLLOW, main.SHEPHERD, main.UNDERHOUND])))
	check("things wander its streets", main._wanderers.roams(7))
	check("its houses hold finds and fights", main._map.events.size() > 0, main._map.events.size())
	if args.size() > 1:
		# Look up the street from the plaza.
		for f in 4:
			if main._map.is_passable(main._party.cell + main._party.DIRECTIONS[f] * 2):
				main._party.facing = f
		main._party.facing = 0
		main._party.rotation.y = 0.0
		await _snap(args[1] + "/city_plaza.png")
		main._set_full_map(true)
		for c in main._map.walking_distances(main._party.cell):
			main._map.explored[c] = true
		main._full_map_view.queue_redraw()
		await _snap(args[1] + "/city_map.png")
		main._set_full_map(false)

	# Back up: beside the bridge.
	main._go_to_area("reservoir", main.Arrival.FROM_BELOW, "city")
	check("climbing back lands beside the bridge", main._party.cell == gate + Gates.approach(main._map, gate), [main._party.cell, gate])
	check("the city is remembered at the fire", main._camp_state.areas_seen.has("city"))
	print("fails=", fails)
	quit()

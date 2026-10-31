extends SceneTree
## Fights on the map, phase 1 (#171, owner 2026-10-30/31): room monsters
## stand in their rooms; they notice the party by sight or when it walks in;
## noticed, they close a cell each beat (a step or a Wait; turning is free);
## beside the party the fight begins; walking up to one that hasn't seen
## you strikes first; wanderers appear out of sight and hunt; beaten groups
## are gone, ones you ran from go home. Args: tag, screenshot dir.

const Roamers := preload("res://scripts/roamers.gd")
const DungeonMap := preload("res://scripts/dungeon_map.gd")

var fails := 0


func check(label: String, ok: bool, detail = "") -> void:
	if not ok: fails += 1
	print("PASS " if ok else "FAIL ", label, "  ", detail)


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var tag: String = args[0] if args.size() > 0 else "desk"
	var dir: String = args[1] if args.size() > 1 else ""

	# The rules on a small map.
	var map = DungeonMap.new(PackedStringArray([
		"#########",
		"#<......#",
		"#.#####.#",
		"#.......#",
		"#########"]), 2)
	check("sight runs along an open line", Roamers.sees(map, Vector2i(1, 1), Vector2i(5, 1), 5))
	check("...not round corners", not Roamers.sees(map, Vector2i(1, 1), Vector2i(3, 3), 9))
	check("...and only as far as the light", not Roamers.sees(map, Vector2i(1, 1), Vector2i(7, 1), Roamers.SIGHT[0]))
	var g := Roamers.Group.new()
	g.cell = Vector2i(7, 3)
	g.noticed = true
	check("a hunter closes one cell", Roamers.step_toward(map, g, Vector2i(1, 1), {}) and g.cell in [Vector2i(6, 3), Vector2i(7, 2)], g.cell)
	g.cell = Vector2i(2, 1)
	check("...and stops beside the party", not Roamers.step_toward(map, g, Vector2i(1, 1), {}))

	# In the game.
	var main = load("res://scenes/main.tscn").instantiate()
	main.play_opening = false
	main.floor_seed = 11
	main.wandering = false
	root.add_child(main)
	await create_timer(0.5).timeout
	main._go_to_floor(2, main.Arrival.FROM_ABOVE)
	await process_frame
	var groups: Array = main._groups
	check("a floor's room fights stand on the map", not groups.is_empty() and groups.all(func(gr): return gr.cell == gr.home and is_instance_valid(gr.node)), groups.size())
	if dir != "":
		var first = groups[0]
		for side in [Vector2i.DOWN, Vector2i.UP, Vector2i.LEFT, Vector2i.RIGHT]:
			var at: Vector2i = first.cell + side * 2
			if main._map.is_passable(at) and Roamers.sees(main._map, at, first.cell, 3):
				main._party.place(main._map, at)
				main._party.facing = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT].find(-side)
				main._party.rotation.y = -main._party.facing * PI / 2.0
				break
		for i in 8:
			await process_frame
		var image := root.get_texture().get_image()
		if image:
			image.save_png("%s/map_fights_%s.png" % [dir, tag])

	# Ran from, beaten.
	var group = groups[0]
	var home: Vector2i = group.home
	group.cell = home + Vector2i(0, 0)
	main._engaged = group
	group.noticed = true
	main._map_fight_over(false)
	check("a group you ran from goes home, unaware", group.cell == home and not group.noticed and main._groups.has(group))
	main._engaged = group
	main._map_fight_over(true)
	check("a beaten group is gone", not main._groups.has(group))

	# Wanderers.
	main._spawn_wanderer()
	var wanderer = main._groups[-1]
	var walk: Dictionary = main._map.walking_distances(main._party.cell)
	check("a wanderer appears a few steps off, already hunting", wanderer.is_wanderer() and wanderer.noticed and walk.get(wanderer.cell, 99) >= Roamers.SPAWN_DISTANCE.x, walk.get(wanderer.cell, 99))

	# Hunting: each Wait brings it a step closer, then the fight.
	for gr in main._groups.duplicate():
		if gr != wanderer:
			main._groups.erase(gr)
			gr.node.queue_free()
	var time_before: int = main._party_state.time_elapsed
	var before: int = walk.get(wanderer.cell, 99)
	main._wait()
	walk = main._map.walking_distances(main._party.cell)
	check("Wait lets a beat pass", main._party_state.time_elapsed > time_before)
	check("...and the hunter closes in", walk.get(wanderer.cell, 99) == before - 1, "%d -> %d" % [before, walk.get(wanderer.cell, 99)])
	var beats := 0
	while not main._in_combat and beats < 20:
		main._wait()
		beats += 1
	check("beside the party, the fight begins", main._in_combat and main._fight_kind == "wander", beats)
	print("fails=", fails)
	quit()

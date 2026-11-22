extends SceneTree
## #266: live exploration fixture; optional screenshots use the private desktop.
const Settings := preload("res://scripts/settings.gd")
var fails := 0
var output := ""

func check(label: String, ok: bool) -> void:
	print("PASS " if ok else "FAIL ", label)
	if not ok: fails += 1

func snap(label: String) -> void:
	if output.is_empty(): return
	for i in 4: await process_frame
	root.get_texture().get_image().save_png(output.path_join(label + ".png"))

func place(main) -> bool:
	var map = main._map
	for y in map.height:
		for x in map.width:
			var cell := Vector2i(x, y)
			if not map.is_passable(cell) or map.door_at(cell) != main.DungeonMap.Door.NONE: continue
			for facing in 4:
				var next: Vector2i = cell + main._party.DIRECTIONS[facing]
				if not map.is_passable(next) or map.door_at(next) != main.DungeonMap.Door.NONE: continue
				if map.content_at(next) != main.DungeonMap.Content.NONE or map.encounter_zones.has(next): continue
				main._party.place(map, cell)
				main._party.facing = facing
				main._party.rotation.y = main._party._facing_to_yaw(facing)
				return true
	return false

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	output = args[0] if not args.is_empty() else ""
	if not output.is_empty(): DirAccess.make_dir_recursive_absolute(output)
	Settings.set_value("tactical_view", false)
	Settings.set_value("flashes", true)
	var main = load("res://scenes/main.tscn").instantiate()
	main.play_opening = false
	main.floor_seed = 11
	main.wandering = false
	root.add_child(main)
	await create_timer(.6).timeout
	main._go_to_floor(1, main.Arrival.FROM_ABOVE)
	main._party.locked = false
	main._party.paused = false
	main._party_state.supplies.source = main.Supplies.Source.LANTERN
	main._party_state.supplies.oil = 100.0
	main._apply_view()
	var life = main._ambience.mine_life
	life.set_process(false)
	life._process(0.0)
	check("empty neighbouring passage found", place(main))
	await create_timer(.3).timeout
	check("mine atmosphere allowed in lit exploration", life.allowed())
	var game_rng: int = main._rng.state
	var camp_rng: int = main._camp_state.rng.state
	var elapsed: float = main._party_state.time_elapsed
	var oil: float = main._party_state.supplies.oil
	for kind in ["bat", "mouse", "dust"]:
		check(kind + " spawns", life.show_effect(kind))
		if not is_instance_valid(life._effect): continue
		check("only one effect at a time", not life.show_effect("dust"))
		check("no physics or light nodes", life._effect.find_children("*", "CollisionObject3D", true, false).is_empty() and life._effect.find_children("*", "Light3D", true, false).is_empty())
		life._elapsed = .7 if kind != "dust" else 1.1
		life.animate()
		if kind != "dust":
			var before: Transform3D = life._actor.transform
			life._process(.08)
			check(kind + " travels with its sampled rig", not before.is_equal_approx(life._actor.transform) and life._actor.player.current_animation_position > 0.0)
		else:
			check("bounded dust shower", life._dust.multimesh.instance_count == 28 and life._dust.multimesh.get_instance_transform(0).origin.y < main.WALL_HEIGHT)
		await snap("mine_" + kind)
		life._process(5.0)
		check(kind + " cleans itself up", life._effect == null)
	check("cosmetics preserve game RNG and expedition resources", game_rng == main._rng.state and camp_rng == main._camp_state.rng.state and elapsed == main._party_state.time_elapsed and is_equal_approx(oil, main._party_state.supplies.oil))
	life._until_next = 0.0
	life._process(.01)
	check("timer starts an occasional effect", is_instance_valid(life._effect) and life._until_next >= 12.0 and life._until_next <= 25.0)
	life.clear()
	var forward: Vector2i = main._party.cell + main._party.DIRECTIONS[main._party.facing]
	main._map.solid[forward] = true
	check("blocked cell cannot host wildlife", life.target_cells().is_empty())
	main._map.solid.erase(forward)
	main._map.doors[forward] = main.DungeonMap.Door.CLOSED
	check("closed passage cannot host wildlife", life.target_cells().is_empty())
	main._map.doors.erase(forward)
	life.show_effect("bat")
	Settings.set_value("flashes", false)
	life._process(.01)
	check("reduced motion clears and prevents effects", life._effect == null and not life.show_effect("dust"))
	Settings.set_value("flashes", true)
	main._party.paused = true
	check("menus and prompts suppress effects", not life.show_effect("mouse"))
	main._party.paused = false
	main._in_combat = true
	check("combat suppresses effects", not life.show_effect("bat"))
	main._in_combat = false
	main._party_state.supplies.oil = 0.0
	check("darkness suppresses effects", not life.show_effect("dust"))
	main._party_state.supplies.oil = 100.0
	main._depth = 3
	check("deeper floors retain their own ambience", not life.show_effect("bat"))
	main._depth = 1
	Settings.set_value("tactical_view", true)
	main._apply_view()
	await create_timer(.6).timeout
	check("overhead shares the lit cells", not life.target_cells().is_empty())
	for cell in life.target_cells():
		check("overhead target is revealed", main._tactical.seen.has(cell))
	if life.show_effect("mouse"):
		life._elapsed = .65
		life.animate()
		await snap("mine_overhead")
	main._go_to_floor(2, main.Arrival.FROM_ABOVE)
	life._process(0.0)
	check("floor change removes previous effects", life._effect == null and life._map == main._map)
	print("mine_life_check fails=", fails)
	main.queue_free()
	# Let the audio mixer release the floor/music streams in headless runs.
	await create_timer(.2).timeout
	quit(1 if fails else 0)

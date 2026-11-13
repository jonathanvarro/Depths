extends SceneTree
## The scouts' refuge (owner choice 2026-11-01): a rest stop on floor 3,
## near the stairs down to the fortress. Making camp heals everyone, eases
## strain and leaves oil and a torch - once a trip, levels kept.
## Args: tag, screenshot dir.

const Refuge := preload("res://scripts/refuge.gd")
const DungeonMap := preload("res://scripts/dungeon_map.gd")
const FloorGenerator := preload("res://scripts/floor_generator.gd")
const Progression := preload("res://scripts/progression.gd")

var fails := 0


func check(label: String, ok: bool, detail = "") -> void:
	if not ok: fails += 1
	print("PASS " if ok else "FAIL ", label, "  ", detail)


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var dir: String = args[1] if args.size() > 1 else ""

	# Placement, on many floor-3 layouts.
	var placed_all := true
	var near := true
	var far := 0
	for seed in 40:
		var layout := FloorGenerator.generate(1000 + seed * 17, true, Refuge.DEPTH)
		var placed: Dictionary = Refuge.place(layout, Refuge.DEPTH)
		var cell: Vector2i = placed["cell"]
		if cell == Vector2i(-1, -1):
			placed_all = false
			continue
		var map = DungeonMap.new(placed["layout"], Refuge.DEPTH)
		var down: Vector2i = map.find_content(DungeonMap.Content.STAIRS_DOWN)
		far = maxi(far, map.walking_distances(down).get(cell, 99))
		if map.content_at(cell) != DungeonMap.Content.REST_SPOT or map.walking_distances(down).get(cell, 99) > 20:
			near = false
	check("every floor 3 gets a refuge", placed_all)
	check("...a rest spot near the stairs down (within 20 steps)", near, "farthest %d steps" % far)
	var rooms = load("res://scripts/room_events.gd").new()
	var never := true
	for i in 300:
		if rooms.pick(DungeonMap.Content.REST_SPOT, 3) == Refuge.EVENT:
			never = false
	check("ordinary rest spots never roll the refuge", never)

	# In the game.
	var main = load("res://scenes/main.tscn").instantiate()
	main.play_opening = false
	root.add_child(main)
	await create_timer(0.5).timeout
	main._go_to_floor(Refuge.DEPTH, main.Arrival.FROM_ABOVE)
	await create_timer(0.3).timeout
	var map = main._map
	var cell: Vector2i = map.marks.get("refuge", Vector2i(-1, -1))
	check("floor 3 in the game has the refuge", cell != Vector2i(-1, -1) and map.events.get(cell) == Refuge.EVENT)
	main._go_to_floor(2, main.Arrival.FROM_BELOW)
	await create_timer(0.2).timeout
	check("...and floor 2 doesn't", not main._map.marks.has("refuge"))
	main._go_to_floor(Refuge.DEPTH, main.Arrival.FROM_ABOVE)
	await create_timer(0.2).timeout
	check("...the same refuge on the way back down", main._map.marks.get("refuge") == cell)

	var ps = main._party_state
	var hero: Companion = ps.members[0]
	hero.xp = Progression.THRESHOLDS[3]
	Progression.advance(hero)
	Progression.advance(hero, "stat_vit")
	hero.health = 3
	hero.change_strain(60.0 - hero.strain)
	var torches: int = ps.supplies.count(load("res://data/items/torch.tres"))
	var result: Dictionary = rooms.resolve(ps, Refuge.EVENT.choices[0])
	check("making camp heals to full and eases strain", hero.health == hero.effective_max_health() and hero.strain <= 30.0, "%d/%d, strain %.0f" % [hero.health, hero.effective_max_health(), hero.strain])
	check("...leaves a torch", ps.supplies.count(load("res://data/items/torch.tres")) == torches + 1, result["text"])
	check("...and keeps the expedition's levels", hero.level == 3)

	main._party.place(map, cell)
	main._run_event(cell)
	check("the refuge opens the layered Overlook", main._overlook.visible and main._party.locked)
	if dir != "":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(dir.path_join("overlook.png"))
	main._overlook.target_activated.emit("stash")
	check("the Overlook opens the persistent camp stash", main._overlook_stash.visible and main._overlook_stash._camp == main._camp_state)
	main._overlook_stash.closed.emit()
	main._overlook.target_activated.emit("fire")
	check("the fire opens the original rest choice", main._event_screen.visible and not main._overlook.visible)
	await main._event_screen._choose(Refuge.EVENT.choices[0])
	main._event_screen._finish({"left": false, "ambush": []})
	await process_frame
	check("after resting the Overlook reopens with a cold fire", main._overlook.visible and not main._overlook.fire_burning)
	main._overlook.target_activated.emit("onward")
	check("the hold path returns to exploration on the same floor", not main._overlook.visible and not main._party.locked and main._depth == 3)

	var camp = main._camp_state
	camp.begin_arrivals()
	check("the trainer is absent before the first Floor 3 return", not camp.site_present("trainer"))
	camp.record_depth(3, false)
	check("a wipe alone does not bring the trainer", not camp.site_present("trainer"))
	camp.record_depth(3)
	ps.supplies.gold = 100
	check("the trainer takes gold and teaches an existing skill", camp.teach(ps, hero, "bulwark") and "bulwark" in hero.talents and ps.supplies.gold == 88)
	check("a duplicate or early advanced lesson takes no gold", not camp.teach(ps, hero, "bulwark") and not camp.teach(ps, hero, "iron_hide") and ps.supplies.gold == 88)
	camp.bounty_paid = true
	check("the King bounty opens the advanced lesson", camp.teach(ps, hero, "iron_hide") and ps.supplies.gold == 64)

	main._floors.erase(2)
	main._go_to_floor(2, main.Arrival.FROM_ABOVE)
	var pickup: RoomEvent = load("res://data/events/quest_treatment_supplies.tres")
	check("the Floor 2 return objective uses the 3D pickup", main._map.events.values().has(pickup) and pickup.prop.resource_path.contains("treatment-supplies-v1"))
	var supplies: SupplyItem = camp.TREATMENT_SUPPLIES
	check("the medicine is named and illustrated in the pack", supplies.display_name == "Medicinal supplies" and supplies.icon != null)
	var count_before: int = ps.supplies.count(supplies)
	rooms.resolve(ps, pickup.choices[0])
	check("taking the medicine adds it to the pack", count_before == 0 and ps.supplies.count(supplies) == 1)
	check("a recovered bundle opens the nurse once", camp.receive_treatment_supplies(ps) and camp.site_present("treatment") and ps.supplies.count(supplies) == 0 and not camp.receive_treatment_supplies(ps))

	if dir != "":
		main._camp.open(camp, ps)
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(dir.path_join("trainer-shelter.png"))
		main._camp.open_activity("trainer")
		await RenderingServer.frame_post_draw
		check("the trainer panel shows the portrait at phone size", main._camp._portrait.visible and main._camp._portrait.texture != null)
		root.get_texture().get_image().save_png(dir.path_join("trainer.png"))
		main._camp.hide()
		for side in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			if map.is_passable(cell + side * 2):
				main._party.place(map, cell + side * 2)
				main._party.facing = main._party.DIRECTIONS.find(-side)
				main._party.rotation.y = main._party._facing_to_yaw(main._party.facing)
				break
		await create_timer(0.4).timeout
		root.get_viewport().get_texture().get_image().save_png(dir.path_join("refuge.png"))
	print("fails=", fails)
	quit()

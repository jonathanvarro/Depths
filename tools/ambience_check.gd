extends SceneTree
## The mine's mood (#129): darkness creeps in as the light fails or nerves
## fray and draws back when they recover; eyes show only far down the way
## ahead and leave when you move; all of it stands aside in a fight.
## Args: tag, screenshot dir.

var fails := 0
var dir := ""
var tag := "desk"


func check(label: String, ok: bool, detail = "") -> void:
	if not ok: fails += 1
	print("PASS " if ok else "FAIL ", label, "  ", detail)


func _snap(name: String) -> void:
	if dir == "":
		return
	for i in 4:
		await process_frame
	root.get_texture().get_image().save_png(dir + "/ambience_" + tag + "_" + name + ".png")


## Stands the party where it can see at least `cells` straight ahead.
func _face_long_way(main, cells: int) -> bool:
	var map = main._map
	for y in map.height:
		for x in map.width:
			var cell := Vector2i(x, y)
			if not map.is_passable(cell) or map.content_at(cell) != main.DungeonMap.Content.NONE or map.encounter_zones.has(cell):
				continue
			for f in 4:
				var step: Vector2i = main._party.DIRECTIONS[f]
				var ok := true
				for i in range(1, cells + 1):
					var next := cell + step * i
					if not map.is_passable(next) or map.door_at(next) != main.DungeonMap.Door.NONE:
						ok = false
						break
				if ok:
					main._party.place(map, cell)
					main._party.facing = f
					main._party.rotation.y = main._party._facing_to_yaw(f)
					return true
	return false


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	tag = args[0] if args.size() > 0 else "desk"
	dir = args[1] if args.size() > 1 else ""
	var main = load("res://scenes/main.tscn").instantiate()
	main.play_opening = false
	main.floor_seed = 11
	root.add_child(main)
	await create_timer(0.5).timeout
	main._go_to_floor(2, main.Arrival.FROM_ABOVE)
	var ambience = main._ambience
	var supplies = main._party_state.supplies
	var lead: Companion = main._party_state.members[0]
	lead.strain = 0.0  # steady nerves to begin with
	await create_timer(1.2).timeout
	check("a full lantern: no darkness at the edges", ambience.strength() < 0.01)
	check("fog lies over the floor", ambience._fog.visible)
	await _snap("bright")
	supplies.oil = 0.0
	await create_timer(2.4).timeout
	check("the lantern out: darkness closes in", ambience.strength() > 0.95, ambience.strength())
	check("...under the HUD", ambience.overlay.get_index() == 0 and ambience.overlay.visible)
	await _snap("dark")
	supplies.oil = supplies.LANTERN_CAPACITY
	await create_timer(2.4).timeout
	check("light again: the darkness draws back", ambience.strength() < 0.01, ambience.strength())
	lead.strain = 60.0
	await create_timer(1.4).timeout
	check("shaken nerves: some darkness, not all", ambience.strength() > 0.4 and ambience.strength() < 0.6, ambience.strength())
	lead.strain = 0.0
	# Eyes, far down the way ahead.
	check("a long way ahead to stand in", _face_long_way(main, 4))
	supplies.oil = 20.0  # dim
	var eyes = ambience.show_sighting("eyes-cluster")
	check("eyes open at the far end of the passage", eyes != null and Vector2(eyes.position.x, eyes.position.z).distance_to(Vector2(main._party.position.x, main._party.position.z)) >= 3 * main.CELL_SIZE, eyes.position if eyes else null)
	await create_timer(0.6).timeout
	await _snap("eyes")
	main._party._turn(1)
	await create_timer(0.4).timeout
	check("turning away, they're gone", ambience.sighting == null and not is_instance_valid(eyes))
	main._party._turn(-1)
	var shadow = ambience.show_sighting("shadow")
	await create_timer(0.7).timeout
	await _snap("shadow")
	check("a shadow passes too", shadow != null)
	# In a fight, it all stands aside.
	supplies.oil = 0.0
	main._start_combat(main._party.cell, [load("res://data/enemies/rat.tres")] as Array[EnemyType])
	await create_timer(2.4).timeout
	check("in a fight: no darkness, fog or sightings", ambience.strength() < 0.01 and not ambience._fog.visible and ambience.sighting == null, ambience.strength())
	print("fails=", fails)
	quit()

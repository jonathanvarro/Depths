extends SceneTree
## Tactical view prototype (owner, 2026-11-08): a fight on the map lifts
## the camera above the room, shows the party, the foes, the tiles they
## threaten and who can be struck, then drops back into first person.
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
	var shot := root.get_texture().get_image()
	if shot:
		shot.save_png("%s/tactical_%s_%s.png" % [dir, tag, name])


## Starts a fight with the first room group, the party two tiles off.
func _fight(main) -> bool:
	if main._groups.is_empty():
		return false
	var group = main._groups[0]
	for side in [Vector2i.DOWN, Vector2i.UP, Vector2i.LEFT, Vector2i.RIGHT]:
		var at: Vector2i = group.cell + side * 2
		if main._map.is_passable(at) and main._map.is_passable(group.cell + side):
			main._party.place(main._map, at)
			main._party.facing = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT].find(-side)
			main._party.rotation.y = -main._party.facing * PI / 2.0
			break
	main._engaged = group
	group.noticed = true
	main._start_combat(group.cell, group.types)
	return true


func _ceilings_hidden(main) -> bool:
	var ceilings: Array = main._level.get_tree().get_nodes_in_group("ceiling")
	return not ceilings.is_empty() and ceilings.all(func(c): return not c.visible)


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	tag = args[0] if args.size() > 0 else "desk"
	dir = args[1] if args.size() > 1 else ""
	var Settings = load("res://scripts/settings.gd")
	Settings.set_value("tactical_view", true)
	var main = load("res://scenes/main.tscn").instantiate()
	main.play_opening = false
	main.floor_seed = 11
	main.simulate_phone_safe_area = tag == "phone"
	root.add_child(main)
	await create_timer(0.5).timeout
	await _snap("explore")
	check("a fight on the map begins", await _fight(main) and main._in_combat and main._combat._state.field)
	await create_timer(1.2).timeout
	var tactical = main._tactical
	var cam: Camera3D = root.get_viewport().get_camera_3d()
	check("the camera lifts above the room", tactical.active and cam == tactical._camera and cam.global_position.y > 6.0, cam.global_position)
	check("...looking down on the party", cam.global_transform.basis.z.y > 0.8, cam.global_transform.basis.z)
	check("ceilings are out of the way", _ceilings_hidden(main))
	check("the party has a token, facing its way", is_instance_valid(tactical._party_token))
	check("tiles show what the foes threaten", not tactical._marks.is_empty(), tactical._marks.size())
	await _snap("board")

	# The fight ends: back into the party's eyes.
	for foe in main._combat._state.foes:
		foe.health = 0
	main._combat._state._check_end()
	var g := 0
	while main._in_combat and g < 100:
		if main._combat._actions.visible:
			main._combat._action_chosen.emit({"kind": "defend"})
		await create_timer(0.1).timeout
		g += 1
	await create_timer(1.2).timeout
	cam = root.get_viewport().get_camera_3d()
	check("when it ends, the view drops back into first person", not tactical.active and cam == main._party.camera and not _ceilings_hidden(main))
	check("...and the board's marks are gone", tactical._marks.is_empty())
	await _snap("after")

	# Switched off: fights stay in first person.
	Settings.set_value("tactical_view", false)
	main._spawn_room_groups()
	if await _fight(main):
		await create_timer(0.5).timeout
		check("switched off in Settings, a fight stays in first person", not tactical.active and root.get_viewport().get_camera_3d() == main._party.camera)
	Settings.set_value("tactical_view", true)
	print("fails=", fails)
	quit()

extends SceneTree
## #169 interface audit: screenshots of every screen, for the before-and-after
## board. Not part of the check suite (no pass/fail). Run it on the hidden
## desktop (tools/testing/background_godot.py) with a --resolution, e.g.
##   -- --resolution 844x390 --script res://tools/ui_audit_capture.gd -- phone Larger OUTDIR
## Args: tag (desk|phone), text size (Normal|Larger), output folder.

const Settings := preload("res://scripts/settings.gd")

var tag := "desk"
var size_name := "Normal"
var dir := ""


func _initialize() -> void:
	call_deferred("run")


func _snap(name: String) -> void:
	for i in 6:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("%s/%s_%s_%s.png" % [dir, name, tag, size_name.to_lower()])
	print("saved ", name)


func _hide(node) -> void:
	if node and node.visible:
		node.visible = false


func run() -> void:
	var args := OS.get_cmdline_user_args()
	tag = args[0] if args.size() > 0 else "desk"
	size_name = args[1] if args.size() > 1 else "Normal"
	dir = args[2] if args.size() > 2 else OS.get_user_data_dir()
	DirAccess.make_dir_recursive_absolute(dir)
	Settings.set_value("text_size", size_name)

	# Title.
	var title = load("res://scenes/title.tscn").instantiate()
	root.add_child(title)
	await create_timer(0.5).timeout
	await _snap("01_title")
	title.queue_free()
	await process_frame

	var main = load("res://scenes/main.tscn").instantiate()
	main.play_opening = false
	main.floor_seed = 23
	main.simulate_phone_safe_area = tag == "phone"
	root.add_child(main)
	await create_timer(0.8).timeout
	_hide(main._hint_box)
	main._say("start") if main.has_method("_say") else null
	await create_timer(0.3).timeout
	await _snap("02_hud")

	# Pack and its Status side.
	main._set_pack(true)
	await create_timer(0.3).timeout
	await _snap("03_pack")
	main._pack.set_status(true)
	await create_timer(0.2).timeout
	await _snap("04_pack_status")
	main._set_pack(false)

	# Quest log and Settings (shared field menu).
	main._quest_log.open(main._camp_state)
	await create_timer(0.3).timeout
	await _snap("05_quest_log")
	main._quest_log.cancel()
	main._settings.open()
	await create_timer(0.3).timeout
	await _snap("06_settings")
	main._settings.cancel()
	await process_frame

	# Full map.
	main._open_full_map() if main.has_method("_open_full_map") else null
	if main.has_method("_open_full_map"):
		await create_timer(0.3).timeout
		await _snap("07_map")
		main._close_full_map() if main.has_method("_close_full_map") else null

	# An event.
	var event: RoomEvent = load("res://data/events/chest_strongbox.tres")
	var rules = main._room_events
	main._event_screen.show_event(event, main._party_state, rules, [])
	await create_timer(0.4).timeout
	await _snap("08_event")
	main._event_screen.visible = false
	main._party.locked = false

	# Combat on the dark stage.
	var types: Array[EnemyType] = [load("res://data/enemies/rat.tres"), load("res://data/enemies/spider.tres")]
	main._start_combat(main._party.cell, types)
	var w := 0
	while not main._combat._actions.visible and w < 80:
		await create_timer(0.1).timeout
		w += 1
	await _snap("09_combat")
	for foe in main._combat._state.foes:
		foe.health = 0
	main._combat._state._check_end()
	main._combat._action_chosen.emit({"kind": "defend"})
	await create_timer(1.0).timeout

	# Coin flip.
	if main.get("_coin"):
		main._coin.flip("A killing blow", "Heads", "Tails", 0.5, "") if main._coin.has_method("flip") else null
		await create_timer(0.3).timeout
		await _snap("10_coin")
		_hide(main._coin)

	# Conversation.
	main._conversation.play(main.COMMANDER_FIRST, main._party_state.members[0], main._camp_state, main._party_state.members)
	await create_timer(0.6).timeout
	await _snap("11_conversation")
	main._conversation.visible = false

	# Results, then camp and its places.
	main._end_expedition(main.Expedition.Ending.RETURNED)
	await create_timer(0.6).timeout
	await _snap("12_results")
	main._results.continue_pressed.emit()
	await create_timer(0.8).timeout
	_hide(main._conversation)
	await _snap("13_camp")
	for id in ["fire", "rest", "supplies", "smith", "treatment"]:
		if id == "stash":
			main._camp.open_activity("rest")
			await create_timer(0.3).timeout
			main._camp._stash_view.show()
		else:
			main._camp_state.set_site_present(id, true)
			main._camp.open_activity(id)
		await create_timer(0.6).timeout
		_hide(main._conversation)
		await _snap("14_camp_" + id)
		main._camp._close_activity()
		main._camp._stash_view.hide()
		await create_timer(0.3).timeout

	# Preparation.
	main._preparation.show_for(2, main._party_state)
	await create_timer(0.4).timeout
	await _snap("15_preparation")
	print("done")
	quit()

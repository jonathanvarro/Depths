extends SceneTree
## Preparation that sticks (#114): once the goblin stash's charm is down
## (caught or clattering), digging can't rattle it; once prodding the
## abandoned pack finds nothing, no rat bursts out. Kept per room, through
## leaving, coming back and saving.

const SaveGame := preload("res://scripts/save_game.gd")

var fails := 0


func check(label: String, ok: bool, detail = "") -> void:
	if not ok: fails += 1
	print("PASS " if ok else "FAIL ", label, "  ", detail)


func _party():
	var p = load("res://scripts/party_state.gd").new()
	var hero := Companion.new()
	hero.max_health = 40
	hero.health = 40
	p.add_member(hero)
	return p


## How many of `runs` real choices end in an ambush, after `prepare`.
func _ambushes(rules, event: RoomEvent, prepare: int, outcome: int, runs := 300) -> int:
	var real: EventChoice = event.choices.filter(func(c): return not c.investigation)[0]
	var careful: EventChoice = event.choices.filter(func(c): return c.investigation)[0]
	var count := 0
	for i in runs:
		var flags: Array = []
		if prepare:
			rules.resolve(_party(), careful, outcome, flags)
		if not rules.resolve(_party(), real, -1, flags)["ambush"].is_empty():
			count += 1
	return count


func _initialize() -> void:
	var rules = load("res://scripts/room_events.gd").new()
	var stash: RoomEvent = load("res://data/events/chest_goblin_stash.tres")
	var pack: RoomEvent = load("res://data/events/chest_abandoned_pack.tres")
	var raw := _ambushes(rules, stash, false, -1)
	check("digging without care can rattle the charm", raw > 30, "%d/300" % raw)
	check("after catching the charm, digging never rattles it", _ambushes(rules, stash, true, 0) == 0)
	check("after it clatters down (failed catch), it can't rattle again", _ambushes(rules, stash, true, 1) == 0)
	check("searching the pack blind can let a rat out (1 in 8)", _ambushes(rules, pack, false, -1) > 10)
	check("once prodding finds nothing, no rat bursts out", _ambushes(rules, pack, true, 1) == 0)
	var real: EventChoice = stash.choices[0]
	var flags: Array = []
	var gold := 0
	for i in 200:
		var r: Dictionary = rules.resolve(_party(), real, -1, ["charm_down"])
		gold += 1 if r["story"].contains("coins") or r["story"].contains("valuables") else 0
	check("the stash's rewards still come", gold > 150, "%d/200" % gold)

	# The room remembers through a save and Continue.
	SaveGame.set_path("user://test_save.dat")
	SaveGame.delete()
	SaveGame.set_continue_requested(false)
	var main = load("res://scenes/main.tscn").instantiate()
	main.play_opening = false
	main.floor_seed = 41
	root.add_child(main)
	await create_timer(0.5).timeout
	var cell := Vector2i(3, 4)
	main._map.event_flags[cell] = ["charm_down"]
	main._save_now()
	main.queue_free()
	await process_frame
	await process_frame
	SaveGame.set_continue_requested(true)
	main = load("res://scenes/main.tscn").instantiate()
	main.play_opening = false
	main.floor_seed = 41
	root.add_child(main)
	await create_timer(0.5).timeout
	check("a room's preparation survives saving", main._map.event_flags.get(cell, []) == ["charm_down"], str(main._map.event_flags))
	SaveGame.delete()
	print("fails=", fails)
	quit()

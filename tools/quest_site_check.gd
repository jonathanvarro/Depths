extends SceneTree
## A floor kept from earlier in the day is built again when a quest that
## belongs on it was taken since (owner playtest, 2026-11-22: floor 1 had no
## survey party's site, and its way down stays shut until the report).

const Quests := preload("res://scripts/quests.gd")

var fails := 0


func check(label: String, ok: bool, detail = "") -> void:
	if not ok: fails += 1
	print("PASS " if ok else "FAIL ", label, "  ", detail)


func _initialize() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	main.play_opening = false
	main.floor_seed = 1111110662
	root.add_child(main)
	await create_timer(0.5).timeout
	main._camp_state.quests.erase("left_behind")
	main._floors.clear()
	main._go_to_floor(1, main.Arrival.FROM_ABOVE)
	check("before the commander's order, floor 1 has no survey site", not "left_behind" in main._map.packages)
	var before = main._map
	Quests.set_stage(main._camp_state, "left_behind", Quests.Stage.ACTIVE)
	main._go_to_floor(1, main.Arrival.FROM_ABOVE)
	check("taken later the same day: going back down, the site is there", "left_behind" in main._map.packages and main._map != before)
	var kept = main._map
	main._go_to_floor(1, main.Arrival.FROM_ABOVE)
	check("...and a floor that has it is kept as it is", main._map == kept)
	print("fails=", fails)
	quit()

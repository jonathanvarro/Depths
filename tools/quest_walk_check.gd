extends SceneTree
## The first quest, walked for real (owner playtest, 2026-11-09): stepping
## onto the fallen party wakes the rats guarding them; once they're beaten,
## the search opens where you stand, and gathering their maps finds the
## evidence. Before the fix the fight swallowed the step, and the bodies
## never opened. Args: tag, screenshot dir.
const Quests := preload("res://scripts/quests.gd")
var fails := 0


func check(label: String, ok: bool, detail = "") -> void:
	if not ok: fails += 1
	print("PASS " if ok else "FAIL ", label, "  ", detail)


func _initialize() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	main.play_opening = false
	main.floor_seed = 11
	root.add_child(main)
	await create_timer(0.4).timeout
	Quests.set_stage(main._camp_state, "left_behind", Quests.Stage.ACTIVE)
	main._floors.clear()
	main._go_to_floor(1, main.Arrival.FROM_ABOVE)
	await process_frame
	var map = main._map
	var fallen := Vector2i(-1, -1)
	for c in map.events:
		if map.events[c].title == "Where they fell":
			fallen = c
	var near := Vector2i(-1, -1)
	var side := Vector2i.ZERO
	for sd in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		if map.is_passable(fallen + sd) and not map.fight_groups.has(fallen + sd):
			near = fallen + sd; side = -sd; break
	main._clear_groups()
	main._party.place(map, near)
	main._party.facing = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT].find(side)
	main._party.rotation.y = -main._party.facing * PI / 2.0
	await process_frame
	main._party._try_step(side)
	await create_timer(0.8).timeout
	check("stepping onto the bodies wakes their guards", main._in_combat)
	for foe in main._combat._state.foes:
		foe.health = 0
	main._combat._state._check_end()
	var g := 0
	while main._in_combat and g < 100:
		if main._combat.awaiting_field_action:
			main._combat._action_chosen.emit({"kind": "wait"})
		elif main._combat._actions.visible:
			main._combat._action_chosen.emit({"kind": "defend"})
		await create_timer(0.1).timeout
		g += 1
	await create_timer(1.5).timeout
	check("once they're beaten, the search opens where you stand", main._party.cell == fallen and main._event_screen.visible and main._event_screen._title.text == "Where they fell", main._party.cell)
	main._event_screen._choose(main._event_screen._event.choices[1])
	await process_frame
	check("...and gathering their maps finds the evidence", Quests.has_flag(main._camp_state, "left_behind", "found"))
	print("fails=", fails)
	quit()

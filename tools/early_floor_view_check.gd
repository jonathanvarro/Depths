extends SceneTree
## Floors 1-3 are explored and fought through the party's eyes (owner
## playtest, 2026-11-21); the view from above opens on floor 4.
## Args: tag, screenshot dir.

const Settings := preload("res://scripts/settings.gd")

var fails := 0


func check(label: String, ok: bool, detail = "") -> void:
	if not ok: fails += 1
	print("PASS " if ok else "FAIL ", label, "  ", detail)


func _initialize() -> void:
	check("the view from above is off by default (owner, 2026-11-21)", Settings.DEFAULTS["view_above"] == false)
	Settings.set_value("view_above", true)
	var main = load("res://scenes/main.tscn").instantiate()
	main.play_opening = false
	main.floor_seed = 11
	main.wandering = false
	root.add_child(main)
	await create_timer(0.5).timeout
	for depth in [1, 2, 3]:
		main._go_to_floor(depth, main.Arrival.FROM_ABOVE)
		await create_timer(0.2).timeout
		check("floor %d: first person, with the setting on" % depth, not main._tactical.active and not main._view_button.visible)
	main._toggle_view()
	check("V does nothing on floor 3", Settings.get_value("view_above") and not main._tactical.active)
	main._go_to_floor(4, main.Arrival.FROM_ABOVE)
	await create_timer(0.2).timeout
	check("floor 4: the view from above, and the View button", main._tactical.active and main._view_button.visible)
	main._toggle_view()
	check("...which V can drop into first person", not main._tactical.active and not Settings.get_value("view_above"))
	Settings.set_value("view_above", false)  # back to the default
	print("fails=", fails)
	quit()

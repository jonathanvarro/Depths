extends SceneTree
## Actual screens, ending changes and arrivals on desktop/landscape phone.
const OUT := "res://art/concepts/results-v1/"
const RESULTS := preload("res://scripts/results_screen.gd")
const SPOILS := preload("res://scripts/spoils_screen.gd")
const PARTY := preload("res://scripts/party_state.gd")
const EXPEDITION := preload("res://scripts/expedition.gd")
var failures: Array[String] = []
var checks := 0

func _initialize() -> void:
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		push_error(label)

func settle() -> void:
	for i in 5: await process_frame

func snap(id: String) -> void:
	await settle()
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(OUT + id + ".png") == OK, "Captured " + id)

func run() -> void:
	var party = PARTY.new()
	for id in ["mara", "corin", "alwen"]:
		party.add_member(load("res://data/companions/" + id + ".tres"))
	var expedition = EXPEDITION.new(party, 3)
	expedition.gold_found = 17
	expedition.visit_floor(3)
	expedition.events_resolved = 4
	expedition.add_defeated("Goblin")
	for hero: Companion in party.members:
		hero.xp = 100
		hero.health -= 2
	var gold: int = party.supplies.gold
	var results = RESULTS.new()
	root.add_child(results)
	var spoils = SPOILS.new()
	root.add_child(spoils)
	for phone in [false, true]:
		root.size = Vector2i(1278, 590) if phone else Vector2i(1280, 720)
		var tag := "phone" if phone else "desktop"
		if phone:
			results.content.add_theme_constant_override("margin_left", 97)
			results.content.add_theme_constant_override("margin_right", 97)
			results.content.add_theme_constant_override("margin_bottom", 35)
		else:
			for side in ["left", "right", "bottom"]: results.content.add_theme_constant_override("margin_" + side, 32)
		for ending in [EXPEDITION.Ending.RETURNED, EXPEDITION.Ending.WIPED, EXPEDITION.Ending.RETURNED]:
			results.show_results(ending, expedition, party, "The expedition is over.")
			await settle()
			check(results._backdrop.texture == (results.WIPE_BACKDROP if ending == EXPEDITION.Ending.WIPED else results.BACKDROP), "Ending-specific backdrop resets " + tag)
			check(results._button.get_global_rect().end.y <= root.size.y, "Continue remains visible " + tag)
			check(results._heroes.get_child_count() == 3, "All three hero rows remain " + tag)
			for texture in [results.ICONS.xp, results.ICONS.advance, results.ICONS.enemies, results.ICONS.events, results.ICONS.deepest]:
				check(texture.get_size() == Vector2(32,32), "Imported result glyph " + tag)
			await snap(("wipe" if ending == EXPEDITION.Ending.WIPED else "return") + "-" + tag)
		results.show_brief("A short story card", "The existing brief remains available.", "Continue")
		check(not results._backdrop.visible, "Brief does not inherit art " + tag)
		results.visible = false
		var heroes: Array = []
		for hero: Companion in party.members: heroes.append({"hero":hero,"from":0,"to":100})
		var payload := {"gold":17,"heroes":heroes,"contract":"Goblins defeated: 1/5"}
		for blow in ["slash", "smash", "pierce", "fire", "fade"]:
			spoils._build(payload)
			spoils.visible = true
			await settle()
			spoils._panel.reset_size()
			var home: Vector2 = (Vector2(root.size) - spoils._panel.size) / 2 - Vector2(0,40)
			await spoils._arrive(blow, home)
			spoils._count_up(payload)
			await create_timer(.85).timeout
			check(spoils._gold_label.text == "+17", "Gold count unchanged " + blow + tag)
			check(spoils._bars.size() == 3, "All XP rows " + blow + tag)
			check(spoils._bars.all(func(row): return row[3].visible and row[3].texture == SPOILS.LEVEL_MARK), "Earned advancement marks light " + blow + tag)
			check(spoils._panel.get_global_rect().position.x >= 0 and spoils._panel.get_global_rect().end.x <= root.size.x, "Spoils fits " + blow + tag)
			check(spoils._fx.get_child_count() == 0, "One-shot effect cleans itself " + blow + tag)
			await snap("spoils-" + blow + "-" + tag)
			spoils.visible = false
	check(party.supplies.gold == gold, "Presentation never grants gold twice")
	results.queue_free()
	spoils.queue_free()
	await process_frame
	# Exercise a real victory too, with an isolated project-local save and no
	# delete operation. Rewards must pass through the art screen exactly once.
	var save = load("res://scripts/save_game.gd")
	save.set_path("res://build/art130-review-save.dat")
	save.set_continue_requested(false)
	var main = load("res://scenes/main.tscn").instantiate()
	main.play_opening = false
	main.floor_seed = 11
	root.add_child(main)
	await create_timer(.6).timeout
	var lead: Companion = main._party_state.members[0]
	var xp_before: int = lead.xp
	var gold_before: int = main._party_state.supplies.gold
	var types: Array[EnemyType] = [load("res://data/enemies/goblin.tres")]
	main._start_combat(main._party.cell, types)
	var guard := 0
	while not main._combat._actions.visible and guard < 50:
		await create_timer(.1).timeout
		guard += 1
	check(main._combat._actions.visible, "Live combat reached hero action")
	main._combat._state.foes[0].health = 1
	lead.aim_base = 2.0
	lead.refresh_stats()
	main._combat._action_chosen.emit({"kind":"attack"})
	guard = 0
	while not main._spoils.visible and guard < 80:
		await create_timer(.05).timeout
		guard += 1
	check(main._spoils.visible, "Victory reaches the new spoils art")
	await create_timer(1).timeout
	var gain: int = main._party_state.supplies.gold - gold_before
	check(gain > 0 and lead.xp > xp_before, "Real victory awards gold and experience")
	check(main._spoils._gold_label.text == "+%d" % gain, "Displayed reward matches actual gain")
	await snap("live-victory-phone")
	main._spoils._skip = true
	guard = 0
	while main._in_combat and guard < 80:
		await create_timer(.05).timeout
		guard += 1
	check(not main._in_combat and not main._spoils.visible, "Victory presentation returns to exploration")
	check(main._party_state.supplies.gold == gold_before + gain, "No duplicate reward after dismissal")
	main.queue_free()
	await process_frame
	var file := FileAccess.open(OUT + "godot-validation.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures},"\t") + "\n")
	file.close()
	print("RESULTS_ART checks=%d failures=%d" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)

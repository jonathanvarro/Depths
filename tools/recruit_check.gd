extends SceneTree
## Recruitment at the fire (#41), heroes staying with the nurse, a full wipe
## that continues at camp, and torches as the light (lantern is an upgrade).
## Args: tag ("desk" or "phone"), screenshot dir.

var fails := 0
var tag := "desk"
var S := ""
var main


func check(label: String, ok: bool, detail = "") -> void:
	if not ok: fails += 1
	print("PASS " if ok else "FAIL ", label, "  ", detail)


func _snap(name: String) -> void:
	for i in 4:
		await process_frame
	root.get_texture().get_image().save_png(S + "/recruit_" + tag + "_" + name + ".png")


func _press(node, label: String) -> bool:
	for b in node.find_children("*", "Button", true, false):
		if b.text.begins_with(label) and b.is_visible_in_tree() and not b.disabled:
			b.pressed.emit()
			return true
	return false


func _open(id: String) -> void:
	main._camp._close_activity()
	main._camp._buttons[id].pressed.emit()
	await process_frame


func _to_camp(ending: int) -> void:
	main._end_expedition(ending)
	await process_frame
	main._results.continue_pressed.emit()
	await create_timer(0.3).timeout


func _head_down() -> void:
	await _open("cave")
	_press(main._camp, "Head back down")
	await create_timer(0.2).timeout
	_press(main._preparation, "Enter the cave")
	await create_timer(0.3).timeout


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	tag = args[0]
	S = args[1]
	main = load("res://scenes/main.tscn").instantiate()
	main.play_opening = false
	main.floor_seed = 23
	main.simulate_phone_safe_area = tag == "phone"
	root.add_child(main)
	await create_timer(0.5).timeout
	var ps = main._party_state
	var mara: Companion = ps.members[0]
	check("Mara is the founder", mara.founder)
	await _to_camp(main.Expedition.Ending.RETURNED)

	# The fire: three recruits with a role, strength and weakness.
	var camp = main._camp_state
	check("three recruits by the fire", camp.candidates.size() == 3)
	check("each has a role, strength and weakness", camp.candidates.all(func(c): return c.role in ["Warden", "Scout", "Brawler"] and c.strength != "" and c.weakness != "" and c.portrait != null))
	check("names differ", camp.candidates.map(func(c): return c.display_name).size() == 3 and camp.candidates[0].display_name != camp.candidates[1].display_name)
	await _open("fire")
	await _snap("fire")
	var first: Companion = camp.candidates[0]
	check("invite the first", _press(main._camp, "Invite") and ps.members.size() == 2 and ps.members[1].display_name == first.display_name)
	check("they leave the fire", first not in camp.candidates)
	_press(main._camp, "Invite")
	check("a third joins; the party is full", ps.members.size() == 3 and not _press(main._camp, "Invite"))
	await _snap("full")
	check("Mara can't be dismissed", not camp.dismiss(ps, mara))
	check("dismiss sends one away", _press(main._camp, "Dismiss") and ps.members.size() == 2)

	# A day passes: one leaves the fire, one arrives.
	var waiting: Array = camp.candidates.duplicate()
	camp.rest(ps)
	check("a new day: someone new by the fire", camp.candidates.size() == 3 and camp.candidates.any(func(c): return c not in waiting))

	# Mara is treated; the recruit goes down alone and she rejoins later.
	mara.add_injury(load("res://data/injuries/deep_wound.tres"))
	camp.treat(mara)
	var recruit: Companion = ps.members[1]
	await _head_down()
	check("Mara stays with the nurse", ps.members.size() == 1 and ps.members[0] == recruit and mara in camp.left_behind)
	await _to_camp(main.Expedition.Ending.RETURNED)
	check("she rejoins at camp", mara in ps.members and camp.left_behind.is_empty())

	# Combat roles: a defending Warden takes a quarter; a Brawler an extra point.
	var CS = load("res://scripts/combat_state.gd")
	var warden := Companion.new(); warden.guard_factor = 0.25
	var brawler := Companion.new(); brawler.toughness = -1
	var goblin: EnemyType = load("res://data/enemies/goblin.tres")
	var acc := goblin.accuracy
	goblin.accuracy = 1.0
	for pair in [[warden, true], [brawler, false]]:
		var p = load("res://scripts/party_state.gd").new()
		p.add_member(pair[0])
		var hero: Companion = p.members[0]
		hero.health = 20
		var c = CS.new(p, [goblin] as Array[EnemyType])
		if pair[1]: c.hero_defend(hero)
		c.foes[0].intent = CS.Intent.SWING
		var out: Dictionary = c.enemy_act(c.foes[0])
		var rolled: int = out["damage"]
		print("  %s took %d" % ["warden (defending)" if pair[1] else "brawler", rolled])
		if pair[1]:
			check("warden defending takes a quarter (2-4 -> 1)", rolled == 1)
		else:
			check("brawler takes an extra point (2-4 -> 3-5)", rolled >= 3 and rolled <= 5)
	goblin.accuracy = acc

	# A full wipe: everything carried is lost, the camp and stash remain.
	var ration: SupplyItem = load("res://data/items/ration.tres")
	camp.store(ps, ration)
	await _head_down()
	for hero: Companion in ps.members:
		hero.min_health = 0
		hero.change_health(-999)
	await create_timer(0.3).timeout
	if main._results.visible:
		main._results.continue_pressed.emit()
	else:
		await _to_camp(main.Expedition.Ending.WIPED)
	await create_timer(0.3).timeout
	check("after a wipe: the camp, not a restart", main._camp.visible and camp.day == 2)
	check("the fallen are gone; Mara, still with the nurse, survived", ps.members.size() == 1 and ps.members[0] == mara and camp.is_recovering(mara))
	check("everything carried is gone, lantern too", ps.supplies.items.all(func(i): return ps.supplies.count(i) == 0) and not ps.supplies.has_lantern)
	check("the stash survived", camp.stash.count(ration) == 1)
	await _open("cave")
	check("cave path: no one fit to go", not _press(main._camp, "Head back down"))
	await _snap("wiped")
	await _open("fire")
	_press(main._camp, "Invite")
	await _open("supplies")
	_press(main._camp, "Top up")
	check("the merchant hands out torches, not oil", ps.supplies.count(main.TORCH) == 4)
	await _head_down()
	check("a recruit goes down with a lit torch", ps.members.size() == 1 and ps.supplies.torch_lit() and main._depth == 1)
	print("fails=", fails)
	quit()

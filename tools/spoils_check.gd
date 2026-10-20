extends SceneTree
## The spoils of a won fight (owner, 2026-10-20): gold and XP shown together
## on the dark stage, arriving the way the last enemy fell. Args: tag, dir.

const SaveGame := preload("res://scripts/save_game.gd")

var fails := 0


func check(label: String, ok: bool, detail = "") -> void:
	if not ok: fails += 1
	print("PASS " if ok else "FAIL ", label, "  ", detail)


func _initialize() -> void:
	var CS = load("res://scripts/combat_screen.gd")
	var hero := Companion.new()
	hero.weapon = load("res://data/gear/wooden_club.tres")
	check("a club smashes", CS.strike_of(hero) == "smash")
	hero.weapon = load("res://data/gear/iron_sword.tres")
	check("a sword slashes", CS.strike_of(hero) == "slash")
	hero.weapon = load("res://data/gear/simple_spear.tres")
	check("a spear pierces", CS.strike_of(hero) == "pierce")
	hero.weapon = null
	check("bare hands smash", CS.strike_of(hero) == "smash")
	hero.reach = true
	check("a sling (reach, no weapon) pierces", CS.strike_of(hero) == "pierce")

	SaveGame.set_path("user://test_save.dat")
	SaveGame.delete()
	SaveGame.set_continue_requested(false)
	var main = load("res://scenes/main.tscn").instantiate()
	main.play_opening = false
	main.floor_seed = 11
	root.add_child(main)
	await create_timer(0.6).timeout
	var lead: Companion = main._party_state.members[0]
	var xp_before := lead.xp
	var gold_before: int = main._party_state.supplies.gold
	var types: Array[EnemyType] = [load("res://data/enemies/goblin.tres")]
	main._start_combat(main._party.cell, types)
	var g := 0
	while not main._combat._actions.visible and g < 50:
		await create_timer(0.1).timeout
		g += 1
	main._combat._state.foes[0].health = 1
	for h in main._party_state.members:
		h.aim_base = 2.0
		h.refresh_stats()
	main._combat._action_chosen.emit({"kind": "attack"})
	g = 0
	while not main._spoils.visible and g < 60:
		await create_timer(0.05).timeout
		g += 1
	check("winning shows the spoils", main._spoils.visible)
	check("...arriving the way the goblin fell", main._combat.last_blow == main.CombatScreen.strike_of(lead), main._combat.last_blow)
	await create_timer(1.0).timeout
	var text := " | ".join(main._spoils.find_children("*", "Label", true, false).map(func(l): return l.text))
	var gained: int = main._party_state.supplies.gold - gold_before
	check("gold and XP together, nothing lost to banners", gained > 0 and text.contains("+%d" % gained) and text.contains("+%d XP" % (lead.xp - xp_before)) and lead.xp > xp_before, text)
	main._spoils._skip = true
	g = 0
	while main._in_combat and g < 60:
		await create_timer(0.05).timeout
		g += 1
	check("then the fog sinks and play goes on", not main._in_combat and not main._spoils.visible)
	SaveGame.delete()
	print("fails=", fails)
	quit()

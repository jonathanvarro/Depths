extends SceneTree
## The spoils of a won fight, on the party's own cards (#231): each card's
## XP bar fills, "+N XP" rises off the portrait, a level-up mark pops in
## when one is owed, and the gold rises with a coin. No screen
## stops play between fights. The finishing blow's kind is still known
## (slash, smash, pierce). Args: tag, screenshot dir.

const SaveGame := preload("res://scripts/save_game.gd")
const Progression := preload("res://scripts/progression.gd")

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
		shot.save_png("%s/spoils_%s_%s.png" % [dir, tag, name])


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	tag = args[0] if args.size() > 0 else "desk"
	dir = args[1] if args.size() > 1 else ""
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
	var card = main._cards[0]
	check("the card's level mark is hidden while no level is owed", not card._level_mark.visible and not card._row_label.text.contains("+"), card._row_label.text)
	# Just short of the next level, so this fight earns one.
	lead.xp = Progression.THRESHOLDS[lead.level + 1] - 1
	lead.emit_changed()
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
	var rose: Label = null
	while rose == null and g < 200:
		await create_timer(0.05).timeout
		g += 1
		# Hit chance tops out below 100%: if the blow missed, swing again.
		if main._combat._actions.visible and main._combat._state.foes[0].health > 0:
			main._combat._action_chosen.emit({"kind": "attack"})
		for child in card.get_children():
			if child is Label and child.text.ends_with(" XP"):
				rose = child
	var gained_xp := lead.xp - xp_before
	check("winning: \"+N XP\" rises off the hero's card (#231)", rose != null and rose.text == "+%d XP" % gained_xp and gained_xp > 0, rose.text if rose else "none")
	check("...with no spoils screen in the way", not main._spoils.visible)
	check("...arriving the way the goblin fell", main._combat.last_blow == main.CombatScreen.strike_of(lead), main._combat.last_blow)
	var gained_gold: int = main._party_state.supplies.gold - gold_before
	var coin = card.get_node_or_null("Gold")
	check("the gold rises off the lead's card too", gained_gold > 0 and coin != null and coin.get_child(1).text == "+%d" % gained_gold, gained_gold)
	await create_timer(1.0).timeout
	await _snap("level_mark")
	check("the bar fills and the level-up mark pops in", card._level_mark.visible and card._row_label.text.contains("+") and Progression.ready_to_advance(lead))
	g = 0
	while main._in_combat and g < 60:
		await create_timer(0.05).timeout
		g += 1
	check("play goes straight on", not main._in_combat)
	SaveGame.delete()
	print("fails=", fails)
	quit()

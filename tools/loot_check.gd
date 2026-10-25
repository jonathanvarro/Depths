extends SceneTree
## Where a monster's find comes from (#148): every creature has its own
## line - goblins steal, beasts drag things to their nests, spiders wrap
## old meals - and none of the beasts "carried" or "wore" anything. Elites
## keep the line; a full pack still offers the find; the miner's pick keeps
## its own wording. Args: tag, screenshot dir.

const GearGen := preload("res://scripts/gear_gen.gd")

var fails := 0


func check(label: String, ok: bool, detail = "") -> void:
	if not ok: fails += 1
	print("PASS " if ok else "FAIL ", label, "  ", detail)


func _initialize() -> void:
	var lines := {}
	var missing := []
	var wrong := []
	for file in DirAccess.get_files_at("res://data/enemies"):
		if not file.ends_with(".tres"):
			continue
		var type: EnemyType = load("res://data/enemies/" + file)
		var text := type.loot_text("a silver locket")
		lines[type.display_name] = text
		if type.loot_line == "" or not text.contains("a silver locket"):
			missing.append(type.display_name)
		if text.contains("carried") or text.contains(" wore "):
			wrong.append(text)
	check("every monster has its own find line", missing.is_empty(), str(missing))
	check("no one 'carried' or 'wore' a find", wrong.is_empty(), str(wrong))
	check("goblins steal", lines["Goblin"].contains("stolen") and lines["Goblin brute"].contains("stolen"))
	check("beasts drag finds to their nests and roosts", lines["Rat"].contains("nest") and lines["Cave bat"].contains("roost"))
	check("spiders wrap old meals", lines["Spider"].contains("webbing") and lines["Venom spider"].contains("webbing"))
	check("the miner keeps its shift's gear", lines["Hollow miner"].contains("last shift"))
	var bare := EnemyType.new()
	bare.display_name = "Thing"
	check("an unwritten monster still reads sensibly", bare.loot_text("a ring") == "Near the fallen thing: a ring.")

	# Elites keep the line.
	var party = load("res://scripts/party_state.gd").new()
	party.add_member(load("res://data/companions/mara.tres"))
	var types: Array[EnemyType] = [load("res://data/enemies/cave_bat.tres")]
	var fight = load("res://scripts/combat_state.gd").new(party, types)
	fight.make_elite(fight.foes[0], "Savage")
	check("an elite keeps its kind's line", fight.foes[0].type.loot_text("a ring").contains("roost"))

	# In the game: into the pack, or offered beside a full one.
	var main = load("res://scenes/main.tscn").instantiate()
	main.play_opening = false
	main.floor_seed = 11
	root.add_child(main)
	await create_timer(0.5).timeout
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var gear: Equipment = null
	while gear == null:
		gear = GearGen.drop(rng, 2, "chest")
	var bat: EnemyType = load("res://data/enemies/cave_bat.tres")
	main._found_gear(gear, bat.loot_text(main._a(gear.display_name.to_lower())))
	check("found gear goes in the pack, with where it came from", gear in main._party_state.supplies.gear and main._message_label.text.contains("roost"), main._message_label.text)
	var supplies = main._party_state.supplies
	var guard := 0
	while supplies.has_room_for_gear() and guard < 40:
		supplies.gear.append(load("res://data/gear/simple_spear.tres").duplicate())
		guard += 1
	var spare: Equipment = load("res://data/gear/simple_spear.tres").duplicate()
	main._found_gear(spare, bat.loot_text("a spear"))
	check("a full pack offers it beside the pack, not lost", main._overflow.has(spare) and spare not in supplies.gear, str(main._overflow.size()))
	print("fails=", fails)
	quit()

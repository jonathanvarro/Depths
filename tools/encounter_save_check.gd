extends SceneTree
## A fair encounter after an interruption (#113): saving in the middle of a
## fight (or event) and continuing restarts it with both sides as they were
## when it began - not fresh enemies against a party that already spent
## health and supplies. Uses its own save file.

const SaveGame := preload("res://scripts/save_game.gd")
const DRAUGHT := preload("res://data/items/restorative_draught.tres")

var fails := 0


func check(label: String, ok: bool, detail = "") -> void:
	if not ok: fails += 1
	print("PASS " if ok else "FAIL ", label, "  ", detail)


func _game(continue_save: bool):
	SaveGame.set_continue_requested(continue_save)
	var main = load("res://scenes/main.tscn").instantiate()
	main.play_opening = false
	main.floor_seed = 41
	root.add_child(main)
	await create_timer(0.5).timeout
	return main


func _initialize() -> void:
	SaveGame.set_path("user://test_save.dat")
	SaveGame.delete()
	var main = await _game(false)
	var ps = main._party_state
	var hero: Companion = ps.members[0]
	ps.supplies.add(DRAUGHT, 2)
	var health_before := hero.health
	var draughts_before: int = ps.supplies.count(DRAUGHT)
	var gold_before: int = ps.supplies.gold
	var cell: Vector2i = main._party.cell
	var types: Array[EnemyType] = [load("res://data/enemies/rat.tres"), load("res://data/enemies/rat.tres")]
	main._start_combat(cell, types)
	await create_timer(0.3).timeout
	# Mid-fight: one rat down, the hero hurt, a draught drunk.
	var state = main._combat._state
	state.foes[0].health = 0
	hero.change_health(-5)
	ps.use_item(DRAUGHT, true)
	main._save_now()  # the window closes, or the phone backgrounds the game
	main.queue_free()
	await process_frame
	await process_frame

	main = await _game(true)
	ps = main._party_state
	hero = ps.members[0]
	check("continuing puts the hero back as the fight began", hero.health == health_before, "%d vs %d" % [hero.health, health_before])
	check("...with the draught not yet drunk", ps.supplies.count(DRAUGHT) == draughts_before, "%d vs %d" % [ps.supplies.count(DRAUGHT), draughts_before])
	check("...and no gold gained or lost", ps.supplies.gold == gold_before)
	await create_timer(0.5).timeout
	check("the fight starts again", main._in_combat)
	if main._in_combat:
		var foes: Array = main._combat._state.foes
		check("...with both enemies at full strength", foes.size() == 2 and foes.all(func(f): return f.health == f.type.max_health))

	# After the fight is over, saving is normal again.
	if main._in_combat:
		for foe in main._combat._state.foes:
			foe.health = 0
		main._combat._state._check_end()
		var guard := 0
		while main._in_combat and guard < 100:
			if main._combat._actions.visible:
				main._combat._action_chosen.emit({"kind": "defend"})
			await create_timer(0.1).timeout
			guard += 1
	check("a finished fight clears the checkpoint", main._encounter_checkpoint.is_empty() and not main._in_combat)

	# #111: a fight that starts with a wall ahead turns the party to face
	# an open way first, so the enemy isn't drawn inside the rock.
	var party = main._party
	var D = party.DIRECTIONS
	var spot: Vector2i = party.cell
	for c: Vector2i in main._map.walking_distances(party.cell):
		if not main._map.encounter_zones.has(c) and main._map.content_at(c) == 0 and range(4).any(func(f): return not main._map.is_passable(c + D[f])):
			spot = c
			break
	party.place(main._map, spot)
	for f in 4:
		if not main._map.is_passable(party.cell + D[f]):
			party.facing = f
			party.rotation.y = party._facing_to_yaw(f)
			break
	var walled: bool = not main._map.is_passable(party.cell + D[party.facing])
	var rats: Array[EnemyType] = [load("res://data/enemies/rat.tres")]
	main._start_combat(party.cell, rats)
	await create_timer(0.3).timeout
	check("a fight never starts facing a wall", main._map.is_passable(party.cell + D[party.facing]), "was facing a wall: %s" % walled)
	if main._in_combat:
		main._combat._state.foes[0].health = 0
		main._combat._state._check_end()
		var g := 0
		while main._in_combat and g < 100:
			if main._combat._actions.visible:
				main._combat._action_chosen.emit({"kind": "defend"})
			await create_timer(0.1).timeout
			g += 1
	SaveGame.delete()
	print("fails=", fails)
	quit()

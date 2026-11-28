extends SceneTree
## The Damp Caves' art hooked up (#302/#303, owner 2026-11-26): wet limestone
## and its sounds, the four creatures' own models and cries, and the shaft
## and crawl ways on with their returns. Args: tag, screenshot dir.

const Sounds := preload("res://scripts/sounds.gd")
const Elites := preload("res://scripts/elites.gd")

var fails := 0


func check(label: String, ok: bool, detail = "") -> void:
	if not ok: fails += 1
	print("PASS " if ok else "FAIL ", label, "  ", detail)


func _snap(path: String) -> void:
	for i in 6:
		await process_frame
	var image := root.get_texture().get_image()
	if image:
		image.save_png(path)


func _face(main, cell: Vector2i) -> void:
	# Stand beside `cell`, looking at it.
	for f in 4:
		var from: Vector2i = cell - main._party.DIRECTIONS[f]
		if main._map.is_passable(from) and main._map.content_at(from) == 0:
			main._party.place(main._map, from)
			main._party.facing = f
			main._party.rotation.y = -f * PI / 2.0
			return


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	# Creatures.
	for pair in [["pale_newt", "pale-newt", "newt"], ["blind_crawler", "blind-crawler", "crawler"], ["leech_swarm", "leech-swarm", "leeches"]]:
		var t: EnemyType = load("res://data/enemies/%s.tres" % pair[0])
		check("%s has its own model and cries" % t.display_name, t.model.resource_path.ends_with(pair[1] + ".tscn") and Sounds.creature(t) == pair[2] and Sounds.EFFECTS.has(pair[2] + "_hurt") and Sounds.EFFECTS.has(pair[2] + "_death"), [t.model.resource_path, Sounds.creature(t)])
		var actor: Node3D = t.model.instantiate()
		check("...and it frames for the fight", actor.has_method("play") and actor.has_method("framing_bounds") and actor.framing_bounds().size.y > 0.1)
		actor.free()
	var mother: EnemyType = Elites.types("drowned")[0]
	check("the Drowned Mother leads in her own model, with her own cries", mother.model.resource_path.ends_with("drowned-mother.tscn") and Sounds.creature(mother) == "mother")
	check("...her brood keep theirs", Elites.types("drowned")[1].model.resource_path.ends_with("pale-newt.tscn"))

	var main = load("res://scenes/main.tscn").instantiate()
	main.play_opening = false
	main.wandering = false
	main.floor_seed = 302
	root.add_child(main)
	await create_timer(0.5).timeout
	main._go_to_area("damp", main.Arrival.FROM_ABOVE)
	check("the Damp Caves are wet limestone", main.environment_theme == main.DAMP_THEME and main.environment_theme.floor_material.resource_path.contains("damp-caves-v1"))
	check("...with their own steps and ambience", main.environment_theme.footstep_sounds[0].resource_path.contains("step-wet") and main._ambience_player.stream.resource_path.contains("ambience-damp"))
	var art: Dictionary = main._map.marks.get("descent_art", {})
	check("the way on to the Cavern is the shaft, to the Hollows the crawl", art.values().any(func(p): return p.ends_with("cavern-onward.tscn")) and art.values().any(func(p): return p.ends_with("hollows-onward.tscn")), art)
	var shaft := Vector2i(-1, -1)
	var crawl := Vector2i(-1, -1)
	for c in art:
		if art[c].ends_with("cavern-onward.tscn"): shaft = c
		else: crawl = c
	if args.size() > 1:
		await _snap(args[1] + "/damp_arrival.png")
		_face(main, shaft)
		await _snap(args[1] + "/damp_shaft.png")
		_face(main, crawl)
		await _snap(args[1] + "/damp_crawl.png")
	main._go_to_area("cavern", main.Arrival.FROM_ABOVE)
	check("the Cavern's way back up is the wet rope", main._map.marks.get("ascent_art", "").ends_with("cavern-return.tscn"))
	check("...and the Cavern keeps its own look", main.environment_theme != main.DAMP_THEME)
	if args.size() > 1:
		_face(main, main._map.find_content(main.DungeonMap.Content.STAIRS_UP))
		await _snap(args[1] + "/cavern_rope.png")
	main._go_to_area("hollows", main.Arrival.FROM_ABOVE)
	check("the Hollows' way back is the crawl", main._map.marks.get("ascent_art", "").ends_with("hollows-return.tscn"))
	main._go_to_area("mines", main.Arrival.FROM_ABOVE)
	check("the Mines keep their own ways", main._map.marks.get("descent_art", {}).is_empty() and main._map.marks.get("ascent_art", "") == "")
	# A fight with the new models.
	main._go_to_area("damp", main.Arrival.FROM_ABOVE)
	var foes: Array[EnemyType] = [load("res://data/enemies/pale_newt.tres"), load("res://data/enemies/blind_crawler.tres"), load("res://data/enemies/leech_swarm.tres")]
	main._start_combat(main._party.cell, foes)
	await create_timer(1.0).timeout
	check("a fight shows them", main._in_combat)
	if args.size() > 1:
		await _snap(args[1] + "/damp_fight.png")
	print("fails=", fails)
	quit()

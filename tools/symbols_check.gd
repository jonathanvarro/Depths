extends SceneTree
## ChatGPT's small symbols and the galleries' finish, connected (#178,
## #166, #167): mastery marks on item icons, the deep monsters' intentions,
## off balance and tasting blood, the map's deep-water mark, the journal's
## silhouettes and learned-fact marks, the waterworks on floor 5 and the
## wounded keeper's animated, talking face. Args: tag, screenshot dir.

const Quality := preload("res://scripts/quality.gd")
const GearModel := preload("res://scripts/gear_model.gd")
const CombatState := preload("res://scripts/combat_state.gd")
const Bestiary := preload("res://scripts/bestiary.gd")
const Galleries := preload("res://scripts/galleries.gd")
const Minimap := preload("res://scripts/minimap.gd")

var fails := 0
var main


func check(label: String, ok: bool, detail = "") -> void:
	if not ok: fails += 1
	print("PASS " if ok else "FAIL ", label, "  ", detail)


func _snap(dir: String, name: String) -> void:
	if dir == "":
		return
	for i in 12:
		await process_frame
	var shot := root.get_texture().get_image()
	if shot:
		shot.save_png("%s/%s.png" % [dir, name])


func _path(texture: Texture2D) -> String:
	return texture.resource_path if texture else ""


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var tag: String = args[0] if args.size() > 0 else "desk"
	var dir: String = args[1] if args.size() > 1 else ""
	var rng := RandomNumberGenerator.new()
	rng.seed = 178

	# Mastery marks.
	var sword := GearModel.generate(rng, "iron_sword", "ordinary")
	check("no mastery yet: no mark", Quality.mastery_mark(sword) == null)
	var marks := {}
	for points in [12.0, 30.0, 84.0, 120.0, 162.0]:
		sword.mastery = points
		sword.tempers = PackedStringArray(["edge", "weight"]) if points >= 54.0 else PackedStringArray()
		marks[points] = _path(Quality.mastery_mark(sword)).get_file()
	check("one notch, then two, then full", marks[12.0] == "one.png" and marks[30.0] == "one.png" and marks[84.0] == "two.png" and marks[162.0] == "full.png", marks)
	sword.mastery = 54.0
	sword.tempers = PackedStringArray()
	check("...and the smith's mark while a temper is due", _path(Quality.mastery_mark(sword)).ends_with("improve.png"))
	check("trinkets and supplies carry none", Quality.mastery_mark(load("res://data/items/ration.tres")) == null)

	# Combat marks.
	var screen = load("res://scripts/combat_screen.gd").new()
	check("the Underhound's long lunge has its own mark", _path(screen._intent_icon(CombatState.Intent.REACH)).ends_with("long-lunge.png"))
	check("the Shepherd's birthing has its own mark", _path(screen._intent_icon(CombatState.Intent.BIRTH)).ends_with("birthing.png"))
	screen.free()
	var party = load("res://scripts/party_state.gd").new()
	party.add_member(load("res://data/companions/mara.tres").duplicate(true))
	var fight = CombatState.new(party, [load("res://data/enemies/goblin.tres"), load("res://data/enemies/borrowed_pack.tres")] as Array[EnemyType])
	fight.prepare(1)
	var goblin = fight.foes[0]
	fight._taste_blood(goblin)
	var view = load("res://scripts/combat_screen.gd").new()
	view._state = fight
	var goblin_marks: Array = view._state_marks(goblin).map(func(t): return _path(t))
	check("a foe that tasted blood wears that mark, not the plain Savage one", goblin_marks.any(func(p): return p.ends_with("tastes-blood.png")) and goblin.tasted, goblin_marks)
	var pack = fight.foes[1]
	pack.staggered = true
	check("an off-balance Borrowed Pack shows it", view._state_marks(pack).any(func(t): return _path(t).ends_with("off-balance.png")) and view._state_words(pack).any(func(w): return w.begins_with("Off balance")))
	view.free()
	var fx = load("res://scripts/combat_fx.gd").new()
	root.add_child(fx)
	fx.splash(Vector2(100, 100), Color("a54b43"))
	var splashed: Array = fx.get_children().filter(func(c): return c is TextureRect)
	check("a thrown brew splashes in its liquid's colour", splashed.size() == 1 and splashed[0].modulate == Color("a54b43") and fx.SPLASH.get_frame_count(fx.SPLASH.get_animation_names()[0]) == 6)
	fx.queue_free()

	# The map, and the journal.
	check("the map inks #167's deep-water mark", _path(Minimap.GLYPHS["water"]).ends_with("deep-water.png"))
	var camp = load("res://scripts/camp_state.gd").new()
	var state = CombatState.new(party, [load("res://data/enemies/goblin_archer.tres")] as Array[EnemyType])
	state.prepare(1)
	Bestiary.record(camp, state, 1)
	var key: String = state.foes[0].type.display_name
	check("a met monster's page has its silhouette", Bestiary.thumbnail(camp, key) != null and _path(Bestiary.thumbnail(camp, key)).ends_with("goblin_archer.png"))
	check("...but no learned marks before one is killed", Bestiary.marks(camp, key).is_empty())
	state.foes[0].health = 0
	Bestiary.record(camp, state, 1)
	var learned: Array = Bestiary.marks(camp, key)
	check("killed: what's learned shows as marks", not learned.is_empty() and learned.any(func(m): return m[0].ends_with("reach.png")), learned.map(func(m): return m[2]))
	check("...and how a flare takes it", learned.any(func(m): return m[0].ends_with("flare.png")))
	camp.bestiary[key]["moves"].append(CombatState.Intent.HEAVY)
	check("a big blow seen: the brace mark", Bestiary.marks(camp, key).any(func(m): return m[0].ends_with("brace.png")))
	var lamp_camp = load("res://scripts/camp_state.gd").new()
	var lamp_fight = CombatState.new(party, [load("res://data/enemies/lamp_eater.tres")] as Array[EnemyType])
	lamp_fight.prepare(1)
	lamp_fight.foes[0].health = 0
	Bestiary.record(lamp_camp, lamp_fight, 2)
	var lamp_marks: Array = Bestiary.marks(lamp_camp, lamp_fight.foes[0].type.display_name)
	check("the lamp-eater's page: a flare feeds it", lamp_marks.any(func(m): return m[0].ends_with("flare.png") and m[1] == "immune" and m[2].contains("drinks")), lamp_marks.map(func(m): return m[2]))
	camp.bestiary[key]["facts"].erase("id")
	check("an older save's entry still finds its silhouette by name", Bestiary.thumbnail(camp, key) != null)

	main = load("res://scenes/main.tscn").instantiate()
	main.play_opening = false
	main.floor_seed = 11
	main.wandering = false
	main.simulate_phone_safe_area = tag == "phone"
	root.add_child(main)
	await create_timer(0.5).timeout

	# The Pack: a mastered sword.
	sword.mastery = 30.0
	main._party_state.supplies.gear.append(sword)
	main._set_pack(true)
	await process_frame
	await process_frame
	var tiles: Array = main._pack.find_children("*", "Panel", true, false).filter(func(p): return p.has_meta("mastery_mark"))
	check("the Pack shows the sword's mastery mark", not tiles.is_empty())
	await _snap(dir, "symbols_%s_pack" % tag)
	main._set_pack(false)

	# The journal page.
	main._camp_state.bestiary = camp.bestiary
	main._quest_log.open(main._camp_state)
	main._quest_log._mode.pressed.emit()
	await process_frame
	main._quest_log.select_quest(key)
	await process_frame
	await _snap(dir, "symbols_%s_journal" % tag)
	main._quest_log.visible = false

	# Floor 5's waterworks.
	main._go_to_floor(Galleries.DEPTH, main.Arrival.FROM_ABOVE)
	await process_frame
	var works: Node3D = main._level.get_node_or_null("Waterworks")
	var pieces: Array = works.get_children() if works else []
	check("floor 5's walls carry channels and pipes, and dry floor a dead lamp", pieces.size() >= 4, pieces.size())
	check("...never a lamp standing in the water", pieces.filter(func(n): return n.scene_file_path.ends_with("silted-lamp.tscn")).all(func(n): return not main._map.is_water(Vector2i(roundi(n.position.x / main.CELL_SIZE), roundi(n.position.z / main.CELL_SIZE)))))
	check("...nor any on stairs, doors or events", pieces.all(func(n):
		var c := Vector2i(roundi(n.position.x / main.CELL_SIZE), roundi(n.position.z / main.CELL_SIZE))
		return main._map.content_at(c) == 0 and not main._map.events.has(c) and main._map.door_at(c) == 0))
	var wall_piece: Array = pieces.filter(func(n): return not n.scene_file_path.ends_with("silted-lamp.tscn"))
	if not wall_piece.is_empty():
		var piece: Node3D = wall_piece[0]
		var cell := Vector2i(roundi(piece.position.x / main.CELL_SIZE), roundi(piece.position.z / main.CELL_SIZE))
		var toward: Vector3 = piece.position - Vector3(cell.x * main.CELL_SIZE, 0, cell.y * main.CELL_SIZE)
		var facing := [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)].find(Vector2i(signi(roundi(toward.x)), signi(roundi(toward.z))))
		var back: Vector2i = cell - [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)][facing]
		main._party.cell = back if main._map.is_passable(back) else cell
		main._party.facing = facing
		main._party.position = main._party._cell_to_world(main._party.cell)
		main._party.rotation.y = main._party._facing_to_yaw(facing)
		await _snap(dir, "symbols_%s_waterworks" % tag)

	# The keeper: map-reading still, then her defiant face, talking.
	var talk: Conversation = load("res://data/conversations/keeper_talk.tres")
	check("her talk's second page has her defiant face", talk.pages[1].expression != null and talk.pages[1].expression.resource_path.ends_with("defiant.tres"))
	main._conversation.play(talk, main._party_state.members[0], main._camp_state, main._party_state.members)
	await process_frame
	var frame: PanelContainer = main._conversation._frames.get("npc")
	check("...the first page keeps the still map-reading pose", frame.get_meta("face").visible and not frame.has_meta("view"))
	main._conversation.choose("\"You killed them")
	for i in 6:
		await process_frame
	var portrait: Control = frame.get_meta("view") if frame.has_meta("view") else null
	check("...then her face moves: the defiant rig, talking", portrait != null and portrait.visible and not frame.get_meta("face").visible and portrait.portrait_set == talk.pages[1].expression and portrait._talk_tween != null and portrait._talk_tween.is_valid())
	await _snap(dir, "symbols_%s_keeper" % tag)
	main._conversation.choose("Go on")
	await process_frame
	print("fails=", fails)
	quit()

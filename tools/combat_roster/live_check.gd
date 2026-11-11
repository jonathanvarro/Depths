extends SceneTree
## Samples the actual light-aware board with in-memory art substitutions.
const ART := "res://art/enemies/combat-roster-3d-v1/"
const ENEMIES := ["great-rat","goblin-archer","goblin-guard","goblin-drummer","goblin-trapper","goblin-queen","broodmother"]
const PARTY := ["mara","corin","alwen","recruit"]
const DIMENSIONS := [Vector2i(1278,590),Vector2i(852,393),Vector2i(667,375)]
const SPECIAL := {"goblin-archer":"draw","goblin-guard":"brace","goblin-drummer":"drum",
	"goblin-trapper":"snare","goblin-queen":"enraged","broodmother":"call"}
const CombatState := preload("res://scripts/combat_state.gd")
const INTENTS := {"great-rat":CombatState.Intent.BITE,"goblin-archer":CombatState.Intent.SHOOT,
	"goblin-guard":CombatState.Intent.BRACE,"goblin-drummer":CombatState.Intent.BEAT,
	"goblin-trapper":CombatState.Intent.SNARE,"goblin-queen":CombatState.Intent.CLEAVER,
	"broodmother":CombatState.Intent.BROOD}
var checks := 0
var failures: Array[String] = []
var captures: Array[String] = []
var out := ""

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		push_error(label)

func snap(name: String) -> void:
	for frame in 5:
		await process_frame
	await RenderingServer.frame_post_draw
	var file := name + ".png"
	check(root.get_texture().get_image().save_png(out + "/" + file) == OK, "Capture " + name)
	captures.append(file)

func light_band(main, band: int) -> void:
	var s = main._party_state.supplies
	s.glow_left = 0
	s.oil = 0
	s.torch_left = 0
	s.has_lantern = false
	s.source = s.Source.NONE
	if band == 2:
		s.source = s.Source.TORCH
		s.torch_left = s.TORCH_BURN_TIME
	elif band == 3:
		s.source = s.Source.LANTERN
		s.has_lantern = true
		s.oil = s.LANTERN_CAPACITY
	s.changed.emit()
	s.light_band_changed.emit(s.light_band())
	await create_timer(.73).timeout
	main._message_label.text = ""
	var height: float = main._tactical._camera.global_position.y - main._party.global_position.y
	check(s.light_band() == band and absf(height - float(main._tactical.CAMERA[band][0])) < .14, "Light band " + str(band))

func actor_at(parent: Node3D, id: String, offset := Vector3.ZERO) -> Node3D:
	var actor: Node3D = load(ART + id + ".tscn").instantiate()
	parent.add_child(actor)
	actor.position = offset
	actor.set_motion(false)
	return actor

func board_size(main, dimensions: Vector2i) -> void:
	root.size = dimensions
	main.simulate_phone_safe_area = dimensions.x < 1000

func set_foe_for_review(main, foe, id: String) -> void:
	foe.type = load("res://data/enemies/" + id.replace("-","_") + ".tres")
	foe.name = foe.type.display_name
	foe.health = foe.type.max_health
	foe.intent = INTENTS[id]
	main._combat._update_intent_line()

func test_enemies(main, foe) -> void:
	for id: String in ENEMIES:
		set_foe_for_review(main,foe,id)
		var actor := actor_at(foe.node,id)
		foe.node.set_meta("visual_height",actor.get_meta("visual_height"))
		actor.look_at(Vector3(main._party.global_position.x,actor.global_position.y,
			main._party.global_position.z),Vector3.UP,true)
		await light_band(main,2)
		check(main._tactical.seen.has(foe.cell) and foe.node.visible,"Adjacent foe on board " + id)
		for dimensions: Vector2i in DIMENSIONS:
			board_size(main,dimensions)
			for pose in ["idle","attack","hurt","fall"]:
				actor.play(pose)
				check(is_zero_approx(actor.position.y),"Fixed floor origin " + id)
				await snap("%s-steady-%s-%d" % [id,pose,dimensions.x])
		board_size(main,DIMENSIONS[1])
		if SPECIAL.has(id):
			actor.play(SPECIAL[id])
			await snap("%s-steady-%s-852" % [id,SPECIAL[id]])
		for band in [0,3]:
			await light_band(main,band)
			actor.play("idle")
			check(foe.node.visible,"Adjacent foe visible " + id)
			await snap("%s-band%d-852" % [id,band])
		await light_band(main,2)
		board_size(main,DIMENSIONS[0])
		await main._tactical.exit()
		foe.node.position = Vector3(foe.cell.x*2,0,foe.cell.y*2)
		actor.play("idle")
		await snap(id + "-first-person")
		main._tactical.enter(main,main._combat._state)
		await create_timer(.85).timeout
		foe.node.remove_child(actor)
		actor.queue_free()

func test_party(main, foe) -> void:
	set_foe_for_review(main,foe,"goblin-guard")
	var token: Node3D = main._tactical._party_token
	var original := token.get_children()
	original[1].hide()
	var enemy := actor_at(foe.node,"goblin-guard")
	enemy.look_at(Vector3(token.global_position.x,enemy.global_position.y,token.global_position.z),Vector3.UP,true)
	for dimensions: Vector2i in DIMENSIONS:
		board_size(main,dimensions)
		for id: String in PARTY:
			var leader := actor_at(token,id,Vector3(0,-.02,0))
			leader.rotation.y = PI
			await snap("%s-leader-%d" % [id,dimensions.x])
			leader.play("attack")
			await snap("%s-attack-%d" % [id,dimensions.x])
			token.remove_child(leader)
			leader.queue_free()
		var actors: Array[Node3D] = [
			actor_at(token,"mara",Vector3(0,-.02,-.44)),
			actor_at(token,"corin",Vector3(-.49,-.02,.37)),
			actor_at(token,"alwen",Vector3(.49,-.02,.38)),
		]
		for model in actors:
			model.rotation.y = PI
			check(token.to_local(model.global_position).length() < .8,"Formation stays in one tile")
		await snap("party-formation-" + str(dimensions.x))
		for band in [0,3]:
			if dimensions.x == 852:
				await light_band(main,band)
				await snap("party-formation-band%d-852" % band)
		if dimensions.x == 852:
			await light_band(main,2)
			actors[0].play("attack")
			actors[1].play("defend")
			actors[2].play("cast")
			await snap("party-formation-actions-852")
		for model in actors:
			token.remove_child(model)
			model.queue_free()
	enemy.queue_free()
	for node in original:
		node.show()

func run() -> void:
	out = OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(out)
	var Settings = load("res://scripts/settings.gd")
	var settings: Dictionary = Settings.DEFAULTS.duplicate()
	settings["flashes"] = false
	Engine.set_meta(Settings.STATE,settings)
	Engine.set_meta(Settings.STATE+"_loaded",true)
	load("res://scripts/save_game.gd").set_path(out+"/isolated-save.dat")
	root.size = DIMENSIONS[0]
	var main = load("res://scenes/main.tscn").instantiate()
	main.play_opening = false
	main.floor_seed = 11
	root.add_child(main)
	await create_timer(.7).timeout
	check(not main._groups.is_empty(),"Test encounter available")
	if main._groups.is_empty():
		quit(1)
		return
	var group = main._groups[0]
	for side in [Vector2i.DOWN,Vector2i.UP,Vector2i.LEFT,Vector2i.RIGHT]:
		var cell: Vector2i = group.cell+side*2
		if main._map.is_passable(cell) and main._map.is_passable(group.cell+side):
			main._party.place(main._map,cell)
			main._party.facing = [Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT].find(-side)
			main._party.rotation.y = -main._party.facing*PI/2
			break
	group.types.clear()
	group.types.append(load("res://data/enemies/spider.tres"))
	group.noticed = true
	main._engage(group)
	await create_timer(1.3).timeout
	var foe = main._combat._state.living_foes()[0]
	foe.cell = main._party.cell + main._party.DIRECTIONS[main._party.facing]
	main._lift_field_foes()
	for patrol in main._groups:
		if is_instance_valid(patrol.node):
			patrol.node.visible = false
	foe.node.get_node("Sprite").hide()
	main._message_label.text = ""
	check(main._tactical.active,"Live tactical view active")
	await test_enemies(main,foe)
	await light_band(main,2)
	await test_party(main,foe)
	var report := {"checks":checks,"failures":failures,"captures":captures,
		"runtime_only_insertion":true,"renderer":RenderingServer.get_current_rendering_method()}
	FileAccess.open(out + "/validation.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  ") + "\n")
	print("ROSTER_LIVE ",checks," failures=",failures)
	main.queue_free()
	await process_frame
	await process_frame
	quit(0 if failures.is_empty() else 1)

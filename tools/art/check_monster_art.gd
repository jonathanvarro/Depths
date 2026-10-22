extends SceneTree
## #141: real scenes, BattleStage, CombatScreen and PartyCard; no Main/saves.
const OUT := "res://art/concepts/monsters-v1/"
const CS := preload("res://scripts/combat_state.gd")
const PARTY := preload("res://scripts/party_state.gd")
const CARD := preload("res://scripts/party_card.gd")
const SCREEN := preload("res://scripts/combat_screen.gd")
const STAGE := preload("res://scripts/battle_stage.gd")
var checks := 0
var failures: Array[String] = []
var captures: Array[String] = []
var world: Node3D
var camera: Camera3D
var ui: CanvasLayer
var actors: Node3D
var screen: Control
var cards: Array = []
var label: Label
var party
var state
var entries: Dictionary = {}

func _initialize() -> void:
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	call_deferred("_run")

func check(ok: bool, text: String) -> void:
	checks += 1
	if not ok:
		failures.append(text)
		push_error(text)

func settle() -> void:
	for tick in 8:
		await process_frame

func snap(name: String) -> void:
	label.text = name.replace("-", " ") + " / art fixture"
	await settle()
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(OUT + name + ".png") == OK, "Saved " + name)
	captures.append(name + ".png")

func clear_panel(node: Node3D) -> void:
	# Same visual clearance calculation as Main, without loading Main or saves.
	var line: float = root.size.y - 16.0 - screen._actions.get_combined_minimum_size().y - 8.0
	for attempt in 2:
		var lowest := -INF
		var distance := 0.0
		for sprite: SpriteBase3D in node.find_children("*", "SpriteBase3D", true, false):
			var box := sprite.get_aabb()
			var foot: Vector3 = sprite.global_transform * Vector3(box.get_center().x, box.position.y, 0)
			var y := camera.unproject_position(foot).y
			if y > lowest:
				lowest = y
				distance = -foot.z
		if lowest <= line or distance <= 0:
			return
		var metres := 2.0 * distance * tan(deg_to_rad(camera.fov) / 2.0) / root.size.y
		node.position.y += (lowest - line) * metres

func fight(ids: Array) -> void:
	if is_instance_valid(screen):
		screen.free()
	if is_instance_valid(actors):
		actors.free()
	actors = Node3D.new()
	world.add_child(actors)
	var types: Array[EnemyType] = []
	for id: String in ids:
		var resource: String = "res://data/enemies/" + id.replace("-", "_") + ".tres"
		var type: EnemyType
		if ResourceLoader.exists(resource):
			type = load(resource).duplicate()
		else:
			type = EnemyType.new()
			type.display_name = id.replace("-", " ").capitalize()
			type.scene = load(entries[id].scene)
			type.initiative = 0
		types.append(type)
	state = CS.new(party, types)
	screen = SCREEN.new()
	ui.add_child(screen)
	for i in state.foes.size():
		var foe = state.foes[i]
		var node: Node3D = foe.type.scene.instantiate()
		actors.add_child(node)
		node.position = Vector3(0 if ids.size() == 1 else (-0.5 if i == 0 else 0.5), 0, -3.4 if foe.in_back() else -2.4)
		STAGE.raise(node)
		foe.node = node
	screen.run(state, cards)
	await settle()
	for foe in state.foes:
		clear_panel(foe.node)
	await settle()
	check(screen._actions.visible, "Real combat actions await player")

func _run() -> void:
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://art/enemies/monsters-v1/catalog.json"))
	world = Node3D.new()
	root.add_child(world)
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("12110e")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color.WHITE
	environment.ambient_light_energy = 0.35
	var env := WorldEnvironment.new()
	env.environment = environment
	world.add_child(env)
	camera = Camera3D.new()
	world.add_child(camera)
	camera.position = Vector3(0, 1.2, 0)
	camera.fov = 70
	camera.current = true
	var light := OmniLight3D.new()
	light.position = Vector3(-0.4, 1.8, 0.2)
	light.light_color = Color(1, 0.8, 0.58)
	light.light_energy = 1.4
	light.omni_range = 12
	world.add_child(light)
	var stage := STAGE.new()
	camera.add_child(stage)
	stage.fit(camera)
	await stage.enter(false)
	ui = CanvasLayer.new()
	root.add_child(ui)
	var row := HBoxContainer.new()
	ui.add_child(row)
	row.add_theme_constant_override("separation", 10)
	party = PARTY.new()
	for id: String in ["mara", "corin", "alwen"]:
		party.add_member(load("res://data/companions/" + id + ".tres"))
		var hero: Companion = party.members[-1]
		hero.speed_base = 1000
		hero.refresh_stats()
		var card := CARD.new()
		row.add_child(card)
		card.show_companion(hero)
		cards.append(card)
	label = Label.new()
	ui.add_child(label)
	label.position = Vector2(18, 52)
	label.add_theme_font_size_override("font_size", 20)
	for entry: Dictionary in catalog.assets:
		entries[entry.id] = entry
		var scene: Node3D = load(entry.scene).instantiate()
		world.add_child(scene)
		var sprite: AnimatedSprite3D = scene.get_node("Sprite")
		check(scene.find_children("*", "CollisionObject3D", true, false).is_empty(), "No collider: " + entry.id)
		check(scene.find_children("*", "Light3D", true, false).is_empty(), "No light added: " + entry.id)
		check(sprite.shaded and sprite.texture_filter == BaseMaterial3D.TEXTURE_FILTER_NEAREST, "Native shaded sprite: " + entry.id)
		check(is_equal_approx(sprite.pixel_size, entry.pixel_size), "Shared physical scale: " + entry.id)
		for pose: String in entry.animations:
			check(sprite.sprite_frames.has_animation(pose), "Imported pose: " + entry.id + "/" + pose)
			sprite.play(pose)
			sprite.pause()
			for i in entry.animations[pose].size():
				sprite.frame = i
				var texture: Texture2D = sprite.sprite_frames.get_frame_texture(pose, i)
				check(texture.get_size() == Vector2(entry.canvas[0], entry.canvas[1]), "Exact pose canvas: " + entry.id + "/" + pose)
				var native_top: int = texture.get_image().get_used_rect().position.y
				var expected: float = sprite.position.y + (entry.canvas[1] / 2.0 - native_top) * sprite.pixel_size
				check(is_equal_approx(float(scene.get_meta("visual_height")), expected), "Tag follows actual native pose: " + entry.id + "/" + pose)
		sprite.play("idle")
		var idle_height: float = sprite.position.y + (entry.canvas[1] / 2.0 - entry.animation_tops.idle[0]) * sprite.pixel_size
		check(is_equal_approx(float(scene.get_meta("visual_height")), idle_height), "Idle restores tag after last pose: " + entry.id)
		if entry.id == "cave-bat":
			check(is_equal_approx(float(scene.get_meta("visual_height")), 2.4), "Idle bat hangs from standard roof; tag tracks top")
			sprite.play("landed")
			check(is_equal_approx(sprite.position.y / sprite.pixel_size, 56), "Landed bat keeps floor pivot")
			sprite.play("swoop")
			check(is_equal_approx(sprite.position.y / sprite.pixel_size, 56 + 0.65 / sprite.pixel_size), "Swoop remains airborne")
		scene.free()
	for id: String in ["cave_bat", "goblin_brute", "gas_bloat", "hollow_miner"]:
		var type: EnemyType = load("res://data/enemies/" + id + ".tres")
		check(type.scene.resource_path.contains("monsters-v1") and type.tint == Color.WHITE and type.sprite_scale == 1.0, "Actual live resource binding: " + id)
	var symbols: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://art/ui/monsters-v1/catalog.json"))
	for group: String in symbols.groups:
		for id: String in symbols.groups[group]:
			check((load(symbols.groups[group][id]) as Texture2D).get_size() == Vector2(32, 32), "Imported 32px symbol: " + id)
	var effects: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://art/effects/monsters-v1/catalog.json"))
	for effect: Dictionary in effects.effects:
		if effect.has("frames"):
			var frames: SpriteFrames = load(effect.frames)
			check(frames.get_frame_count("once") == effect.frame_count and not frames.get_animation_loop("once"), "One-shot effect: " + effect.id)
			var last: Image = frames.get_frame_texture("once", effect.frame_count - 1).get_image()
			check(last.get_used_rect().size == Vector2i.ZERO, "Effect clears on its last frame: " + effect.id)
	for phone: bool in [false, true]:
		root.size = Vector2i(1278, 590) if phone else Vector2i(1280, 720)
		row.position = Vector2(18, root.size.y - 178)
		var tag := "phone" if phone else "desktop"
		for id: String in entries:
			await fight([id])
			await snap(id + "-" + tag)
			var special: Dictionary = {"cave-bat":["swoop", "landed"], "goblin-brute":["wind-up", "recover"], "gas-bloat":["swell", "burst"], "hollow-miner":["grab"]}
			for pose: String in special.get(id, []):
				var node: Node3D = state.foes[0].node
				var sprite: AnimatedSprite3D = node.get_node("Sprite")
				sprite.play(pose)
				if pose == "burst":
					sprite.pause()
					sprite.frame = 1
				clear_panel(node)
				await snap(id + "-" + pose + "-" + tag)
		await fight(["breach-hound", "breach-hound"])
		var left: Node3D = state.foes[0].node
		var right: Node3D = state.foes[1].node
		check(right.position.x - left.position.x >= 1.0, "Two hounds retain separate formation centres")
		await snap("hound-pair-" + tag)
		for i in 3:
			var texture: Texture2D = load(symbols.groups.status[["grabbed", "snared", "gassed"][i]])
			cards[i].set_marks([[texture, "Art preview: " + ["grabbed", "snared", "gassed"][i]]])
		var gas := AnimatedSprite2D.new()
		gas.sprite_frames = load("res://art/effects/monsters-v1/gas-burst.tres")
		gas.animation = &"once"
		gas.frame = 1
		gas.position = Vector2(root.size.x / 2, root.size.y / 2)
		gas.scale = Vector2(2, 2)
		ui.add_child(gas)
		await snap("gas-and-status-" + tag)
		gas.free()
	var report := {"issue":141,"checks":checks,"failures":failures,"captures":captures,"limits":"Real BattleStage/CombatScreen/PartyCard with in-memory party and fixture enemies; no Main, saves or new combat behaviour. Special poses/statuses are explicitly selected for review. Phone-shaped desktop, not physical iPhone."}
	var file := FileAccess.open(OUT + "godot-validation.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t") + "\n")
	file.close()
	print("MONSTER_ART checks=%d failures=%d captures=%d" % [checks, failures.size(), captures.size()])
	quit(0 if failures.is_empty() else 1)

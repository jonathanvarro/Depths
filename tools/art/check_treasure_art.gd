extends SceneTree
## Isolated treasure resource, display and world-light checks; no campaign state.
const OUT := "res://art/concepts/treasure-v1/"
const DIR := "res://art/props/treasure-v1/"
const FONT := preload("res://art/fonts/source-sans-3/SourceSans3-Variable.ttf")
var checks := 0
var failures: Array[String] = []
var captures := 0

func _initialize() -> void:
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func _run() -> void:
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://art/items/treasure-v1/catalog.json"))
	check(catalog.assets.size() == 14,"Fourteen treasure icons")
	var ids: Array[String] = []
	for entry in catalog.assets:
		check(not ids.has(entry.id),"Unique ID "+entry.id)
		ids.append(entry.id)
		for field in ["icon","illustration"]:
			var texture: Texture2D = load(entry[field])
			var size := Vector2(64,64) if field == "icon" else Vector2(128,128)
			check(texture.get_size() == size,entry.id+" exact "+field+" canvas")
			var image := texture.get_image()
			check(not image.is_invisible(),entry.id+" nonempty "+field)
			check(image.get_pixel(0,0).a == 0 and image.get_pixel(int(size.x)-1,int(size.y)-1).a == 0,entry.id+" alpha margins "+field)
	for id in ["coins-small","coins-heap","coin-purse","coin-sack"]:
		var prop = load(DIR+id+".tscn").instantiate()
		root.add_child(prop)
		var sprite: Sprite3D = prop.get_node("Sprite")
		check(sprite.shaded and sprite.texture_filter == BaseMaterial3D.TEXTURE_FILTER_NEAREST,id+" lit nearest")
		check(sprite.billboard == BaseMaterial3D.BILLBOARD_FIXED_Y and sprite.alpha_cut == SpriteBase3D.ALPHA_CUT_DISCARD,id+" upright cutout")
		check(is_zero_approx(sprite.position.y+(64-120)*sprite.pixel_size),id+" floor registration")
		check(sprite.texture.get_size() == Vector2(128,128),id+" full plate canvas")
		check(prop.get_child_count() == 1,id+" visual only, no light or collider")
		prop.queue_free()
	var chest = load(DIR+"chest.tscn").instantiate()
	root.add_child(chest)
	var chest_sprite: AnimatedSprite3D = chest.get_node("Sprite")
	check(chest_sprite.shaded and chest_sprite.billboard == BaseMaterial3D.BILLBOARD_FIXED_Y,"Chest lit and upright")
	check(is_zero_approx(chest_sprite.position.y+(64-120)*chest_sprite.pixel_size),"Chest shared floor pivot")
	var before: Vector3 = chest.position
	for state in ["closed","open","empty"]:
		chest.set_state(state)
		check(chest_sprite.animation == StringName(state) and chest.position == before,"Chest swaps without moving "+state)
		check(not chest_sprite.is_playing() and chest_sprite.sprite_frames.get_frame_count(StringName(state)) == 1,"Chest static state "+state)
	check(chest_sprite.sprite_frames.get_frame_texture(&"closed",0) == load("res://art/props/tutorial-chest-v1/closed.png"),"Actual existing closed texture reused")
	check(chest_sprite.sprite_frames.get_frame_texture(&"empty",0) == load("res://art/props/tutorial-chest-v1/empty.png"),"Actual existing empty texture reused")
	chest.queue_free()
	await process_frame
	if "--capture" in OS.get_cmdline_user_args():
		await _inventory(catalog.assets)
		await _world()
	var report := {"godot":"4.7.2","checks":checks,"failures":failures,"captures":captures,
		"viewports":[[1280,720],[1278,590]],"icon_review_sizes":[64,40],"physical_phone_test":false,
		"scope":"Treasure art only; no loot quantities, prices, inventory/currency or room integration."}
	FileAccess.open(OUT+"godot-validation.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  ")+"\n")
	print("TREASURE_ART_CHECKS: ",checks," failures: ",failures.size()," captures: ",captures)
	quit(0 if failures.is_empty() else 1)

func _inventory(entries: Array) -> void:
	var canvas := Control.new()
	root.add_child(canvas)
	var background := ColorRect.new()
	canvas.add_child(background)
	var board := Control.new()
	canvas.add_child(board)
	var boxes: Array[Control] = []
	for i in entries.size():
		var x := (i%7)*126
		var y := floori(i/7.0)*184
		for small in [false,true]:
			var box := TextureRect.new()
			box.texture = load(entries[i].icon)
			box.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			box.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			box.position = Vector2(x+24,y+4) if not small else Vector2(x+36,y+80)
			box.size = Vector2(64,64) if not small else Vector2(40,40)
			board.add_child(box)
			boxes.append(box)
		var label := Label.new()
		label.text = entries[i].label.replace(" ","\n")
		label.position = Vector2(x,y+125)
		label.size = Vector2(112,55)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_override("font",FONT)
		label.add_theme_font_size_override("font_size",15)
		board.add_child(label)
	for phone in [false,true]:
		root.size = Vector2i(1278,590) if phone else Vector2i(1280,720)
		background.size = Vector2(root.size)
		# Native 64px and 40px display; no fractional canvas scaling.
		board.position = (Vector2(root.size)-Vector2(882,368))/2
		await process_frame
		var suffix := "phone" if phone else "desktop"
		for box in boxes:
			check(Rect2(Vector2(48,12),Vector2(root.size)-Vector2(96,24)).encloses(box.get_global_rect()),"Icon safe bounds "+suffix)
		for light in [false,true]:
			background.color = Color("d6cbb4") if light else Color("1b2420")
			for child in board.get_children():
				if child is Label:child.modulate = Color("262b27") if light else Color("e6dac1")
			await _capture("inventory-"+("light-" if light else "dark-")+suffix)
	canvas.queue_free()
	await process_frame

func _world() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var map = load("res://scripts/dungeon_map.gd").new(PackedStringArray(["#######","###.###","##,,,##","##,,,##","##,,,##","###S###","#######"]))
	var level = load("res://scripts/level_builder.gd").new()
	world.add_child(level)
	level.build(map,load("res://themes/cave.tres"),2.4,2.4)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color.BLACK
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("1a2424")
	env.ambient_light_energy = 0.4
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	world.add_child(world_env)
	var camera := Camera3D.new()
	camera.position = Vector3(7.2,1.2,12)
	camera.fov = 70
	world.add_child(camera)
	var lamp := OmniLight3D.new()
	lamp.position = camera.position+Vector3(0.3,-0.2,-0.4)
	lamp.light_color = Color("e8a84a")
	lamp.omni_range = 8.4
	world.add_child(lamp)
	var chest = load(DIR+"chest.tscn").instantiate()
	chest.position = Vector3(7.2,0,9.6)
	world.add_child(chest)
	var pickups := Node3D.new()
	world.add_child(pickups)
	var names := ["coins-small","coins-heap","coin-purse","coin-sack"]
	for i in names.size():
		var prop = load(DIR+names[i]+".tscn").instantiate()
		prop.position = Vector3(6.15+i*0.7,0,9.6)
		pickups.add_child(prop)
	for phone in [false,true]:
		root.size = Vector2i(1278,590) if phone else Vector2i(1280,720)
		var suffix := "phone" if phone else "desktop"
		chest.visible = true
		pickups.visible = false
		for state in ["closed","open","empty"]:
			chest.set_state(state)
			await _light_pair(lamp,"chest-"+state+"-"+suffix)
		chest.visible = false
		pickups.visible = true
		await _light_pair(lamp,"pickups-"+suffix)
	world.queue_free()
	await process_frame

func _light_pair(lamp: OmniLight3D, label: String) -> void:
	lamp.light_energy = 1.6
	var bright := await _capture(label)
	lamp.light_energy = 0.35
	var dim := await _capture(label+"-dim")
	check(_luminance(dim) < _luminance(bright),"Scene responds to dim light "+label)

func _luminance(image: Image) -> float:
	var total := 0.0
	for y in range(16,image.get_height(),32):
		for x in range(16,image.get_width(),32):total += image.get_pixel(x,y).get_luminance()
	return total

func _capture(label: String) -> Image:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	check(image.save_png(OUT+label+".png") == OK,"Capture "+label)
	captures += 1
	return image

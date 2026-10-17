extends SceneTree
## Isolated visual mockup for #13/#31. No combat gameplay is implemented here.
var gui: Control

func _initialize() -> void:
	call_deferred("_run")

func box(parent: Node3D, size: Vector3, position: Vector3, material: Material) -> void:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = material
	node.mesh = mesh
	node.position = position
	parent.add_child(node)

func label(parent: Node, text: String, font_size: int = 20) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", Color("e7dbc1"))
	parent.add_child(node)
	return node

func panel(parent: Node, color: Color = Color("18201d")) -> PanelContainer:
	var node := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color("655b40")
	style.set_border_width_all(1)
	style.set_content_margin_all(10)
	node.add_theme_stylebox_override("panel", style)
	parent.add_child(node)
	return node

func build_gui(width: int) -> void:
	if gui:
		gui.free()
	gui = Control.new()
	gui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(gui)
	var small := width < 1000
	var heading := label(gui,"CAVE · COMBAT CONCEPT",16 if small else 20)
	heading.position = Vector2(48 if small else 24,16)
	var turn := label(gui,"Mara's turn — choose a target",18 if small else 24)
	turn.position = Vector2(48 if small else 24,40)
	var target := panel(gui)
	target.position = Vector2(width - (252 if small else 228),22)
	label(target,"Selected: Goblin",18)
	var bottom := HBoxContainer.new()
	gui.add_child(bottom)
	bottom.anchor_top = 1
	bottom.anchor_bottom = 1
	bottom.anchor_right = 1
	bottom.offset_left = 48 if small else 24
	bottom.offset_right = -48 if small else -24
	bottom.offset_top = -146 if small else -182
	bottom.offset_bottom = -16
	bottom.add_theme_constant_override("separation", 12)
	var card := panel(bottom)
	var col := VBoxContainer.new()
	card.add_child(col)
	var portrait = load("res://scripts/portrait_view.gd").new()
	portrait.custom_minimum_size = Vector2(70,70) if small else Vector2(104,104)
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	col.add_child(portrait)
	portrait.show_portrait(load("res://data/portraits/mara.tres"))
	label(col,"Mara · 14/20",14 if small else 18)
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size.y = 6
	bar.value = 70
	col.add_child(bar)
	for i in 2:
		var empty := panel(bottom,Color("141a18"))
		empty.custom_minimum_size.x = 78 if small else 110
		empty.modulate.a = 0.55
		label(empty,"Empty\nslot",14 if small else 18).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(spacer)
	var choices := panel(bottom)
	var options := VBoxContainer.new()
	choices.add_child(options)
	label(options,"Action",18)
	var row := HBoxContainer.new()
	options.add_child(row)
	row.add_theme_constant_override("separation",8)
	for text in ["Attack", "Defend", "Item"]:
		var button := Button.new()
		button.text = text
		button.custom_minimum_size = Vector2(90,48) if small else Vector2(120,56)
		button.add_theme_font_size_override("font_size",18 if small else 22)
		row.add_child(button)
	label(options,"Rat · Spider · Goblin",14 if small else 16)
	label(options,"Layout study — example encounter",12 if small else 14)

func _run() -> void:
	root.size = Vector2i(1280,720)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.content_scale_factor = 1.0
	root.title = "Depths art review"
	var world := Node3D.new()
	root.add_child(world)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("101716")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("738478")
	environment.environment.ambient_light_energy = 0.3
	world.add_child(environment)
	var cave: EnvironmentTheme = load("res://themes/cave.tres")
	for x in [-2,0,2]:
		for z in [-2,0,2,4]:
			var ground := MeshInstance3D.new()
			var plane := PlaneMesh.new()
			plane.size = Vector2(2,2)
			plane.material = cave.floor_material
			ground.mesh = plane
			ground.position = Vector3(x,0,z)
			world.add_child(ground)
			var ceiling := MeshInstance3D.new()
			ceiling.mesh = plane.duplicate()
			ceiling.mesh.material = cave.ceiling_material
			ceiling.position = Vector3(x,2.4,z)
			ceiling.rotation.z = PI
			world.add_child(ceiling)
		box(world,Vector3(2,2.4,.25),Vector3(x,1.2,-3.2),cave.wall_material)
	for z in [-2,0,2,4]:
		box(world,Vector3(.25,2.4,2),Vector3(-3.1,1.2,z),cave.wall_material)
		box(world,Vector3(.25,2.4,2),Vector3(3.1,1.2,z),cave.wall_material)
	var camera := Camera3D.new()
	camera.position = Vector3(0,1.45,3.6)
	camera.fov = 70
	world.add_child(camera)
	camera.look_at(Vector3(0,.85,-1))
	var lantern := OmniLight3D.new()
	lantern.position = Vector3(-.4,1.7,3)
	lantern.light_color = Color("ffd29a")
	lantern.light_energy = 1.8
	lantern.omni_range = 12
	world.add_child(lantern)
	for entry in [["rat",Vector3(-1.1,0,1.1)],["spider",Vector3(0,0,.8)],["goblin",Vector3(1.0,0,0)]]:
		var enemy: Node3D = load("res://art/enemies/cave-v1/"+entry[0]+"/scene.tscn").instantiate()
		enemy.position = entry[1]
		world.add_child(enemy)
	build_gui(1280)
	await create_timer(0.8).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://art/expedition-v1/combat-desktop.png")
	root.size = Vector2i(844,390)
	camera.look_at(Vector3(0,-.65,-1))
	await process_frame
	build_gui(844)
	await create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://art/expedition-v1/combat-phone.png")
	print("ART_RENDER_REVIEW_SAVED")
	quit()

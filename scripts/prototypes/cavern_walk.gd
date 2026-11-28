extends Node3D
## Standalone Cavern walking study. Never loads Main, settings or a save.
const Terrain := preload("res://scripts/prototypes/cavern_height_map.gd")
const Walker := preload("res://scripts/prototypes/cavern_party.gd")
const RouteMap := preload("res://scripts/prototypes/cavern_route_map.gd")
const Ui := preload("res://scripts/ui_theme.gd")
const Brass := preload("res://art/ui/reliquary-brass-v1/style.gd")
const Safe := preload("res://scripts/safe_area.gd")
const ART := "res://art/props/cavern-rest-v1/"
const ACTIONS := ["move_forward", "move_back", "turn_left", "turn_right"]
@export var simulate_phone_safe_area := false
var terrain = Terrain.new()
var party
var world: Node3D
var ui: Control
var location: Label
var help: Label
var map_panel: PanelContainer
var route_map: Control
var menu: PanelContainer
var safe_rect: Rect2
var buttons: Dictionary = {}
var floor_body: StaticBody3D
var _stone := SurfaceTool.new()
var _wood := SurfaceTool.new()
var _builders: Array = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Ui.install()
	_install_actions()
	world = Node3D.new(); world.name = "World"; world.process_mode = Node.PROCESS_MODE_PAUSABLE; add_child(world)
	_build_terrain()
	_build_rift()
	party = Walker.new(); party.name = "Party"; world.add_child(party); party.setup(Terrain.TILE)
	party.move_time = 0.42; party.turn_time = 0.22
	party.camera.current = true; party.camera.near = 0.04; party.camera.far = 110
	_build_ui()
	party.moved.connect(_moved)
	party.entered_cell.connect(func(_c): _moved(party.cell, party.facing))
	party.place(terrain, terrain.arrival)
	get_viewport().size_changed.connect(_layout)
	_layout()

func _install_actions() -> void:
	var keys := [[KEY_W, KEY_UP], [KEY_S, KEY_DOWN], [KEY_A, KEY_LEFT], [KEY_D, KEY_RIGHT]]
	for i in ACTIONS.size():
		if InputMap.has_action(ACTIONS[i]): continue
		InputMap.add_action(ACTIONS[i])
		for key in keys[i]:
			var event := InputEventKey.new(); event.physical_keycode = key
			InputMap.action_add_event(ACTIONS[i], event)

func _quad(builder: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	var normal := (c-a).cross(b-a).normalized()
	for p in [a,b,c,a,c,d]:
		builder.set_normal(normal)
		builder.set_uv(Vector2(p.x,p.z) * .5 if absf(normal.y) > .6 else Vector2(p.x+p.z,p.y)*.5)
		builder.add_vertex(p)

func _slab(builder: SurfaceTool, points: Array[Vector3], depth: float) -> void:
	if builder == _wood:
		# Contiguous individual boards, with colour seams rather than holes in
		# the supporting deck. All planks/rails share one dark timber palette.
		var boards := maxi(1, ceili(points[0].distance_to(points[1])/.24))
		for i in boards:
			builder.set_color(Color("593b22") * (0.8+0.2*sin(points[0].x*19+i*7)))
			var a := points[0].lerp(points[1],float(i)/boards)
			var b := points[0].lerp(points[1],float(i+1)/boards)
			var c := points[3].lerp(points[2],float(i+1)/boards)
			var d := points[3].lerp(points[2],float(i)/boards)
			_quad(builder,a,b,c,d)
		builder.set_color(Color("402a19"))
	else:
		_quad(builder, points[0], points[1], points[2], points[3])
	for i in 4:
		var a := points[i]; var b := points[(i+1)%4]
		_quad(builder, b, a, a-Vector3.UP*depth, b-Vector3.UP*depth)
	_quad(builder, points[3]-Vector3.UP*depth, points[2]-Vector3.UP*depth, points[1]-Vector3.UP*depth, points[0]-Vector3.UP*depth)

func _build_terrain() -> void:
	_stone.begin(Mesh.PRIMITIVE_TRIANGLES); _wood.begin(Mesh.PRIMITIVE_TRIANGLES)
	_builders = [_stone, _wood]
	var pad := Terrain.HALF_PAD
	for cell: Vector2i in terrain.heights:
		var centre: Vector3 = terrain.world(cell)
		var builder: SurfaceTool = _wood if terrain.bridge_cells.has(cell) else _stone
		_slab(builder, [centre+Vector3(-pad,0,-pad), centre+Vector3(pad,0,-pad), centre+Vector3(pad,0,pad), centre+Vector3(-pad,0,pad)], .16 if builder == _wood else .65)
		for other: Vector2i in terrain.links[cell]:
			# Author every undirected connector exactly once.
			if other.y*10+other.x < cell.y*10+cell.x: continue
			var end: Vector3 = terrain.world(other)
			var along := (end-centre); along.y = 0; along = along.normalized()
			var across := Vector3(-along.z,0,along.x)*pad
			var a := centre+along*pad; var b := end-along*pad
			builder = _wood if terrain.bridge_cells.has(cell) or terrain.bridge_cells.has(other) else _stone
			var corners: Array[Vector3] = [a-across, b-across, b+across, a+across]
			# Consistent top winding whichever cardinal direction the edge takes.
			if (corners[2]-corners[0]).cross(corners[1]-corners[0]).y < 0: corners.reverse()
			_slab(builder, corners, .16 if builder == _wood else .65)
	var materials := [load(ART+"cavern-floor.tres"), load("res://art/materials/worked-props-v2/wood.tres")]
	floor_body = StaticBody3D.new(); floor_body.name = "WalkableFloor"; floor_body.collision_layer = 1; world.add_child(floor_body)
	for i in _builders.size():
		var mesh: ArrayMesh = _builders[i].commit()
		var view := MeshInstance3D.new(); view.name = "StonePath" if i == 0 else "BridgeDeck"
		view.mesh = mesh; view.material_override = materials[i]; view.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		world.add_child(view)
		var collider := CollisionShape3D.new(); collider.shape = mesh.create_trimesh_shape(); floor_body.add_child(collider)
	# Bridge rails and individual plank divisions sit outside the walking lane.
	var wood: Material = materials[1]
	for side in [-1,1]:
		_box("BridgeRail", Vector3(9, .8, 6+side*.74), Vector3(12,.09,.09), wood)
		for x in range(3,16,2): _box("RailPost", Vector3(x,.4,6+side*.74), Vector3(.1,.9,.1), wood)
	# Small iron bands break the long deck into readable boards, without coplanar tops.
	var iron: Material = load("res://art/materials/worked-props-v2/iron.tres")
	for x in range(3,16): _box("DeckBrace", Vector3(x,-.14,6), Vector3(.1,.13,1.45), iron)

func _box(label: String, at: Vector3, extent: Vector3, material: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new(); mesh.size = extent
	# Metre UVs prevent a 30m cliff from stretching a single texture pixel grid.
	var arrays := mesh.get_mesh_arrays()
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var uv := PackedVector2Array(); var colours := PackedColorArray()
	for i in vertices.size():
		var p := vertices[i]; var n := normals[i]
		uv.append(Vector2(p.x,p.z)*.5 if absf(n.y)>.5 else (Vector2(p.z,p.y)*.5 if absf(n.x)>.5 else Vector2(p.x,p.y)*.5))
		colours.append(Color("593b22") if label.begins_with("Bridge") or label == "RailPost" else Color("484c50"))
	arrays[Mesh.ARRAY_TEX_UV] = uv; arrays[Mesh.ARRAY_COLOR] = colours
	var mapped := ArrayMesh.new(); mapped.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	var node := MeshInstance3D.new(); node.name = label; node.mesh = mapped; node.material_override = material
	node.position = at; node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; world.add_child(node)
	return node

func _asset(path: String, at: Vector3, scale_by := Vector3.ONE, yaw := 0.0) -> Node3D:
	var node: Node3D = load(path).instantiate()
	node.position = at; node.scale = scale_by; node.rotation.y = yaw
	world.add_child(node)
	if node.has_method("set_motion"): node.set_motion(false)
	return node

func _build_rift() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR; env.background_color = Color("0a131a")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("8dabb8"); env.ambient_light_energy = .38
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true; env.fog_light_color = Color("152b36"); env.fog_light_energy = .6; env.fog_density = .012
	var atmosphere := WorldEnvironment.new(); atmosphere.environment = env; world.add_child(atmosphere)
	var rim := DirectionalLight3D.new(); rim.rotation_degrees = Vector3(-35,-25,0)
	rim.light_color = Color("9ab9c7"); rim.light_energy = .5; world.add_child(rim)
	var rock: Material = load(ART+"cavern-wall.tres")
	_box("WestCliff", Vector3(-.1,2,10), Vector3(1,30,22), rock)
	_box("EastCliff", Vector3(18.1,2,10), Vector3(1,30,22), rock)
	# A real opening at the endpoint, rather than an exit painting over rock.
	_box("NorthCliffLeft", Vector3(7.1,2,1), Vector3(15.4,30,1), rock)
	_box("NorthCliffRight", Vector3(17.9,2,1), Vector3(1.4,30,1), rock)
	_box("ExitLintel", Vector3(16,10.1,1), Vector3(2.4,13.8,1), rock)
	_box("ExitFoundation", Vector3(16,-6.5,1), Vector3(2.4,13,1), rock)
	_box("SouthCliff", Vector3(9,2,19.5), Vector3(19,30,1), rock)
	var bottom: Material = load(ART+"cavern-floor.tres")
	_box("DeepRock", Vector3(9,-12,10), Vector3(19,.6,20), bottom)
	_box("ExitFloor", Vector3(16,-.15,0), Vector3(2.4,.3,6.8), bottom)
	_box("ExitWest", Vector3(14.65,1.6,-.5), Vector3(.3,3.2,6), rock)
	_box("ExitEast", Vector3(17.35,1.6,-.5), Vector3(.3,3.2,6), rock)
	_box("ExitRoof", Vector3(16,3.35,-.5), Vector3(3,.3,6), rock)
	var dark := StandardMaterial3D.new(); dark.albedo_color = Color("071014"); dark.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_box("BeyondRestApproach", Vector3(16,1.6,-3.4), Vector3(3,3.2,.3), dark)
	# Fractured faces and formations use the delivered art's scoped materials.
	for z in [4,9,14,18]:
		_asset(ART+"wall-rib.tscn", Vector3(.45,1,z), Vector3(2,4,2), PI/2)
		_asset(ART+"wall-rib.tscn", Vector3(17.55,2,z), Vector3(2,5,2), -PI/2)
	for spec in [[5,-11,10], [12,-11,12], [6,-11,17], [12,-11,3]]:
		_asset(ART+"column-tall.tscn", Vector3(spec[0],spec[1],spec[2]), Vector3(1.2,3,1.2))
	for spec in [[4,15,4], [10,16,8], [14,15,14], [6,14,16]]:
		_asset(ART+"roof-pendant.tscn", Vector3(spec[0],spec[1],spec[2]), Vector3(2,3,2))
	_asset(ART+"goblin-daub.tscn", Vector3(.48,1.1,8), Vector3.ONE, PI/2)
	_asset(ART+"goblin-totem.tscn", terrain.world(Vector2i(8,8))+Vector3(.9,0,.65), Vector3.ONE)
	# Floor-supported plinths keep the three lanterns grounded off the route.
	for cell in [Vector2i(1,3), Vector2i(8,3), Vector2i(5,8)]:
		var offset := Vector3(-.95,0,0) if cell.x == 1 else (Vector3(.95,0,0) if cell.x == 8 else Vector3(0,0,.95))
		var at: Vector3 = terrain.world(cell)+offset
		_box("LampPlinth", at-Vector3(0,.3,0), Vector3(.65,.6,.65), bottom)
		_asset("res://art/dressing/mine-refined-v2/lantern-standing.tscn", at, Vector3.ONE)
		var lamp := OmniLight3D.new(); lamp.position = at+Vector3.UP*.7
		lamp.light_color = Color("ffbc6c"); lamp.light_energy = 1.8; lamp.omni_range = 6; world.add_child(lamp)
	# Keep this threshold's apron out of the authored walking floor.
	var throat := _asset(ART+"on-to-rest.tscn", terrain.world(terrain.destination)+Vector3(0,0,-1.3), Vector3.ONE)
	throat.get_node("DownwardExitLanding").hide()

func _build_ui() -> void:
	var layer := CanvasLayer.new(); layer.layer = 10; add_child(layer)
	ui = Control.new(); ui.name = "UI"; ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); ui.mouse_filter = Control.MOUSE_FILTER_IGNORE; layer.add_child(ui)
	var title := Label.new(); title.name = "Title"; title.text = "Cavern"; title.theme_type_variation = "PageTitle"; ui.add_child(title)
	location = Label.new(); location.name = "Location"; location.add_theme_font_size_override("font_size",16); ui.add_child(location)
	help = Label.new(); help.name = "Help"; help.text = "W / S  Move     A / D  Turn\nM  Map     Esc  Menu"; help.add_theme_font_size_override("font_size",16); ui.add_child(help)
	for label in [title,location,help]:
		label.add_theme_color_override("font_shadow_color",Color.BLACK)
		label.add_theme_constant_override("shadow_offset_x",1); label.add_theme_constant_override("shadow_offset_y",2)
	button("Map", "Map", func(): toggle_map())
	button("Menu", "☰", func(): toggle_menu())
	for spec in [["Forward","↑","move_forward"], ["Back","↓","move_back"], ["Left","↶","turn_left"], ["Right","↷","turn_right"]]:
		var b := button(spec[0], spec[1], Callable())
		b.tooltip_text = {"Forward":"Move forward", "Back":"Move backward", "Left":"Turn left", "Right":"Turn right"}[spec[0]]
		b.button_down.connect(func():
			if not menu.visible and not map_panel.visible: Input.action_press(spec[2]))
		b.button_up.connect(Input.action_release.bind(spec[2]))
		b.mouse_exited.connect(Input.action_release.bind(spec[2]))
	map_panel = PanelContainer.new(); map_panel.name = "Route"; map_panel.visible = false; ui.add_child(map_panel)
	var column := VBoxContainer.new(); column.add_theme_constant_override("separation",6); map_panel.add_child(column)
	var heading := Label.new(); heading.text = "Cavern · explored paths"; heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; column.add_child(heading)
	route_map = RouteMap.new(); route_map.terrain = terrain; route_map.party = party; route_map.size_flags_vertical = Control.SIZE_EXPAND_FILL; column.add_child(route_map)
	var legend := Label.new(); legend.text = "Stone · upper     Blue · lower     Timber · bridge"; legend.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; legend.add_theme_font_size_override("font_size",14); column.add_child(legend)
	var close := Button.new(); close.text = "Close map"; close.custom_minimum_size.y = 48; close.pressed.connect(toggle_map); column.add_child(close); buttons["CloseMap"] = close
	menu = PanelContainer.new(); menu.name = "Pause"; menu.visible = false; ui.add_child(menu)
	var choices := VBoxContainer.new(); choices.add_theme_constant_override("separation",8); menu.add_child(choices)
	var label := Label.new(); label.text = "Cavern walking study"; label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; choices.add_child(label)
	for spec in [["Continue",func(): toggle_menu()], ["Start again",func(): restart()], ["Quit prototype",func(): get_tree().quit()]]:
		var b := Button.new(); b.text = spec[0]; b.custom_minimum_size.y = 48; b.pressed.connect(spec[1]); choices.add_child(b); buttons[spec[0]] = b
	var note := Label.new(); note.text = "A standalone route. No expedition progress is saved."; note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; note.add_theme_font_size_override("font_size",14); choices.add_child(note)

func button(id: String, text: String, action: Callable) -> Button:
	var b := Button.new(); b.name = id; b.text = text; b.focus_mode = Control.FOCUS_NONE
	Brass.apply(b, Brass.Edge.CENTRE, 8)
	b.add_theme_font_size_override("font_size",24 if id != "Map" else 18)
	ui.add_child(b); buttons[id] = b
	if action.is_valid(): b.pressed.connect(action)
	return b

func _layout() -> void:
	var pixels := get_viewport().get_visible_rect().size
	# Keep readable 648-high UI proportions on Retina displays, while smaller
	# landscape windows retain at least 48 actual pixels per action.
	var ui_scale := maxf(1.0,pixels.y/648.0)
	ui.scale = Vector2.ONE*ui_scale
	var viewport := pixels/ui_scale
	var inset := Safe.insets(get_viewport(), simulate_phone_safe_area)
	# Simulated insets are specified for a 648px UI; this scene uses actual pixels.
	if simulate_phone_safe_area: inset *= pixels.y/648.0
	inset /= ui_scale
	safe_rect = Rect2(Vector2(inset.x+12,inset.y+10), viewport-Vector2(inset.x+inset.z+24,inset.y+inset.w+20))
	var small := viewport.y < 480
	var title: Label = ui.get_node("Title"); title.position = safe_rect.position; title.add_theme_font_size_override("font_size",24 if small else 30)
	location.position = safe_rect.position+Vector2(0,36 if small else 42); location.size.x = safe_rect.size.x-170; location.clip_text = true
	buttons.Map.position = Vector2(safe_rect.end.x-158,safe_rect.position.y); buttons.Map.size = Vector2(94,48)
	buttons.Menu.position = Vector2(safe_rect.end.x-56,safe_rect.position.y); buttons.Menu.size = Vector2(56,48)
	var unit := 52.0 if small else 62.0
	var pad := safe_rect.end-Vector2(unit*3+12,unit*2+6)
	for spec in [["Forward",1,0], ["Left",0,1], ["Back",1,1], ["Right",2,1]]:
		buttons[spec[0]].position = pad+Vector2(spec[1],spec[2])*(unit+6); buttons[spec[0]].size = Vector2.ONE*unit
	help.position = Vector2(safe_rect.position.x,safe_rect.end.y-54); help.visible = not small
	map_panel.position = safe_rect.position+Vector2((safe_rect.size.x-minf(460,safe_rect.size.x))*.5,0)
	map_panel.size = Vector2(minf(460,safe_rect.size.x),safe_rect.size.y)
	menu.size = Vector2(minf(350,safe_rect.size.x), 282); menu.position = safe_rect.get_center()-menu.size*.5

func release_controls() -> void:
	for action in ACTIONS: Input.action_release(action)

func toggle_map() -> void:
	if menu.visible: return
	release_controls(); map_panel.visible = not map_panel.visible; party.locked = map_panel.visible
	_modal_visibility()
	if map_panel.visible: route_map.queue_redraw(); buttons.CloseMap.grab_focus()

func toggle_menu() -> void:
	release_controls()
	if map_panel.visible: map_panel.hide()
	menu.visible = not menu.visible; party.locked = menu.visible
	_modal_visibility()
	get_tree().paused = menu.visible
	if menu.visible: buttons.Continue.grab_focus()

func _modal_visibility() -> void:
	var open := menu.visible or map_panel.visible
	for control in [ui.get_node("Title"),location,help,buttons.Map,buttons.Menu,buttons.Forward,buttons.Back,buttons.Left,buttons.Right]: control.visible = not open
	if not open: help.visible = get_viewport().get_visible_rect().size.y >= 480

func restart() -> void:
	release_controls(); get_tree().paused = false
	get_tree().reload_current_scene()

func _moved(c: Vector2i, facing: int) -> void:
	location.text = "%s · %s" % [terrain.place_name(c), ["North","East","South","West"][facing]]
	if is_instance_valid(route_map): route_map.queue_redraw()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	if event.physical_keycode == KEY_ESCAPE:
		if map_panel.visible: toggle_map()
		else: toggle_menu()
		get_viewport().set_input_as_handled()
	elif event.physical_keycode == KEY_M and not menu.visible:
		toggle_map(); get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT: release_controls()

func _exit_tree() -> void:
	release_controls(); get_tree().paused = false

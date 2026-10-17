extends Node3D
## Grid-movement prototype: generates a placeholder dungeon floor, places the
## party at the start, and adds the map and touch controls.

const DungeonMap := preload("res://scripts/dungeon_map.gd")
const Party := preload("res://scripts/party.gd")
const Minimap := preload("res://scripts/minimap.gd")
const FloorGenerator := preload("res://scripts/floor_generator.gd")

const CELL_SIZE := 2.0
const WALL_HEIGHT := 2.4

## Hand-drawn floor for debugging (see use_debug_layout).
## '#' wall, '.' floor, 'S' start. Rows must all be the same length.
const DEBUG_LAYOUT := [
	"############",
	"#S...#.....#",
	"#.##.#.###.#",
	"#.#..#...#.#",
	"#.#.####.#.#",
	"#...#....#.#",
	"###.#.####.#",
	"#.....#....#",
	"#.###.#.##.#",
	"#...#...#..#",
	"############",
]

## Action name -> keys. Registered at startup so the input map lives in code.
const KEY_BINDINGS := {
	"move_forward": [KEY_W, KEY_UP],
	"move_back": [KEY_S, KEY_DOWN],
	"turn_left": [KEY_A, KEY_LEFT],
	"turn_right": [KEY_D, KEY_RIGHT],
}

const TOUCH_BUTTON_SIZE := Vector2(88, 88)

## Seed for the generated floor; 0 picks a new random floor each run.
## Every run prints its seed, so a floor worth revisiting can be replayed.
@export var floor_seed := 0
## Use DEBUG_LAYOUT instead of generating a floor.
@export var use_debug_layout := false


func _ready() -> void:
	_register_input_actions()
	var map = DungeonMap.new(_make_layout())
	_build_environment()
	_build_floor(map)

	var minimap := Minimap.new()
	minimap.setup(map)
	var party := Party.new()
	party.moved.connect(minimap.on_party_moved)
	add_child(party)
	party.setup(map, CELL_SIZE)

	_build_ui(minimap)


func _make_layout() -> PackedStringArray:
	if use_debug_layout:
		return PackedStringArray(DEBUG_LAYOUT)
	var seed_value := floor_seed if floor_seed != 0 else randi()
	print("Floor seed: ", seed_value)
	return FloorGenerator.generate(seed_value)


func _register_input_actions() -> void:
	for action in KEY_BINDINGS:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		for key in KEY_BINDINGS[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action, event)


func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color.BLACK
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("1a2424")
	env.ambient_light_energy = 0.4
	env.fog_enabled = true
	env.fog_light_color = Color.BLACK
	env.fog_density = 0.08
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)


func _build_floor(map) -> void:
	var stone := StandardMaterial3D.new()
	stone.albedo_color = Color("4a4640")
	stone.roughness = 1.0
	var ground := StandardMaterial3D.new()
	ground.albedo_color = Color("5a4232")
	ground.roughness = 1.0

	var wall_mesh := BoxMesh.new()
	wall_mesh.size = Vector3(CELL_SIZE, WALL_HEIGHT, CELL_SIZE)
	wall_mesh.material = stone
	var tile_mesh := PlaneMesh.new()
	tile_mesh.size = Vector2(CELL_SIZE, CELL_SIZE)
	tile_mesh.material = ground
	var ceiling_mesh := PlaneMesh.new()
	ceiling_mesh.size = Vector2(CELL_SIZE, CELL_SIZE)
	ceiling_mesh.flip_faces = true
	ceiling_mesh.material = stone

	for y in map.height:
		for x in map.width:
			var cell := Vector2i(x, y)
			var at := Vector3(x * CELL_SIZE, 0.0, y * CELL_SIZE)
			if map.is_wall(cell):
				if map.is_exposed_wall(cell):
					_add_mesh(wall_mesh, at + Vector3(0, WALL_HEIGHT / 2.0, 0))
			else:
				_add_mesh(tile_mesh, at)
				_add_mesh(ceiling_mesh, at + Vector3(0, WALL_HEIGHT, 0))


func _add_mesh(mesh: Mesh, at: Vector3) -> void:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = at
	add_child(instance)


func _build_ui(minimap: Control) -> void:
	var ui := CanvasLayer.new()
	add_child(ui)

	var map_corner := MarginContainer.new()
	map_corner.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	map_corner.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_set_margins(map_corner, 16)
	map_corner.add_child(minimap)
	ui.add_child(map_corner)

	# Touch pad:   [ ↺ ] [ ▲ ] [ ↻ ]
	#                    [ ▼ ]
	var pad_corner := MarginContainer.new()
	pad_corner.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	pad_corner.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	pad_corner.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_set_margins(pad_corner, 24)
	var pad := GridContainer.new()
	pad.columns = 3
	for spec in [["↺", "turn_left"], ["▲", "move_forward"], ["↻", "turn_right"],
			["", ""], ["▼", "move_back"], ["", ""]]:
		pad.add_child(_make_touch_button(spec[0], spec[1]))
	pad_corner.add_child(pad)
	ui.add_child(pad_corner)


## Holding the button holds the action, exactly like holding the key.
func _make_touch_button(label: String, action: String) -> Control:
	if action.is_empty():
		var spacer := Control.new()
		spacer.custom_minimum_size = TOUCH_BUTTON_SIZE
		spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return spacer
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = TOUCH_BUTTON_SIZE
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 36)
	button.modulate.a = 0.75
	button.button_down.connect(Input.action_press.bind(action))
	button.button_up.connect(Input.action_release.bind(action))
	return button


func _set_margins(container: MarginContainer, pixels: int) -> void:
	for side in ["left", "top", "right", "bottom"]:
		container.add_theme_constant_override("margin_" + side, pixels)

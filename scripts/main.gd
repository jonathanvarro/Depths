extends Node3D
## Grid-movement prototype: generates a placeholder dungeon floor, places the
## party at the start, and adds the map and touch controls.

const DungeonMap := preload("res://scripts/dungeon_map.gd")
const Party := preload("res://scripts/party.gd")
const Minimap := preload("res://scripts/minimap.gd")
const FloorGenerator := preload("res://scripts/floor_generator.gd")
const STONE_WALL := preload("res://art/textures/stone-v1/wall_plain.tres")
const WORN_WALL := preload("res://art/textures/stone-v1/wall_worn.tres")
const STONE_FLOOR := preload("res://art/textures/stone-v1/floor.tres")
const STONE_CEILING := preload("res://art/textures/stone-v1/ceiling.tres")

const CELL_SIZE := 2.0
const WALL_HEIGHT := 2.4

## Hand-drawn floor for debugging (see use_debug_layout).
## '#' wall, '.' floor, 'S' start, other letters are contents (see
## dungeon_map.gd). Rows must all be the same length.
const DEBUG_LAYOUT := [
	"############",
	"#S.C.#..E..#",
	"#.##.#.###.#",
	"#.#..#...#.#",
	"#.#.####.#.#",
	"#...#....#.#",
	"###.#.####.#",
	"#..T..#..R.#",
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
	"toggle_debug": [KEY_F3],
}

const TOUCH_BUTTON_SIZE := Vector2(88, 88)
const MESSAGE_SECONDS := 2.0

## Seed for the generated floor; 0 picks a new random floor each run.
## Every run prints its seed, so a floor worth revisiting can be replayed.
@export var floor_seed := 0
## Use DEBUG_LAYOUT instead of generating a floor.
@export var use_debug_layout := false
## Start with the debug overlay on (F3 toggles it while playing).
@export var show_debug := false

var _map  # dungeon_map.gd
var _seed_text := "debug layout"
var _minimap: Control
var _debug_label: Label
var _message_label: Label
var _message_tween: Tween


func _ready() -> void:
	_register_input_actions()
	var map = DungeonMap.new(_make_layout())
	_map = map
	_build_environment()
	_build_floor(map)

	_minimap = Minimap.new()
	_minimap.setup(map)
	_build_ui(_minimap)
	var party := Party.new()
	party.moved.connect(_minimap.on_party_moved)
	party.moved.connect(_on_party_moved)
	party.entered_cell.connect(_on_party_entered_cell)
	add_child(party)
	party.setup(map, CELL_SIZE)
	_set_debug(show_debug)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_debug"):
		_set_debug(not _debug_label.visible)


## Placeholder for real encounters: for now each content just announces itself.
func _on_party_entered_cell(cell: Vector2i) -> void:
	var content: int = _map.enter(cell)
	if content == DungeonMap.Content.NONE:
		return
	var content_text := DungeonMap.content_name(content)
	print("Entered %s at %s" % [content_text, cell])
	_show_message(content_text)


func _on_party_moved(cell: Vector2i, facing: int) -> void:
	var content: int = _map.content_at(cell)
	var state := ""
	if content != DungeonMap.Content.NONE:
		state = " (used)" if _map.triggered.has(cell) else ""
	_debug_label.text = "Seed: %s
Cell: %s  Facing: %s
Here: %s%s
Contents on floor: %d" % [
		_seed_text, cell, ["N", "E", "S", "W"][facing],
		DungeonMap.content_name(content), state, _map.contents.size()]


func _set_debug(enabled: bool) -> void:
	_debug_label.visible = enabled
	_minimap.reveal_all = enabled


func _show_message(text: String) -> void:
	if _message_tween:
		_message_tween.kill()
	_message_label.text = text
	_message_label.modulate.a = 1.0
	_message_tween = create_tween()
	_message_tween.tween_interval(MESSAGE_SECONDS)
	_message_tween.tween_property(_message_label, "modulate:a", 0.0, 0.5)


func _make_layout() -> PackedStringArray:
	if use_debug_layout:
		return PackedStringArray(DEBUG_LAYOUT)
	var seed_value := floor_seed if floor_seed != 0 else randi()
	_seed_text = str(seed_value)
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
	var wall_mesh := BoxMesh.new()
	wall_mesh.size = Vector3(CELL_SIZE, WALL_HEIGHT, CELL_SIZE)
	wall_mesh.material = STONE_WALL
	var worn_wall_mesh := BoxMesh.new()
	worn_wall_mesh.size = wall_mesh.size
	worn_wall_mesh.material = WORN_WALL
	var tile_mesh := PlaneMesh.new()
	tile_mesh.size = Vector2(CELL_SIZE, CELL_SIZE)
	tile_mesh.material = STONE_FLOOR
	var ceiling_mesh := PlaneMesh.new()
	ceiling_mesh.size = Vector2(CELL_SIZE, CELL_SIZE)
	ceiling_mesh.flip_faces = true
	ceiling_mesh.material = STONE_CEILING

	for y in map.height:
		for x in map.width:
			var cell := Vector2i(x, y)
			var at := Vector3(x * CELL_SIZE, 0.0, y * CELL_SIZE)
			if map.is_wall(cell):
				if map.is_exposed_wall(cell):
					# Stable variation without consuming the floor generator's RNG.
					var mesh := worn_wall_mesh if (x * 7 + y * 11) % 5 == 0 else wall_mesh
					_add_mesh(mesh, at + Vector3(0, WALL_HEIGHT / 2.0, 0))
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

	_debug_label = Label.new()
	_debug_label.position = Vector2(16, 16)
	_debug_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	ui.add_child(_debug_label)

	_message_label = Label.new()
	_message_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_message_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_message_label.position.y = 48
	_message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message_label.add_theme_font_size_override("font_size", 32)
	_message_label.add_theme_color_override("font_color", Color("e8d9b0"))
	_message_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	_message_label.modulate.a = 0.0
	ui.add_child(_message_label)

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

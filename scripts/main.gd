extends Node3D
## Exploration prototype: generates the floors of one site, dressed by an
## environment theme, and handles moving between them, plus the map, touch
## controls, messages, and debug overlay.

const DungeonMap := preload("res://scripts/dungeon_map.gd")
const Party := preload("res://scripts/party.gd")
const Minimap := preload("res://scripts/minimap.gd")
const FloorGenerator := preload("res://scripts/floor_generator.gd")
const LevelBuilder := preload("res://scripts/level_builder.gd")

const CELL_SIZE := 2.0
const WALL_HEIGHT := 2.4
## Mixed into the site seed so each floor of a site gets its own layout.
const FLOOR_SEED_STEP := 7919

## Hand-drawn first floor for debugging (see use_debug_layout).
## '#' wall, '.' floor, 'S' start, 'D' closed passage, 'B' blocked passage,
## other letters are contents (see dungeon_map.gd). Rows must all be the
## same length.
const DEBUG_LAYOUT := [
	"############",
	"#S.C.#..E..#",
	"#D##B#.###.#",
	"#.#..#...#.#",
	"#.#.####.#.#",
	"#...#....#.#",
	"###.#.####.#",
	"#..T..#..R.#",
	"#.###.#.##.#",
	"#...#...#.>#",
	"############",
]

## Action name -> keys. Registered at startup so the input map lives in code.
const KEY_BINDINGS := {
	"move_forward": [KEY_W, KEY_UP],
	"move_back": [KEY_S, KEY_DOWN],
	"turn_left": [KEY_A, KEY_LEFT],
	"turn_right": [KEY_D, KEY_RIGHT],
	"toggle_debug": [KEY_F3],
	"toggle_map": [KEY_M, KEY_TAB],
}

const TOUCH_BUTTON_SIZE := Vector2(88, 88)
const MESSAGE_SECONDS := 2.0

## Seed for the site; 0 picks a new random site each run. The first floor
## uses this seed directly; deeper floors derive theirs from it. Every run
## prints its seed, so a site worth revisiting can be replayed.
@export var floor_seed := 0
## Use DEBUG_LAYOUT for the first floor instead of generating it.
@export var use_debug_layout := false
## Start with the debug overlay on (F3 toggles it while playing).
@export var show_debug := false
## How the site looks and what its features are called.
@export var environment_theme: EnvironmentTheme = preload("res://themes/cave.tres")
## Floors in this site; the deepest has no way further down.
@export var floors_in_site := 3

var _site_seed := 0
var _depth := 0
var _floors := {}  # depth -> dungeon_map.gd, kept so revisited floors remember their state
var _map  # dungeon_map.gd for the current floor
var _level: Node3D
var _party: Node3D
var _minimap: Control
var _full_map: Control  # full-screen overlay
var _full_map_view: Control
var _full_map_title: Label
var _debug_label: Label
var _message_label: Label
var _message_tween: Tween
var _prompt: Control
var _prompt_label: Label
var _prompt_action := Callable()


func _ready() -> void:
	_register_input_actions()
	_build_environment()
	_site_seed = floor_seed if floor_seed != 0 else randi()
	print("Floor seed: ", _site_seed)

	_minimap = Minimap.new()
	_build_ui(_minimap)
	_party = Party.new()
	_party.moved.connect(_minimap.on_party_moved)
	_party.moved.connect(_full_map_view.on_party_moved)
	_party.moved.connect(_on_party_moved)
	_party.entered_cell.connect(_on_party_entered_cell)
	_party.opened_door.connect(_on_party_opened_door)
	_party.blocked_by.connect(_on_party_blocked)
	add_child(_party)
	_party.setup(CELL_SIZE)
	_go_to_floor(1, true)
	_set_debug(show_debug)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_debug"):
		_set_debug(not _debug_label.visible)
	elif event.is_action_pressed("toggle_map"):
		_set_full_map(not _full_map.visible)
	elif _full_map.visible and event.is_action_pressed("ui_cancel"):
		_set_full_map(false)
	elif _prompt.visible and event.is_action_pressed("ui_accept"):
		_answer_prompt(true)
	elif _prompt.visible and event.is_action_pressed("ui_cancel"):
		_answer_prompt(false)


## Builds (or returns to) a floor. Arriving from above puts the party at the
## way up; arriving from below puts it at the way down.
func _go_to_floor(depth: int, from_above: bool) -> void:
	_depth = depth
	if not _floors.has(depth):
		_floors[depth] = DungeonMap.new(_make_layout(depth), depth)
	_map = _floors[depth]

	if _level:
		_level.queue_free()
	_level = LevelBuilder.new()
	_level.build(_map, environment_theme, CELL_SIZE, WALL_HEIGHT)
	add_child(_level)

	_minimap.setup(_map)
	_full_map_view.setup(_map)
	var arrival: Vector2i = _map.start_cell if from_above else _map.find_content(DungeonMap.Content.STAIRS_DOWN)
	_party.place(_map, arrival)
	_show_message("%s · depth %d" % [environment_theme.display_name, depth])


func _make_layout(depth: int) -> PackedStringArray:
	if use_debug_layout and depth == 1:
		return PackedStringArray(DEBUG_LAYOUT)
	return FloorGenerator.generate(_site_seed + (depth - 1) * FLOOR_SEED_STEP, depth < floors_in_site)


func _on_party_entered_cell(cell: Vector2i) -> void:
	var content: int = _map.enter(cell)
	match content:
		DungeonMap.Content.NONE:
			return
		DungeonMap.Content.STAIRS_DOWN:
			_ask(environment_theme.descent_prompt, _go_to_floor.bind(_depth + 1, true))
		DungeonMap.Content.STAIRS_UP:
			if _depth == 1:
				_show_message(environment_theme.exit_message)  # campsite comes later
			else:
				_ask(environment_theme.ascent_prompt, _go_to_floor.bind(_depth - 1, false))
		_:
			# Placeholder for real encounters: for now contents just announce themselves.
			var content_text := DungeonMap.content_name(content)
			print("Entered %s at %s" % [content_text, cell])
			_show_message(content_text)


func _on_party_opened_door(cell: Vector2i) -> void:
	_level.refresh_door(cell)
	_show_message(environment_theme.closed_open_message)


func _on_party_blocked(_cell: Vector2i) -> void:
	_show_message(environment_theme.blocked_message)


func _on_party_moved(cell: Vector2i, facing: int) -> void:
	var content: int = _map.content_at(cell)
	var state := ""
	if content != DungeonMap.Content.NONE:
		state = " (used)" if _map.triggered.has(cell) else ""
	var seed_text: String = "debug layout" if use_debug_layout and _depth == 1 else str(_site_seed)
	_debug_label.text = "Seed: %s  Depth: %d/%d\nCell: %s  Facing: %s\nHere: %s%s\nContents on floor: %d  Passages: %d" % [
		seed_text, _depth, floors_in_site, cell, ["N", "E", "S", "W"][facing],
		DungeonMap.content_name(content), state, _map.contents.size(), _map.doors.size()]


## Shows a yes/no question; `on_yes` runs if the player agrees.
func _ask(question: String, on_yes: Callable) -> void:
	_prompt_label.text = question
	_prompt_action = on_yes
	_prompt.visible = true
	_party.locked = true


func _answer_prompt(yes: bool) -> void:
	_prompt.visible = false
	_party.locked = false
	var action := _prompt_action
	_prompt_action = Callable()
	if yes and action.is_valid():
		action.call()


func _set_debug(enabled: bool) -> void:
	_debug_label.visible = enabled
	_minimap.reveal_all = enabled
	_full_map_view.reveal_all = enabled


## Opens or closes the full-screen map. The party can't move while it's open,
## and it can't open over a yes/no prompt.
func _set_full_map(open: bool) -> void:
	if open and _prompt.visible:
		return
	_full_map.visible = open
	_party.locked = open
	if open:
		_full_map_title.text = "%s · depth %d of %d" % [environment_theme.display_name, _depth, floors_in_site]


func _show_message(text: String) -> void:
	if _message_tween:
		_message_tween.kill()
	_message_label.text = text
	_message_label.modulate.a = 1.0
	_message_tween = create_tween()
	_message_tween.tween_interval(MESSAGE_SECONDS)
	_message_tween.tween_property(_message_label, "modulate:a", 0.0, 0.5)


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

	_build_prompt(ui)
	_build_full_map(ui)
	minimap.pressed.connect(_set_full_map.bind(true))


## Full-screen map: title, the explored floor scaled to fit, and a legend in
## the environment's own words. Tapping anywhere closes it.
func _build_full_map(ui: CanvasLayer) -> void:
	_full_map = Control.new()
	_full_map.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_full_map.mouse_filter = Control.MOUSE_FILTER_STOP
	_full_map.gui_input.connect(func(event: InputEvent):
		if (event is InputEventMouseButton and event.pressed) or (event is InputEventScreenTouch and event.pressed):
			_set_full_map(false))
	ui.add_child(_full_map)

	var shade := ColorRect.new()
	shade.color = Color(0.03, 0.03, 0.03, 0.94)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_full_map.add_child(shade)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_margins(margin, 24)
	_full_map.add_child(margin)
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)

	_full_map_title = Label.new()
	_full_map_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_full_map_title.add_theme_font_size_override("font_size", 28)
	_full_map_title.add_theme_color_override("font_color", Color("e8d9b0"))
	column.add_child(_full_map_title)

	_full_map_view = Minimap.new()
	_full_map_view.full_view = true
	_full_map_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_full_map_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(_full_map_view)

	var legend := HFlowContainer.new()
	legend.alignment = FlowContainer.ALIGNMENT_CENTER
	legend.mouse_filter = Control.MOUSE_FILTER_IGNORE
	legend.add_theme_constant_override("h_separation", 20)
	column.add_child(legend)
	var t := environment_theme
	var c := Minimap.CONTENT_COLORS
	for entry in [
			["You", Minimap.COLOR_PARTY], [t.closed_name, Minimap.COLOR_CLOSED_PASSAGE],
			[t.blocked_name, Minimap.COLOR_BLOCKED_PASSAGE], [t.descent_name + " / " + t.ascent_name, c[6]],
			["Encounter", c[1]], ["Chest", c[2]], ["Trap", c[3]], ["Strange object", c[4]], ["Rest spot", c[5]]]:
		legend.add_child(_legend_item(entry[0], entry[1]))

	var hint := Label.new()
	hint.text = "Tap anywhere or press M to close"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.5))
	column.add_child(hint)
	_full_map.visible = false


func _legend_item(text: String, color: Color) -> Control:
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var swatch := ColorRect.new()
	swatch.color = color
	swatch.custom_minimum_size = Vector2(14, 14)
	swatch.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	swatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(swatch)
	var label := Label.new()
	label.text = text
	row.add_child(label)
	return row


## Centred yes/no box for deliberate choices like descending. Big buttons
## for touch; Enter/Escape also answer.
func _build_prompt(ui: CanvasLayer) -> void:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(center)

	var panel := PanelContainer.new()
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	panel.add_child(box)
	_prompt_label = Label.new()
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_label.add_theme_font_size_override("font_size", 28)
	box.add_child(_prompt_label)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 24)
	box.add_child(buttons)
	for spec in [["Go", true], ["Stay", false]]:
		var button := Button.new()
		button.text = spec[0]
		button.custom_minimum_size = Vector2(140, 72)
		button.focus_mode = Control.FOCUS_NONE
		button.add_theme_font_size_override("font_size", 28)
		button.pressed.connect(_answer_prompt.bind(spec[1]))
		buttons.add_child(button)
	_prompt = center
	_prompt.visible = false


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

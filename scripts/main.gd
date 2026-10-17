extends Node3D
## Exploration prototype: generates the floors of one site, dressed by an
## environment theme, and handles moving between them, plus the map, touch
## controls, messages, and debug overlay.

const DungeonMap := preload("res://scripts/dungeon_map.gd")
const Party := preload("res://scripts/party.gd")
const Minimap := preload("res://scripts/minimap.gd")
const FloorGenerator := preload("res://scripts/floor_generator.gd")
const LevelBuilder := preload("res://scripts/level_builder.gd")
const PartyState := preload("res://scripts/party_state.gd")
const PartyCard := preload("res://scripts/party_card.gd")
const PackScreen := preload("res://scripts/pack_screen.gd")
const Supplies := preload("res://scripts/supplies.gd")

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
	"toggle_pack": [KEY_I, KEY_B],
	"debug_hurt": [KEY_H],  # only while the F3 overlay is open
	"debug_heal": [KEY_J],
	"debug_injure": [KEY_K],
}

const TOUCH_BUTTON_SIZE := Vector2(88, 88)
const MESSAGE_SECONDS := 2.0
const AMBIENCE_VOLUME_DB := -10.0
const FOOTSTEP_VOLUME_DB := -6.0
const EFFECT_VOLUME_DB := -4.0

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
## The lone survivor the game starts with; the other two slots fill later.
@export var starting_hero: Companion = preload("res://data/companions/mara.tres")
## What the survivor carries at the start. Amounts follow ChatGPT's economy
## research (docs/starter-cave-economy-research.md); tune freely.
@export var starting_supplies: Dictionary[SupplyItem, int] = {
	preload("res://data/items/oil_flask.tres"): 3,
	preload("res://data/items/ration.tres"): 2,
	preload("res://data/items/restorative_draught.tres"): 1,
	preload("res://data/items/dressing.tres"): 2,
}
## Injuries a trap can cause (#11); one is picked at random.
@export var trap_injuries: Array[Injury] = [
	preload("res://data/injuries/deep_wound.tres"),
	preload("res://data/injuries/limp.tres"),
]
## Trap damage, and the chance it also leaves a lasting injury.
@export var trap_damage := 3
@export_range(0.0, 1.0) var trap_injury_chance := 0.5
## Shown as the game opens on the deepest floor, where the companions died.
@export_multiline var opening_message := "Your companions lie still. Find the way out."

## Where the party appears on a floor.
enum Arrival { OPENING, FROM_ABOVE, FROM_BELOW }
## Pretend to be a modern iPhone in landscape (camera cutout on both sides,
## home bar at the bottom) to check the HUD stays clear of them on Windows.
@export var simulate_phone_safe_area := false

## iPhone 15 landscape safe-area insets (59pt sides, 21pt bottom) in this
## game's 648px-tall UI space: left, top, right, bottom.
const SIMULATED_PHONE_INSETS := Vector4(97, 0, 97, 35)

var _site_seed := 0
var _party_state  # party_state.gd: heroes and time, kept across floors
var _cards: Array[PanelContainer] = []  # party_card.gd, one per slot
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
var _prompt_no_action := Callable()
var _pack: Control  # pack_screen.gd
var _safe_area: Control  # HUD lives in here, clear of notches and home bars
var _full_map_margin: MarginContainer
var _ambience_player: AudioStreamPlayer
var _footstep_player: AudioStreamPlayer
var _effect_player: AudioStreamPlayer


func _ready() -> void:
	_register_input_actions()
	_build_environment()
	_site_seed = floor_seed if floor_seed != 0 else randi()
	print("Floor seed: ", _site_seed)
	_party_state = PartyState.new()
	_party_state.add_member(starting_hero)
	for item in starting_supplies:
		_party_state.supplies.add(item, starting_supplies[item])

	_minimap = Minimap.new()
	_build_ui(_minimap)
	_party = Party.new()
	_party.moved.connect(_minimap.on_party_moved)
	_party.moved.connect(_full_map_view.on_party_moved)
	_party.moved.connect(_on_party_moved)
	_party.entered_cell.connect(_on_party_entered_cell)
	_party.opened_door.connect(_on_party_opened_door)
	_party.blocked_by.connect(_on_party_blocked)
	_build_audio()
	_party.stepped.connect(func(_cell): _footstep_player.play())
	_party.stepped.connect(func(_cell): _party_state.advance_time(_party_state.step_time()))
	_party.bumped.connect(func(_cell): _play_effect(environment_theme.bump_sound))
	add_child(_party)
	_party.setup(CELL_SIZE)
	_party_state.supplies.changed.connect(_update_lantern)
	_party_state.supplies.light_band_changed.connect(_on_light_band_changed)
	_update_lantern()
	# The survivor wakes on the deepest floor and climbs out (#8). The debug
	# layout is a single hand-drawn floor, so it starts there instead.
	_go_to_floor(1 if use_debug_layout else floors_in_site, Arrival.OPENING)
	_set_debug(show_debug)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_debug"):
		_set_debug(not _debug_label.visible)
	elif _debug_label.visible and event.is_action_pressed("debug_hurt") and not _party_state.members.is_empty():
		_party_state.members[0].change_health(-3)
	elif _debug_label.visible and event.is_action_pressed("debug_heal") and not _party_state.members.is_empty():
		_party_state.members[0].add_effect_over_time("health", 6, 12)
	elif _debug_label.visible and event.is_action_pressed("debug_injure") and not _party_state.members.is_empty():
		_party_state.members[0].add_injury(trap_injuries.pick_random())
	elif event.is_action_pressed("toggle_map"):
		_set_full_map(not _full_map.visible)
	elif _full_map.visible and event.is_action_pressed("ui_cancel"):
		_set_full_map(false)
	elif event.is_action_pressed("toggle_pack"):
		_set_pack(not _pack.visible)
	elif _pack.visible and event.is_action_pressed("ui_cancel"):
		_set_pack(false)
	elif _prompt.visible and event.is_action_pressed("ui_accept"):
		_answer_prompt(true)
	elif _prompt.visible and event.is_action_pressed("ui_cancel"):
		_answer_prompt(false)


## Builds (or returns to) a floor. Arriving from above puts the party at the
## way up; arriving from below puts it at the way down; the opening uses the
## floor's start cell.
func _go_to_floor(depth: int, arrival: Arrival) -> void:
	if _depth != 0:
		_party_state.complete_pending_effects()  # owner rule (#8): durations finish between floors
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
	var cell: Vector2i = _map.start_cell
	if arrival == Arrival.FROM_ABOVE:
		cell = _map.find_content(DungeonMap.Content.STAIRS_UP)
	elif arrival == Arrival.FROM_BELOW:
		cell = _map.find_content(DungeonMap.Content.STAIRS_DOWN)
	_party.place(_map, cell)
	if arrival == Arrival.OPENING and not use_debug_layout:
		_show_message(opening_message)
	else:
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
			_ask(environment_theme.descent_prompt, _go_to_floor.bind(_depth + 1, Arrival.FROM_ABOVE))
		DungeonMap.Content.TRAP:
			_spring_trap()
		DungeonMap.Content.REST_SPOT:
			# Each rest spot can be used once; saying no keeps it for later.
			_ask("A sheltered spot. Rest here? (%d time)" % PartyState.REST_TIME, _rest,
					func(): _map.triggered.erase(cell))
		DungeonMap.Content.STAIRS_UP:
			if _depth == 1:
				_show_message(environment_theme.exit_message)  # campsite comes later
			else:
				_ask(environment_theme.ascent_prompt, _go_to_floor.bind(_depth - 1, Arrival.FROM_BELOW))
		_:
			# Placeholder for real encounters: for now contents just announce themselves.
			var content_text := DungeonMap.content_name(content)
			print("Entered %s at %s" % [content_text, cell])
			_show_message(content_text)


## Placeholder trap until room encounters (#16) add clues and choices:
## it hurts someone and may leave a lasting injury.
func _spring_trap() -> void:
	var victims: Array[Companion] = _party_state.living_members()
	if victims.is_empty():
		return
	var victim: Companion = victims.pick_random()
	victim.change_health(-trap_damage)
	var text := "A trap! %s is hurt." % victim.display_name
	if not trap_injuries.is_empty() and randf() < trap_injury_chance:
		var injury: Injury = trap_injuries.pick_random()
		if victim.add_injury(injury):
			text = "A trap! %s suffers a %s." % [victim.display_name, injury.display_name.to_lower()]
	_play_effect(environment_theme.bump_sound)
	_show_message(text)


func _rest() -> void:
	_party_state.rest()
	_show_message("You rest. Food and remedies take full effect.")


func _update_lantern() -> void:
	_party.set_light(_party_state.supplies.light_fraction())


func _on_light_band_changed(band: Supplies.Light) -> void:
	match band:
		Supplies.Light.DIM:
			_show_message("The lantern burns low.")
		Supplies.Light.OUT:
			_show_message("The lantern gutters out. Only a faint glow remains.")


func _on_party_opened_door(cell: Vector2i) -> void:
	_level.refresh_door(cell)
	_play_effect(environment_theme.open_sound)
	_show_message(environment_theme.closed_open_message)


func _on_party_blocked(_cell: Vector2i) -> void:
	_show_message(environment_theme.blocked_message)


func _on_party_moved(cell: Vector2i, facing: int) -> void:
	var content: int = _map.content_at(cell)
	var state := ""
	if content != DungeonMap.Content.NONE:
		state = " (used)" if _map.triggered.has(cell) else ""
	var seed_text: String = "debug layout" if use_debug_layout and _depth == 1 else str(_site_seed)
	_debug_label.text = "Seed: %s  Depth: %d/%d\nCell: %s  Facing: %s\nHere: %s%s\nContents on floor: %d  Passages: %d\nParty: %s\nTime: %d  Oil: %.1f (%s)" % [
		seed_text, _depth, floors_in_site, cell, ["N", "E", "S", "W"][facing],
		DungeonMap.content_name(content), state, _map.contents.size(), _map.doors.size(),
		_party_state.summary(), _party_state.time_elapsed, _party_state.supplies.oil,
		Supplies.LIGHT_NAMES[_party_state.supplies.light_band()]]


## Shows a yes/no question; `on_yes` runs if the player agrees, `on_no` if not.
func _ask(question: String, on_yes: Callable, on_no := Callable()) -> void:
	_prompt_label.text = question
	_prompt_action = on_yes
	_prompt_no_action = on_no
	_prompt.visible = true
	_party.locked = true


func _answer_prompt(yes: bool) -> void:
	_prompt.visible = false
	_party.locked = false
	var action := _prompt_action if yes else _prompt_no_action
	_prompt_action = Callable()
	_prompt_no_action = Callable()
	if action.is_valid():
		action.call()


func _set_debug(enabled: bool) -> void:
	_debug_label.visible = enabled
	_minimap.reveal_all = enabled
	_full_map_view.reveal_all = enabled


## Opens or closes the pack screen; like the map, the party waits meanwhile.
func _set_pack(open: bool) -> void:
	if open and (_prompt.visible or _full_map.visible):
		return
	_pack.visible = open
	_party.locked = open
	_pack.refresh()


## Opens or closes the full-screen map. The party can't move while it's open,
## and it can't open over a yes/no prompt.
func _set_full_map(open: bool) -> void:
	if open and (_prompt.visible or _pack.visible):
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


## Placeholder sound: the theme's ambience loops, footsteps vary in sample
## and pitch, and one-off effects share a player.
func _build_audio() -> void:
	_ambience_player = AudioStreamPlayer.new()
	_ambience_player.stream = environment_theme.ambience
	_ambience_player.volume_db = AMBIENCE_VOLUME_DB
	add_child(_ambience_player)
	if _ambience_player.stream:
		_ambience_player.play()

	var steps := AudioStreamRandomizer.new()
	for sound in environment_theme.footstep_sounds:
		steps.add_stream(-1, sound)
	steps.random_pitch = 1.12
	steps.random_volume_offset_db = 2.0
	_footstep_player = AudioStreamPlayer.new()
	_footstep_player.stream = steps
	_footstep_player.volume_db = FOOTSTEP_VOLUME_DB
	add_child(_footstep_player)

	_effect_player = AudioStreamPlayer.new()
	_effect_player.volume_db = EFFECT_VOLUME_DB
	_effect_player.max_polyphony = 2
	add_child(_effect_player)


func _play_effect(sound: AudioStream) -> void:
	if sound:
		_effect_player.stream = sound
		_effect_player.play()


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
	var canvas := CanvasLayer.new()
	add_child(canvas)
	# Everything except full-screen backgrounds goes inside the safe area.
	var ui := Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(ui)
	_safe_area = ui

	var map_corner := MarginContainer.new()
	map_corner.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	map_corner.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_set_margins(map_corner, 16)
	var map_column := VBoxContainer.new()
	map_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	map_corner.add_child(map_column)
	map_column.add_child(minimap)
	# Supplies live in the pack, not on the HUD (#10).
	var pack_button := Button.new()
	pack_button.text = "Pack"
	pack_button.custom_minimum_size = Vector2(96, 52)
	pack_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	pack_button.focus_mode = Control.FOCUS_NONE
	pack_button.modulate.a = 0.8
	pack_button.pressed.connect(func(): _set_pack(true))
	map_column.add_child(pack_button)
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

	_build_party_cards(ui)
	_build_prompt(ui)
	_build_full_map(canvas)
	_pack = PackScreen.new()
	canvas.add_child(_pack)
	_pack.setup(_party_state)
	_pack.visible = false
	_pack.closed.connect(_set_pack.bind(false))
	_pack.used.connect(_show_message)
	minimap.pressed.connect(_set_full_map.bind(true))
	get_viewport().size_changed.connect(_apply_safe_area)
	_apply_safe_area()


## Keeps the HUD out from under the iPhone's camera cutout, rounded corners
## and home bar. On desktop there's nothing to avoid.
func _apply_safe_area() -> void:
	var insets := _safe_area_insets()
	for control: Control in [_safe_area, _full_map_margin, _pack.content]:
		control.offset_left = insets.x
		control.offset_top = insets.y
		control.offset_right = -insets.z
		control.offset_bottom = -insets.w


## Left, top, right, bottom insets in UI pixels.
func _safe_area_insets() -> Vector4:
	if simulate_phone_safe_area:
		return SIMULATED_PHONE_INSETS
	if not OS.has_feature("mobile"):
		return Vector4.ZERO
	var window := Vector2(DisplayServer.window_get_size())
	var safe := Rect2(DisplayServer.get_display_safe_area())
	var to_ui := get_viewport().get_visible_rect().size / window
	return Vector4(safe.position.x * to_ui.x, safe.position.y * to_ui.y,
			(window.x - safe.end.x) * to_ui.x, (window.y - safe.end.y) * to_ui.y)


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
	shade.color = Color(0.03, 0.03, 0.03, 1.0)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_full_map.add_child(shade)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_margins(margin, 24)
	_full_map.add_child(margin)
	_full_map_margin = margin
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


## Portrait cards along the bottom-left, one per party slot.
func _build_party_cards(ui: Control) -> void:
	var corner := MarginContainer.new()
	corner.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	corner.grow_vertical = Control.GROW_DIRECTION_BEGIN
	corner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_margins(corner, 16)
	ui.add_child(corner)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	corner.add_child(row)
	for i in PartyState.MAX_MEMBERS:
		var card := PartyCard.new()
		row.add_child(card)
		_cards.append(card)
	_party_state.changed.connect(_refresh_cards)
	_refresh_cards()


func _refresh_cards() -> void:
	for i in _cards.size():
		var card = _cards[i]
		if i < _party_state.members.size():
			var hero: Companion = _party_state.members[i]
			if not hero.changed.is_connected(card.refresh):
				hero.changed.connect(card.refresh)
			card.show_companion(hero)
		else:
			card.show_empty()


## Centred yes/no box for deliberate choices like descending. Big buttons
## for touch; Enter/Escape also answer.
func _build_prompt(ui: Control) -> void:
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

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
const EventScreen := preload("res://scripts/event_screen.gd")
const RoomEvents := preload("res://scripts/room_events.gd")
const Expedition := preload("res://scripts/expedition.gd")
const SafeArea := preload("res://scripts/safe_area.gd")
const OpeningGenerator := preload("res://scripts/opening_generator.gd")
const DialogueBox := preload("res://scripts/dialogue_box.gd")
## Seconds between unprompted lines, so heroes don't chatter (#57).
const SPEECH_COOLDOWN := 6.0
## Opening: remark on being lost at junctions this often (steps).
const LOST_REMARK_EVERY := 18

## The opening escape (#30, #56) is "floor 0": Mara wakes among the bodies
## and bleeds through a branching maze with no map. Three fights come after
## set distances walked; once all three are over and she's weak enough,
## daylight appears just ahead.
const OPENING_DEPTH := 0
const BLEED_EVERY := 12  # time units per point of health lost to bleeding
const EXIT_HEALTH := 3  # at or below this (after the fights), daylight appears
const OPENING_MIN_HEALTH := 2  # she can't drop below this in the opening
const EXIT_DISTANCE := Vector2i(4, 6)  # steps ahead of her where daylight opens
## Steps walked before each fight; a retreat brings the same fight back a
## few steps later.
const OPENING_FIGHT_STEPS: Array[int] = [20, 44, 68]
const OPENING_REFIGHT_AFTER := 8
## If she somehow walks this far, daylight opens anyway.
const OPENING_STEP_LIMIT := 130
## The opening's fights, in order: gentler tutorial creatures, a rat first.
const OPENING_FIGHTS := [
	[preload("res://data/enemies/starved_rat.tres")],
	[preload("res://data/enemies/starved_rat.tres")],
	[preload("res://data/enemies/small_spider.tres")],
]
## Daylight can open this many steps after the last fight even if she's
## not yet weak (the torch may have spared her, #59).
const OPENING_EXIT_AFTER_LAST_FIGHT := 10
## The opening's tutorial props (#58, #59): searching the two bodies gives
## torches and a sword; she starts holding a broken knife.
const TORCH := preload("res://data/items/torch.tres")
const BROKEN_KNIFE := preload("res://data/gear/broken_knife.tres")
const IRON_SWORD := preload("res://data/gear/iron_sword.tres")
const OPENING_BODY_EVENTS := [
	preload("res://data/events/opening_body_torches.tres"),
	preload("res://data/events/opening_body_sword.tres"),
]
const OPENING_START_STRAIN := 10.0
const OPENING_PANIC_STRAIN := 80.0
## Slower steps and turns, so hints and moments have room (#56).
const OPENING_MOVE_TIME := 0.42
const OPENING_TURN_TIME := 0.32
## Waking up: looking down at the floor, then lifting the head (#56).
const WAKE_PITCH_DEGREES := -60.0
const ResultsScreen := preload("res://scripts/results_screen.gd")
const PreparationScreen := preload("res://scripts/preparation_screen.gd")
## Placeholder camp stop between expeditions until the campsite exists
## (#18/#22): rest restores health and eases strain; injuries wait for the
## nurse.
const CAMP_STRAIN_RELIEF := 40.0
## Injuries the F3 + K debug key picks from.
const DEBUG_INJURIES: Array[Injury] = [
	preload("res://data/injuries/deep_wound.tres"),
	preload("res://data/injuries/limp.tres"),
]
const CombatState := preload("res://scripts/combat_state.gd")
const CombatScreen := preload("res://scripts/combat_screen.gd")
const RAT := preload("res://data/enemies/rat.tres")
const SPIDER := preload("res://data/enemies/spider.tres")
const GOBLIN := preload("res://data/enemies/goblin.tres")
## Enemy groups an encounter can hold, by floor depth (#14; #15 will give
## them distinct tactics and tune the mix). One group is picked at random
## from those no larger than the party.
## Deeper floors mix tactics: rats pick on the weakest while a spider webs
## someone or a goblin flanks (#15).
const ENCOUNTER_GROUPS := {
	1: [[RAT], [RAT], [SPIDER], [RAT, RAT]],
	2: [[RAT], [SPIDER], [RAT, RAT], [RAT, SPIDER], [GOBLIN, RAT]],
	3: [[SPIDER], [GOBLIN], [SPIDER, RAT], [GOBLIN, SPIDER], [GOBLIN, RAT, RAT], [GOBLIN, SPIDER, RAT]],
}
## Retreat lands the party this many steps away (trial of the owner's idea).
const RETREAT_DISTANCE := Vector2i(3, 6)
const Supplies := preload("res://scripts/supplies.gd")
const StrainRules := preload("res://scripts/strain.gd")

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
	"debug_strain": [KEY_L],
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
## Play the opening escape (#30) when a new game starts.
@export var play_opening := true
## Art for the fallen companions in the opening room, one per body (Node3D
## scenes whose origin sits on the floor). Missing files fall back to a plain
## placeholder shape. ChatGPT's sprites: art/props/opening-bodies-v1 (#55).
@export var body_scenes: PackedStringArray = [
	"res://art/props/opening-bodies-v1/fallen-a.tscn",
	"res://art/props/opening-bodies-v1/fallen-b.tscn",
]
## The dying fire in the opening room (a Node3D scene on the floor).
## Missing file: placeholder embers. ChatGPT's art: art/features/campfire-v1.
@export var fire_scene_path := "res://art/features/campfire-v1/scene.tscn"
## Shown as the game opens on the deepest floor, where the companions died.
@export_multiline var opening_message := "Your companions lie still. Find the way out."

## Where the party appears on a floor.
enum Arrival { OPENING, FROM_ABOVE, FROM_BELOW }
## Pretend to be a modern iPhone in landscape (camera cutout on both sides,
## home bar at the bottom) to check the HUD stays clear of them on Windows.
@export var simulate_phone_safe_area := false


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
var _combat: Control  # combat_screen.gd
var _event_screen: Control  # event_screen.gd
var _room_events = RoomEvents.new()
var _expedition  # expedition.gd: this expedition's record (#17)
var _results: Control  # results_screen.gd
var _preparation: Control  # preparation_screen.gd
var _ending := false
var _floor_started := false
var _in_opening := false
var _opening := {}  # opening_generator.gd output
var _bleed_clock := 0
var _exit_cell := Vector2i(-1, -1)
var _hint_box: Control
var _hint_label: Label
var _hint := ""  # which hint is showing
var _hints_done := {}
var _steps_taken := 0
var _opening_fights_done := 0
var _next_fight_at := 0
var _last_fight_step := 0
var _panic_started := false
var _searched_bodies := {}  # body cell -> true once actually searched
var _eyelids: Control
var _dialogue_box: PanelContainer  # dialogue_box.gd
var _last_line := ""
var _last_spoke_at := -100.0
var _said := {}  # one-off remarks already made
var _last_lost_remark := 0
var _eyelid_top: ColorRect
var _eyelid_bottom: ColorRect
var _in_combat := false
var _touch_pad: Control
var _pack_button: Button
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
	_expedition = Expedition.new(_party_state, 1)
	_room_events.loot_found.connect(func(loot): _expedition.add_found(loot))

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
	_party.stepped.connect(_on_opening_step)
	_party.bumped.connect(func(_cell): _update_hints("bumped"))
	_party.opened_door.connect(func(_cell): _update_hints("web_torn"))
	_party.opened_door.connect(func(_cell): _say("web"))
	_party.moved.connect(func(_cell, _facing): _update_hints("moved"))
	_party.bumped.connect(func(_cell): _play_effect(environment_theme.bump_sound))
	_party.panicked.connect(_on_party_panicked)
	_party_state.changed.connect(_on_party_state_changed)
	_on_party_state_changed(false)  # note starting states without announcing them
	add_child(_party)
	_party.setup(CELL_SIZE)
	_party_state.supplies.changed.connect(_update_lantern)
	_party_state.supplies.light_band_changed.connect(_on_light_band_changed)
	_update_lantern()
	# The survivor wakes on the deepest floor and climbs out (#8). The debug
	# layout is a single hand-drawn floor, so it starts there instead.
	if use_debug_layout or not play_opening:
		_go_to_floor(1, Arrival.OPENING)
	else:
		_begin_opening()
	_set_debug(show_debug)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_debug"):
		_set_debug(not _debug_label.visible)
	elif _debug_label.visible and event.is_action_pressed("debug_hurt") and not _party_state.members.is_empty():
		_party_state.members[0].change_health(-3)
	elif _debug_label.visible and event.is_action_pressed("debug_heal") and not _party_state.members.is_empty():
		_party_state.members[0].add_effect_over_time("health", 6, 12)
	elif _debug_label.visible and event.is_action_pressed("debug_strain") and not _party_state.members.is_empty():
		_party_state.members[0].change_strain(20.0)
	elif _debug_label.visible and event.is_action_pressed("debug_injure") and not _party_state.members.is_empty():
		_party_state.members[0].add_injury(DEBUG_INJURIES.pick_random())
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
	if _floor_started:
		_party_state.complete_pending_effects()  # owner rule (#8): durations finish between floors
	_floor_started = true
	_depth = depth
	_expedition.visit_floor(depth)
	if not _floors.has(depth):
		_floors[depth] = DungeonMap.new(_make_layout(depth), depth)
		_assign_events(_floors[depth])
	_map = _floors[depth]

	_build_level()
	_minimap.setup(_map)
	_full_map_view.setup(_map)
	var cell: Vector2i = _map.start_cell
	if arrival == Arrival.FROM_ABOVE:
		cell = _map.find_content(DungeonMap.Content.STAIRS_UP)
	elif arrival == Arrival.FROM_BELOW:
		cell = _map.find_content(DungeonMap.Content.STAIRS_DOWN)
	_party.place(_map, cell)
	if _in_opening:
		pass  # the wake-up shows the opening line once the bodies are in view
	elif arrival == Arrival.OPENING and not use_debug_layout:
		_show_message(opening_message)
	else:
		_show_message("%s · depth %d" % [environment_theme.display_name, depth])


func _build_level() -> void:
	if _level:
		_level.queue_free()
	_level = LevelBuilder.new()
	_level.build(_map, environment_theme, CELL_SIZE, WALL_HEIGHT)
	add_child(_level)
	if _depth == OPENING_DEPTH and _in_opening:
		_add_opening_dressing()


func _make_layout(depth: int) -> PackedStringArray:
	if depth == OPENING_DEPTH:
		return _opening["layout"]
	if use_debug_layout and depth == 1:
		return PackedStringArray(DEBUG_LAYOUT)
	return FloorGenerator.generate(_site_seed + (depth - 1) * FLOOR_SEED_STEP, depth < floors_in_site, depth)


func _on_party_entered_cell(cell: Vector2i) -> void:
	# Later expeditions: the deepest point, where the others fell, is the
	# goal for now (the site's real objective is still undecided).
	if _expedition.number > 1 and _depth == floors_in_site and cell == _map.start_cell and not use_debug_layout:
		_ask("The bottom of the cave, where the others fell. End the expedition here?",
				_end_expedition.bind(Expedition.Ending.REACHED_BOTTOM))
		return
	# Opening: the next fight comes once she's walked far enough (#56).
	if _in_opening and _opening_fights_done < OPENING_FIGHTS.size() and _steps_taken >= _next_fight_at:
		var types: Array[EnemyType] = []
		types.assign(OPENING_FIGHTS[_opening_fights_done])
		_start_combat(cell, types)
		return
	# A fight fills its room: entering any part of it starts the fight.
	var fight_cell: Vector2i = _map.encounter_zones.get(cell, Vector2i(-1, -1))
	if fight_cell != Vector2i(-1, -1) and not _map.triggered.has(fight_cell):
		_map.enter(fight_cell)
		_start_combat(fight_cell)
		return
	var content: int = _map.enter(cell)
	match content:
		DungeonMap.Content.NONE:
			return
		DungeonMap.Content.STAIRS_DOWN:
			_ask(environment_theme.descent_prompt, _go_to_floor.bind(_depth + 1, Arrival.FROM_ABOVE))
		DungeonMap.Content.CHEST, DungeonMap.Content.TRAP, DungeonMap.Content.STRANGE_OBJECT, DungeonMap.Content.REST_SPOT:
			_run_event(cell)
		DungeonMap.Content.STAIRS_UP:
			if _depth <= 1:  # floor 1, or the opening's daylight exit
				_ask("%s Leave the cave?" % environment_theme.exit_message,
						_end_expedition.bind(Expedition.Ending.RETURNED))
			else:
				_ask(environment_theme.ascent_prompt, _go_to_floor.bind(_depth - 1, Arrival.FROM_BELOW))
		_:
			# Placeholder for real encounters: for now contents just announce themselves.
			var content_text := DungeonMap.content_name(content)
			print("Entered %s at %s" % [content_text, cell])
			_show_message(content_text)


## Gives each chest, trap, strange object and rest spot on a floor its event,
## picked to suit the depth (#16).
func _assign_events(map) -> void:
	for cell in map.contents:
		var event: RoomEvent = _room_events.pick(map.contents[cell], map.depth)
		if event:
			map.events[cell] = event


## A room event (#16): clue, choices, "Leave it". Leaving keeps it for later;
## an ambush starts a fight.
func _run_event(cell: Vector2i) -> void:
	var event: RoomEvent = _map.events.get(cell)
	if event == null:
		_show_message(DungeonMap.content_name(_map.content_at(cell)))
		return
	_party.locked = true
	_event_screen.show_event(event, _party_state, _room_events)
	var result: Dictionary = await _event_screen.finished
	_party.locked = false
	if result["left"]:
		_map.triggered.erase(cell)
		return
	if _in_opening and event in OPENING_BODY_EVENTS:
		_searched_bodies[cell] = true
		_say("search_body", true)
		_refresh_tutorial_hint()
	_expedition.events_resolved += 1
	if not result["ambush"].is_empty():
		var types: Array[EnemyType] = []
		types.assign(result["ambush"])
		_start_combat(cell, types)


## A fight (#14): enemies appear ahead in the first-person view and the
## action panel replaces the movement pad until it's over.
## `types` sets the enemies (e.g. an ambush); empty picks a group for the floor.
func _start_combat(cell: Vector2i, types: Array[EnemyType] = []) -> void:
	var opening_spider := _in_opening and _opening_fights_done == OPENING_FIGHTS.size() - 1
	if types.is_empty():
		var groups: Array = ENCOUNTER_GROUPS.get(clampi(_depth, 1, ENCOUNTER_GROUPS.size()))
		# Never more enemies than heroes standing, so a lone survivor isn't swamped.
		var party_size: int = _party_state.living_members().size()
		var fitting := groups.filter(func(g: Array): return g.size() <= party_size)
		types.assign((fitting if not fitting.is_empty() else [[groups[0][0]]]).pick_random())
	var state = CombatState.new(_party_state, types)
	if opening_spider:
		for foe in state.foes:
			foe.has_webbed = true  # the opening's spider bites first (#59)
	_place_foes(state.foes)
	_in_combat = true
	_update_hints("fight")
	_say("fight_start", true)
	_party.locked = true
	_touch_pad.visible = false
	_pack_button.disabled = true
	_combat.run(state, _cards)
	var result: int = await _combat.finished
	for foe in state.foes:
		if is_instance_valid(foe.node):
			foe.node.queue_free()
	_in_combat = false
	_touch_pad.visible = true
	_pack_button.disabled = false
	for foe in state.foes:
		if foe.health <= 0:
			_expedition.add_defeated(foe.type.display_name)
	match result:
		CombatState.Result.VICTORY:
			_party.locked = false
			_show_message("The way is clear.")
			_say("fight_won", true)
			_update_hints("fight_over")
			if _in_opening:
				_on_opening_fight_won()
			_check_opening_exit()
		CombatState.Result.RETREAT:
			_party.locked = false
			_map.triggered.erase(cell)  # they're still there, at full strength
			_expedition.retreats += 1
			_flee_from(cell)
			if _in_opening:
				_next_fight_at = _steps_taken + OPENING_REFIGHT_AFTER  # it follows her
			_check_opening_exit()
		CombatState.Result.DEFEAT:
			_end_expedition(Expedition.Ending.WIPED)


## Ends the expedition (#17) and shows what it gained and cost.
func _end_expedition(ending: int) -> void:
	if _ending:
		return
	_ending = true
	_set_full_map(false)
	_set_pack(false)
	_party.locked = true  # after closing overlays, which unlock on close
	var notes := {
		Expedition.Ending.RETURNED: "You stagger out into the daylight, alone." if _in_opening else "You climb out into the daylight.",
		Expedition.Ending.WIPED: "No one is left to carry the lantern. Recruiting new heroes at camp comes later; for now the story begins again.",
		Expedition.Ending.REACHED_BOTTOM: "You stood where the others fell, and lived to climb back.",
	}
	if _in_opening and ending == Expedition.Ending.RETURNED:
		_results.show_brief("Barely survived", "You stagger out into the daylight, alone.", "To camp")
	else:
		_results.show_results(ending, _expedition, _party_state, notes[ending])
	await _results.continue_pressed
	_results.visible = false
	if ending == Expedition.Ending.WIPED:
		get_tree().reload_current_scene()
		return
	_start_new_expedition()


## Placeholder camp stop, then back into the cave from the top. The cave
## remembers what was explored, opened and cleared.
func _start_new_expedition() -> void:
	_end_opening()
	for hero: Companion in _party_state.members:
		hero.appearance.clear()  # washed at camp
		hero.emit_changed()
	# A lantern from camp, filled (#59: the opening had only torches).
	if not _party_state.supplies.has_lantern:
		_party_state.supplies.has_lantern = true
		_party_state.supplies.oil = Supplies.LANTERN_CAPACITY
	# At camp the torch is put out; the lantern is her light now.
	_party_state.supplies.source = Supplies.Source.LANTERN
	_party_state.supplies.torch_left = 0.0
	_party_state.supplies.changed.emit()
	_update_lantern()
	for hero: Companion in _party_state.living_members():
		hero.complete_pending_effects()
		hero.change_health(hero.effective_max_health())
		hero.change_strain(-CAMP_STRAIN_RELIEF)
		hero.hunger = 0
	_expedition = Expedition.new(_party_state, _expedition.number + 1)
	_preparation.show_for(_expedition.number, _party_state)
	await _preparation.entered
	_ending = false
	_party.locked = false
	_go_to_floor(1, Arrival.FROM_ABOVE)
	_show_message("Rested at camp. Expedition %d: back into the cave." % _expedition.number)


## Stands the enemies in front of the party, spread across the corridor.
func _place_foes(foes: Array) -> void:
	var forward := -_party.global_transform.basis.z
	var right := _party.global_transform.basis.x
	var ahead_open: bool = _map.is_passable(_party.cell + Party.DIRECTIONS[_party.facing])
	var distance := CELL_SIZE * (1.2 if ahead_open else 0.4)
	var spread := {1: [0.0], 2: [-0.45, 0.45], 3: [-0.7, 0.0, 0.7]}
	var offsets: Array = spread.get(foes.size(), [0.0])
	for i in foes.size():
		var node: Node3D = foes[i].type.scene.instantiate()
		node.position = _party.position + forward * distance + right * offsets[mini(i, offsets.size() - 1)]
		_level.add_child(node)
		foes[i].node = node


## Retreat (trial): bolt to a random spot a few steps away, losing time
## (and so lantern oil) on the way.
func _flee_from(cell: Vector2i) -> void:
	var distances: Dictionary = _map.walking_distances(cell)
	var options: Array[Vector2i] = []
	for c in distances:
		var in_range: bool = distances[c] >= RETREAT_DISTANCE.x and distances[c] <= RETREAT_DISTANCE.y
		# Somewhere empty, and not back inside the fight's room.
		if in_range and _map.content_at(c) == DungeonMap.Content.NONE and not _map.encounter_zones.has(c):
			options.append(c)
	if options.is_empty():
		for c in distances:
			if c != cell and _map.content_at(c) == DungeonMap.Content.NONE and not _map.encounter_zones.has(c):
				options.append(c)
	if options.is_empty():
		return
	_party_state.advance_time(CombatState.RETREAT_TIME)
	_party.place(_map, options.pick_random())
	_show_message("You flee blindly into the dark, and lose your way.")


var _strain_states := {}  # Companion -> last strain state, to announce changes


## Strain (#12): announce state changes and let panic take over some moves.
func _on_party_state_changed(announce := true) -> void:
	for member: Companion in _party_state.living_members():
		if not member.changed.is_connected(_on_party_state_changed):
			member.changed.connect(_on_party_state_changed)  # e.g. strain from a trap
		var state := member.strain_state()
		var before: int = _strain_states.get(member, state)
		_strain_states[member] = state
		if not announce:
			continue
		if state > before:
			_show_message("%s is %s." % [member.display_name, StrainRules.NAMES[state].to_lower()])
			if state == StrainRules.State.PANICKING and not _in_opening:
				_say("panic", true)
		elif state < before and state == StrainRules.State.STEADY:
			_show_message("%s steadies." % member.display_name)
	# No random bolting during the opening: panic shows, but the controls
	# tutorial shouldn't fight the player (#30).
	var panicking: bool = _party_state.panicking_member() != null and not _in_opening
	_party.panic_chance = StrainRules.PANIC_BOLT_CHANCE if panicking else 0.0
	# Badly hurt: say so once per expedition (not during fights).
	for member: Companion in _party_state.living_members():
		if announce and not _in_combat and member.health * 4 <= member.effective_max_health():
			_say("hurt", false, true)
	# Falling outside a fight (a trap, a bad drink) ends the expedition too.
	if announce and _party_state.living_members().is_empty() and not _in_combat and not _ending:
		_end_expedition.call_deferred(Expedition.Ending.WIPED)


func _on_party_panicked() -> void:
	var who: Companion = _party_state.panicking_member()
	_show_message("%s panics and bolts!" % (who.display_name if who else "Someone"))


# --- Opening escape (#30) -------------------------------------------------

func _begin_opening() -> void:
	_in_opening = true
	_opening = OpeningGenerator.generate(_site_seed)
	var hero: Companion = _party_state.members[0]
	# Hurt and filthy, but panic is held back until later (#56).
	hero.strain = OPENING_START_STRAIN
	hero.strain_locked = true
	hero.min_health = OPENING_MIN_HEALTH
	hero.appearance = ["blood", "dirt"]
	hero.emit_changed()  # redraw the card with the overlays
	_party.move_time = OPENING_MOVE_TIME
	_party.turn_time = OPENING_TURN_TIME
	_next_fight_at = OPENING_FIGHT_STEPS[0]
	# No lantern: the fire lights the room; torches must be found (#59).
	_party_state.supplies.has_lantern = false
	_party_state.supplies.source = Supplies.Source.NONE
	_party_state.supplies.changed.emit()
	_update_lantern()
	_party.step_check = _opening_step_check
	if not _party.refused.is_connected(_on_step_refused):
		_party.refused.connect(_on_step_refused)
		_party_state.supplies.torch_burnt_out.connect(_on_torch_burnt_out)
		_combat.enemy_acted.connect(_on_combat_enemy_acted)
		_party_state.changed.connect(_refresh_tutorial_hint)
	_minimap.visible = false  # no map during the escape
	_on_party_state_changed(false)
	_go_to_floor(OPENING_DEPTH, Arrival.OPENING)
	for i in OPENING_BODY_EVENTS.size():
		var body: Vector2i = _opening_body_cells()[i]
		_map.contents[body] = DungeonMap.Content.CHEST  # searchable, via its event
		_map.events[body] = OPENING_BODY_EVENTS[i]
	# Wake facing down the room toward the way out, the bodies in view.
	_party.facing = 1
	_party.rotation.y = -PI / 2.0
	_party.moved.emit(_party.cell, _party.facing)
	_wake_up()


## Eyes open slowly and the head lifts from the floor; then the bodies are
## in view and the line about them appears.
func _wake_up() -> void:
	_party.locked = true
	_party.camera.rotation.x = deg_to_rad(WAKE_PITCH_DEGREES)
	_set_eyelids(0.0)
	_eyelids.visible = true
	var lids := create_tween()
	lids.tween_interval(0.7)
	lids.tween_method(_set_eyelids, 0.0, 0.35, 0.6)
	lids.tween_method(_set_eyelids, 0.35, 0.0, 0.25)
	lids.tween_interval(0.4)
	lids.tween_callback(_say.bind("wake", true))
	lids.tween_method(_set_eyelids, 0.0, 0.7, 0.7)
	lids.tween_method(_set_eyelids, 0.7, 0.15, 0.2)
	lids.tween_method(_set_eyelids, 0.15, 1.0, 0.9)
	var look := create_tween()
	look.tween_interval(1.6)
	look.tween_property(_party.camera, "rotation:x", 0.0, 2.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await look.finished
	_eyelids.visible = false
	_party.locked = false
	_show_message(opening_message)
	_update_hints("start")
	await get_tree().create_timer(2.6).timeout
	_say("bodies", true, true)


## 0 = eyes shut, 1 = wide open.
func _set_eyelids(open: float) -> void:
	var cover := (1.0 - open) * 0.5
	_eyelid_top.anchor_bottom = cover
	_eyelid_bottom.anchor_top = 1.0 - cover


func _end_opening() -> void:
	if not _in_opening:
		return
	_in_opening = false
	for hero: Companion in _party_state.members:
		hero.min_health = 0
		hero.strain_locked = false
	_party.move_time = Party.MOVE_TIME
	_party.turn_time = Party.TURN_TIME
	_party.step_check = Callable()
	_minimap.visible = true
	_show_hint("")


## Bleeding: a point of health every few steps until daylight appears.
func _on_opening_step(_cell: Vector2i) -> void:
	if not _in_opening:
		return
	_steps_taken += 1
	_bleed_clock += _party_state.step_time()
	if _bleed_clock >= BLEED_EVERY and _exit_cell == Vector2i(-1, -1):
		_bleed_clock = 0
		var hero: Companion = _party_state.members[0]
		hero.change_health(-1)
		if not _hints_done.has("bleeding"):
			_hints_done["bleeding"] = true
			_say("bleeding", true, true)
	# Lost and hurrying: now and then at a junction, and once to find the exit.
	if _opening_fights_done >= 1:
		_say("find_exit", false, true)
	if _steps_taken - _last_lost_remark >= LOST_REMARK_EVERY and _open_ways(_party.cell) >= 3:
		_last_lost_remark = _steps_taken
		_say("lost")
	_check_opening_exit()


func _open_ways(cell: Vector2i) -> int:
	return Party.DIRECTIONS.filter(func(d): return _map.is_passable(cell + d)).size()


func _on_opening_fight_won() -> void:
	_opening_fights_done += 1
	if _opening_fights_done < OPENING_FIGHTS.size():
		_next_fight_at = maxi(OPENING_FIGHT_STEPS[_opening_fights_done], _steps_taken + OPENING_REFIGHT_AFTER)
	else:
		_last_fight_step = _steps_taken


## Once all three fights are over and she's weak enough, daylight opens a
## few steps ahead (or anyway, if she's walked a very long way).
func _check_opening_exit() -> void:
	if not _in_opening or _in_combat or _exit_cell != Vector2i(-1, -1):
		return
	var hero: Companion = _party_state.members[0]
	var fights_over := _opening_fights_done >= OPENING_FIGHTS.size()
	var can_leave := fights_over and (hero.health <= EXIT_HEALTH or _steps_taken - _last_fight_step >= OPENING_EXIT_AFTER_LAST_FIGHT)
	if not can_leave and _steps_taken < OPENING_STEP_LIMIT:
		return
	_exit_cell = _pick_exit_cell()
	_map.contents[_exit_cell] = DungeonMap.Content.STAIRS_UP
	_build_level()
	_show_message("Cold air on your face. Daylight, just ahead!")
	_update_hints("exit")
	_say("daylight", true)


## A spot a few steps away, preferably ahead of her rather than behind.
func _pick_exit_cell() -> Vector2i:
	var behind: Vector2i = _party.cell - Party.DIRECTIONS[_party.facing]
	var room: Rect2i = _opening["room"]
	for avoid_behind in [true, false]:
		var distance := {_party.cell: 0}
		var queue: Array[Vector2i] = [_party.cell]
		var i := 0
		var options: Array[Vector2i] = []
		var farthest: Vector2i = _party.cell
		while i < queue.size():
			var c := queue[i]
			i += 1
			for d in Party.DIRECTIONS:
				var n: Vector2i = c + d
				if distance.has(n) or not _map.is_passable(n) or (avoid_behind and n == behind):
					continue
				distance[n] = distance[c] + 1
				if distance[n] > EXIT_DISTANCE.y:
					continue
				queue.append(n)
				if room.has_point(n) or _map.door_at(n) != DungeonMap.Door.NONE:
					continue
				if distance[n] >= EXIT_DISTANCE.x:
					options.append(n)
				if distance[n] > distance.get(farthest, 0):
					farthest = n
		if not options.is_empty():
			return options.pick_random()
		if avoid_behind == false and farthest != _party.cell:
			return farthest
	return _party.cell + Party.DIRECTIONS[_party.facing]


## The companions' bodies, and the daylight once the exit is open.
func _add_opening_dressing() -> void:
	var room: Rect2i = _opening["room"]
	var start: Vector2i = _opening["start"]
	# In the far corners of the room, in view as she wakes facing east.
	var cells := _opening_body_cells()
	_add_fire(start + Vector2i(3, -1))  # the far corner: in view, lighting the bodies and doorway
	for i in cells.size():
		var path: String = body_scenes[i] if i < body_scenes.size() else ""
		var body: Node3D
		if path != "" and ResourceLoader.exists(path):
			body = load(path).instantiate()  # a camera-facing sprite, drawn lying down
		else:
			body = _placeholder_body()
			body.rotation.y = PI / 2.0 + randf_range(-0.5, 0.5)  # lying across her view
		body.position = Vector3(cells[i].x * CELL_SIZE, 0.0, cells[i].y * CELL_SIZE)
		_level.add_child(body)
	if _exit_cell != Vector2i(-1, -1):
		var daylight := OmniLight3D.new()
		daylight.light_color = Color(0.82, 0.88, 1.0)
		daylight.light_energy = 3.0
		daylight.omni_range = CELL_SIZE * 4.0
		daylight.position = Vector3(_exit_cell.x * CELL_SIZE, WALL_HEIGHT - 0.3, _exit_cell.y * CELL_SIZE)
		_level.add_child(daylight)


## Where the two bodies lie: the far corners, in view as she wakes.
func _opening_body_cells() -> Array[Vector2i]:
	var start: Vector2i = _opening["start"]
	return [start + Vector2i(2, -1), start + Vector2i(2, 1)]


## A dying fire: the room's only light until she finds a torch (#59).
## Placeholder embers until there's art.
func _add_fire(cell: Vector2i) -> void:
	if fire_scene_path != "" and ResourceLoader.exists(fire_scene_path):
		var art: Node3D = load(fire_scene_path).instantiate()
		art.position = Vector3(cell.x * CELL_SIZE, 0.0, cell.y * CELL_SIZE)
		_level.add_child(art)
		# A soft fill so the whole small room reads, not just the fire.
		var fill := OmniLight3D.new()
		fill.light_color = Color(1.0, 0.55, 0.25)
		fill.light_energy = 1.0
		fill.omni_range = CELL_SIZE * 3.6
		var middle: Vector2i = _opening["start"] + Vector2i(1, 0)  # lights the bodies from the front
		fill.position = Vector3(middle.x * CELL_SIZE, 1.4, middle.y * CELL_SIZE)
		_level.add_child(fill)
		return
	var fire := Node3D.new()
	fire.position = Vector3(cell.x * CELL_SIZE, 0.0, cell.y * CELL_SIZE)
	var embers := MeshInstance3D.new()
	var mound := SphereMesh.new()
	mound.radius = 0.18
	mound.height = 0.12
	var glow := StandardMaterial3D.new()
	glow.albedo_color = Color(0.9, 0.35, 0.1)
	glow.emission_enabled = true
	glow.emission = Color(1.0, 0.4, 0.1)
	glow.emission_energy_multiplier = 0.8
	mound.material = glow
	embers.mesh = mound
	embers.position.y = 0.05
	fire.add_child(embers)
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.55, 0.25)
	light.light_energy = 1.8
	light.omni_range = CELL_SIZE * 3.6
	light.position.y = 0.5
	fire.add_child(light)
	var flicker := create_tween().set_loops()
	flicker.bind_node(light)
	flicker.tween_property(light, "light_energy", 1.4, 0.18)
	flicker.tween_property(light, "light_energy", 1.95, 0.23)
	flicker.tween_property(light, "light_energy", 1.65, 0.15)
	_level.add_child(fire)


## Opening: she won't leave the room without a light (#58, #59).
func _opening_step_check(target: Vector2i) -> String:
	if not _in_opening or _party_state.supplies.torch_lit() or _panic_started:
		return ""
	var room: Rect2i = _opening["room"]
	if room.has_point(target) or not room.has_point(_party.cell):
		return ""
	return "too_dark"


func _on_step_refused(reason: String) -> void:
	if reason == "too_dark":
		_say("too_dark", true)
		_refresh_tutorial_hint()


func _on_torch_burnt_out() -> void:
	if not _in_opening:
		_show_message("Your torch burns out.")
		return
	_say("torch_out", true)
	if _party_state.supplies.count(TORCH) > 0:
		_show_hint("Your torch has burned out! Open the Pack and light the spare.", "torch_out")


## Fight 3: once the spider has struck, teach throwing the torch.
func _on_combat_enemy_acted(_foe, outcome: Dictionary) -> void:
	if not _in_opening or _opening_fights_done != OPENING_FIGHTS.size() - 1 or _hints_done.has("throw"):
		return
	if not _party_state.supplies.torch_lit():
		return
	var hero: Companion = _party_state.members[0]
	var poisoned: bool = _combat._state.venom_turns(hero) > 0
	_show_hint(("Poisoned! " if poisoned else "") + "Open Item and throw your torch to scare the spider away.", "throw")


## Without any light left, she panics: the panic mechanic, explained.
func _start_opening_panic() -> void:
	_panic_started = true
	var hero: Companion = _party_state.members[0]
	hero.strain_locked = false
	hero.strain = OPENING_PANIC_STRAIN
	_on_party_state_changed()
	_show_hint("In the dark, %s panics: her hands shake, so she hits less often and less hard. Light, food and rest calm her." % hero.display_name, "panic")
	_hints_done["panic_at"] = _steps_taken
	_say("panic", true)


## The next thing the tutorial wants, worked out from where she is: search
## the bodies, equip the sword, drop the broken knife, light a torch.
func _refresh_tutorial_hint() -> void:
	if not _in_opening or not _hints_done.has("start"):
		return
	var supplies = _party_state.supplies
	if _hint == "torch_out" and supplies.torch_lit():
		_finish_hint()
	if _hint not in ["", "search", "equip", "drop", "light"]:
		return
	var touch := OS.has_feature("mobile")
	var open_pack := "tap Pack" if touch else "press I or click Pack"
	var hero: Companion = _party_state.members[0]
	var text := ""
	var key := ""
	if not _opening_body_cells().all(func(c): return _searched_bodies.has(c)):
		key = "search"
		text = "Search your companions: walk onto each of them."
	elif hero.weapon != IRON_SWORD and IRON_SWORD in supplies.gear:
		key = "equip"
		text = "Open your pack (%s) and equip the iron sword." % open_pack
	elif BROKEN_KNIFE in supplies.gear:
		key = "drop"
		text = "Drop the broken knife from your pack. It's no use now."
	elif not supplies.torch_lit() and not _hints_done.has("light") and supplies.count(TORCH) > 0:
		key = "light"
		text = "Light a torch from your pack. It's too dark to go on without one."
	if key == "":
		if _hint in ["search", "equip", "drop", "light"]:
			_finish_hint()
		return
	if _hint != key:
		_show_hint(text, key)  # the next step replaces the last; nothing is skipped


## A dark, cloth-wrapped shape lying on the floor, until there's real art.
func _placeholder_body() -> Node3D:
	var root := Node3D.new()
	var cloth := StandardMaterial3D.new()
	cloth.albedo_color = Color(0.36, 0.29, 0.22)
	cloth.roughness = 1.0
	var torso := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.5, 0.2, 1.35)
	box.material = cloth
	torso.mesh = box
	torso.position.y = 0.1
	root.add_child(torso)
	var head := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.14
	sphere.height = 0.26
	var skin := StandardMaterial3D.new()
	skin.albedo_color = Color(0.55, 0.45, 0.38)
	sphere.material = skin
	head.mesh = sphere
	head.position = Vector3(0.0, 0.13, -0.8)
	root.add_child(head)
	return root


## Just-in-time hints, worded for keyboard or touch. Each shows once, until
## the player has done the thing it describes.
func _update_hints(event: String) -> void:
	if not _in_opening:
		return
	var touch := OS.has_feature("mobile")  # computers: keys, with clicking as an alternative
	match event:
		"start":
			_show_hint("Tap ▲ to move forward" if touch else "Move forward: W or ↑ (or click ▲)")
		"moved":
			if _hint == "start" and _steps_taken >= 1:
				_finish_hint()
			_refresh_tutorial_hint()
			var ahead: Vector2i = _party.cell + Party.DIRECTIONS[_party.facing]
			var can_go: bool = _party_state.supplies.torch_lit() or _panic_started  # not before she has light
			if can_go and not _hints_done.has("web") and (_map.door_at(ahead) == DungeonMap.Door.CLOSED or _map.door_at(ahead + Party.DIRECTIONS[_party.facing]) == DungeonMap.Door.CLOSED):
				_show_hint("Walk into the web to tear through it.", "web")
			elif not _hints_done.has("turn") and _hints_done.has("start") and _hint == "" and not _map.is_passable(ahead):
				_show_hint("Tap ↺ or ↻ to turn" if touch else "Turn: A and D, or ← and → (or click ↺ ↻)", "turn")
			elif _hint == "turn" and _map.is_passable(ahead):
				_finish_hint()
			elif _hint == "panic" and _steps_taken >= _hints_done.get("panic_at", 0) + 8:
				_finish_hint()
		"bumped":
			if not _hints_done.has("turn") and _hint == "":
				_show_hint("Tap ↺ or ↻ to turn" if touch else "Turn: A and D, or ← and → (or click ↺ ↻)", "turn")
		"web_torn":
			if _hint == "web":
				_finish_hint()
		"fight":
			if not _hints_done.has("fight"):
				_show_hint(("Tap" if touch else "Click") + " an enemy's name to target it, then Attack. Defend halves the damage you take.", "fight")
		"fight_over":
			if _hint in ["fight", "throw"]:
				_finish_hint()
		"pack":
			_refresh_tutorial_hint()
		"exit":
			_show_hint("Daylight! Walk into the light to get out.", "exit")


func _show_hint(text: String, key := "start") -> void:
	_hint = key if text != "" else ""
	_hint_label.text = text
	_hint_box.visible = text != ""
	# In a fight, sit above the action panel instead of beside it.
	var lift := 150.0 if _in_combat else 24.0
	_hint_box.offset_bottom = -lift
	_hint_box.offset_top = -lift - _hint_box.get_combined_minimum_size().y


func _finish_hint() -> void:
	_hints_done[_hint] = true
	_show_hint("")


## Speech box just above the portrait cards (#57).
func _build_dialogue_box(ui: Control) -> void:
	var corner := MarginContainer.new()
	corner.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	corner.grow_vertical = Control.GROW_DIRECTION_BEGIN
	corner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	corner.add_theme_constant_override("margin_left", 16)
	corner.add_theme_constant_override("margin_bottom", 196)  # sits above the cards
	ui.add_child(corner)
	_dialogue_box = DialogueBox.new()
	corner.add_child(_dialogue_box)


## The lead hero says something fitting `situation` (#57): a line from their
## library, in the box above the cards, while their portrait talks.
## Unforced lines respect a short cooldown; `once` lines are said only once.
func _say(situation: String, force := false, once := false) -> void:
	if once and _said.has(situation):
		return
	var now := Time.get_ticks_msec() / 1000.0
	if not force and now - _last_spoke_at < SPEECH_COOLDOWN:
		return
	var living: Array[Companion] = _party_state.living_members()
	if living.is_empty() or living[0].dialogue == null:
		return
	var hero: Companion = living[0]
	var line: String = hero.dialogue.pick(situation, _last_line)
	if line == "":
		return
	_said[situation] = true
	_last_line = line
	_last_spoke_at = now
	var seconds: float = _dialogue_box.say(hero.display_name, line)
	for card in _cards:
		if card.companion == hero:
			card._portrait.talk(minf(seconds, 2.5))


## Two black lids that close over the screen from top and bottom.
func _build_eyelids(canvas: CanvasLayer) -> void:
	_eyelids = Control.new()
	_eyelids.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_eyelids.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(_eyelids)
	_eyelid_top = ColorRect.new()
	_eyelid_top.color = Color.BLACK
	_eyelid_top.anchor_right = 1.0
	_eyelid_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_eyelids.add_child(_eyelid_top)
	_eyelid_bottom = ColorRect.new()
	_eyelid_bottom.color = Color.BLACK
	_eyelid_bottom.anchor_right = 1.0
	_eyelid_bottom.anchor_bottom = 1.0
	_eyelid_bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_eyelids.add_child(_eyelid_bottom)
	_eyelids.visible = false


func _build_hint(ui: Control) -> void:
	_hint_box = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.045, 0.04, 0.82)
	style.border_color = Color("dbb477")
	style.set_border_width(SIDE_LEFT, 3)
	style.set_content_margin_all(10)
	_hint_box.add_theme_stylebox_override("panel", style)
	_hint_box.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_hint_box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_hint_box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_hint_box.position.y -= 24
	_hint_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint_label = Label.new()
	_hint_label.add_theme_font_size_override("font_size", 20)
	_hint_label.add_theme_color_override("font_color", Color("e8d9b0"))
	_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint_label.custom_minimum_size = Vector2(380, 0)
	_hint_box.add_child(_hint_label)
	ui.add_child(_hint_box)
	_hint_box.visible = false


func _update_lantern() -> void:
	_party.set_light(_party_state.supplies.light_fraction())


func _on_light_band_changed(band: Supplies.Light) -> void:
	var supplies = _party_state.supplies
	if supplies.source == Supplies.Source.TORCH and band != Supplies.Light.OUT:
		if _in_opening and not _hints_done.has("light"):
			_hints_done["light"] = true
			_say("torch_lit", true)
		if band == Supplies.Light.DIM:
			_show_message("Your torch gutters.")
		return
	if _in_opening and band == Supplies.Light.OUT:
		if _in_combat:
			_say("throw_torch", true)
		if not _panic_started and supplies.count(TORCH) == 0 and _hints_done.has("light"):
			_start_opening_panic()
		return
	match band:
		Supplies.Light.DIM:
			_show_message("The lantern burns low.")
			_say("dark")
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
	if open and (_prompt.visible or _full_map.visible or _in_combat or _event_screen.visible):
		return
	_pack.visible = open
	_party.locked = open
	if open:
		_update_hints("pack")
	_pack.refresh()


## Opens or closes the full-screen map. The party can't move while it's open,
## and it can't open over a yes/no prompt.
func _set_full_map(open: bool) -> void:
	if open and (_prompt.visible or _pack.visible or _in_combat or _event_screen.visible or _in_opening):
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
	_pack_button = pack_button
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
	_touch_pad = pad_corner

	_build_party_cards(ui)
	_build_dialogue_box(ui)
	_build_hint(ui)
	_build_prompt(ui)
	_build_full_map(canvas)
	_pack = PackScreen.new()
	canvas.add_child(_pack)
	_pack.setup(_party_state)
	_pack.visible = false
	_pack.closed.connect(_set_pack.bind(false))
	_pack.used.connect(_show_message)
	_pack.used.connect(func(_m): _refresh_tutorial_hint())
	_combat = CombatScreen.new()
	canvas.add_child(_combat)
	_event_screen = EventScreen.new()
	ui.add_child(_event_screen)
	_results = ResultsScreen.new()
	canvas.add_child(_results)
	_build_eyelids(canvas)
	_preparation = PreparationScreen.new()
	canvas.add_child(_preparation)
	minimap.pressed.connect(_set_full_map.bind(true))
	get_viewport().size_changed.connect(_apply_safe_area)
	_apply_safe_area()


## Keeps the HUD out from under the iPhone's camera cutout, rounded corners
## and home bar. On desktop there's nothing to avoid.
func _apply_safe_area() -> void:
	var insets := _safe_area_insets()
	for control: Control in [_safe_area, _full_map_margin, _pack.content, _combat.content, _results.content, _preparation.content]:
		control.offset_left = insets.x
		control.offset_top = insets.y
		control.offset_right = -insets.z
		control.offset_bottom = -insets.w


## Left, top, right, bottom insets in UI pixels.
func _safe_area_insets() -> Vector4:
	return SafeArea.insets(get_viewport(), simulate_phone_safe_area)


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

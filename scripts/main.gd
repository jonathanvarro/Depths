extends Node3D
## Exploration prototype: generates the floors of one site, dressed by an
## environment theme, and handles moving between them, plus the map, touch
## controls, messages, and debug overlay.

const DungeonMap := preload("res://scripts/dungeon_map.gd")
const Dressing := preload("res://scripts/dressing.gd")
const Landmarks := preload("res://scripts/landmarks.gd")
const Ambience := preload("res://scripts/ambience.gd")
const Recruits := preload("res://scripts/recruits.gd")
const Trinkets := preload("res://scripts/trinkets.gd")
const GearGen := preload("res://scripts/gear_gen.gd")
const TURN_LEFT_ICON := preload("res://art/ui/controls-v1/turn-left.svg")
const SPADE := preload("res://data/items/spade.tres")
const PICK := preload("res://data/items/pick.tres")
const CLEAR_PASSAGE_TIME := 4
const TURN_RIGHT_ICON := preload("res://art/ui/controls-v1/turn-right.svg")
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
const ChestScreen := preload("res://scripts/chest_screen.gd")
const CampState := preload("res://scripts/camp_state.gd")
const CampScreen := preload("res://scripts/camp_screen.gd")
const SaveGame := preload("res://scripts/save_game.gd")
const Progression := preload("res://scripts/progression.gd")
const Sounds := preload("res://scripts/sounds.gd")
const Music := preload("res://scripts/music.gd")
const Quests := preload("res://scripts/quests.gd")
const ConversationScreen := preload("res://scripts/conversation_screen.gd")
const QuestLog := preload("res://scripts/quest_log.gd")
const Story := preload("res://scripts/story.gd")
const Packages := preload("res://scripts/packages.gd")
const BattleStage := preload("res://scripts/battle_stage.gd")
const SpoilsScreen := preload("res://scripts/spoils_screen.gd")
const VisionFilter := preload("res://scripts/vision_filter.gd")
## The commander waiting outside after the escape (#122, first slice).
const COMMANDER_FIRST := preload("res://data/conversations/commander_first.tres")
const CoinFlip := preload("res://scripts/coin_flip.gd")
const Settings := preload("res://scripts/settings.gd")
const SettingsScreen := preload("res://scripts/settings_screen.gd")
const TITLE_SCENE := "res://scenes/title.tscn"
## Opening: remark on being lost at junctions this often (steps).
const LOST_REMARK_EVERY := 18

## The opening escape (#30, #56, #69) is "floor 0": Mara wakes among the
## bodies and bleeds through a branching maze with no map. A first stretch
## is hers to explore; past a second web come three fights, a chest after
## the first and a stumble that kills her torch after the second. Once all
## three are over and she's weak enough, daylight appears just ahead.
const OPENING_DEPTH := 0
const BLEED_EVERY := 16  # time units per point of health lost to bleeding
const OPENING_START_HEALTH := 10
const EXIT_HEALTH := 3  # at or below this (after the fights), daylight appears
const OPENING_MIN_HEALTH := 2  # she can't drop below this in the opening
const EXIT_DISTANCE := Vector2i(4, 6)  # steps ahead of her where daylight opens
## Steps from the second web to fight 1, from fight 1 to fight 2, from
## fight 2 to the stumble, and from the stumble to the spider. A retreat
## brings the same fight back a few steps later.
const OPENING_FIRST_FIGHT_AFTER := 6
const OPENING_SECOND_FIGHT_AFTER := 16
const OPENING_TRIP_AFTER := 6
const OPENING_SPIDER_AFTER_TRIP := 6
const OPENING_REFIGHT_AFTER := 8
const NEVER := 1 << 30
## If she walks this far past the second web, daylight opens anyway.
const OPENING_STEP_LIMIT := 110
## At or below this in the spider fight, the game makes her throw the torch.
const FORCE_THROW_HEALTH := 4
## Tutorial steps worked out from her state (see _refresh_tutorial_hint).
const TUTORIAL_STEPS := ["", "search", "equip", "drop", "light", "relight", "draught"]
const DRAUGHT := preload("res://data/items/restorative_draught.tres")
## The chest after fight 1 (#69): her first healing.
const OPENING_CHEST := {
	preload("res://data/items/restorative_draught.tres"): 1,
	preload("res://data/items/dressing.tres"): 1,
}
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
const HintRing := preload("res://scripts/hint_ring.gd")
const Glyphs := preload("res://art/ui/backlog96-v1/glyphs.gd")
const WEBBED_ICON := preload("res://art/ui/visual105-v1/webbed.png")
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
## Each camp day gets its own cave: the site seed is mixed with the day (#40).
const DAY_SEED_STEP := 104729
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
const ARCHER := preload("res://data/enemies/goblin_archer.tres")
const GUARD := preload("res://data/enemies/goblin_guard.tres")
const QUEEN := preload("res://data/enemies/goblin_queen.tres")
const GREAT_RAT := preload("res://data/enemies/great_rat.tres")
const WEBSPINNER := preload("res://data/enemies/webspinner.tres")
const DRUMMER := preload("res://data/enemies/goblin_drummer.tres")
# New monsters (#140): placeholders until #141's art.
const BAT := preload("res://data/enemies/cave_bat.tres")
const BRUTE := preload("res://data/enemies/goblin_brute.tres")
const BLOAT := preload("res://data/enemies/gas_bloat.tres")
const MINER := preload("res://data/enemies/hollow_miner.tres")
const BEETLE := preload("res://data/enemies/rock_beetle.tres")
const VENOM_SPIDER := preload("res://data/enemies/venom_spider.tres")
const TRAPPER := preload("res://data/enemies/goblin_trapper.tres")
const LAMP_EATER := preload("res://data/enemies/lamp_eater.tres")
const HOUND := preload("res://data/enemies/breach_hound.tres")
const BROODMOTHER := preload("res://data/enemies/broodmother.tres")
const CAPTAIN := preload("res://data/enemies/gate_captain.tres")
## The goblin fortress (#44): floor 3 is its outskirts, floor 4 the fortress
## with the queen's hall behind a gate.
const OUTSKIRTS_DEPTH := 3
const FORTRESS_DEPTH := 4
const Fortress := preload("res://scripts/fortress.gd")
const FORTRESS_THEME := preload("res://themes/fortress.tres")
const GATE_FIGHT: Array = [GUARD, GUARD, ARCHER]
const QUEEN_FIGHT: Array = [QUEEN, GUARD, GUARD]
## Enemy groups an encounter can hold, by floor depth (#14; #15 will give
## them distinct tactics and tune the mix). One group is picked at random
## from those no larger than the party.
## Deeper floors mix tactics: rats pick on the weakest while a spider webs
## someone or a goblin flanks (#15).
const ENCOUNTER_GROUPS := {
	1: [[RAT], [RAT], [SPIDER], [GREAT_RAT], [RAT, RAT], [RAT, SPIDER], [GREAT_RAT, RAT], [RAT, RAT, RAT],
			[BAT], [BAT, RAT], [BAT, BAT, RAT]],
	# Floor 1 is onboarding; floor 2 is where the real game starts and
	# floor 3 warms up for the fortress (owner, 2026-10-19, #49).
	2: [[GREAT_RAT], [GOBLIN], [GOBLIN, RAT], [SPIDER, SPIDER], [GOBLIN, SPIDER], [WEBSPINNER, GOBLIN],
			[GREAT_RAT, SPIDER], [GREAT_RAT, SPIDER, RAT], [GOBLIN, RAT, RAT], [GOBLIN, SPIDER, RAT],
			[GOBLIN, GOBLIN, RAT], [GOBLIN, GOBLIN, SPIDER], [BAT, GOBLIN], [BAT, BAT, SPIDER],
			[BEETLE], [BEETLE, RAT], [BEETLE, SPIDER, RAT], [VENOM_SPIDER, GOBLIN], [TRAPPER, GOBLIN], [TRAPPER, GOBLIN, RAT],
			[BROODMOTHER]],  # rare: one group in many
	3: [[GOBLIN], [GOBLIN, ARCHER], [GOBLIN, DRUMMER],
			[GOBLIN, GOBLIN, ARCHER], [GOBLIN, WEBSPINNER, GOBLIN], [GOBLIN, GOBLIN, DRUMMER], [GUARD, GOBLIN, ARCHER],
			[GOBLIN, ARCHER, DRUMMER], [GUARD, GOBLIN, GOBLIN],
			[GOBLIN, GOBLIN, ARCHER, RAT], [GOBLIN, GOBLIN, SPIDER, SPIDER], [GOBLIN, GOBLIN, ARCHER, DRUMMER],
			# The brute, and what came up through the breach (#140).
			[BRUTE], [BRUTE, ARCHER], [BRUTE, GOBLIN, DRUMMER], [MINER], [MINER, BLOAT], [MINER, MINER],
			[BLOAT, GOBLIN, ARCHER], [BLOAT, BLOAT, MINER],
			[TRAPPER, GOBLIN, GOBLIN], [VENOM_SPIDER, GOBLIN, ARCHER], [LAMP_EATER, MINER], [LAMP_EATER, BLOAT, MINER],
			[HOUND, HOUND], [HOUND, HOUND, LAMP_EATER], [HOUND, HOUND, HOUND],
			[CAPTAIN, GOBLIN, ARCHER], [BROODMOTHER, SPIDER]],  # the captain and the Broodmother are rare
	4: [[GOBLIN], [GOBLIN, ARCHER], [GUARD, GOBLIN], [GUARD, ARCHER], [GOBLIN, GOBLIN, ARCHER],
			[GUARD, GOBLIN, ARCHER], [GUARD, GOBLIN, GOBLIN], [GUARD, DRUMMER, GOBLIN], [GUARD, GUARD, ARCHER, GOBLIN],
			[BRUTE, GUARD], [BRUTE, ARCHER, GOBLIN], [BRUTE, GOBLIN, DRUMMER],
			[TRAPPER, GUARD, GOBLIN], [CAPTAIN, GUARD, ARCHER]],
}
## Full parties meet groups close to their size (#49): never more enemies
## than heroes standing, except one extra for a full party on the deepest
## floors; and groups of at least (heroes - 1) when there are any.
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
## Bleeding feedback (#71): a red flash at the screen edges and a heartbeat
## on each point lost. Lower health: stronger flash, faster heartbeat, and
## edges that stay dark between ticks.
const HEARTBEAT := Sounds.HEARTBEAT  # credited recorded source (#96/#54)
const HEARTBEAT_VOLUME_DB := -2.0
const WOUND_SHADER := """
shader_type canvas_item;
uniform float flash = 0.0;
uniform float dim = 0.0;
void fragment() {
	vec2 p = (UV - 0.5) * vec2(1.0, 1.25);
	float edge = smoothstep(0.26, 0.72, length(p));
	float red = edge * flash;
	float dark = edge * dim;
	float alpha = clamp(red + dark, 0.0, 0.95);
	COLOR = vec4(vec3(0.6, 0.02, 0.02) * red / max(red + dark, 0.001), alpha);
}
"""

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
@export var floors_in_site := 4
## The lone survivor the game starts with; the other two slots fill later.
@export var starting_hero: Companion = preload("res://data/companions/mara.tres")
## What the survivor carries at the start. Amounts follow ChatGPT's economy
## research (docs/starter-cave-economy-research.md); tune freely.
@export var starting_supplies: Dictionary[SupplyItem, int] = {
	preload("res://data/items/torch.tres"): 4,  # torches first; the lantern is an upgrade
	preload("res://data/items/ration.tres"): 2,
	preload("res://data/items/restorative_draught.tres"): 1,
	preload("res://data/items/dressing.tres"): 2,
}
## Play the opening escape (#30) when a new game starts.
@export var play_opening := true
## Red edge flashes when bleeding costs health (#71). Settings (#52) can
## turn this off for players sensitive to flashing.
@export var screen_flashes := true
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
var _first_seed := 0  # the site seed on day 1
var _camp_state = CampState.new()  # day, stash, recovery (#40)
var _camp: Control  # camp_screen.gd
var _active_cell := Vector2i(-1, -1)  # a fight or event in progress (redone after loading)
## The game as it stood when that fight or event began (#113). Saving
## mid-encounter writes this instead, so Continue restarts the encounter
## with both sides as they were: no fresh enemies against a spent party.
var _encounter_checkpoint := {}
## Enemies of a fight that isn't the room's own (an ambush, the gate, the
## queen), so a resumed game starts that same fight (#113).
var _active_fight: Array[EnemyType] = []
var _wipe_pending := false  # wiped: the save already holds the aftermath
var _save_queued := false
var _settings: Control  # settings_screen.gd (#52)
var _cave_theme: EnvironmentTheme  # floors 1-3; the fortress has its own (#44)
var _fight_kind := ""  # "gate" or "queen" while those fights run (#44)
var _props := {}  # cell -> prop node for this floor's room contents (#46)
var _cell_now := Vector2i(-1, -1)
var _cell_before := Vector2i(-1, -1)  # where to step back to from the hall's door
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
var _full_map_close: Button
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
var _hint_ok: Button
var _hint_shade: ColorRect
var _hint_icon: TextureRect  # what the card is about, at a glance (#105)
var _hint_ring: Panel  # hint_ring.gd: circles the button to press
var _hint := ""  # which hint is showing
var _hint_text := ""
var _hint_inside := ""  # a "pack" card's text once the Pack is open
var _hint_mode := ""  # "act", "pack" or "ok" (see _show_hint)
var _hint_queue: Array = []  # a card waiting for an "ok" card to close
var _chest: Control  # chest_screen.gd
var _web2_at := -1  # step she broke the second web
var _starting_weapon: Equipment  # the hero's broken weapon, dropped in the tutorial
## The fallen companion's weapon this hero takes in the opening (balance report).
var _opening_weapon: Equipment = IRON_SWORD
var _trip_at := -1
var _tripped := false
var _spider_swings := 0
var _opening_chest_cell := Vector2i(-1, -1)
var _level_chest_open := false
var _chest_looted := false
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
var _rng := RandomNumberGenerator.new()  # trinket drops and rewards (#135)
## Finds that didn't fit, waiting to be offered beside the pack (#133):
## SupplyItem or Equipment -> how many.
var _overflow := {}
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
var _music: Node  # music.gd: a track per place (#54)
var _conversation: Control  # conversation_screen.gd (#122)
var _quest_log: Control  # quest_log.gd (#123)
var _stage: Node3D  # battle_stage.gd: fog and darkness behind every fight
var _spoils: Control  # spoils_screen.gd: gold and XP after a won fight
var _vision: CanvasLayer  # vision_filter.gd: the cold blue of memories and dreams
var _ambience: Node  # ambience.gd: fog, creeping darkness, eyes beyond the light (#129)
var _wound_overlay: ColorRect
var _wound_tween: Tween
var _heart_player: AudioStreamPlayer
var _bleed_ticks := 0  # bleed ticks shown this run (for tests)


func _ready() -> void:
	_register_input_actions()
	Settings.apply(get_tree())
	_build_environment()
	_cave_theme = environment_theme
	_site_seed = floor_seed if floor_seed != 0 else randi()
	_rng.randomize()
	_first_seed = _site_seed
	_camp_state.start(_first_seed, _party_state)
	_camp_state.day_passed.connect(_on_camp_day_passed)
	print("Floor seed: ", _site_seed)
	_party_state = PartyState.new()
	# The hero chosen on the title's hero screen (#95).
	if SaveGame.new_game_hero() != "" and ResourceLoader.exists(SaveGame.new_game_hero()):
		starting_hero = load(SaveGame.new_game_hero())
	SaveGame.set_new_game_hero("")
	_party_state.add_member(starting_hero)
	# The opening starts with nothing; she's restocked at camp (#69).
	if use_debug_layout or not play_opening:
		for item in starting_supplies:
			_party_state.supplies.add(item, starting_supplies[item])
	_expedition = Expedition.new(_party_state, 1)
	_room_events.loot_found.connect(func(loot): _expedition.add_found(loot))
	_room_events.gold_found.connect(func(amount): _expedition.gold_found += amount)
	_room_events.camp = _camp_state  # events can move quests on (#123)
	_room_events.gold_found.connect(func(_amount): Sounds.play(self, "coins"))
	_party_state.supplies.torch_flared.connect(func(): Sounds.play(self, "torch"))
	_party_state.supplies.torch_burnt_out.connect(func(): Sounds.play(self, "burnout", -7.0))

	_minimap = Minimap.new()
	_build_ui(_minimap)
	_party = Party.new()
	_party.moved.connect(_minimap.on_party_moved)
	_party.moved.connect(_full_map_view.on_party_moved)
	_party.moved.connect(_on_party_moved)
	_party.entered_cell.connect(_on_party_entered_cell)
	_party.opened_door.connect(_on_party_opened_door)
	_party.blocked_by.connect(_on_party_blocked)
	_party.interacted.connect(_on_party_interacted)
	_party.opened_door.connect(_on_opening_web_torn)
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
	_ambience.attach(_party, _party.camera)
	_stage = BattleStage.new()  # fights take place on a dark stage (owner, 2026-10-20)
	_party.camera.add_child(_stage)
	_stage.fit(_party.camera)
	_party_state.supplies.changed.connect(_update_lantern)
	_party_state.supplies.light_band_changed.connect(_on_light_band_changed)
	_update_lantern()
	_camp_state.changed.connect(_save_soon)
	var saved: Dictionary = SaveGame.read() if SaveGame.continue_requested() else {}
	SaveGame.set_continue_requested(false)
	# #80: new story starts (or a restarted tutorial) reach a partial camp.
	# Existing campaigns and explicit debug/test starts keep their saved services.
	if play_opening and not use_debug_layout and (saved.is_empty() or saved.get("opening", false)):
		_camp_state.begin_arrivals()
	# The survivor wakes on the deepest floor and climbs out (#8). The debug
	# layout is a single hand-drawn floor, so it starts there instead.
	if not saved.is_empty() and not saved.get("opening", false):
		_restore(saved)
	elif not saved.is_empty():
		# Saved during the opening: the short scripted escape starts again,
		# in the same maze (#45).
		_site_seed = saved["seed"]
		_first_seed = _site_seed
		if saved.has("hero") and ResourceLoader.exists(saved["hero"]):
			starting_hero = load(saved["hero"])
			_party_state.members.clear()
			_party_state.add_member(starting_hero)
			_refresh_cards()
		_begin_opening()
	elif use_debug_layout or not play_opening:
		_go_to_floor(1, Arrival.OPENING)
	else:
		_begin_opening()
	_set_debug(show_debug)


func _unhandled_input(event: InputEvent) -> void:
	if _hint_mode == "ok" and event.is_action_pressed("ui_accept"):
		_finish_hint()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("toggle_debug"):
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
	var waited := 0
	if _floor_started:
		# Owner rule (#8): durations finish between floors - but the time they
		# still needed is spent (#65), so the stairs aren't a free rest.
		waited = _party_state.remaining_effect_time()
		_party_state.advance_time(waited)
		_party_state.complete_pending_effects()
	_floor_started = true
	_depth = depth
	_apply_theme()
	_expedition.visit_floor(depth)
	if not _floors.has(depth):
		var layout := _make_layout(depth)
		var marks := {}
		if depth == FORTRESS_DEPTH and not use_debug_layout:
			var fortress: Dictionary = Fortress.fortify(layout, _camp_state.gate_broken)
			layout = fortress["layout"]
			marks = {"hall": fortress["hall"], "gates": fortress["gates"]}
		# Quest packages the story wants here (#123), stamped into rock.
		# Never join a package through the queen's hall or past her gates.
		var avoid: Array = marks.get("hall", []) + marks.get("gates", [])
		var join: Dictionary = {}
		if not avoid.is_empty():
			var plain = DungeonMap.new(layout, depth)
			join = plain.walking_distances(plain.find_content(DungeonMap.Content.STAIRS_UP))
		var stamped: Dictionary = Packages.place(layout, Packages.active(_camp_state, depth) if not _in_opening else [], _site_seed + depth * 7919 + 13, avoid, join)
		_floors[depth] = DungeonMap.new(stamped["layout"], depth)
		_floors[depth].marks = marks
		_assign_events(_floors[depth])
		for cell in stamped["events"]:
			_floors[depth].events[cell] = stamped["events"][cell]
		_floors[depth].fight_groups = stamped["fights"]
		_floors[depth].packages = stamped["placed"]
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
	elif waited > 0:
		_show_message("%s · depth %d · waited %d while it took hold" % [environment_theme.display_name, depth, waited])
	else:
		_show_message("%s · depth %d" % [environment_theme.display_name, depth])
	_fortress_signs(depth)
	_save_now()  # autosave on every floor change (#45)


func _build_level() -> void:
	if _level:
		_level.queue_free()
	_level = LevelBuilder.new()
	var visual_theme: EnvironmentTheme=environment_theme
	if _depth==OPENING_DEPTH and _in_opening and _exit_cell!=Vector2i(-1,-1):
		visual_theme=environment_theme.duplicate()
		visual_theme.ascent_scene=preload("res://art/features/daylight-exit-v1/scene.tscn")
	_level.build(_map, visual_theme, CELL_SIZE, WALL_HEIGHT)
	_play_place_music()
	add_child(_level)
	_add_room_props()
	if _depth == OPENING_DEPTH and _in_opening:
		_add_opening_dressing()
	elif _depth == OUTSKIRTS_DEPTH and not use_debug_layout:
		_add_outskirts_dressing()
	elif _depth==FORTRESS_DEPTH:
		_add_fortress_dressing()
	if not _in_opening and not use_debug_layout:
		var landmarks := Landmarks.place(_level, _map, _depth, _site_seed, CELL_SIZE, WALL_HEIGHT)  # #117
		Dressing.dress(_level, _map, _depth, _site_seed, CELL_SIZE, WALL_HEIGHT, landmarks)  # #128


func _make_layout(depth: int) -> PackedStringArray:
	if depth == OPENING_DEPTH:
		return _opening["layout"]
	if use_debug_layout and depth == 1:
		return PackedStringArray(DEBUG_LAYOUT)
	return FloorGenerator.generate(_site_seed + (depth - 1) * FLOOR_SEED_STEP, depth < floors_in_site, depth)


func _on_party_entered_cell(cell: Vector2i) -> void:
	# A landmark (#117): named the first time, marked on the map from then on.
	var landmark: Dictionary = Landmarks.at_cell(_map, cell)
	if not landmark.is_empty() and not landmark["seen"]:
		landmark["seen"] = true
		_show_message(landmark["name"] + ".")
		_minimap.queue_redraw()
		_full_map_view.queue_redraw()
	# The queen's hall (#44): a warning, then no turning back.
	if _depth == FORTRESS_DEPTH and cell in _map.marks.get("hall", []) and not _camp_state.queen_defeated:
		_ask("The queen's hall. Once you step inside, there's no turning back. Go in?",
				_queen_fight.bind(cell), _step_back)
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
		var fixed: Array[EnemyType] = []  # a quest package's own fight (#123)
		fixed.assign(_map.fight_groups.get(fight_cell, []))
		_start_combat(fight_cell, fixed)
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
				_ask("%s Leave the mine?" % environment_theme.exit_message,
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
	_begin_encounter(cell)
	_room_events.depth = _depth  # deeper floors hold richer treasure (#42)
	if not _map.event_flags.has(cell):
		_map.event_flags[cell] = []
	_event_screen.show_event(event, _party_state, _room_events, _map.event_flags[cell])
	var result: Dictionary = await _event_screen.finished
	_end_encounter()
	for item in result.get("no_room", {}):
		_left_over(item, result["no_room"][item])
	# A chest may hold finer gear (owner, 2026-10-21).
	if not result["left"] and event.kind == DungeonMap.Content.CHEST and result["ambush"].is_empty() and not _in_opening:
		var gear: Equipment = GearGen.drop(_rng, _depth, "chest")
		if gear:
			_found_gear(gear, "Underneath: %s." % _a(gear.display_name.to_lower()))
	await _offer_overflow()
	_party.locked = false
	if result["left"]:
		_map.triggered.erase(cell)
		return
	_empty_prop(cell)
	if Quests.has_flag(_camp_state, "lower_gate", "seen") and not Quests.has_flag(_camp_state, "lower_gate", "ending_shown"):
		await _slice_ending()
	if _in_opening and cell in _opening_body_cells():
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
	_active_fight = types.duplicate()
	_begin_encounter(cell)
	var opening_spider := _in_opening and _opening_fights_done == OPENING_FIGHTS.size() - 1
	if types.is_empty():
		types.assign(encounter_pool(_depth, _party_state.living_members().size()).pick_random())
	var state = CombatState.new(_party_state, types)
	if not _in_opening:
		state.prepare(_depth, _fight_kind)  # deeper is tougher; some elites (#140)
	if opening_spider:
		for foe in state.foes:
			foe.has_webbed = true  # the opening's spider bites first (#59)
			foe.glancing = true  # and only fire drives it off (#69)
			state.plan(foe)
	_party.face_open(cell if cell != _party.cell else Vector2i(-1, -1))  # never fight a wall (#111)
	_place_foes(state.foes)
	_in_combat = true
	# Fog surges up from the floor and the cave fades to near-black: the
	# fight takes place on a dark stage, so enemies never meet the walls.
	_stage.enter(Settings.get_value("flashes"))  # plays as the fight opens
	_update_hints("fight")
	_say("fight_start", true, false, _any_voice())
	_party.locked = true
	_touch_pad.visible = false
	_pack_button.disabled = true
	if _music:
		_music.play("combat")
	_combat.run(state, _cards)
	var result: int = await _combat.finished
	for hero: Companion in _party_state.members:
		hero.fight_ended()  # fight-long boons and banes count down (#133)
	for foe in state.foes:
		if foe.health <= 0:
			_expedition.add_defeated(foe.type.display_name)
			_camp_state.count_kill(foe.type.display_name)  # today's contract (#42)
	# A win: the spoils, on the dark stage, arriving the way the last enemy
	# fell (owner, 2026-10-20). Otherwise purses are picked up as before.
	var spoils := _gather_spoils(state) if result == CombatState.Result.VICTORY else {}
	if result != CombatState.Result.VICTORY:
		for foe in state.foes:
			if foe.health <= 0:
				_loot_purse(foe)
	if not spoils.is_empty():
		await _spoils.play(spoils, _combat.last_blow, Settings.get_value("flashes"))
	if result == CombatState.Result.VICTORY:
		_trinket_drops(state)
		await _offer_overflow()
	await _stage.exit()  # the fog sinks back; the cave returns
	_play_place_music()
	for foe in state.foes:
		if is_instance_valid(foe.node):
			foe.node.queue_free()
	_in_combat = false
	_end_encounter()
	_combat.only_action = ""
	_combat.no_retreat = false
	_layout_hint()
	_touch_pad.visible = true
	_pack_button.disabled = false
	match result:
		CombatState.Result.VICTORY:
			_party.locked = false
			if spoils.is_empty():
				_show_message("The way is clear.")
			match _fight_kind:
				"gate": _break_gates()
				"queen": _queen_defeated()
			_say("fight_won", true, false, _any_voice())
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
	_fight_kind = ""


# --- Experience (#47) ---------------------------------------------------

## A fight won: every hero still with the party learns from it. Ordinary
## fights draw on the floor's limited fight XP; the gate and the queen are
## one-off awards instead.
## Gold and experience from a won fight, applied now and returned for the
## spoils screen: {"gold", "heroes": [{"hero", "from", "to"}], "note",
## "contract"}. Empty when there's nothing to show (the opening).
func _gather_spoils(state) -> Dictionary:
	if _in_opening or _depth < 1:
		return {}
	var gold := 0
	for foe in state.foes:
		if foe.health <= 0:
			gold += _take_purse(foe)
	var amount := _fight_xp(state)
	var heroes := []
	var before := {}
	for hero: Companion in _party_state.members:
		if hero.is_with_party():
			before[hero] = hero.xp
	if amount > 0:
		_grant_xp(amount, true)
		for hero in before:
			heroes.append({"hero": hero, "from": before[hero], "to": hero.xp})
	var note := "Nothing more to learn on this floor." if amount <= 0 and _fight_kind == "" else ""
	var contract := ""
	var c: Dictionary = _camp_state.contract
	if c.has("enemy") and not c.get("paid", true):
		contract = "Contract: %d of %d %s" % [c["done"], c["count"], c["plural"]]
	if gold > 0:
		Sounds.play(self, "coins")
	if gold == 0 and heroes.is_empty() and note == "":
		return {}
	return {"gold": gold, "heroes": heroes, "note": note, "contract": contract}


## Tougher foes sometimes leave a trinket (#135): fine or rare jewellery,
## or on floors 2+ a cursed one. Into the pack if there's room.
func _trinket_drops(state) -> void:
	if _in_opening or _depth < 1:
		return
	for foe in state.foes:
		if foe.health > 0:
			continue
		var find = Trinkets.drop(_rng, _depth, foe.type.max_health, foe.elite != "")
		var gear: Equipment = GearGen.drop(_rng, _depth, "foe", foe.type.max_health, foe.elite != "")
		if foe.type.drop and _rng.randf() < foe.type.drop_chance:  # a hollow miner's pick (#140)
			if _party_state.supplies.add_what_fits(foe.type.drop) > 0:
				_show_message("The %s's %s clatters free. It's in the pack." % [foe.type.display_name.to_lower(), foe.type.drop.display_name.to_lower()])
			else:
				_left_over(foe.type.drop, 1)
		if gear:
			_found_gear(gear, "The %s carried %s." % [foe.type.display_name.to_lower(), _a(gear.display_name.to_lower())])
		if find == null:
			continue
		var name: String = find.display_name.to_lower()
		if find is Equipment:
			if not _party_state.supplies.has_room_for_gear():
				_left_over(find, 1)  # offered beside the pack
				continue
			_party_state.supplies.gear.append(find)
			_party_state.supplies.changed.emit()
		elif _party_state.supplies.add_what_fits(find) == 0:
			_left_over(find, 1)
			continue
		_show_message("The %s wore %s. It's in the pack." % [foe.type.display_name.to_lower(), _a(name)])


## "a goblin", "an ash-shaft spear".
static func _a(noun: String) -> String:
	return ("an " if noun.substr(0, 1) in ["a", "e", "i", "o", "u"] else "a ") + noun


## Finer weapons and armour found (owner, 2026-10-21): into the pack if
## there's room, else offered beside it to swap for.
func _found_gear(gear: Equipment, line: String) -> void:
	if not _party_state.supplies.has_room_for_gear():
		_show_message(line)
		_left_over(gear, 1)
		return
	_party_state.supplies.gear.append(gear)
	_party_state.supplies.changed.emit()
	_show_message(line + " It's in the pack.")


## The fight's experience for the party, drawn from the floor's allowance.
func _fight_xp(state) -> int:
	var amount := 0
	match _fight_kind:
		"gate":
			amount = Progression.GATE_XP
		"queen":
			amount = Progression.QUEEN_XP + Progression.CLEARED_XP
		_:
			var threat := 0
			for foe in state.foes:
				if not foe.is_alive():
					threat += foe.type.threat
			amount = _camp_state.take_floor_xp(_depth, threat * Progression.XP_PER_THREAT)
	return amount


## Everyone with the party gets the full award; anyone below the camp's
## benchmark (one level under its best) gets it twice until they catch up.
func _grant_xp(amount: int, quiet := false) -> void:
	var benchmark: int = Progression.THRESHOLDS[maxi(1, _camp_state.best_level - 1)] if _camp_state.best_level > 1 else 0
	for hero: Companion in _party_state.members:
		if not hero.is_with_party():
			continue
		var extra := clampi(benchmark - hero.xp, 0, amount)
		var was_ready := Progression.ready_to_advance(hero)
		hero.xp += amount + extra
		if not was_ready and Progression.ready_to_advance(hero) and not quiet:
			_show_message("%s is ready to advance - choose at camp." % hero.display_name)
		hero.emit_changed()


## A beaten enemy's purse (goblins, #42).
func _loot_purse(foe) -> void:
	var coins := _take_purse(foe)
	if coins > 0:
		_show_message("+%d gold" % coins)
		Sounds.play(self, "coins")


## Takes a beaten enemy's purse into the pack. Returns the coins.
func _take_purse(foe) -> int:
	var purse: Vector2i = foe.type.purse
	if purse.y <= 0:
		return 0
	var coins := randi_range(purse.x, purse.y)
	_party_state.supplies.gold += coins
	_party_state.supplies.changed.emit()
	_expedition.gold_found += coins
	return coins


## The enemy groups a party of `party_size` can meet at `depth` (#49).
static func encounter_pool(depth: int, party_size: int) -> Array:
	var groups: Array = ENCOUNTER_GROUPS.get(clampi(depth, 1, ENCOUNTER_GROUPS.size()))
	var cap := party_size + (1 if party_size >= PartyState.MAX_MEMBERS and depth >= 3 else 0)
	var fitting := groups.filter(func(g: Array): return g.size() <= cap)
	if fitting.is_empty():
		return [[groups[0][0]]]
	var close := fitting.filter(func(g: Array): return g.size() >= party_size - 1)
	return close if not close.is_empty() else fitting


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
		Expedition.Ending.WIPED: "Everyone falls, and everything they carried is lost. Recruits don't come back; a main hero wakes at camp, badly hurt. New companions wait by the fire.",
		Expedition.Ending.REACHED_BOTTOM: "You stood where the others fell, and lived to climb back.",
	}
	if ending == Expedition.Ending.WIPED:
		_main_heroes_wake_at_camp()
		_wipe_pending = true
		_save_now()
	if _in_opening and ending == Expedition.Ending.RETURNED:
		_hints_done[_hint] = true
		_show_hint("")  # the escape is over: no "walk into the light" on top
		_results.show_brief("Barely survived", "You stagger out into the daylight, alone.", "To camp")
	else:
		_results.show_results(ending, _expedition, _party_state, notes[ending], _homecoming_lines())
	await _results.continue_pressed
	_results.visible = false
	if _in_opening and ending == Expedition.Ending.RETURNED:
		# Outside, the king's forces are waiting (#122, first slice).
		await _conversation.play(COMMANDER_FIRST, _party_state.members[0], _camp_state, _party_state.members)
	if ending == Expedition.Ending.WIPED:
		_party_state.supplies.lose_everything()  # the campaign goes on (#41)
	_start_new_expedition()
	_wipe_pending = false


## Placeholder camp stop, then back into the cave from the top. The cave
## remembers what was explored, opened and cleared.
func _start_new_expedition() -> void:
	var returned_from_expedition := not _in_opening
	if _in_opening:
		for item in starting_supplies:  # restocked at camp (#69)
			_party_state.supplies.add(item, starting_supplies[item])
	_end_opening()
	if returned_from_expedition:
		_camp_state.expedition_returned()
		Story.on_return(_camp_state)  # news that waited for a return (#123)
	for hero: Companion in _party_state.members:
		hero.appearance.clear()  # washed at camp
		hero.trip_ended()  # trip-long boons and banes end (#133)
		hero.emit_changed()
	# Torches light the way; a lantern is an upgrade to buy later (owner,
	# 2026-10-17). A party that has one goes back to it at camp.
	if _party_state.supplies.has_lantern:
		_party_state.supplies.source = Supplies.Source.LANTERN
		_party_state.supplies.torch_left = 0.0
	_party_state.supplies.changed.emit()
	_update_lantern()
	# The fallen are gone (main heroes are carried, #83); heroes who stayed
	# with the nurse rejoin (#41).
	for hero: Companion in _party_state.members.duplicate():
		if not hero.is_with_party():
			_party_state.remove_member(hero)
	_camp_state.rejoin(_party_state)
	_camp_state.record_depth(_expedition.deepest)  # towards the scouts' routes (#79)
	var reward: int = _camp_state.collect_contract(_party_state)
	var note := ""
	if _camp_state.queen_defeated and not _camp_state.bounty_paid:
		_camp_state.bounty_paid = true
		_party_state.supplies.gold += _camp_state.QUEEN_BOUNTY
		_party_state.supplies.changed.emit()
		note = "The camp cheers the queen's death. The quartermaster pays the bounty: %d gold." % _camp_state.QUEEN_BOUNTY
	_camp_loop(reward, note)


## The campsite (#40) until the party heads down: nothing recovers by itself
## - rest in your tent. Also where a game saved at camp resumes (#45).
func _camp_loop(reward := 0, note := "") -> void:
	_ending = true
	_party.locked = true
	_camp.open(_camp_state, _party_state)
	if _ambience_player:
		_ambience_player.stop()
	if _music:
		_music.play("camp")
	if note != "":
		_camp.announce(note)
	elif reward > 0:
		_camp.announce("The king's quartermaster pays the contract: %d gold." % reward)
	_save_now()  # autosave on returning to camp (#45)
	var start_depth: int = await _camp.cave_chosen
	_party_state.field_bind_used = false  # the field medic's binding: once a trip
	_party_state.field_binds = 0
	_camp.visible = false
	_camp_state.leave_behind(_party_state)
	_expedition = Expedition.new(_party_state, _expedition.number + 1)
	for key: String in _said.keys():
		if key.contains(":"):
			_said.erase(key)  # each hero's once-a-trip remarks (#118)
	_preparation.show_for(_expedition.number, _party_state)
	await _preparation.entered
	_ending = false
	_party.locked = false
	_go_to_floor(start_depth, Arrival.FROM_ABOVE)
	if start_depth > 1:
		for depth in range(1, start_depth):
			_expedition.visit_floor(depth)  # the scouts led them through
		_show_message("Day %d. Expedition %d: the scouts' route, straight to floor %d." % [_camp_state.day, _expedition.number, start_depth])
	else:
		_show_message("Day %d. Expedition %d: back into the mine." % [_camp_state.day, _expedition.number])
	_light_torch_if_dark()


# --- Saving (#45) -----------------------------------------------------

func _notification(what: int) -> void:
	# Closing the window, or a phone sending the app to the background.
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		if is_node_ready() and _party_state:
			_save_now()


## A full wipe (#83): recruits are lost, but an unconscious main hero
## wakes at camp, hurt and with a lasting injury.
func _main_heroes_wake_at_camp() -> void:
	for hero: Companion in _party_state.members:
		if hero.is_unconscious():
			hero.health = 1
			hero.add_injury(DEBUG_INJURIES[0])  # a deep wound
			hero.emit_changed()


## Camp changes (buying, hiring, resting) save once things settle.
func _save_soon() -> void:
	if _save_queued:
		return
	_save_queued = true
	(func():
		_save_queued = false
		if _camp.visible:
			_save_now()).call_deferred()


func save_and_exit() -> void:
	_save_now()
	get_tree().change_scene_to_file(TITLE_SCENE)


## Writes the whole campaign. During the opening only a marker is kept: the
## escape starts again on Continue. A fight or event in progress is undone
## so it happens again after loading.
## A fight or event starts at `cell`: remember the game as it is now (#113).
func _begin_encounter(cell: Vector2i) -> void:
	_active_cell = cell
	_encounter_checkpoint = {} if _in_opening else _save_data()


func _end_encounter() -> void:
	_active_cell = Vector2i(-1, -1)
	_active_fight.clear()
	_encounter_checkpoint = {}


func _save_now() -> void:
	if _in_opening:
		SaveGame.write({"opening": true, "seed": _first_seed, "hero": starting_hero.resource_path})
		return
	if _ending and not _camp.visible and not _wipe_pending:
		return  # the results screen: the camp saves next
	if not _encounter_checkpoint.is_empty():
		SaveGame.write(_encounter_checkpoint)  # mid-fight: as it stood at the start
		return
	SaveGame.write(_save_data())


## Everything a save needs, as plain data.
func _save_data() -> Dictionary:
	var people: Array = []  # every hero object once; referenced by index
	for hero in _party_state.members + _camp_state.left_behind + _camp_state.candidates:
		if hero not in people:
			people.append(hero)
	var index := func(hero): return people.find(hero)
	var at_camp: bool = _camp.visible or _preparation.visible or _wipe_pending
	var party: Array = _party_state.members.filter(func(h: Companion): return h.is_with_party() or not _wipe_pending)
	var supplies: Dictionary = SaveGame.pack_object(_party_state.supplies)
	if _wipe_pending:  # everything carried is lost (#41)
		var nothing = Supplies.new()
		nothing.lose_everything()
		supplies = SaveGame.pack_object(nothing)
	var floors := []
	for depth in _floors:
		var map = _floors[depth]
		var undo: bool = map == _map and _active_cell != Vector2i(-1, -1) and map.triggered.has(_active_cell) and _active_fight.is_empty()
		if undo:
			map.triggered.erase(_active_cell)
		floors.append([depth, SaveGame.pack_object(map)])
		if undo:
			map.triggered[_active_cell] = true
	var recovering := []
	for hero in _camp_state.recovering:
		recovering.append([index.call(hero), _camp_state.recovering[hero]])
	var start_heroes := []
	for hero in _expedition._start_heroes:
		if hero in people:
			start_heroes.append([index.call(hero), SaveGame.pack_value(_expedition._start_heroes[hero])])
	return {
		"seed": _site_seed, "first_seed": _first_seed, "depth": _depth,
		"at_camp": at_camp, "cell": _party.cell, "facing": _party.facing,
		"resume": not at_camp and _active_cell != Vector2i(-1, -1),
		"resume_fight": _active_fight.map(func(t): return t.resource_path),
		"resume_kind": _fight_kind,
		"people": people.map(func(h): return SaveGame.pack_object(h)),
		"party": party.map(func(h): return index.call(h)),
		"time": _party_state.time_elapsed,
		"supplies": supplies,
		"camp": SaveGame.pack_object(_camp_state, ["stash", "candidates", "left_behind", "recovering", "rng"]),
		"stash": SaveGame.pack_object(_camp_state.stash),
		"candidates": _camp_state.candidates.map(func(h): return index.call(h)),
		"left_behind": _camp_state.left_behind.map(func(h): return index.call(h)),
		"recovering": recovering,
		"camp_rng": _camp_state.rng.state,
		"expedition": SaveGame.pack_object(_expedition, ["_start_heroes"]),
		"start_heroes": start_heroes,
		"floors": floors,
	}


## Rebuilds the campaign from a save and carries on where it left off.
func _restore(data: Dictionary) -> void:
	_site_seed = data["seed"]
	_first_seed = data["first_seed"]
	var people: Array = data["people"].map(func(d):
		var hero := Companion.new()
		SaveGame.unpack_into(hero, d)
		return hero)
	_party_state.members.assign(data["party"].map(func(i): return people[i]))
	_party_state.time_elapsed = data["time"]
	SaveGame.unpack_into(_party_state.supplies, data["supplies"])
	_party_state.update_capacity()  # pack space follows the party (#133)
	SaveGame.unpack_into(_camp_state, data["camp"])
	SaveGame.unpack_into(_camp_state.stash, data["stash"])
	_camp_state.candidates.assign(data["candidates"].map(func(i): return people[i]))
	_camp_state.left_behind.assign(data["left_behind"].map(func(i): return people[i]))
	_camp_state.recovering = {}
	for pair in data["recovering"]:
		_camp_state.recovering[people[pair[0]]] = pair[1]
	_camp_state.rng.state = data["camp_rng"]
	_expedition = Expedition.new(_party_state, data["expedition"]["number"])
	SaveGame.unpack_into(_expedition, data["expedition"])
	for pair in data["start_heroes"]:
		_expedition._start_heroes[people[pair[0]]] = SaveGame.unpack_value(pair[1])
	_floors = {}
	for pair in data["floors"]:
		var map = DungeonMap.new(pair[1]["_rows"], pair[0])
		SaveGame.unpack_into(map, pair[1])
		_floors[pair[0]] = map
	_floor_started = true
	_party_state.changed.emit()
	_party_state.supplies.changed.emit()
	_refresh_cards()
	_on_party_state_changed(false)
	_update_lantern()
	if data["at_camp"]:
		_camp_state.rejoin(_party_state)  # saved right after a wipe: they're back
		_refresh_cards()
		_camp_loop()
		return
	_depth = data["depth"]
	_map = _floors[_depth]
	_build_level()
	_minimap.setup(_map)
	_full_map_view.setup(_map)
	_party.place(_map, data["cell"])
	_party.facing = data["facing"]
	_party.rotation.y = -_party.facing * PI / 2.0
	_party.moved.emit(_party.cell, _party.facing)
	_show_message("%s · depth %d · continued" % [environment_theme.display_name, _depth])
	if data["resume"]:  # an interrupted fight or event happens again
		var fight: Array[EnemyType] = []
		for path in data.get("resume_fight", []):
			if ResourceLoader.exists(path):
				fight.append(load(path))
		if fight.is_empty():
			_on_party_entered_cell.call_deferred(_party.cell)
		else:  # an ambush, the gate or the queen: the same fight again
			_fight_kind = data.get("resume_kind", "")
			_combat.no_retreat = _fight_kind == "queen"
			_start_combat.call_deferred(_party.cell, fight)


## Going in without a light: a torch is lit at the cave mouth, if there is one.
func _light_torch_if_dark() -> void:
	var supplies = _party_state.supplies
	if supplies.source == Supplies.Source.NONE and supplies.count(TORCH) > 0:
		supplies.light_torch(TORCH)


# --- Room contents (#46) ---------------------------------------------

## Chests, objects and rest spots show in their rooms. Unresolved traps need
## Keen eyes; resolved traps stay visible to everyone. Enemies still ambush.
func _add_room_props() -> void:
	_props.clear()
	if _map == null:
		return
	for cell in _map.events:
		var event: RoomEvent = _map.events[cell]
		if _map.solid.has(cell):
			continue
		if event.kind == DungeonMap.Content.TRAP and not _party_state.sees_traps() and not _map.triggered.has(cell):
			continue  # hidden - unless Mara's keen eyes spot it (#95)
		_create_room_prop(cell,event)
		if _map.triggered.has(cell):
			_empty_prop(cell)


func _create_room_prop(cell: Vector2i,event: RoomEvent) -> Node3D:
	var node: Node3D = event.prop.instantiate() if event.prop else _placeholder_prop(event.kind)
	if node:
		node.position = Vector3(cell.x * CELL_SIZE, 0.0, cell.y * CELL_SIZE)
		if event.prop_on_wall:
			# Against a wall of its cell, facing in (the shrine's art, #132).
			for side in Dressing.SIDES:
				if _map.is_wall(cell + side):
					node.position += Vector3(side.x, 0, side.y) * (CELL_SIZE / 2.0 - 0.01)
					node.rotation.y = Dressing._yaw_facing(-side)
					break
		_level.add_child(node)
		_props[cell] = node
	return node


func _empty_prop(cell: Vector2i) -> void:
	var node = _props.get(cell)
	# A trap hidden from this hero gains its resolved prop immediately.
	if node == null and _map != null and _map.triggered.has(cell) and not _map.solid.has(cell):
		var event: RoomEvent = _map.events.get(cell)
		if event:node = _create_room_prop(cell,event)
	if node and "state" in node:
		node.set("state", "empty")


## Simple shapes until the props arrive (#96): a pale stone for strange
## objects, a ring of stones for rest spots, a rock pile for anything else.
func _placeholder_prop(kind: int) -> Node3D:
	var root := Node3D.new()
	var stone := StandardMaterial3D.new()
	stone.albedo_color = Color(0.45, 0.43, 0.4)
	match kind:
		DungeonMap.Content.STRANGE_OBJECT:
			var pale := StandardMaterial3D.new()
			pale.albedo_color = Color(0.85, 0.83, 0.76)
			var plinth := MeshInstance3D.new()
			var box := BoxMesh.new()
			box.size = Vector3(0.5, 0.5, 0.5)
			box.material = stone
			plinth.mesh = box
			plinth.position.y = 0.25
			root.add_child(plinth)
			var figure := MeshInstance3D.new()
			var capsule := CapsuleMesh.new()
			capsule.radius = 0.12
			capsule.height = 0.45
			capsule.material = pale
			figure.mesh = capsule
			figure.position.y = 0.72
			root.add_child(figure)
		DungeonMap.Content.TRAP:  # only for keen eyes: a rusted spike plate
			var plate := MeshInstance3D.new()
			var board := BoxMesh.new()
			board.size = Vector3(0.9, 0.04, 0.9)
			var rust := StandardMaterial3D.new()
			rust.albedo_color = Color(0.5, 0.25, 0.15)
			board.material = rust
			plate.mesh = board
			plate.position.y = 0.02
			root.add_child(plate)
			for i in 9:
				var spike := MeshInstance3D.new()
				var cone := CylinderMesh.new()
				cone.top_radius = 0.0
				cone.bottom_radius = 0.04
				cone.height = 0.18
				cone.material = rust
				spike.mesh = cone
				spike.position = Vector3(-0.3 + (i % 3) * 0.3, 0.12, -0.3 + (i / 3) * 0.3)
				root.add_child(spike)
		DungeonMap.Content.REST_SPOT:
			for i in 7:
				var rock := MeshInstance3D.new()
				var sphere := SphereMesh.new()
				sphere.radius = 0.09
				sphere.height = 0.12
				sphere.material = stone
				rock.mesh = sphere
				var angle := TAU * i / 7.0
				rock.position = Vector3(cos(angle) * 0.35, 0.05, sin(angle) * 0.35)
				root.add_child(rock)
		_:
			for i in 4:
				var rock := MeshInstance3D.new()
				var box := BoxMesh.new()
				box.size = Vector3(0.3, 0.22, 0.26) * (1.0 - i * 0.15)
				box.material = stone
				rock.mesh = box
				rock.position = Vector3(-0.2 + i * 0.13, 0.11, (i % 2) * 0.15)
				rock.rotation.y = i * 0.7
				root.add_child(rock)
	return root


# --- The goblin fortress (#44) ------------------------------------------

## Floors 1-3 are cave; the fortress floor has its own look and sound.
func _apply_theme() -> void:
	var theme: EnvironmentTheme = FORTRESS_THEME if _depth >= FORTRESS_DEPTH and not use_debug_layout else _cave_theme
	environment_theme = theme
	_refresh_place_ambience()


func _refresh_place_ambience() -> void:
	if _ambience_player == null:
		return
	var stream: AudioStream = Sounds.LOOPS["outskirts"] if _depth == OUTSKIRTS_DEPTH and not use_debug_layout and not _camp_state.queen_defeated else environment_theme.ambience
	if _ambience_player.stream != stream:
		_ambience_player.stop()
		_ambience_player.stream = stream
	if stream and not _ambience_player.playing:
		_ambience_player.play()


## Signs of the fortress: marks and drums on its outskirts, the gate below.
func _fortress_signs(depth: int) -> void:
	if use_debug_layout or _camp_state.queen_defeated:
		return
	if depth == OUTSKIRTS_DEPTH:
		_show_message("Goblin marks daubed on the rock. Somewhere below: drums.")
	elif depth == FORTRESS_DEPTH:
		_show_message("Worked stone and timber: the goblin fortress." if _camp_state.gate_broken
				else "Worked stone and timber: the goblin fortress. Her hall lies beyond a barred gate.")


func _gate_fight() -> void:
	_fight_kind = "gate"
	var types: Array[EnemyType] = []
	types.assign(GATE_FIGHT)
	_start_combat(_party.cell, types)


## The gate's guards are beaten: it stays broken for good, whatever the day.
## Nerves steadied when the gate falls (balance report, owner 2026-10-19).
const GATE_RELIEF := 15.0


func _break_gates() -> void:
	_camp_state.gate_broken = true
	for hero: Companion in _party_state.living_members():
		hero.change_strain(-GATE_RELIEF)  # courage rises as the gate splinters
	for gate in _map.marks.get("gates", []):
		_map.doors[gate] = DungeonMap.Door.OPEN
	_build_level()
	Sounds.play(self, "gate", -6.0)
	_show_message("The gate splinters. The way to the queen's hall is open.")
	_save_now()


func _queen_fight(cell: Vector2i) -> void:
	_fight_kind = "queen"
	_combat.no_retreat = true
	var types: Array[EnemyType] = []
	types.assign(QUEEN_FIGHT)
	_start_combat(cell, types)


## Declined the hall: back out the way she came.
func _step_back() -> void:
	if _cell_before != Vector2i(-1, -1) and _map.is_passable(_cell_before):
		_party.place(_map, _cell_before)


## The site is cleared (#44): a story beat, a bounty waiting at camp.
func _queen_defeated() -> void:
	_camp_state.queen_defeated = true
	Quests.set_stage(_camp_state, "queen_claim", Quests.Stage.RESOLVED)  # a side quest now (#122)
	_camp_state.contract = {}
	_save_now()
	_party.locked = true
	# Her hoard holds something unique (#135).
	var owned: Array = _party_state.members.map(func(h): return h.trinket) + _party_state.supplies.gear
	var prize: Equipment = Trinkets.unique_reward(_rng, owned)
	if prize:
		if _party_state.supplies.has_room_for_gear():
			_party_state.supplies.gear.append(prize)
		else:
			_camp_state.stash.gear.append(prize)  # carried up for you
		_party_state.supplies.changed.emit()
	_results.show_brief("The goblin queen is dead",
			"Her guards scatter into the dark and the drums fall silent. The fortress is broken. The king's camp will want to hear of this - and pay for it." + ("

In her hoard: the %s." % prize.display_name.to_lower() if prize else ""),
			"Continue",preload("res://art/illustrations/fortress-v1/victory.png"))
	await _results.continue_pressed
	_results.visible = false
	_party.locked = false


## Small authored goblin occupation props in the existing outskirts rooms (#99).
func _add_outskirts_dressing() -> void:
	var scenes:= [
		preload("res://art/props/fortress-v1/palisade.tscn"),
		preload("res://art/props/fortress-v1/watch-post.tscn"),
		preload("res://art/props/fortress-v1/goblin-mark.tscn"),
		preload("res://art/props/fortress-v1/trophies.tscn")]
	var placed := 0
	for y in _map.height:
		for x in _map.width:
			var cell := Vector2i(x, y)
			if placed >= 10 or _map.is_wall(cell) or not _map._is_room_cell(cell) or _map.content_at(cell) != DungeonMap.Content.NONE:
				continue
			if (x * 7 + y * 13) % 11 != 0:
				continue
			var art: Node3D=scenes[placed%scenes.size()].instantiate()
			art.position=Vector3(x*CELL_SIZE+.65,0,y*CELL_SIZE+.65)
			_level.add_child(art)
			placed+=1


## A decorative seat at the back of the existing hall; no new blocker.
func _add_fortress_dressing() -> void:
	var hall: Array=_map.marks.get("hall",[])
	if hall.is_empty():return
	var seat: Vector2i=hall[0]
	var best: float=-1.0
	for cell: Vector2i in hall:
		if _map.is_wall(cell) or _map.content_at(cell)!=DungeonMap.Content.NONE:continue
		var distance:=100000.0
		for gate: Vector2i in _map.marks.get("gates",[]):distance=minf(distance,Vector2(cell).distance_squared_to(Vector2(gate)))
		if distance>best:best=distance;seat=cell
	var throne:=preload("res://art/props/fortress-v1/throne.tscn").instantiate()
	throne.position=Vector3(seat.x*CELL_SIZE,0,seat.y*CELL_SIZE)
	_level.add_child(throne)


## A foe that joins mid-fight (the queen's guards) appears beside the others.
func _place_extra_foe(foe) -> void:
	var forward := -_party.global_transform.basis.z
	var right := _party.global_transform.basis.x
	var node: Node3D = foe.type.scene.instantiate()
	node.position = _party.position + forward * CELL_SIZE * 1.0 + right * randf_range(-1.0, 1.0)
	_dress_foe(node, foe.type)
	BattleStage.raise(node)
	_level.add_child(node)
	_clear_of_panel(node)
	foe.node = node


## Visions of the past and dreams (owner, 2026-10-20): `true` drains the
## whole screen to a cold blue, `false` brings back the present. For
## scripted memories and dreams; conversations with `vision` ticked do it
## themselves.
func set_vision(on: bool) -> void:
	if on:
		await _vision.enter(Settings.get_value("flashes"))
	else:
		await _vision.exit()


## The first story slice ends at the lower water gate (docs/first-slice-
## plan.md): a short card, then play carries on in the cave as before.
func _slice_ending() -> void:
	Quests.set_flag(_camp_state, "lower_gate", "ending_shown")
	_party.locked = true
	_results.show_brief("The way down continues",
			"Below the fortress, the old channels run on into flooded galleries no map has charted. Whatever the commander is looking for, it lies further down.

This is as far as the cave goes for now. Your campaign carries on - the queen, the camp and the upper floors are still yours to finish.",
			"Continue")
	await _results.continue_pressed
	_results.visible = false
	_party.locked = false


## Optional legacy presentation adjustments; new art has its own native scale.
func _dress_foe(node: Node3D, type: EnemyType) -> void:
	node.scale *= type.sprite_scale
	var sprite := node.get_node_or_null("Sprite")
	if sprite and type.tint != Color.WHITE:
		sprite.modulate = type.tint


## A new camp day (#40): the cave re-randomizes - new layouts, fresh enemies.
func _on_camp_day_passed(day: int) -> void:
	_site_seed = _first_seed + (day - 1) * DAY_SEED_STEP
	_floors.clear()


## Stands the enemies in front of the party, spread across the corridor.
func _place_foes(foes: Array) -> void:
	var forward := -_party.global_transform.basis.z
	var right := _party.global_transform.basis.x
	# The battle stage hides the cave, so enemies always take the same spots,
	# whatever the walls (walls can't hide or clip them: BattleStage.raise).
	var ahead_open := true
	var distance := CELL_SIZE * 1.2
	var spread := {1: [0.0], 2: [-0.5, 0.5], 3: [-0.85, 0.0, 0.85], 4: [-1.05, -0.35, 0.35, 1.05]}
	# Front and back rows (#72): spread across the corridor together (so
	# their tags don't overlap), with the back row a little further off.
	var ordered: Array = foes.filter(func(f): return not f.in_back()) + foes.filter(func(f): return f.in_back())
	var offsets: Array = spread.get(ordered.size(), [0.0])
	for i in ordered.size():
		var foe = ordered[i]
		var depth := distance + (CELL_SIZE * 0.5 if foe.in_back() and ahead_open else 0.0)
		var node: Node3D = foe.type.scene.instantiate()
		node.position = _party.position + forward * depth + right * offsets[mini(i, offsets.size() - 1)]
		_dress_foe(node, foe.type)
		if foe.elite != "":
			_mark_elite(node)
		BattleStage.raise(node)
		_level.add_child(node)
		_clear_of_panel(node)
		foe.node = node


## An elite (#140) stands a little larger, with a hot rim of colour.
func _mark_elite(node: Node3D) -> void:
	node.scale *= 1.1
	var sprite: SpriteBase3D = node.get_node_or_null("Sprite")
	if sprite:
		sprite.modulate = sprite.modulate * Color(1.25, 0.95, 0.85)


## Fights take place on a dark stage with no floor in view, so a foe whose
## feet would sit behind the action panel or the party's cards (a rat, a
## guard's shield) is lifted until it stands clear of them.
func _clear_of_panel(node: Node3D) -> void:
	var camera: Camera3D = _party.camera
	var screen_height: float = get_viewport().get_visible_rect().size.y
	# The panel's top, from its own size: it may not be laid out yet when
	# the first fight starts. 16 is the fight screen's margin.
	var line: float = screen_height - 16.0 - _combat._actions.get_combined_minimum_size().y - 8.0
	for attempt in 2:  # the second pass corrects for perspective
		var lowest := -INF
		var distance := 0.0
		var sprites: Array = node.find_children("*", "SpriteBase3D", true, false)
		if node is SpriteBase3D:
			sprites.append(node)
		for sprite: SpriteBase3D in sprites:
			var box := sprite.get_aabb()
			var foot: Vector3 = sprite.global_transform * Vector3(box.get_center().x, box.position.y, 0.0)
			if camera.is_position_behind(foot):
				continue
			var y := camera.unproject_position(foot).y
			if y > lowest:
				lowest = y
				distance = (foot - camera.global_position).dot(-camera.global_transform.basis.z)
		if lowest <= line or distance <= 0.0:
			return
		var metres_per_pixel := 2.0 * distance * tan(deg_to_rad(camera.fov) / 2.0) / screen_height
		node.position.y += (lowest - line) * metres_per_pixel


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
var _hunger_states := {}  # Companion -> 0 fed, 1 hungry, 2 starving (#64)


## Strain (#12): announce state changes and let panic take over some moves.
func _on_party_state_changed(announce := true) -> void:
	_party_state.update_capacity()  # a limp, dressed or not, changes the pack (#104)
	_update_wound_dim()
	for member: Companion in _party_state.living_members():
		if not member.changed.is_connected(_on_party_state_changed):
			member.changed.connect(_on_party_state_changed)  # e.g. strain from a trap
		var state := member.strain_state()
		var before: int = _strain_states.get(member, state)
		_strain_states[member] = state
		var hunger := 0 if not member.is_hungry() else (2 if member.hunger >= StrainRules.STARVING_AFTER else 1)
		var hunger_before: int = _hunger_states.get(member, hunger)
		_hunger_states[member] = hunger
		if not announce:
			continue
		# Worse nerves or a growing hunger: the card shows it (#64).
		var card = _card_for(member)
		if state > before:
			if card:
				card.alert(PartyCard.NERVES_ICON, PartyCard.STRAIN_BORDERS[state])
			if state == StrainRules.State.PANICKING and not _in_opening:
				_say("panic", true, false, member)
			elif state == StrainRules.State.SHAKEN and not _in_opening:
				_say("shaken", false, true, member)
		if hunger > hunger_before and card:
			card.alert(PartyCard.RATION.icon, Color("e0542f") if hunger == 2 else Color.WHITE)
	# No random bolting during the opening: panic shows, but the controls
	# tutorial shouldn't fight the player (#30).
	var panicking: bool = _party_state.panicking_member() != null and not _in_opening
	_party.panic_chance = StrainRules.PANIC_BOLT_CHANCE if panicking else 0.0
	# Badly hurt: say so once per expedition (not during fights).
	for member: Companion in _party_state.living_members():
		if announce and not _in_combat and member.health * 4 <= member.effective_max_health():
			_say("hurt", false, true, member)
	# Falling outside a fight (a trap, a bad drink) ends the expedition too.
	if announce and _party_state.living_members().is_empty() and not _in_combat and not _ending:
		_end_expedition.call_deferred(Expedition.Ending.WIPED)


func _card_for(hero: Companion):
	for card in _cards:
		if card.companion == hero:
			return card
	return null


func _on_party_panicked() -> void:
	var who: Companion = _party_state.panicking_member()
	_show_message("%s panics and bolts!" % (who.display_name if who else "Someone"))


# --- Opening escape (#30) -------------------------------------------------

func _begin_opening() -> void:
	_in_opening = true
	_opening = OpeningGenerator.generate(_site_seed)
	var hero: Companion = _party_state.members[0]
	# Hurt, bleeding and filthy, but panic is held back until later (#56, #69).
	hero.health = roundi(hero.effective_max_health() * OPENING_START_HEALTH / 20.0)  # half, as Mara's 10/20
	_starting_weapon = hero.weapon
	_opening_weapon = hero.companion_weapon if hero.companion_weapon else IRON_SWORD
	hero.strain = OPENING_START_STRAIN
	hero.strain_locked = true
	hero.min_health = OPENING_MIN_HEALTH
	hero.appearance = ["blood", "dirt"]
	hero.bleeding = true
	hero.emit_changed()  # redraw the card with the overlays
	_refresh_cards()  # just Mara: no empty slots during the escape
	_party.move_time = OPENING_MOVE_TIME
	_party.turn_time = OPENING_TURN_TIME
	_next_fight_at = NEVER  # fights wait until she's through the second web
	# No lantern: the fire lights the room; torches must be found (#59).
	# The torch doesn't burn down here; she loses it by tripping (#69).
	_party_state.supplies.has_lantern = false
	_party_state.supplies.source = Supplies.Source.NONE
	_party_state.supplies.torch_burns = false
	_party_state.supplies.changed.emit()
	_update_lantern()
	_party.step_check = _opening_step_check
	if not _party.refused.is_connected(_on_step_refused):
		_party.refused.connect(_on_step_refused)
		_party_state.supplies.torch_burnt_out.connect(_on_torch_burnt_out)
		_combat.enemy_acted.connect(_on_combat_enemy_acted)
		_combat.hero_acted.connect(_on_combat_hero_acted)
		_party_state.changed.connect(_refresh_tutorial_hint)
	_minimap.visible = false  # no map during the escape
	_on_party_state_changed(false)
	_go_to_floor(OPENING_DEPTH, Arrival.OPENING)
	for i in OPENING_BODY_EVENTS.size():
		var body: Vector2i = _opening_body_cells()[i]
		_map.contents[body] = DungeonMap.Content.CHEST  # searchable, via its event
		var body_event: RoomEvent = OPENING_BODY_EVENTS[i]
		if body_event.choices[0].outcomes[0].gear.has(IRON_SWORD):
			# This hero's own fitting weapon instead of the shared sword.
			body_event = body_event.duplicate(true)
			var gear: Array[Equipment] = [_opening_weapon]
			body_event.choices[0].outcomes[0].gear = gear
		_map.events[body] = body_event
		_map.solid[body] = true  # searched from beside, not stood on (#69)
	_map.solid[_opening_fire_cell()] = true
	# Wake facing down the room toward the way out, the bodies in view.
	_party.facing = 1
	_party.rotation.y = -PI / 2.0
	_party.moved.emit(_party.cell, _party.facing)
	_wake_up()


## Eyes open slowly and the head lifts from the floor; then the bodies are
## in view and the line about them appears. She keeps blinking a while
## after she's up (#69).
func _wake_up() -> void:
	_party.locked = true
	_party.camera.rotation.x = deg_to_rad(WAKE_PITCH_DEGREES)
	_set_eyelids(0.0)
	_eyelids.visible = true
	var lids := create_tween()
	lids.tween_interval(1.0)
	lids.tween_method(_set_eyelids, 0.0, 0.35, 0.8)
	lids.tween_method(_set_eyelids, 0.35, 0.0, 0.35)
	lids.tween_interval(0.6)
	lids.tween_callback(_say.bind("wake", true))
	lids.tween_method(_set_eyelids, 0.0, 0.7, 0.9)
	lids.tween_method(_set_eyelids, 0.7, 0.15, 0.3)
	lids.tween_method(_set_eyelids, 0.15, 0.85, 1.1)
	var look := create_tween()
	look.tween_interval(2.2)
	look.tween_property(_party.camera, "rotation:x", 0.0, 3.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await look.finished
	_party.locked = false
	_show_message(opening_message)
	_update_hints("start")
	# Still dazed: a few heavy blinks while she finds her feet.
	var blinks := create_tween()
	for gap in [0.5, 1.1, 1.6]:
		blinks.tween_interval(gap)
		blinks.tween_method(_set_eyelids, 0.85, 0.0, 0.18)
		blinks.tween_interval(0.12)
		blinks.tween_method(_set_eyelids, 0.0, 0.9, 0.35)
	blinks.tween_method(_set_eyelids, 0.9, 1.0, 0.6)
	blinks.tween_callback(func(): _eyelids.visible = false)
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
		hero.bleeding = false
		hero.emit_changed()
	_party.move_time = Party.MOVE_TIME
	_party.turn_time = Party.TURN_TIME
	_party.step_check = Callable()
	_party_state.supplies.torch_burns = true
	_minimap.visible = true
	_show_hint("")
	_refresh_cards()


## Bleeding: a point of health every few steps until daylight appears.
func _on_opening_step(_cell: Vector2i) -> void:
	if not _in_opening:
		return
	_steps_taken += 1
	_bleed_clock += _party_state.step_time()
	var hero: Companion = _party_state.members[0]
	if _bleed_clock >= BLEED_EVERY and hero.bleeding:
		_bleed_clock = 0
		hero.change_health(-1)
		_bleed_pulse(hero)
		_say("bleeding", true, true)
	# Explain the bleeding once nothing more pressing is on screen.
	if not _hints_done.has("bleeding") and _said.has("bleeding") and _hint in ["", "turn"]:
		_show_hint("Bleeding: %s loses health with every step. Find a way out." % hero.display_name, "bleeding", "ok")
	if _steps_taken == _trip_at:
		_trip()
	# Lost and hurrying: now and then at a junction, and once to find the exit.
	if _opening_fights_done >= 1:
		_say("find_exit", false, true)
	if _steps_taken - _last_lost_remark >= LOST_REMARK_EVERY and _open_ways(_party.cell) >= 3:
		_last_lost_remark = _steps_taken
		_say("explore" if _web2_at < 0 else "lost")
	_check_opening_exit()


## One point lost to bleeding (#71): the edges flash red and her heart
## thumps, harder and faster the weaker she is. The first is the strongest
## of the early ones, to go with the bleeding card.
func _bleed_pulse(hero: Companion) -> void:
	_bleed_ticks += 1
	var weakness := 1.0 - clampf(float(hero.health) / hero.effective_max_health(), 0.0, 1.0)
	var beats := 2 + roundi(weakness * 3.0)
	var gap := lerpf(0.8, 0.4, weakness)
	_heart_player.pitch_scale = lerpf(1.0, 1.15, weakness)
	for i in beats:
		get_tree().create_timer(i * gap).timeout.connect(_heart_player.play)
	if not screen_flashes or not Settings.get_value("flashes"):
		return
	var peak := lerpf(0.45, 0.85, weakness)
	if _bleed_ticks == 1:
		peak = maxf(peak, 0.75)
	if _wound_tween:
		_wound_tween.kill()
	_wound_tween = create_tween()
	_wound_tween.tween_method(_set_wound_flash, 0.0, peak, 0.07)
	_wound_tween.tween_method(_set_wound_flash, peak, 0.0, lerpf(0.45, 0.9, weakness))


func _set_wound_flash(amount: float) -> void:
	_wound_overlay.material.set_shader_parameter("flash", amount)


## Badly hurt and bleeding: the edges stay dark between ticks, closing in
## as health falls below half (#71). Clears when the bleeding stops.
func _update_wound_dim() -> void:
	if _wound_overlay == null:
		return
	var dim := 0.0
	var living: Array[Companion] = _party_state.living_members()
	if screen_flashes and Settings.get_value("flashes") and not living.is_empty() and living[0].bleeding:
		var fraction := float(living[0].health) / living[0].effective_max_health()
		dim = clampf((0.5 - fraction) / 0.5, 0.0, 1.0) * 0.55
	_wound_overlay.material.set_shader_parameter("dim", dim)


func _open_ways(cell: Vector2i) -> int:
	return Party.DIRECTIONS.filter(func(d): return _map.is_passable(cell + d)).size()


## Through the second web: from here on the fights come (#69).
func _on_opening_web_torn(cell: Vector2i) -> void:
	if not _in_opening or cell != _opening["web2"] or _web2_at >= 0:
		return
	_web2_at = _steps_taken
	_next_fight_at = _steps_taken + OPENING_FIRST_FIGHT_AFTER
	_say("web2", true)


func _on_opening_fight_won() -> void:
	_opening_fights_done += 1
	match _opening_fights_done:
		1:  # a chest turns up, with her first healing (#69)
			_next_fight_at = _steps_taken + OPENING_SECOND_FIGHT_AFTER
			_place_opening_chest()
		2:  # she trips soon after, and the torch goes out
			_next_fight_at = NEVER
			_trip_at = _steps_taken + OPENING_TRIP_AFTER
		_:
			_last_fight_step = _steps_taken


## Once all three fights are over and she's weak enough, daylight opens a
## few steps ahead (or anyway, if she's walked a very long way). The ways
## off the path to it close behind her, so it can't be avoided (#69).
func _check_opening_exit() -> void:
	if not _in_opening or _in_combat or _exit_cell != Vector2i(-1, -1):
		return
	var hero: Companion = _party_state.members[0]
	var fights_over := _opening_fights_done >= OPENING_FIGHTS.size()
	var can_leave := fights_over and (hero.health <= EXIT_HEALTH or _steps_taken - _last_fight_step >= OPENING_EXIT_AFTER_LAST_FIGHT)
	var walked_too_far := _web2_at >= 0 and _steps_taken - _web2_at >= OPENING_STEP_LIMIT
	if not can_leave and not walked_too_far:
		return
	_exit_cell = _pick_exit_cell()
	_map.contents[_exit_cell] = DungeonMap.Content.STAIRS_UP
	_seal_off_path(_map.walking_path(_party.cell, _exit_cell))
	hero.bleeding = false  # the cold air: she's past caring
	hero.emit_changed()
	_build_level()
	_show_message("Cold air on your face. Daylight, just ahead!")
	_update_hints("exit")
	_say("daylight", true)


## Walls up every side way off `path`, so it leads only to the daylight.
func _seal_off_path(path: Array[Vector2i]) -> void:
	var on_path := {}
	for cell in path:
		on_path[cell] = true
	for cell in path:
		for d in Party.DIRECTIONS:
			var side: Vector2i = cell + d
			if on_path.has(side) or _map.is_wall(side) or _map.solid.has(side):
				continue
			_map.set_symbol(side, "#")
			_map.contents.erase(side)


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


## After the first fight: a chest turns up (#69). If the wall right beside
## her can take a niche, it's cut there, in view; otherwise the chest sits
## in the nearest dead end ahead. Either way it never blocks a passage.
## The "A chest!" card comes when she first sees it.
func _place_opening_chest() -> void:
	var here: Vector2i = _party.cell
	var forward: Vector2i = Party.DIRECTIONS[_party.facing]
	var left: Vector2i = Party.DIRECTIONS[wrapi(_party.facing - 1, 0, 4)]
	var right: Vector2i = Party.DIRECTIONS[wrapi(_party.facing + 1, 0, 4)]
	var ahead := here + forward
	var cell := Vector2i(-1, -1)
	for c: Vector2i in [ahead, ahead + left, ahead + right, here + left, here + right]:
		if _can_be_niche(c):
			_map.set_symbol(c, ".")
			cell = c
			break
	if cell == Vector2i(-1, -1):
		cell = _nearest_dead_end(here, here - forward)
	if cell == Vector2i(-1, -1):
		return
	_map.contents[cell] = DungeonMap.Content.CHEST
	_map.solid[cell] = true
	_opening_chest_cell = cell
	_build_level()
	_check_chest_in_view()


## The closest dead end (one way in) from `from`, not going back through
## `behind` or through a web, and not the room. (-1, -1) if none.
func _nearest_dead_end(from: Vector2i, behind: Vector2i) -> Vector2i:
	var room: Rect2i = _opening["room"]
	for avoid_behind in [true, false]:
		var seen := {from: true}
		var queue: Array[Vector2i] = [from]
		var i := 0
		while i < queue.size():
			var c := queue[i]
			i += 1
			if c != from and not room.has_point(c) and _open_ways(c) == 1:
				return c
			for d in Party.DIRECTIONS:
				var n: Vector2i = c + d
				if seen.has(n) or not _map.is_passable(n) or _map.door_at(n) != DungeonMap.Door.NONE:
					continue
				if avoid_behind and n == behind:
					continue
				seen[n] = true
				queue.append(n)
	return Vector2i(-1, -1)


## Once the chest is in sight (straight ahead, or right beside her), Mara
## spots it and the card says how to open it.
func _check_chest_in_view() -> void:
	if not _in_opening or _opening_chest_cell == Vector2i(-1, -1) or _said.has("chest_seen"):
		return
	var cell: Vector2i = _party.cell
	var in_view := false
	for d in Party.DIRECTIONS:
		if cell + d == _opening_chest_cell:
			in_view = true
	for step in range(1, 5):
		var c: Vector2i = cell + Party.DIRECTIONS[_party.facing] * step
		if c == _opening_chest_cell:
			in_view = true
		if not _map.is_passable(c):
			break
	if not in_view:
		return
	_say("chest_seen", true, true)
	_show_hint("A chest! Walk into it to open it.", "chest_find")


## A buried wall cell touching exactly one floor cell: opening it makes a
## dead-end niche, never a new way through.
func _can_be_niche(cell: Vector2i) -> bool:
	if cell.x < 1 or cell.y < 1 or cell.x >= _map.width - 1 or cell.y >= _map.height - 1:
		return false
	if not _map.is_wall(cell) or _opening["room"].grow(1).has_point(cell):
		return false
	var floors := 0
	for d in Party.DIRECTIONS:
		if not _map.is_wall(cell + d):
			floors += 1
	return floors == 1


## Something found that didn't fit: kept aside to offer when the moment ends.
func _left_over(item, count: int) -> void:
	_overflow[item] = _overflow.get(item, 0) + count


## Offers whatever didn't fit, if anything, then forgets it.
func _offer_overflow() -> void:
	if _overflow.is_empty():
		return
	var finds := _overflow.duplicate()
	_overflow.clear()
	await _offer_no_room(finds)


## Finds that didn't fit (#133): shown like a chest beside the pack, so the
## player can leave something else instead. Whatever stays is left behind.
func _offer_no_room(finds: Dictionary) -> void:
	_chest.open("No room in your pack", finds, _party_state)
	await _chest.closed
	_chest.visible = false


func _open_opening_chest(cell: Vector2i) -> void:
	_update_hints("chest_opened")
	_party.locked = true
	_chest.open("A battered chest", OPENING_CHEST, _party_state)
	Sounds.play(self, "chest")
	_say("chest", true)
	_show_hint("Drag or tap items into your pack.", "chest_take")
	await _chest.closed
	_chest.visible = false
	_party.locked = false
	if _chest.is_empty():
		_map.triggered[cell] = true
		_level_chest_open = true
		_build_level()
	if _hint == "chest_take":
		_finish_hint()
	_layout_hint()
	_refresh_tutorial_hint()


func _on_chest_took(_item, _quantity: int) -> void:
	_chest_looted = true
	if _chest.is_empty() and _hint == "chest_take":
		_show_hint("That's everything. Close the chest.", "chest_take")


## The party walked into something solid: search a body, open the chest,
## or warm her hands at the fire (#69).
func _on_party_interacted(cell: Vector2i) -> void:
	if _in_opening and cell == _opening_chest_cell:
		if not _map.triggered.has(cell):
			_open_opening_chest(cell)
		else:
			_show_message("The chest is empty.")
		return
	if _in_opening and cell == _opening_fire_cell():
		_show_message("The fire is dying. It won't last, and it can't be carried.")
		_say("fire", false, true)
		return
	if _map.triggered.has(cell):
		_show_message("Nothing more to take.")
		return
	if _map.content_at(cell) != DungeonMap.Content.NONE:
		_map.enter(cell)
		_run_event(cell)


## After fight 2 she stumbles in the dark; the torch flies from her hand
## and dies. She has to light the spare (#69).
func _trip() -> void:
	_tripped = true
	_party.locked = true
	var camera: Camera3D = _party.camera
	var fall := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	fall.tween_property(camera, "rotation:x", deg_to_rad(-55.0), 0.3)
	fall.parallel().tween_property(camera, "rotation:z", deg_to_rad(14.0), 0.3)
	fall.parallel().tween_property(camera, "position:y", 0.45, 0.3)
	await fall.finished
	Sounds.play(self, "stumble", -6.0)
	_party_state.supplies.lose_torch()
	Sounds.play(self, "burnout", -9.0)
	_show_message("You stumble - the torch flies from your hand and hisses out.")
	_say("trip", true)
	await get_tree().create_timer(1.4).timeout
	var rise := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	rise.tween_property(camera, "rotation:x", 0.0, 1.6)
	rise.parallel().tween_property(camera, "rotation:z", 0.0, 1.6)
	rise.parallel().tween_property(camera, "position:y", Party.EYE_HEIGHT, 1.6)
	await rise.finished
	_party.locked = false
	_next_fight_at = _steps_taken + OPENING_SPIDER_AFTER_TRIP
	_refresh_tutorial_hint()


## The companions' bodies, the fire, the chest, and the daylight once the
## exit is open.
func _add_opening_dressing() -> void:
	var cells := _opening_body_cells()
	_add_fire(_opening_fire_cell())  # the far corner: in view, lighting the bodies and doorway
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
	if _opening_chest_cell != Vector2i(-1, -1):
		_add_chest(_opening_chest_cell, _level_chest_open)
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


func _opening_fire_cell() -> Vector2i:
	return _opening["start"] + Vector2i(3, -1)


## The opening's chest: ChatGPT's chest art (closed, then empty once
## looted, #70); a plain box and lid if the art is missing.
const CHEST_SCENE := "res://art/props/tutorial-chest-v1/scene.tscn"


func _add_chest(cell: Vector2i, opened: bool) -> void:
	if ResourceLoader.exists(CHEST_SCENE):
		var art: Node3D = load(CHEST_SCENE).instantiate()
		art.position = Vector3(cell.x * CELL_SIZE, 0.0, cell.y * CELL_SIZE)
		art.set("state", "empty" if opened else "closed")
		_level.add_child(art)
		return
	var chest := Node3D.new()
	chest.position = Vector3(cell.x * CELL_SIZE, 0.0, cell.y * CELL_SIZE)
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color(0.42, 0.28, 0.16)
	wood.roughness = 1.0
	var band := StandardMaterial3D.new()
	band.albedo_color = Color(0.32, 0.3, 0.27)
	band.metallic = 0.6
	var box := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = Vector3(0.9, 0.45, 0.6)
	box_mesh.material = wood
	box.mesh = box_mesh
	box.position.y = 0.225
	chest.add_child(box)
	var lid := MeshInstance3D.new()
	var lid_mesh := BoxMesh.new()
	lid_mesh.size = Vector3(0.94, 0.12, 0.64)
	lid_mesh.material = band
	lid.mesh = lid_mesh
	lid.position = Vector3(0.0, 0.51, 0.0)
	if opened:
		lid.position = Vector3(0.0, 0.62, -0.3)
		lid.rotation.x = -1.2
	chest.add_child(lid)
	# Turn it to face the passage it opens onto.
	for f in Party.DIRECTIONS.size():
		if not _map.is_wall(cell + Party.DIRECTIONS[f]):
			chest.rotation.y = -f * PI / 2.0 + PI
	# A faint glint so it reads in the dark.
	var glint := OmniLight3D.new()
	glint.light_color = Color(1.0, 0.8, 0.5)
	glint.light_energy = 0.4
	glint.omni_range = CELL_SIZE * 1.2
	glint.position.y = 0.9
	chest.add_child(glint)
	_level.add_child(chest)


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


## Opening: she won't go on without a light (#58, #59): not out of the
## room before she has one, and not anywhere once she's tripped and lost
## it while the spare is still unlit (#69).
func _opening_step_check(target: Vector2i) -> String:
	if not _in_opening or _party_state.supplies.torch_lit() or _panic_started:
		return ""
	if _tripped and _party_state.supplies.count(TORCH) > 0:
		return "too_dark"
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
		var spare := " Light another from the pack." if _party_state.supplies.count(TORCH) > 0 else " That was the last one."
		_show_message("Your torch burns out." + spare)
		_say("torch_out")


## Fight 3: the spider bites and bites; once she's nearly down, the game
## makes her throw the torch (#69).
func _on_combat_enemy_acted(_foe, _outcome: Dictionary) -> void:
	if not _in_opening or _opening_fights_done != OPENING_FIGHTS.size() - 1:
		return
	if not _party_state.supplies.torch_lit():
		return
	var hero: Companion = _party_state.members[0]
	if hero.health <= FORCE_THROW_HEALTH and _combat.only_action == "":
		_combat.only_action = "throw"
		_say("forced_throw", true)
		_show_hint("Throw your torch! It's the only thing the spider fears.", "force_throw", "ok")


## Fight 3: her blows glance off; after a swing or two, the throw is taught.
func _on_combat_hero_acted(_hero: Companion, action: Dictionary, outcome: Dictionary) -> void:
	if not _in_opening or _opening_fights_done != OPENING_FIGHTS.size() - 1:
		return
	if action["kind"] != "attack":
		return
	_spider_swings += 1
	if outcome.get("glanced", false):
		_say("spider_glance", true)
	if _spider_swings >= 1 and not _hints_done.has("throw") and _hint != "throw" and _party_state.supplies.torch_lit():
		_show_hint("Blades glance off. Throw your torch!", "throw")


## Without any light left, she panics: the panic mechanic, explained.
func _start_opening_panic() -> void:
	_panic_started = true
	var hero: Companion = _party_state.members[0]
	hero.strain_locked = false
	hero.strain = OPENING_PANIC_STRAIN
	_on_party_state_changed()
	_show_hint("No light: %s panics and fights worse. Light, food and rest calm %s." % [hero.display_name, hero.pronouns[1]], "panic", "ok")
	_hints_done["panic_at"] = _steps_taken
	_say("panic", true)


## The next thing the tutorial wants, worked out from where she is: search
## the bodies, equip the sword, drop the broken knife, light a torch, drink
## the draught from the chest, light the spare after tripping.
## Pack steps hold her still until the Pack is open (#69).
func _refresh_tutorial_hint() -> void:
	if not _in_opening or not _hints_done.has("start"):
		return
	if _hint not in TUTORIAL_STEPS:
		return
	var supplies = _party_state.supplies
	var touch := _is_touch()
	var open_pack := "Tap Pack" if touch else "Press I (or click Pack)"
	var hero: Companion = _party_state.members[0]
	var text := ""
	var inside := ""
	var key := ""
	if not _opening_body_cells().all(func(c): return _searched_bodies.has(c)):
		key = "search"
		text = "Walk into your fallen companions to search them."
	elif hero.weapon != _opening_weapon and _opening_weapon in supplies.gear:
		key = "equip"
		text = "%s to open your pack." % open_pack
		inside = "Equip the %s." % _opening_weapon.display_name.to_lower().trim_prefix("companion's ")
	elif _starting_weapon and _starting_weapon in supplies.gear:
		key = "drop"
		text = "%s to open your pack." % open_pack
		inside = "Drop the %s." % _starting_weapon.display_name.to_lower()
	elif not supplies.torch_lit() and not _hints_done.has("light") and supplies.count(TORCH) > 0:
		key = "light"
		text = "Too dark. %s to open your pack." % open_pack
		inside = "Use a torch to light it."
	elif _tripped and not supplies.torch_lit() and supplies.count(TORCH) > 0 and not _panic_started:
		key = "relight"
		text = "Your torch is out! %s and light the spare." % open_pack
		inside = "Light the spare torch."
	elif _chest_looted and supplies.count(DRAUGHT) > 0 and hero.pending_effects.is_empty() and not _hints_done.has("draught"):
		key = "draught"
		text = "Badly hurt. %s and drink the draught." % open_pack
		inside = "Drink the draught: it heals as you walk."
	if key == "":
		if _hint in TUTORIAL_STEPS and _hint != "":
			_finish_hint()
		return
	if _hint != key or _hint_text != text:
		_show_hint(text, key, "pack" if inside != "" else "act", inside)  # the next step replaces the last; nothing is skipped


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
	var touch := _is_touch()  # computers: keys, with clicking as an alternative
	var turn_text := "Tap the curved arrows to turn" if touch else "Turn: A and D, or ← and → (or click the curved arrows)"
	match event:
		"start":
			_show_hint("Tap ▲ to move forward" if touch else "Move forward: W or ↑ (or click ▲)")
		"moved":
			if _hint == "start" and _steps_taken >= 1:
				_finish_hint()
			_refresh_tutorial_hint()
			var ahead: Vector2i = _party.cell + Party.DIRECTIONS[_party.facing]
			var can_go: bool = _party_state.supplies.torch_lit() or _panic_started  # not before she has light
			if can_go and not _hints_done.has("web") and _hint == "" and (_map.door_at(ahead) == DungeonMap.Door.CLOSED or _map.door_at(ahead + Party.DIRECTIONS[_party.facing]) == DungeonMap.Door.CLOSED):
				_show_hint("Walk into the web to tear through it.", "web")
			elif not _hints_done.has("turn") and _hints_done.has("start") and _hint == "" and not _map.is_passable(ahead) and not _map.solid.has(ahead):
				_show_hint(turn_text, "turn")
			elif _hint == "turn" and _map.is_passable(ahead):
				_finish_hint()
			elif _hint == "chest_find" and _map.triggered.has(_opening_chest_cell):
				_finish_hint()
			_check_chest_in_view()
		"bumped":
			if not _hints_done.has("turn") and _hint == "":
				_show_hint(turn_text, "turn")
		"web_torn":
			if _hint == "web":
				_finish_hint()
		"chest_opened":
			if _hint == "chest_find":
				_finish_hint()
		"fight":
			if not _hints_done.has("fight"):
				_show_hint(("Tap" if touch else "Click") + " an enemy to target it, then Attack. Its icon shows its next move. Defend softens a blow and stops a heavy one.", "fight", "ok")
		"fight_over":
			if _hint in ["fight", "throw", "force_throw"]:
				_finish_hint()
		"pack":
			_refresh_tutorial_hint()
		"exit":
			_show_hint("Daylight! Walk into the light to get out.", "exit")


## Tutorial cards (#69): centred and prominent. `mode`:
## "act"  - stays until she does what it says (moving, turning...);
## "pack" - holds her still until the Pack is open, then shows `inside`;
## "ok"   - pauses everything until dismissed (Got it / Enter).
## While a screen is open (Pack, chest, fight) the card moves aside.
func _show_hint(text: String, key := "start", mode := "act", inside := "") -> void:
	if text != "" and _hint_mode == "ok" and mode != "ok" and _hint != key:
		_hint_queue = [text, key, mode, inside]  # don't cut off an explanation
		return
	_hint = key if text != "" else ""
	_hint_text = text
	_hint_inside = inside
	_hint_mode = mode if text != "" else ""
	_layout_hint()


func _layout_hint() -> void:
	if _hint_box == null:
		return
	var shown := _hint != ""
	var in_pack := _pack.visible
	var screen_open := in_pack or _chest.visible or _in_combat or _event_screen.visible
	_hint_label.text = _hint_inside if _hint_mode == "pack" and in_pack and _hint_inside != "" else _hint_text
	_hint_ok.visible = _hint_mode == "ok"
	_hint_shade.visible = shown and _hint_mode == "ok"
	_hint_icon.texture = _hint_icon_for(_hint) if shown else null
	_hint_icon.visible = _hint_icon.texture != null
	_hint_ring.finder = _hint_target if shown else Callable()
	_hint_box.visible = shown
	_party.paused = shown and (_hint_mode == "ok" or (_hint_mode == "pack" and not in_pack))
	if not shown:
		return
	_hint_box.reset_size()
	var size := _hint_box.get_combined_minimum_size()
	var insets := _safe_area_insets()
	var view := get_viewport().get_visible_rect().size
	var y := view.y * 0.4 - size.y / 2.0  # the middle, a little high
	if _in_combat:
		y = insets.y + 200.0  # below the fight's log, above the enemies
	elif in_pack or _chest.visible or _event_screen.visible:
		y = view.y - insets.w - size.y - 24.0  # along the bottom, clear of the header
	if not screen_open and _hint_mode == "ok":
		y = view.y * 0.42 - size.y / 2.0
	_hint_box.position = Vector2((view.x - size.x) / 2.0, y)


## The picture for a tutorial card (#105).
func _hint_icon_for(key: String) -> Texture2D:
	match key:
		"bleeding": return Glyphs.STATUS["bleeding"]
		"throw", "force_throw", "light", "relight": return TORCH.icon
		"draught": return DRAUGHT.icon
		"equip": return _opening_weapon.icon
		"drop": return _starting_weapon.icon if _starting_weapon else null
		"web": return WEBBED_ICON
		"fight": return Glyphs.intention(CombatState.Intent.ATTACK)
	return null


## The button a tutorial card wants pressed, ringed so the words can be few.
func _hint_target() -> Control:
	if _hint in ["throw", "force_throw"] and _in_combat:
		var name := "Throw torch" if _combat._item_buttons.visible else "Item"
		for row in [_combat._item_buttons, _combat._action_buttons]:
			for button in row.get_children():
				if button.text == name:
					return button
	if _hint_mode == "pack" and not _pack.visible:
		return _pack_button
	return null


func _finish_hint() -> void:
	_hints_done[_hint] = true
	var was_ok := _hint_mode == "ok"
	_hint_mode = ""
	_show_hint("")
	if was_ok and not _hint_queue.is_empty():
		var queued: Array = _hint_queue
		_hint_queue = []
		_show_hint(queued[0], queued[1], queued[2], queued[3])
	_refresh_tutorial_hint()


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
## `who` speaks if given (the hurt or frightened hero, #118); otherwise the
## lead. A `once` line from a given hero is once per hero per expedition.
func _say(situation: String, force := false, once := false, who: Companion = null) -> void:
	var key := situation if who == null else "%s:%s" % [situation, who.display_name]
	if once and _said.has(key):
		return
	var now := Time.get_ticks_msec() / 1000.0
	if not force and now - _last_spoke_at < SPEECH_COOLDOWN:
		return
	var living: Array[Companion] = _party_state.living_members()
	if living.is_empty():
		return
	var hero: Companion = who if who else living[0]
	var lines: DialogueLines = Recruits.lines_for(hero)
	if lines == null:
		return
	var line: String = lines.pick(situation, _last_line)
	if line == "":
		return
	_said[key] = true
	_last_line = line
	_last_spoke_at = now
	var seconds: float = _dialogue_box.say(hero.display_name, line)
	for card in _cards:
		if card.companion == hero:
			card._portrait.talk(minf(seconds, 2.5))


## Anyone standing may call out in a fight, not only the lead (#118).
func _any_voice() -> Companion:
	var living: Array[Companion] = _party_state.living_members()
	return living.pick_random() if not living.is_empty() else null


## One line from each hero who made it back (#118): grief if someone
## didn't, their wounds if badly hurt, otherwise relief. Only facts the
## game knows - who fell, how hurt they are.
func _homecoming_lines() -> Dictionary:
	var rows: Array = _expedition.hero_rows(_party_state)
	var fallen: Array = rows.filter(func(r): return not r["back"]).map(func(r): return r["hero"].display_name)
	var said := {}
	for row in rows:
		var hero: Companion = row["hero"]
		var lines: DialogueLines = Recruits.lines_for(hero)
		if not row["back"] or lines == null:
			continue
		var line := ""
		if not fallen.is_empty():
			line = lines.pick("camp_grief").replace("{fallen}", fallen.pick_random())
		if line == "" and hero.health * 2 < hero.effective_max_health():
			line = lines.pick("camp_hurt")
		if line == "":
			line = lines.pick("camp_return")
		if line != "":
			said[hero] = line
	return said


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


## The tutorial card (#69): its own layer, above the Pack, chest and fight
## screens. "ok" cards dim the view behind them and wait for Got it.
func _build_hint() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	_hint_shade = ColorRect.new()
	_hint_shade.color = Color(0, 0, 0, 0.45)
	_hint_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_hint_shade.mouse_filter = Control.MOUSE_FILTER_STOP  # play waits
	_hint_shade.visible = false
	layer.add_child(_hint_shade)
	_hint_box = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.045, 0.04, 0.94)
	style.border_color = Color("dbb477")
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(18)
	_hint_box.add_theme_stylebox_override("panel", style)
	_hint_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint_box.add_child(column)
	_hint_icon = TextureRect.new()
	_hint_icon.custom_minimum_size = Vector2(56, 56)
	_hint_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_hint_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_hint_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_hint_icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_hint_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint_icon.visible = false
	column.add_child(_hint_icon)
	_hint_label = Label.new()
	_hint_label.add_theme_font_size_override("font_size", 25)
	_hint_label.add_theme_color_override("font_color", Color("f0e2bb"))
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint_label.custom_minimum_size = Vector2(540, 0)
	column.add_child(_hint_label)
	_hint_ok = Button.new()
	_hint_ok.text = "Got it"
	_hint_ok.custom_minimum_size = Vector2(170, 56)
	_hint_ok.focus_mode = Control.FOCUS_NONE
	_hint_ok.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_hint_ok.add_theme_font_size_override("font_size", 22)
	_hint_ok.pressed.connect(_finish_hint)
	column.add_child(_hint_ok)
	layer.add_child(_hint_box)
	_hint_box.visible = false
	_hint_ring = HintRing.new()
	layer.add_child(_hint_ring)


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


func _on_party_blocked(cell: Vector2i) -> void:
	if _depth == FORTRESS_DEPTH and cell in _map.marks.get("gates", []) and not _camp_state.gate_broken:
		_ask("A barred gate, and goblin guards behind it. Break it down? They'll fight.", _gate_fight)
		return
	# A spade or pick clears a blocked passage (#133).
	var tool: SupplyItem = null
	for item: SupplyItem in [SPADE, PICK]:
		if _party_state.supplies.count(item) > 0:
			tool = item
			break
	if tool and _depth != FORTRESS_DEPTH:
		_ask("Something chokes the passage. Clear it with the %s? (%d time)" % [tool.display_name.to_lower(), CLEAR_PASSAGE_TIME], _clear_passage.bind(cell))
		return
	_show_message(environment_theme.blocked_message + ("" if _depth == FORTRESS_DEPTH else " A spade or a pick would clear it."))


## Hacks through a blocked passage with a spade or pick (#133).
func _clear_passage(cell: Vector2i) -> void:
	_party_state.advance_time(CLEAR_PASSAGE_TIME)
	_map.doors[cell] = DungeonMap.Door.OPEN
	_level.refresh_door(cell)
	_play_effect(environment_theme.open_sound)
	_show_message("You hack your way through.")


func _on_party_moved(cell: Vector2i, facing: int) -> void:
	if cell != _cell_now:
		_cell_before = _cell_now
		_cell_now = cell
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
	if open and (_prompt.visible or _full_map.visible or _in_combat or _event_screen.visible or _chest.visible or _camp.visible):
		return
	_pack.visible = open
	_party.locked = open
	_update_hints("pack")
	_pack.refresh()
	_layout_hint()


## Opens or closes the full-screen map. The party can't move while it's open,
## and it can't open over a yes/no prompt.
func _set_full_map(open: bool) -> void:
	if open and (_prompt.visible or _pack.visible or _in_combat or _event_screen.visible or _in_opening or _camp.visible):
		return
	_full_map.visible = open
	_party.locked = open
	if open:
		_full_map_title.text = "%s · depth %d of %d" % [environment_theme.display_name, _depth, floors_in_site]
		_full_map_close.grab_focus.call_deferred()


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
	Settings.ensure_buses()
	_ambience_player = AudioStreamPlayer.new()
	_ambience_player.bus = "Music"
	_ambience_player.stream = environment_theme.ambience
	_ambience_player.volume_db = AMBIENCE_VOLUME_DB
	add_child(_ambience_player)
	_refresh_place_ambience()

	var steps := AudioStreamRandomizer.new()
	for sound in environment_theme.footstep_sounds:
		steps.add_stream(-1, sound)
	steps.random_pitch = 1.12
	steps.random_volume_offset_db = 2.0
	_footstep_player = AudioStreamPlayer.new()
	_footstep_player.bus = "Effects"
	_footstep_player.stream = steps
	_footstep_player.volume_db = FOOTSTEP_VOLUME_DB
	add_child(_footstep_player)

	_heart_player = AudioStreamPlayer.new()
	_heart_player.bus = "Effects"
	_heart_player.stream = HEARTBEAT
	_heart_player.volume_db = HEARTBEAT_VOLUME_DB
	add_child(_heart_player)

	_music = Music.new()
	add_child(_music)
	_effect_player = AudioStreamPlayer.new()
	_effect_player.bus = "Effects"
	_effect_player.volume_db = EFFECT_VOLUME_DB
	_effect_player.max_polyphony = 2
	add_child(_effect_player)


## The cave's music, or the fortress's on its floor (#54).
func _play_place_music() -> void:
	if _music and not _in_combat:
		_music.play("fortress" if _depth == FORTRESS_DEPTH else "cave")


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
	# Bleeding vignette (#71): under the HUD, over the view, never in the way.
	_wound_overlay = ColorRect.new()
	_wound_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_wound_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var wound_material := ShaderMaterial.new()
	wound_material.shader = Shader.new()
	wound_material.shader.code = WOUND_SHADER
	_wound_overlay.material = wound_material
	wound_material.set_shader_parameter("flash", 0.0)
	wound_material.set_shader_parameter("dim", 0.0)
	canvas.add_child(_wound_overlay)
	_ambience = Ambience.new()
	_ambience.main = self
	add_child(_ambience)
	canvas.add_child(_ambience.overlay)
	canvas.move_child(_ambience.overlay, 0)  # under the wound vignette and the HUD
	# Everything except full-screen backgrounds goes inside the safe area.
	var ui := Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(ui)
	_safe_area = ui
	var held_light:=preload("res://scripts/held_light_view.gd").new()
	held_light.name="HeldLight"
	ui.add_child(held_light)
	held_light.setup(self)

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
	# The turn arrows are drawn, not typed: the web build has no system font
	# to fall back on for ↺ and ↻.
	for spec in [[TURN_LEFT_ICON, "turn_left"], ["▲", "move_forward"], [TURN_RIGHT_ICON, "turn_right"],
			["", ""], ["▼", "move_back"], ["", ""]]:
		pad.add_child(_make_touch_button(spec[0], spec[1]))
	pad_corner.add_child(pad)
	ui.add_child(pad_corner)
	_touch_pad = pad_corner

	_build_party_cards(ui)
	_build_dialogue_box(ui)
	_build_hint()
	_build_prompt(ui)
	_build_full_map(canvas)
	_pack = PackScreen.new()
	canvas.add_child(_pack)
	_pack.setup(_party_state)
	_pack.visible = false
	_pack.closed.connect(_set_pack.bind(false))
	_pack.save_and_exit.connect(save_and_exit)
	_pack.used.connect(_show_message)
	_pack.used.connect(func(_m): _refresh_tutorial_hint())
	_combat = CombatScreen.new()
	canvas.add_child(_combat)
	_event_screen = EventScreen.new()
	ui.add_child(_event_screen)
	_chest = ChestScreen.new()
	canvas.add_child(_chest)
	_chest.took.connect(_on_chest_took)
	_results = ResultsScreen.new()
	canvas.add_child(_results)
	_build_eyelids(canvas)
	# The coin flip (#77) sits above everything, tutorial cards included.
	var coin_layer := CanvasLayer.new()
	coin_layer.layer = 6
	# Conversations (#122) sit above the screens they follow.
	var talk_layer := CanvasLayer.new()
	talk_layer.layer = 4
	add_child(talk_layer)
	_conversation = ConversationScreen.new()
	talk_layer.add_child(_conversation)
	_quest_log = QuestLog.new()
	talk_layer.add_child(_quest_log)
	_spoils = SpoilsScreen.new()
	talk_layer.add_child(_spoils)
	_vision = VisionFilter.new()
	add_child(_vision)
	_conversation.vision = _vision
	_pack.open_quests.connect(func(): _quest_log.open(_camp_state))
	add_child(coin_layer)
	var coin := CoinFlip.new()
	coin_layer.add_child(coin)
	_combat.coin = coin
	_combat.place_foe = _place_extra_foe
	_combat.reframe = _clear_of_panel  # a bat landing (#141)
	# Settings (#52), above everything, from the Pack or the camp.
	var settings_layer := CanvasLayer.new()
	settings_layer.layer = 7
	add_child(settings_layer)
	_settings = SettingsScreen.new()
	settings_layer.add_child(_settings)
	_settings.closed.connect(_update_wound_dim)
	_pack.open_settings.connect(func(): _settings.open())
	_event_screen.coin = coin
	_camp = CampScreen.new()
	canvas.add_child(_camp)
	_camp.save_and_exit.connect(save_and_exit)
	_camp.open_settings.connect(func(): _settings.open())
	_camp.conversation = _conversation  # people at camp with news (#123)
	_preparation = PreparationScreen.new()
	canvas.add_child(_preparation)
	minimap.pressed.connect(_set_full_map.bind(true))
	get_viewport().size_changed.connect(_apply_safe_area)
	_apply_safe_area()


## Keeps the HUD out from under the iPhone's camera cutout, rounded corners
## and home bar. On desktop there's nothing to avoid.
func _apply_safe_area() -> void:
	var insets := _safe_area_insets()
	if _settings:
		_settings.content.offset_left = insets.x
		_settings.content.offset_top = insets.y
		_settings.content.offset_right = -insets.z
		_settings.content.offset_bottom = -insets.w
	for control: Control in [_safe_area, _full_map_margin, _pack.content, _combat.content, _results.content, _preparation.content, _chest.content, _camp.content]:
		control.offset_left = insets.x
		control.offset_top = insets.y
		control.offset_right = -insets.z
		control.offset_bottom = -insets.w


## Left, top, right, bottom insets in UI pixels.
func _safe_area_insets() -> Vector4:
	return SafeArea.insets(get_viewport(), simulate_phone_safe_area)


## Full-screen sketch with self-explanatory symbols; tapping anywhere closes it.
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

	var header:=HBoxContainer.new()
	column.add_child(header)
	_full_map_title = Label.new()
	_full_map_title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	_full_map_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_full_map_title.add_theme_font_size_override("font_size", 28)
	_full_map_title.add_theme_color_override("font_color", Color("e8d9b0"))
	header.add_child(_full_map_title)
	_full_map_close=Button.new()
	_full_map_close.text="Close"
	_full_map_close.custom_minimum_size=Vector2(96,52)
	_full_map_close.pressed.connect(_set_full_map.bind(false))
	header.add_child(_full_map_close)

	_full_map_view = Minimap.new()
	_full_map_view.full_view = true
	_full_map_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_full_map_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(_full_map_view)

	var hint := Label.new()
	hint.text = "Tap anywhere or press M to close"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.5))
	column.add_child(hint)
	_full_map.visible = false


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
			card.show_row = _party_state.members.size() > 1
			card.show_companion(hero)
		else:
			card.show_empty()
		# The escape is Mara's alone: no empty slots on screen (#69).
		card.visible = i < _party_state.members.size() or not _in_opening


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
## A phone, or a tablet playing in the browser (an iPad's Safari reports
## itself as a Mac, so ask the screen rather than the system).
func _is_touch() -> bool:
	return OS.has_feature("mobile") or (OS.has_feature("web") and DisplayServer.is_touchscreen_available())


## `label` is a short text or an icon.
func _make_touch_button(label, action: String) -> Control:
	if action.is_empty():
		var spacer := Control.new()
		spacer.custom_minimum_size = TOUCH_BUTTON_SIZE
		spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return spacer
	var button := Button.new()
	if label is Texture2D:
		button.icon = label
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	else:
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

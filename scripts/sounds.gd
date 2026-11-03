extends RefCounted
## Finished dark foley (#96/#99), derived from credited CC0 sources plus
## original layers. One-shots free themselves; loops belong to their screen.
## Sources, edits and licences: audio/dark-v1/CREDITS.md and catalog.json.

const EFFECTS := {
	"wander_claws": preload("res://audio/galleries-v1/wander-claws.wav"),
	"wander_shuffle": preload("res://audio/galleries-v1/wander-shuffle.wav"),
	"wander_stones": preload("res://audio/galleries-v1/wander-stones.wav"),
	"wander_chitter": preload("res://audio/galleries-v1/wander-chitter.wav"),
	"wade": preload("res://audio/galleries-v1/wade-1.wav"),
	"sluice": preload("res://audio/galleries-v1/sluice-wheel.wav"),
	"drain": preload("res://audio/galleries-v1/water-drain.wav"),
	"hit": preload("res://audio/dark-v1/hit-1.wav"),
	"block": preload("res://audio/dark-v1/block-wood.wav"),
	"block_metal": preload("res://audio/dark-v1/block-metal.wav"),
	"miss": preload("res://audio/dark-v1/miss-1.wav"),
	"web": preload("res://audio/dark-v1/web-spit.wav"),
	"venom": preload("res://audio/dark-v1/venom.wav"),
	"coins": preload("res://audio/dark-v1/coins-1.wav"),
	"purchase": preload("res://audio/dark-v1/purchase.wav"),
	"coin_flip": preload("res://audio/dark-v1/coin-flip.wav"),
	"chest": preload("res://audio/dark-v1/chest-open.wav"),
	"torch": preload("res://audio/dark-v1/torch-light.wav"),
	"burnout": preload("res://audio/dark-v1/torch-burnout.wav"),
	"stumble": preload("res://audio/dark-v1/stumble.wav"),
	"fall": preload("res://audio/dark-v1/fall.wav"),
	"ui": preload("res://audio/dark-v1/ui-click.wav"),
	"gate": preload("res://audio/dark-v1/gate-break.wav"),
	"queen": preload("res://audio/dark-v1/queen-screech.wav"),
	"drum": preload("res://audio/dark-v1/drum-hit.wav"),
	# Field sounds (#217): ChatGPT's audio/field-v1, sources in its CREDITS.md.
	"passage_roots": preload("res://audio/field-v1/passage-roots.wav"),
	"prayer_cast": preload("res://audio/field-v1/prayer-cast.wav"),
	"prayer_mend": preload("res://audio/field-v1/prayer-mend.wav"),
	"prayer_light": preload("res://audio/field-v1/prayer-light.wav"),
	"prayer_watch": preload("res://audio/field-v1/prayer-watch.wav"),
	"prayer_miscast": preload("res://audio/field-v1/prayer-miscast.wav"),
	"prayer_bind": preload("res://audio/field-v1/prayer-bind.wav"),
	"rat_hurt": preload("res://audio/field-v1/rat-hurt.wav"),
	"rat_death": preload("res://audio/field-v1/rat-death.wav"),
	"spider_hurt": preload("res://audio/field-v1/spider-hurt.wav"),
	"spider_death": preload("res://audio/field-v1/spider-death.wav"),
	"goblin_hurt": preload("res://audio/field-v1/goblin-hurt.wav"),
	"goblin_death": preload("res://audio/field-v1/goblin-death.wav"),
	"beetle_hurt": preload("res://audio/field-v1/beetle-hurt.wav"),
	"beetle_death": preload("res://audio/field-v1/beetle-death.wav"),
	"bat_hurt": preload("res://audio/field-v1/bat-hurt.wav"),
	"bat_death": preload("res://audio/field-v1/bat-death.wav"),
	"deep_hurt": preload("res://audio/field-v1/deep-hurt.wav"),
	"deep_death": preload("res://audio/field-v1/deep-death.wav"),
	"map_noticed": preload("res://audio/field-v1/map-noticed.wav"),
	"map_heavy_blow": preload("res://audio/field-v1/map-heavy-blow.wav"),
	"trap_dart": preload("res://audio/field-v1/trap-dart.wav"),
	"trap_snare": preload("res://audio/field-v1/trap-snare.wav"),
	"trap_alarm_bell": preload("res://audio/field-v1/trap-alarm-bell.wav"),
	"trap_tripwire": preload("res://audio/field-v1/trap-tripwire.wav"),
	"brew_drink": preload("res://audio/field-v1/brew-drink.wav"),
	"brew_shatter": preload("res://audio/field-v1/brew-shatter.wav"),
	"level_up": preload("res://audio/field-v1/level-up.wav"),
	"stairs_down": preload("res://audio/field-v1/stairs-down.wav"),
	"stairs_up": preload("res://audio/field-v1/stairs-up.wav"),
	"pack_eat": preload("res://audio/field-v1/pack-eat.wav"),
	"pack_bandage": preload("res://audio/field-v1/pack-bandage.wav"),
	"pack_oil": preload("res://audio/field-v1/pack-oil.wav"),
	"pack_tome": preload("res://audio/field-v1/pack-tome.wav"),
	"smith_temper": preload("res://audio/field-v1/smith-temper.wav"),
}
const VARIANTS := {
	"wade": [preload("res://audio/galleries-v1/wade-1.wav"), preload("res://audio/galleries-v1/wade-2.wav"), preload("res://audio/galleries-v1/wade-3.wav")],
	"hit": [preload("res://audio/dark-v1/hit-1.wav"),preload("res://audio/dark-v1/hit-2.wav"),preload("res://audio/dark-v1/hit-3.wav")],
	"miss": [preload("res://audio/dark-v1/miss-1.wav"),preload("res://audio/dark-v1/miss-2.wav")],
	"coins": [preload("res://audio/dark-v1/coins-1.wav"),preload("res://audio/dark-v1/coins-2.wav")],
}
const LOOPS := {
	"galleries": preload("res://audio/galleries-v1/galleries-loop.wav"),
	"camp": preload("res://audio/dark-v1/camp-ambience-loop.wav"),
	"outskirts": preload("res://audio/dark-v1/outskirts-ambience-loop.wav"),
	"torch": preload("res://audio/dark-v1/torch-burn-loop.wav"),
}
const HEARTBEAT := preload("res://audio/dark-v1/heartbeat.wav")
static var _rng: RandomNumberGenerator
const WANDER_KEYS := ["wander_claws", "wander_shuffle", "wander_stones", "wander_chitter"]


## The field sound family (#217) for an enemy type, by its file name:
## "rat", "spider", "goblin", "beetle", "bat" or "deep" (the deeper,
## stranger things). Add "_hurt" or "_death".
static func creature(type) -> String:
	var id: String = type.resource_path.get_file().get_basename() if type else ""
	for family in ["rat", "spider", "goblin", "beetle", "bat"]:
		if id.contains(family):
			return family
	if id in ["webspinner", "broodmother"]:
		return "spider"
	if id == "gate_captain":
		return "goblin"
	return "deep"


## The sound for using `item` (#217), or "".
static func for_item(item) -> String:
	if not item is SupplyItem:
		return ""
	match item.effect:
		SupplyItem.Effect.FEED_PARTY: return "pack_eat"
		SupplyItem.Effect.HEAL_ONE, SupplyItem.Effect.DRESS_INJURY: return "pack_bandage"
		SupplyItem.Effect.REFILL_LANTERN: return "pack_oil"
		SupplyItem.Effect.TOME: return "pack_tome"
		SupplyItem.Effect.CANDLE: return "prayer_cast"
		SupplyItem.Effect.BREW: return "brew_drink"
	return ""


## A prayer's sound (#217): its own, or the shared one; the miscast if it faltered.
static func prayer(id: String, failed: bool) -> String:
	if failed:
		return "prayer_miscast"
	return "prayer_" + id if EFFECTS.has("prayer_" + id) else "prayer_cast"


static func warning_index() -> int:
	return _random().randi_range(0, WANDER_KEYS.size() - 1)


static func _random() -> RandomNumberGenerator:
	if _rng == null:
		_rng = RandomNumberGenerator.new()
		_rng.randomize()
	return _rng


static func play(from: Node, key: String, volume_db := -4.0, pitch_spread := 0.06) -> void:
	if from == null or not from.is_inside_tree() or not EFFECTS.has(key):
		return
	var player := AudioStreamPlayer.new()
	var rng := _random()  # presentation randomness never advances combat/event dice
	player.stream = VARIANTS[key][rng.randi_range(0, VARIANTS[key].size()-1)] if VARIANTS.has(key) else EFFECTS[key]
	player.bus = "Effects"
	player.volume_db = volume_db
	player.pitch_scale = 1.0 + rng.randf_range(-pitch_spread, pitch_spread)
	player.finished.connect(player.queue_free)
	from.add_child(player)
	player.play()


## The caller starts/stops this with its own visibility/lifetime.
static func make_loop(from: Node, key: String, volume_db: float) -> AudioStreamPlayer:
	if from == null or not LOOPS.has(key):
		return null
	var player := AudioStreamPlayer.new()
	player.stream = LOOPS[key]
	player.bus = "Effects"
	player.volume_db = volume_db
	from.add_child(player)
	return player

extends RefCounted
## Finished dark foley (#96/#99), derived from credited CC0 sources plus
## original layers. One-shots free themselves; loops belong to their screen.
## Sources, edits and licences: audio/dark-v1/CREDITS.md and catalog.json.

const EFFECTS := {
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
}
const VARIANTS := {
	"hit": [preload("res://audio/dark-v1/hit-1.wav"),preload("res://audio/dark-v1/hit-2.wav"),preload("res://audio/dark-v1/hit-3.wav")],
	"miss": [preload("res://audio/dark-v1/miss-1.wav"),preload("res://audio/dark-v1/miss-2.wav")],
	"coins": [preload("res://audio/dark-v1/coins-1.wav"),preload("res://audio/dark-v1/coins-2.wav")],
}
const LOOPS := {
	"camp": preload("res://audio/dark-v1/camp-ambience-loop.wav"),
	"outskirts": preload("res://audio/dark-v1/outskirts-ambience-loop.wav"),
	"torch": preload("res://audio/dark-v1/torch-burn-loop.wav"),
}
const HEARTBEAT := preload("res://audio/dark-v1/heartbeat.wav")
static var _rng: RandomNumberGenerator


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

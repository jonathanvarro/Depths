extends RefCounted
## One-off sound effects (#54): ChatGPT's darker second set
## (audio/samples-v2-dark), owner-approved 2026-10-18. Any node can play one;
## the player frees itself when done, on the Effects bus.

const EFFECTS := {
	"hit": preload("res://audio/samples-v2-dark/club-hit.wav"),
	"block": preload("res://audio/samples-v2-dark/shield-block.wav"),
	"coins": preload("res://audio/samples-v2-dark/coin-pouch.wav"),
	"chest": preload("res://audio/samples-v2-dark/chest-open.wav"),
	"torch": preload("res://audio/samples-v2-dark/torch-light.wav"),
}
const HEARTBEAT := preload("res://audio/samples-v2-dark/heartbeat.wav")


static func play(from: Node, key: String, volume_db := -4.0, pitch_spread := 0.06) -> void:
	if from == null or not from.is_inside_tree() or not EFFECTS.has(key):
		return
	var player := AudioStreamPlayer.new()
	player.stream = EFFECTS[key]
	player.bus = "Effects"
	player.volume_db = volume_db
	player.pitch_scale = 1.0 + randf_range(-pitch_spread, pitch_spread)  # no two blows alike
	player.finished.connect(player.queue_free)
	from.add_child(player)
	player.play()

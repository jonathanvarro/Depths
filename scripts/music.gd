extends Node
## Music (#54): one track per place, crossfading when the place changes, on
## the Music bus (Settings volume). Tracks live in audio/music/ under these
## names (.ogg, .mp3 or .wav); a missing track just means silence.
## Licences and credits: audio/music/README.md.

const FOLDER := "res://audio/music/"
const PLACES := ["title", "cave", "fortress", "combat", "camp", "galleries"]
const FADE := 1.5  # seconds
## After a fight the battle music winds down more slowly (owner, 2026-11-21).
const AFTER_FIGHT := 4.0
const VOLUME_DB := -8.0

var place := ""
var _players: Array[AudioStreamPlayer] = []
var _current := 0
var _tween: Tween


func _init() -> void:
	for i in 2:
		var player := AudioStreamPlayer.new()
		player.bus = "Music"
		player.volume_db = -80.0
		add_child(player)
		_players.append(player)


static func track_for(where: String) -> AudioStream:
	if where == "galleries":
		return preload("res://audio/galleries-v1/below-the-sluice.wav")
	for extension in [".ogg", ".mp3", ".wav"]:
		var path: String = FOLDER + where + extension
		if ResourceLoader.exists(path):
			return load(path)
	return null


## Moves to `where`'s track; the old one fades out as the new fades in.
func play(where: String) -> void:
	play_with_fade(-1.0, where)


## As play(), over `fade` seconds (below zero: the usual FADE).
func play_with_fade(fade: float, where: String) -> void:
	if fade < 0.0:
		fade = FADE
	if where == place:
		return
	place = where
	var old := _players[_current]
	_current = 1 - _current
	var new := _players[_current]
	var stream := track_for(where)
	if _tween and _tween.is_valid():
		_tween.kill()  # a change mid-fade (a fight right after a fight)
		new.stop()
	var tween := create_tween().set_parallel()
	_tween = tween
	if old.playing:
		tween.tween_property(old, "volume_db", -80.0, fade).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
		tween.chain().tween_callback(old.stop)
	if stream:
		if stream is AudioStreamOggVorbis or stream is AudioStreamMP3:
			stream.loop = true
		elif stream is AudioStreamWAV and stream.loop_mode == AudioStreamWAV.LOOP_DISABLED:
			stream.loop_mode = AudioStreamWAV.LOOP_FORWARD  # the tracks are loop cuts
			stream.loop_begin = 0
			stream.loop_end = int(stream.get_length() * stream.mix_rate)
		new.stream = stream
		new.volume_db = -80.0
		new.play()
		tween.tween_property(new, "volume_db", VOLUME_DB, fade).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)

extends Node
## Music (#54): one track per place, crossfading when the place changes, on
## the Music bus (Settings volume). Tracks live in audio/music/ under these
## names (.ogg, .mp3 or .wav); a missing track just means silence.
## Licences and credits: audio/music/README.md.

const FOLDER := "res://audio/music/"
const PLACES := ["title", "cave", "fortress", "combat", "camp"]
const FADE := 1.5  # seconds
const VOLUME_DB := -8.0

var place := ""
var _players: Array[AudioStreamPlayer] = []
var _current := 0


func _init() -> void:
	for i in 2:
		var player := AudioStreamPlayer.new()
		player.bus = "Music"
		player.volume_db = -80.0
		add_child(player)
		_players.append(player)


static func track_for(where: String) -> AudioStream:
	for extension in [".ogg", ".mp3", ".wav"]:
		var path: String = FOLDER + where + extension
		if ResourceLoader.exists(path):
			return load(path)
	return null


## Moves to `where`'s track; the old one fades out as the new fades in.
func play(where: String) -> void:
	if where == place:
		return
	place = where
	var old := _players[_current]
	_current = 1 - _current
	var new := _players[_current]
	var stream := track_for(where)
	var tween := create_tween().set_parallel()
	if old.playing:
		tween.tween_property(old, "volume_db", -80.0, FADE)
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
		tween.tween_property(new, "volume_db", VOLUME_DB, FADE)

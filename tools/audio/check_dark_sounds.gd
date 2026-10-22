extends SceneTree
## Native decoding, loop lifetime, Settings routing, presentation RNG and
## real camp lifecycle. No Main _ready or campaign/save lifecycle runs.
const SOUNDS := preload("res://scripts/sounds.gd")
const PARTY := preload("res://scripts/party_state.gd")
const Settings := preload("res://scripts/settings.gd")
var checks := 0
var failures: Array=[]
func _initialize() -> void:call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures.append(label);push_error(label)
func run() -> void:
	Settings.ensure_buses();AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"),true)
	var cat: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://audio/dark-v1/catalog.json"))
	check(cat.assets.size()==30,"Thirty complete requested assets")
	for entry: Dictionary in cat.assets:
		var sound: AudioStreamWAV=load(entry.path)
		check(sound!=null,"Native WAV decodes "+entry.id)
		check(sound.mix_rate==44100 and not sound.stereo and sound.format==AudioStreamWAV.FORMAT_16_BITS,"Uncompressed mono PCM16 44.1k "+entry.id)
		check(absf(sound.get_length()-entry.seconds)<2.0/44100,"Exact decoded duration "+entry.id)
		check(sound.loop_mode==(AudioStreamWAV.LOOP_FORWARD if entry.loop else AudioStreamWAV.LOOP_DISABLED),"Intended imported loop mode "+entry.id)
	var host:=Node.new();root.add_child(host)
	seed(3941);var expected:=randf();seed(3941)
	SOUNDS.play(host,"hit",-80.0,0.0)
	check(randf()==expected,"Sound variation never advances global game dice")
	for key: String in SOUNDS.EFFECTS:
		SOUNDS.play(host,key,-80.0,0.0)
		var player: AudioStreamPlayer=host.get_child(-1)
		check(player.playing and player.bus=="Effects","One-shot routes/plays "+key)
		check(player.stream.loop_mode==AudioStreamWAV.LOOP_DISABLED,"One-shot cannot leak a loop "+key)
	var count:=host.get_child_count();SOUNDS.play(host,"missing-key")
	check(host.get_child_count()==count,"Unknown effect adds no player")
	await create_timer(3.4).timeout
	check(host.get_child_count()==0,"All one-shot players free after finishing")
	var loop: AudioStreamPlayer=SOUNDS.make_loop(host,"camp",-80.0)
	loop.play();await process_frame
	check(loop.playing and loop.bus=="Effects" and loop.stream.loop_mode==AudioStreamWAV.LOOP_FORWARD,"Explicit owned ambience loop")
	loop.stop();check(not loop.playing,"Loop stops on request");host.queue_free();await process_frame
	var party=PARTY.new();party.add_member(load("res://data/companions/mara.tres"))
	var camp=load("res://scripts/camp_screen.gd").new();root.add_child(camp)
	check(not camp._ambience.playing,"Hidden camp starts silent")
	camp.open(load("res://scripts/camp_state.gd").new(),party);await process_frame
	check(camp._ambience.playing and camp._ambience.stream==SOUNDS.LOOPS.camp,"Real camp open starts its bed")
	camp.visible=false;await process_frame
	check(not camp._ambience.playing,"Hidden camp stops its ambience")
	camp.queue_free();await process_frame
	# Exercise current production floor-ambience selection on detached Main.
	var main=load("res://scripts/main.gd").new()
	main._ambience_player=AudioStreamPlayer.new();root.add_child(main._ambience_player)
	main._ambience_player.bus="Music";main.environment_theme=load("res://themes/cave.tres")
	main.use_debug_layout=false;main._depth=main.OUTSKIRTS_DEPTH;main._refresh_place_ambience()
	check(main._ambience_player.stream==SOUNDS.LOOPS.outskirts,"Depth three selects distant drums")
	main._camp_state.queen_defeated=true;main._refresh_place_ambience()
	check(main._ambience_player.stream==main.environment_theme.ambience,"Defeated queen removes the drum bed")
	main._ambience_player.stop();main._depth=1;main._refresh_place_ambience()
	check(main._ambience_player.playing,"Returning from camp restarts an unchanged cave bed")
	main._ambience_player.stop();main._ambience_player.stream=null
	await create_timer(.15).timeout # allow the audio mixer to release retired loop playbacks
	main._ambience_player.free();main._ambience_player=null;main.free();await process_frame
	var coin=load("res://scripts/coin_flip.gd").new();root.add_child(coin)
	check(coin._player.stream==SOUNDS.EFFECTS.coin_flip and coin._player.bus=="Effects","Real coin uses registered flick/landing")
	coin.queue_free();await process_frame
	await create_timer(.15).timeout
	var file:=FileAccess.open("res://art/concepts/sound-v1/godot-validation.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failed":failures.size(),"failures":failures},"\t"));file.close()
	print("DARK_SOUND_GODOT: ",checks," checks, ",failures.size()," failed")
	quit(1 if not failures.is_empty() else 0)

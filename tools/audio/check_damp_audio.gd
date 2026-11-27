extends SceneTree
## Native imported decoder/playback/loop/bus fixture, master muted, no Main/settings.
var checks:=0
var failures: Array[String]=[]
var out: String
func _initialize() -> void:
	out=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(out);call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures.append(label);push_error(label)
func run() -> void:
	for bus: String in ["Effects","Music"]:
		if AudioServer.get_bus_index(bus)<0:
			AudioServer.add_bus();AudioServer.set_bus_name(AudioServer.bus_count-1,bus)
	AudioServer.set_bus_mute(0,true)
	var effects:=AudioServer.get_bus_index("Effects");var music:=AudioServer.get_bus_index("Music")
	AudioServer.set_bus_volume_db(effects,-4);AudioServer.set_bus_volume_db(music,-9)
	AudioServer.set_bus_mute(effects,true);check(not AudioServer.is_bus_mute(music),"Effects mute independent of Music")
	AudioServer.set_bus_mute(effects,false);AudioServer.set_bus_mute(music,true);check(not AudioServer.is_bus_mute(effects),"Music mute independent of Effects")
	var catalog: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://audio/damp-caves-v1/catalog.json"))
	check(catalog.assets.size()==20,"twelve environment sounds plus eight creature reactions")
	var memory:=0
	for row: Dictionary in catalog.assets:
		var stream: AudioStreamWAV=load("res://"+row.file)
		check(stream!=null,"native WAV decode "+row.id)
		if stream==null:continue
		check(stream.mix_rate==44100 and not stream.stereo and stream.format==AudioStreamWAV.FORMAT_16_BITS,"uncompressed 44.1k mono PCM16 "+row.id)
		check(absf(stream.get_length()-row.seconds)<.003,"native duration "+row.id)
		check((stream.loop_mode==AudioStreamWAV.LOOP_FORWARD)==row.loop,"explicit native loop "+row.id)
		check(FileAccess.get_sha256("res://"+row.file)==row.sha256,"waveform hash "+row.id)
		memory+=stream.data.size()
		var player:=AudioStreamPlayer.new();root.add_child(player);player.bus="Effects";player.stream=stream;player.play()
		await process_frame;check(player.playing and player.bus=="Effects","owned Effects playback "+row.id)
		player.seek(maxf(0,stream.get_length()-.025));await create_timer(.15).timeout
		check(player.playing if row.loop else not player.playing,"loop wraps or one-shot finishes "+row.id)
		player.stop();check(not player.playing,"explicit lifecycle stop "+row.id);player.queue_free();await process_frame
	check(memory<12*1024*1024,"whole set PCM memory below 12MiB")
	check(is_equal_approx(AudioServer.get_bus_volume_db(effects),-4) and is_equal_approx(AudioServer.get_bus_volume_db(music),-9),"bus levels retained")
	var report:={"checks":checks,"failures":failures,"pcm_bytes":memory,"master_muted":true,"player_settings_used":false,
	 "live_bindings_changed":false,"physical_iPhone":false,"human_listening_approved":false}
	FileAccess.open(out.path_join("native-validation.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  ")+"\n")
	print("DAMP_AUDIO_NATIVE=",checks," failures=",failures.size());quit(0 if failures.is_empty() else 1)

extends SceneTree
## Real decoder/playback/loop/bus tests only. No Main, game RNG or settings files.
var checks:=0
var failures:Array[String]=[]
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures.append(label);push_error(label)
func _initialize()->void:call_deferred("run")
func run()->void:
	for bus in ["Effects","Music"]:
		if AudioServer.get_bus_index(bus)<0:
			AudioServer.add_bus();AudioServer.set_bus_name(AudioServer.bus_count-1,bus)
	AudioServer.set_bus_mute(0,true) # Test playback remains inaudible to the owner.
	var effects:=AudioServer.get_bus_index("Effects")
	var music:=AudioServer.get_bus_index("Music")
	AudioServer.set_bus_volume_db(effects,-4);AudioServer.set_bus_volume_db(music,-9)
	AudioServer.set_bus_mute(effects,true)
	check(AudioServer.is_bus_mute(effects) and not AudioServer.is_bus_mute(music),"Effects mute independent of Music")
	AudioServer.set_bus_mute(effects,false);AudioServer.set_bus_mute(music,true)
	check(not AudioServer.is_bus_mute(effects) and AudioServer.is_bus_mute(music),"Music mute independent of Effects")
	AudioServer.set_bus_mute(music,false)
	var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://catalog.json"))
	check(data.assets.size()==57,"46 field assets and 11 Galleries effects/music")
	for entry:Dictionary in data.assets:
		var stream:AudioStreamWAV=load("res://"+str(entry.file))
		check(stream!=null,"Native WAV decode "+entry.id)
		if not stream:continue
		check(stream.mix_rate==44100 and not stream.stereo,"44.1k mono "+entry.id)
		check(absf(stream.get_length()-float(entry.seconds))<.003,"Native duration "+entry.id)
		check((stream.loop_mode==AudioStreamWAV.LOOP_FORWARD)==bool(entry.loop),"Explicit native loop flag "+entry.id)
		if not entry.get("music",false):check(stream.format==AudioStreamWAV.FORMAT_16_BITS,"Uncompressed effect format "+entry.id)
		var player:=AudioStreamPlayer.new();root.add_child(player)
		player.bus="Music" if entry.get("music",false) else "Effects";player.stream=stream;player.play()
		await process_frame
		check(player.playing,"Real playback starts "+entry.id)
		check(player.bus==("Music" if entry.get("music",false) else "Effects"),"Intended bus "+entry.id)
		player.seek(maxf(0,stream.get_length()-.025))
		await create_timer(.14).timeout
		check(player.playing if entry.loop else not player.playing,"Loop wraps or one-shot finishes "+entry.id)
		player.stop();check(not player.playing,"Explicit player stop "+entry.id)
		player.stream=null;player.queue_free();await process_frame
	check(is_equal_approx(AudioServer.get_bus_volume_db(effects),-4) and is_equal_approx(AudioServer.get_bus_volume_db(music),-9),"Independent volume values retained")
	await create_timer(.15).timeout
	var file:=FileAccess.open("res://validation.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"display":DisplayServer.get_name(),"all_assets":57,"master_muted":true,"player_settings_used":false,"game_rules_or_rng_used":false,"physical_iphone_tested":false},"\t")+"\n");file.close()
	print("AUDIO_ASSET_NATIVE: ",checks," checks, ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)

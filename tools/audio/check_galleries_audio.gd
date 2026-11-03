extends SceneTree
## Real controller/event hooks, with only lifecycle/UI/save calls suppressed.
## Never instantiate the live Main lifecycle or read/write player files.
const SOUNDS:=preload("res://scripts/sounds.gd")
const SETTINGS:=preload("res://scripts/settings.gd")
const MUSIC:=preload("res://scripts/music.gd")
const GALLERIES:=preload("res://scripts/galleries.gd")
const MODEL:=preload("res://scripts/party_state.gd")
const MAP:=preload("res://scripts/dungeon_map.gd")
const QUESTS:=preload("res://scripts/quests.gd")
class IsolatedMain:
	extends "res://scripts/main.gd"
	func _ready() -> void:pass
	func _build_level() -> void:pass
	func _show_message(_text:String) -> void:pass
	func _tip(_key:String,_text:String) -> void:pass
var checks:=0
var failures:Array[String]=[]
func check(ok:bool,label:String) -> void:
	checks+=1
	if not ok:failures.append(label);push_error(label)
func _initialize() -> void:call_deferred("run")
func players(parent:Node) -> Array:
	return parent.get_children().filter(func(n):return n is AudioStreamPlayer)
func run() -> void:
	Engine.set_meta("depths_settings",SETTINGS.DEFAULTS.duplicate());Engine.set_meta("depths_settings_loaded",true)
	SETTINGS.ensure_buses();AudioServer.set_bus_mute(0,true)
	var catalog:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://audio/galleries-v1/catalog.json"))
	for e in catalog.assets:
		var stream:AudioStream=load("res://"+e.file)
		check(stream!=null and absf(stream.get_length()-e.seconds)<.05,"Runtime stream "+e.id)
		check(stream is AudioStreamWAV and (stream.loop_mode==AudioStreamWAV.LOOP_FORWARD)==e.loop,"Correct native loop flag "+e.id)
	var main:=IsolatedMain.new();root.add_child(main)
	main._party_state=MODEL.new();main._party_state.add_member(load("res://data/companions/mara.tres"))
	main._map=MAP.new(PackedStringArray(["#####","#S..#","#####"]),5)
	main._map.water[Vector2i(2,1)]=true;main._depth=5;main._in_opening=false
	main._rng.seed=167;var game_state:int=main._rng.state
	for i in 4:
		main._hear_wanderers(main.WANDER_SOUNDS[i],i)
		var p:AudioStreamPlayer=players(main)[-1]
		check(p.stream==SOUNDS.EFFECTS[SOUNDS.WANDER_KEYS[i]] and p.bus=="Effects" and p.volume_db<=-12,"Matching distant warning "+str(i))
	check(main._rng.state==game_state,"Warnings never advance gameplay RNG")
	var before:=players(main).size();var time_before:int=main._party_state.time_elapsed
	main._wade(Vector2i(1,1));check(players(main).size()==before,"Dry cell has no wading sound")
	main._wade(Vector2i(2,1));var wade:AudioStreamPlayer=players(main)[-1]
	check(wade.stream in SOUNDS.VARIANTS.wade and wade.bus=="Effects","Wet step uses one of three real variants")
	check(main._party_state.time_elapsed==time_before+GALLERIES.WADE_TIME,"Existing wading time remains exact")
	main._in_opening=true;before=players(main).size();main._wade(Vector2i(2,1));check(players(main).size()==before,"Opening does not get wading foley")
	main._in_opening=false
	main.environment_theme=GALLERIES.theme_from(load("res://themes/cave.tres"))
	main._ambience_player=AudioStreamPlayer.new();main.add_child(main._ambience_player)
	main._refresh_place_ambience()
	check(main._ambience_player.stream==SOUNDS.LOOPS.galleries and main._ambience_player.playing and main._ambience_player.bus=="Effects","Real floor theme plays water ambience on Effects")
	var original:=main._ambience_player.get_instance_id();main._refresh_place_ambience()
	check(main._ambience_player.get_instance_id()==original,"Ambience refresh reuses one player")
	main._music=MUSIC.new();main.add_child(main._music);main._play_place_music()
	check(main._music.place=="galleries" and MUSIC.track_for("galleries").resource_path.ends_with("below-the-sluice.wav"),"Deeper floor selects the new score")
	main._depth=1;main.environment_theme=load("res://themes/cave.tres");main._refresh_place_ambience();main._play_place_music()
	check(main._ambience_player.bus=="Music" and main._music.place=="cave","Leaving the Galleries restores existing audio routing/music")
	main._depth=5;main._minimap=Control.new();main.add_child(main._minimap)
	QUESTS.set_flag(main._camp_state,"dry_passage","ending_shown")
	main._drain_galleries()
	check(main._map.water.is_empty() and players(main)[-1].stream==SOUNDS.EFFECTS.drain,"Actual drain clears water and plays drain once")
	var screen=preload("res://scripts/event_screen.gd").new();root.add_child(screen)
	var rules=preload("res://scripts/room_events.gd").new();rules.camp=main._camp_state
	var event:RoomEvent=load("res://data/events/quest_sluice.tres")
	screen.show_event(event,main._party_state,rules);screen._choose(event.choices[0])
	check(rules.drained and players(screen).size()==1 and players(screen)[0].stream==SOUNDS.EFFECTS.sluice,"Real sluice choice starts iron groan")
	# Verify native finished cleanup without waiting through the long sound.
	for p in players(screen):p.seek(p.stream.get_length()-.04)
	await create_timer(.8).timeout
	check(players(screen).is_empty(),"One-shot player frees after finishing")
	var settings:Dictionary=Engine.get_meta("depths_settings");settings.Effects=0.0;settings.Music=0.0;SETTINGS.apply()
	check(AudioServer.is_bus_mute(AudioServer.get_bus_index("Effects")) and AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")),"Effects and Music independently obey Settings mute")
	for p in players(main):p.stop()
	for p in main._music._players:p.stop()
	screen.free();main.free();await create_timer(.2).timeout
	var out:=FileAccess.open("res://art/concepts/galleries-audio-v1/"+("godot-headless.json" if DisplayServer.get_name()=="headless" else "godot-native.json"),FileAccess.WRITE)
	out.store_string(JSON.stringify({"checks":checks,"failures":failures,"player_files_used":false},"\t")+"\n");out.close()
	print("GALLERIES_GODOT: %d checks, %d failures"%[checks,failures.size()]);quit.call_deferred(0 if failures.is_empty() else 1)

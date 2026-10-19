extends SceneTree
## #80: initial story state, independent arrival triggers, commerce and live camp.
const CS=preload("res://scripts/camp_state.gd")
const PS=preload("res://scripts/party_state.gd")
const SG=preload("res://scripts/save_game.gd")
const Settings=preload("res://scripts/settings.gd")
const OUT="res://art/concepts/camp-arrivals-v1/"
var checks:=0
var failures:Array[String]=[]
var captures:Array[String]=[]

func _initialize() -> void:
	call_deferred("_run")

func check(ok:bool,label:String) -> void:
	checks+=1
	if not ok:failures.append(label);push_error(label)

func settle() -> void:
	for i in 6:await process_frame

func snap(name:String) -> void:
	await settle();await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(OUT+name+".png")==OK,"Capture "+name)
	captures.append(name)

func press(button:Button,touch:bool) -> void:
	for down in [true,false]:
		if touch:
			var event:=InputEventScreenTouch.new();event.position=button.get_global_rect().get_center();event.pressed=down;Input.parse_input_event(event)
		else:
			var event:=InputEventMouseButton.new();event.position=button.get_global_rect().get_center();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=down;Input.parse_input_event(event)
		await settle()

func _run() -> void:
	var legacy=CS.new();SG.unpack_into(legacy,{"day":4})
	check(legacy.can_trade() and legacy.site_present("smith") and legacy.smith_arrival_day==0,"Old saves keep established services")
	var party=PS.new();party.add_member(load("res://data/companions/mara.tres"))
	party.supplies.gold=200
	party.supplies.has_lantern=false
	var ration:SupplyItem=load("res://data/items/ration.tres")
	var treasure:SupplyItem=load("res://data/items/silver_trinket.tres")
	var club:Equipment=load("res://data/gear/wooden_club.tres")
	party.supplies.add(treasure,1);party.supplies.gear.append(club)
	var camp=CS.new();camp.start(31,party);camp.begin_arrivals()
	check(["rest","fire","treatment","supplies","cave"].all(func(id):return camp.site_present(id)) and not camp.site_present("smith"),"Owner's initial physical sites")
	check(camp.merchant_unloading and not camp.can_trade() and camp.smith_arrival_day==2,"Unloading is distinct from absence; smith due first morning")
	check(not camp.buy(party,ration) and not camp.buy_lantern(party) and not camp.sell(party,treasure) and not camp.sell_gear(party,club) and not camp.buy_gear(party,club),"Model rejects all trade while unloading or smith absent")
	check(party.supplies.gold==200 and party.supplies.count(treasure)==1 and party.supplies.gear.size()==1 and not party.supplies.has_lantern,"Rejected trades preserve money/items/lantern")
	var saved:Dictionary=SG.pack_object(camp,["stash","rng"]);var restored=CS.new();SG.unpack_into(restored,saved)
	check(restored.merchant_unloading and restored.smith_arrival_day==2 and not restored.site_present("smith"),"Initial arrival state survives existing save serialization")
	camp.expedition_returned()
	check(camp.can_trade() and not camp.site_present("smith"),"First expedition return opens merchant independently of morning")
	check(camp.buy(party,ration) and camp.sell(party,treasure),"Trading succeeds once open")
	camp.rest(party)
	check(camp.day==2 and camp.site_present("smith") and camp.smith_arrival_day==0 and camp.can_trade(),"First night brings smith without resetting merchant")
	check(camp.buy_gear(party,club),"Smith stock becomes usable after arrival")
	camp.rest(party);check(camp.can_trade() and camp.site_present("smith"),"Later rests never replay initial state")
	var early_rest=CS.new();early_rest.start(32,party);early_rest.begin_arrivals();early_rest.rest(party)
	check(early_rest.site_present("smith") and not early_rest.can_trade(),"Resting before an expedition brings smith but does not open trading")
	var poor=PS.new();poor.add_member(load("res://data/companions/mara.tres"))
	poor.supplies.has_lantern=false
	check(restored.give_charity(poor) and poor.supplies.count(CS.TORCH)==2 and not restored.can_trade(),"Existing emergency torches remain available without trading")
	check(not restored.give_charity(poor),"Emergency kit still limited")
	for resolution in [Vector2i(1280,720),Vector2i(1278,590),Vector2i(1334,750)]:
		root.size=resolution
		Settings.set_value("text_size","Normal",self)
		var tag:String="desktop" if resolution.x==1280 else str(resolution.x)
		SG.set_continue_requested(false)
		var main=load("res://scenes/main.tscn").instantiate()
		main.play_opening=true;main.use_debug_layout=false;main.floor_seed=31;main.simulate_phone_safe_area=resolution.x!=1280
		root.add_child(main);await create_timer(.35).timeout
		check(main._in_opening and main._camp_state.merchant_unloading and not main._camp_state.site_present("smith"),"Real new story configures initial arrivals "+tag)
		main._start_new_expedition();await settle()
		var screen=main._camp;camp=main._camp_state
		check(screen.visible and camp.merchant_unloading and not camp.can_trade(),"Tutorial escape does not open shop "+tag)
		check(screen._site_art.supplies.get_node("Unloading").is_visible_in_tree() and not screen._site_art.supplies.get_node("Base").visible and not screen._site_art.supplies.get_node("Lantern0").visible,"Unloading art replaces finished stall/light "+tag)
		check(not screen._site_art.smith.visible and not screen._buttons.smith.visible and screen._buttons.smith.disabled,"Absent smith has no art/light/target "+tag)
		check(screen._buttons.supplies.text.contains("Unloading"),"Closed shop visibly named "+tag)
		for id in ["rest","fire","treatment","supplies","cave"]:
			var button:Button=screen._buttons[id]
			check(button.visible and not button.disabled and root.get_visible_rect().encloses(button.get_global_rect()) and button.get_global_rect().size.y>=44,"Initial accessible site "+id+tag)
		for button in [screen._save_button,screen._settings_button]:
			check(root.get_visible_rect().encloses(button.get_global_rect()) and button.get_global_rect().size.y>=44,"Global controls fit "+button.text+tag)
		await snap("starting-"+tag)
		Settings.set_value("text_size","Larger",self);await settle()
		check(screen._buttons.supplies.get_global_rect().size.y>=44,"Larger unloading target "+tag)
		check([screen._save_button,screen._settings_button].all(func(b):return root.get_visible_rect().encloses(b.get_global_rect()) and b.get_global_rect().size.y>=44),"Larger global controls fit "+tag)
		await snap("starting-"+tag+"-larger")
		Settings.set_value("text_size","Normal",self);await settle()
		await press(screen._buttons.supplies,resolution.x!=1280)
		check(screen._current=="supplies" and screen._body.find_children("*","Button",true,false).is_empty(),"Mouse/touch inspects closed merchant without shop actions "+tag)
		check(not screen._save_button.visible and not screen._settings_button.visible and root.get_visible_rect().encloses(screen._back.get_global_rect()),"Activity has clear Back without partly covered globals "+tag)
		var words:String=" ".join(screen._body.find_children("*","Label",true,false).map(func(l):return l.text))
		check(words.contains("Trading is not available yet"),"Unavailability explained "+tag)
		await snap("unloading-"+tag)
		screen._close_activity();screen.open_activity("smith");check(screen._current=="","Direct absent smith access refused "+tag)
		# Take the actual camp departure/preparation path before returning.
		screen.cave_chosen.emit(1);await settle();main._preparation._enter.pressed.emit();await settle()
		check(not main._preparation.visible,"Preparation closes through real button "+tag)
		main._start_new_expedition();await settle()
		check(camp.can_trade() and not screen._site_art.supplies.get_node("Unloading").visible and screen._site_art.supplies.get_node("Base").visible,"Real first expedition return opens finished merchant "+tag)
		check(not camp.site_present("smith"),"Returning alone does not bring smith "+tag)
		await snap("trading-"+tag)
		camp.rest(main._party_state);await settle()
		check(camp.site_present("smith") and screen._buttons.smith.visible and screen._site_art.smith.visible,"Actual first rest reveals smith "+tag)
		await snap("morning-"+tag)
		screen.open_activity("supplies");check(not screen._body.find_children("*","Button",true,false).is_empty(),"Established merchant shows stock "+tag)
		var reload=CS.new();SG.unpack_into(reload,SG.pack_object(camp,["stash","rng"]))
		check(reload.can_trade() and reload.site_present("smith") and reload.smith_arrival_day==0,"Established stage survives save "+tag)
		main.queue_free();await settle()
	Settings.set_value("text_size","Normal",self)
	var report={"checks":checks,"failures":failures,"captures":captures,"physical_phone_test":false}
	var file=FileAccess.open(OUT+"godot-validation.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"\t")+"\n");file.close()
	print("CAMP_ARRIVALS: ",checks," failures: ",failures.size()," captures: ",captures.size())
	quit(1 if not failures.is_empty() else 0)

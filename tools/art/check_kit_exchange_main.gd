extends SceneTree
## Actual Main integration, with a private project-local fixture save.
const SAFE:=preload("res://scripts/safe_area.gd")
const OUT:="res://art/concepts/interface/exchange-live-v1/"
var checks:=0
var failures:Array[String]=[]
var main

func _initialize() -> void:
	preload("res://scripts/save_game.gd").set_path("res://build/exchange-review/main-save.dat")
	preload("res://scripts/save_game.gd").set_continue_requested(false)
	Engine.set_meta("depths_settings",preload("res://scripts/settings.gd").DEFAULTS.duplicate())
	Engine.set_meta("depths_settings_loaded",true)
	call_deferred("run")

func check(ok:bool,label:String) -> void:
	checks+=1
	if not ok:failures.append(label);push_error(label)

func settle() -> void:
	for i in 10:await process_frame

func snap(name:String) -> void:
	await settle();await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(OUT+name+".png")==OK,"Capture "+name)

func escape() -> void:
	var event:=InputEventAction.new();event.action="ui_cancel";event.pressed=true
	Input.parse_input_event(event);await settle()

func run() -> void:
	main=load("res://scenes/main.tscn").instantiate()
	main.play_opening=false;main.floor_seed=11;main.simulate_phone_safe_area=true
	root.add_child(main);await create_timer(0.6).timeout
	AudioServer.set_bus_mute(0,true)
	var party=main._party_state
	var camp=main._camp_state
	var ration:SupplyItem=load("res://data/items/ration.tres")
	var ore:SupplyItem=load("res://data/items/copper_ore.tres")
	var cloth:SupplyItem=load("res://data/items/fine_cloth.tres")
	party.supplies.gold=40;party.supplies.add(ore,2)
	main._end_expedition(main.Expedition.Ending.RETURNED);await settle()
	main._results.continue_pressed.emit();await create_timer(0.4).timeout
	check(main._camp.visible,"Actual results reach camp")
	main._camp.open_activity("supplies");await settle()
	var view=main._camp._merchant_view
	check(view.visible and not main._camp._activity.visible,"Merchant replaces old list activity")
	check(view.get_parent()==main._camp.content and view.scale==Vector2.ONE,"Merchant is outside the scaled camp canvas")
	for shape in [Vector2i(1280,720),Vector2i(1278,590)]:
		root.size=shape
		for scale_factor in [1.0,1.3]:
			root.content_scale_factor=scale_factor
			await settle()
			view.select_item(ration,"left");await settle()
			check(root.get_visible_rect().encloses(view._close.get_global_rect()),"Safe close at %s / %s"%[shape,scale_factor])
			check(view._details.get_global_rect().end.y<=main._camp.content.get_global_rect().end.y,"Inspection inside camp safe area")
			await snap("main-merchant-%d-%s"%[shape.x,"larger" if scale_factor>1 else "normal"])
	var gold:int=party.supplies.gold
	view.select_item(ore,"right");view._primary.pressed.emit();await settle()
	check(party.supplies.gold==gold+ore.price and party.supplies.count(ore)==1,"Actual camp sells one treasure")
	await escape();check(main._camp.is_open("supplies") and view._key==null,"First Escape clears inspection")
	await escape();check(main._camp._current=="" and not view.visible,"Second Escape returns to clearing")
	check(main._camp._buttons.supplies.has_focus(),"Focus returns to merchant site")
	main._camp.open_activity("supplies");await settle()
	camp.set_site_present("supplies",false);await settle()
	check(main._camp._current=="" and not view.visible,"Absent merchant closes service")
	camp.set_site_present("supplies",true)
	camp.set_merchant_unloading(true);main._camp.open_activity("supplies");await settle()
	check(view.visible and view._left_entries.is_empty(),"Actual arriving merchant exposes no stock")
	camp.set_merchant_unloading(false);await settle()
	check(not view._left_entries.is_empty(),"Live arrival transition reveals stock")
	main._camp._close_activity();main._camp.hide()
	party.supplies.capacity=party.supplies.slots_used()
	main._offer_no_room({cloth:4});await settle()
	check(main._chest.visible and main._chest.contents.get(cloth)==4,"Actual reward overflow uses the same loot interface")
	main._chest.select_item(cloth,"left");await settle()
	check(main._chest._primary.disabled,"Actual full pack explains unavailable Take")
	await snap("main-reward-overflow-phone")
	main._chest.closed.emit();await settle()
	check(not main._chest.visible,"Reward window closes through existing await")
	var file:=FileAccess.open(OUT+"main-validation.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"physical_iPhone":false,"private_save":"build/exchange-review/main-save.dat"},"\t")+"\n");file.close()
	main.free();main=null;party=null;camp=null;view=null;await settle()
	print("KIT_EXCHANGE_MAIN: checks=%d failures=%d"%[checks,failures.size()])
	quit(0 if failures.is_empty() else 1)

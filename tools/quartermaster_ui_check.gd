extends SceneTree
const SETTINGS:=preload("res://scripts/settings.gd")
const SAVE:=preload("res://scripts/save_game.gd")
var main
var out: String
var checks:=0
var failures: Array[String]=[]
var chosen: Array[int]=[]

func _initialize() -> void:
	out=OS.get_cmdline_user_args()[0] if not OS.get_cmdline_user_args().is_empty() else "res://build/quartermaster-review"
	DirAccess.make_dir_recursive_absolute(out);SAVE.set_path(out.path_join("private-test-save.dat"))
	Engine.set_meta("depths_settings",SETTINGS.DEFAULTS.duplicate());Engine.set_meta("depths_settings_loaded",true)
	call_deferred("run")

func check(label: String,ok: bool) -> void:
	checks+=1
	if not ok:failures.append(label);push_error(label)

func settle() -> void:
	for i in 12:await process_frame

func snap(label: String) -> void:
	if DisplayServer.get_name()=="headless":return
	await settle();await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(label+".png"))

func press(button: Button,touch:=false) -> void:
	button.grab_focus();await settle()
	var at:=button.get_global_rect().get_center()
	for down in [true,false]:
		if touch:
			var event:=InputEventScreenTouch.new();event.index=0;event.pressed=down;event.position=at;root.push_input(event,true)
		else:
			var event:=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=down;event.position=at;root.push_input(event,true)
		await process_frame
	await settle()

func text_of(view: Node) -> String:
	return " | ".join(view.find_children("*","Label",true,false).map(func(label):return label.text))

func run() -> void:
	main=load("res://scenes/main.tscn").instantiate();main.play_opening=false;main.use_debug_layout=true;main.wandering=false
	root.add_child(main);await create_timer(.6).timeout
	var camp=main._camp_state;var party=main._party_state
	main._camp.open(camp,party);main._camp.open_activity("cave");await settle()
	var desk=main._camp._quartermaster_view
	desk.departure_requested.connect(func(depth: int):chosen.append(depth))
	check("mine-path interaction opens Garran",desk.is_visible_in_tree() and main._camp.is_busy() and not main._camp._activity.visible)
	check("camp has a grounded original station",main._camp._site_art.cave.get_node("Quartermaster").texture!=null)
	check("portrait and service role",desk.FACE!=null and desk._heading.text.contains("Quartermaster"))
	check("earned routes remain locked",desk._route_buttons[2].disabled and desk._route_buttons[3].disabled and desk.selected_depth==1)
	var before: int=party.supplies.gold
	desk._prepare();check("planning entrance is free",chosen==[1] and party.supplies.gold==before)
	chosen.clear();desk.selected_depth=4;desk._prepare();check("guarded stale/locked route",chosen.is_empty())
	desk.selected_depth=1;camp.floors_reached[2]=1;desk._refresh()
	check("survey progress explains eligibility",text_of(desk).contains("1/2"))
	camp.floors_reached[2]=2;party.supplies.gold=50;desk._refresh();await settle()
	desk._route_buttons[2].pressed.emit();await settle()
	check("route selection spends nothing",desk.selected_depth==2 and party.supplies.gold==50 and chosen.is_empty())
	desk._prepare();check("prepared route reports depth without billing",chosen==[2] and party.supplies.gold==50);chosen.clear()
	party.supplies.gold=0;desk._prepare();check("route rechecks funds",chosen.is_empty())
	party.supplies.gold=50;camp.issue_level=0;desk.show_tab("supplies");await settle()
	check("current and next issue explained",text_of(desk).contains("Free on return") and desk._upgrade.text.begins_with("Field issue"))
	desk._buy_issue();check("one upgrade pays once and persists",camp.issue_level==1 and party.supplies.gold==20 and text_of(desk).contains("Paid."))
	desk._buy_issue();check("missing resources cannot buy next tier",camp.issue_level==1 and party.supplies.gold==20)
	party.supplies.gold=0;camp.stash.gold=60;camp.stash.add(load("res://data/items/coal.tres"),3)
	desk._buy_issue();check("upgrade uses existing stash rules",camp.issue_level==2 and camp.stash.gold==0 and party.supplies.gold==0)
	party.supplies.gold=100;camp.stash.add(load("res://data/items/copper_ore.tres"),2);desk._buy_issue()
	check("expedition issue uses its existing ore cost",camp.issue_level==3 and party.supplies.gold==0)
	check("maximum issue remains clear",desk._upgrade==null and text_of(desk).contains("full allowance"))
	var data: Dictionary=SAVE.pack_object(camp,["stash","candidates","left_behind","recovering","rng","fallen","lost_bodies","carried"])
	var again=load("res://scripts/camp_state.gd").new();SAVE.unpack_into(again,data)
	check("save retains issue and scouts",again.issue_level==3 and again.route_open(2))
	for topic: String in desk.TOPICS:
		desk.show_tab("talk");desk._reply=desk.TOPICS[topic][1];desk._refresh();await settle()
		check("Garran answers "+topic,text_of(desk).contains(desk.TOPICS[topic][1]))
	# Actual Main stretch, phone margins and the Larger interface setting.
	camp.issue_level=0;party.supplies.gold=50;desk.selected_depth=1
	for shape in [Vector2i(1280,720),Vector2i(1278,590),Vector2i(844,390),Vector2i(667,375)]:
		for setting: String in ["Normal","Larger"]:
			root.size=shape;main.simulate_phone_safe_area=shape.x<1280;SETTINGS.set_value("text_size",setting,self);main._apply_safe_area();await settle()
			for tab: String in ["routes","supplies","talk"]:
				await press(desk._tabs[tab],tab=="talk");await settle()
				check("mouse/touch tab "+tab+str(shape)+setting,desk.tab==tab)
				var viewport:=root.get_visible_rect();var rect: Rect2=desk._panel.get_global_rect()
				check("panel fits "+tab+str(shape)+setting,viewport.grow(2).encloses(rect))
				var scale: Vector2=root.get_screen_transform().get_scale();var pixel:=minf(scale.x,scale.y)
				for button: Button in [desk._close,desk._tabs.routes,desk._tabs.supplies,desk._tabs.talk]:
					check("44px persistent target "+str(shape)+setting,button.size.y*pixel>=43)
				if tab=="routes":
					check("departure is visible and tappable "+str(shape)+setting,viewport.encloses(desk._departure.get_global_rect()) and desk._departure.size.y*pixel>=43)
				if tab=="supplies":
					for label: Label in desk._rows.find_children("*","Label",true,false):
						if label.has_meta("issue_name"):check("supply name has readable line width "+str(shape)+setting,label.size.x*pixel>=160 and label.size.y*pixel<65)
				if setting=="Normal":await snap("%s-%d"%[tab,shape.x])
	# Back/Escape returns to the same existing camp site.
	desk.finish();await settle();check("Back returns to clearing",not main._camp.is_busy() and main._camp._buttons.cave.is_visible_in_tree())
	main._camp.open_activity("cave");await settle()
	var escape:=InputEventKey.new();escape.keycode=KEY_ESCAPE;escape.pressed=true;root.push_input(escape,true);await settle()
	check("Escape closes desk",not desk.visible and not main._camp.is_busy())
	main._camp._close_activity();await snap("camp-phone")
	root.size=Vector2i(1280,720);main.simulate_phone_safe_area=false;main._apply_safe_area();await settle();await snap("camp")
	# Actual preparation flow: a plan and Back are free; Enter pays once.
	SETTINGS.set_value("text_size","Normal",self);root.size=Vector2i(844,390);main._apply_safe_area()
	party.supplies.gold=10;camp.stash.gold=40;camp.floors_reached[2]=2
	main._camp_loop();await settle()
	for attempt in 3:
		main._camp.open_activity("cave");await settle();desk._route_buttons[2].pressed.emit();await settle();desk._departure.pressed.emit();await settle()
		check("route reaches preparation without billing "+str(attempt),main._preparation.visible and party.supplies.gold==10 and camp.stash.gold==40)
		if attempt==0:
			main._preparation._back.pressed.emit();await settle()
			check("Back to camp preserves route money",main._camp.visible and party.supplies.gold==10 and camp.stash.gold==40)
		elif attempt==1:
			party.supplies.gold=0;camp.stash.gold=0;main._preparation._enter.pressed.emit();await settle()
			check("Enter rechecks route fee",main._camp.visible and main._depth==1 and party.supplies.gold==0)
			party.supplies.gold=10;camp.stash.gold=40
		else:
			main._preparation._enter.pressed.emit();await create_timer(.5).timeout
			check("Enter pays exactly once and reaches chosen floor",main._depth==2 and party.supplies.gold==0 and camp.stash.gold==50-camp.route_price(2))
	main.queue_free();await settle()
	FileAccess.open(out.path_join("validation.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"physical_iPhone":false},"  "))
	print("QUARTERMASTER_UI checks=",checks," failures=",failures.size());quit(0 if failures.is_empty() else 1)

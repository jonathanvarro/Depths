extends SceneTree
const PREFS:=preload("res://scripts/settings.gd")
const SAVE:=preload("res://scripts/save_game.gd")
var main
var out: String
var failures: Array[String]=[]
var checks:=0

class Clock extends Node:
	var ticks:=0
	func _process(_delta: float) -> void:ticks+=1

func _initialize() -> void:
	out=OS.get_cmdline_user_args()[0] if not OS.get_cmdline_user_args().is_empty() else "res://build/field-kit-v3-check"
	DirAccess.make_dir_recursive_absolute(out)
	SAVE.set_path(out.path_join("test-save.dat"))
	PREFS.set_value("flashes",false)
	call_deferred("run")

func check(label: String, ok: bool) -> void:
	checks+=1
	print("PASS " if ok else "FAIL ",label)
	if not ok:failures.append(label)

func settle() -> void:
	for i in 12:await process_frame

func snap(label: String) -> void:
	await settle();await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(label+".png"))

func press(button: Button,touch:=false) -> void:
	var at:=button.get_global_rect().get_center()
	for down in [true,false]:
		if touch:
			var event:=InputEventScreenTouch.new();event.index=0;event.pressed=down;event.position=at
			root.push_input(event,true)
		else:
			var event:=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=down;event.position=at
			root.push_input(event,true)
		await process_frame
	await settle()

func escape() -> void:
	for down in [true,false]:
		var event:=InputEventKey.new();event.keycode=KEY_ESCAPE;event.physical_keycode=KEY_ESCAPE;event.pressed=down
		root.push_input(event,true);await process_frame
	await settle()

func run() -> void:
	main=load("res://scenes/main.tscn").instantiate()
	main.play_opening=false;main.floor_seed=11;main.wandering=false
	root.add_child(main);current_scene=main
	await create_timer(.7).timeout
	var party=main._party_state
	for id in ["corin","alwen"]:party.add_member(load("res://data/companions/"+id+".tres"))
	for id in ["torch","ration","dressing","restorative_draught","holy_water"]:party.supplies.add(load("res://data/items/"+id+".tres"),3)
	for id in ["plain_knife","simple_spear","padded_coat","satchel"]:party.supplies.gear.append(load("res://data/gear/"+id+".tres").duplicate())
	party.members[0].body=load("res://data/gear/leather_jerkin.tres").duplicate();party.members[0].body.tier="rare"
	main._set_pack(true);await settle()
	var pack=main._pack
	for shape in [Vector2i(1280,720),Vector2i(1278,590),Vector2i(844,390),Vector2i(667,375)]:
		for ui_scale in [1.0,1.3]:
			root.size=shape;root.content_scale_factor=ui_scale
			main.simulate_phone_safe_area=shape.y<720;main._apply_safe_area()
			pack._compact_equipment=false;pack._fit_workspace();await settle()
			var tag:="%d-%s"%[shape.x,"larger" if ui_scale>1 else "normal"]
			var pixels:=root.get_screen_transform().get_scale()
			print("LAYOUT ",shape," scale=",ui_scale," viewport=",root.get_visible_rect().size," screen=",root.get_screen_transform().get_scale()," stretch=",root.get_stretch_transform().get_scale()," content=",pack.content.size," compact=",pack._compact," pocket=",pack._bag.slots[0].size)
			var bag_rect: Rect2=pack._bag.get_global_transform()*pack._bag.art_rect
			check("full bag stays inside its drawing area "+tag,pack._bag.get_global_rect().grow(1).encloses(bag_rect))
			check("book spine stays right of bag "+tag,pack._journal.global_position.x>=pack._bag.get_global_rect().end.x)
			check("header fits safe area "+tag,pack.content.get_global_rect().grow(1).encloses(pack._header.get_global_rect()))
			for control in [pack._menu,pack._close,pack._journal]+pack._hero_row.get_children():
				check("header/portrait/book touch target "+tag,control.size.x*pixels.x>=43.5 and control.size.y*pixels.y>=43.5)
			for portrait in pack._hero_row.get_children():
				check("portrait clears brass frame "+tag,portrait.get_global_rect().grow(-5).encloses(portrait.get_child(0).get_global_rect()))
			for tile in pack._bag.slots:
				check("pocket touch target "+tag,tile.size.x*pixels.x>=43.5 and tile.size.y*pixels.y>=43.5)
				if tile.get_child_count()>0:
					var icon: Control=tile.get_child(0)
					check("item centred in pocket "+tag,icon.get_global_rect().get_center().distance_to(tile.get_global_rect().get_center())<1)
			await snap("pack-"+tag)
			if pack._compact:pack._toggle_compact();await settle()
			for control in [pack._equip_tab,pack._status_tab]:
				check("tab touch target "+tag,control.size.x*pixels.x>=43.5 and control.size.y*pixels.y>=43.5)
			for slot: Button in pack._slot_buttons.values():
				check("square equipment target "+tag,absf(slot.size.x-slot.size.y)<1 and slot.size.x*pixels.x>=43.5)
				check("equipment drawing stays within silhouette pane "+tag,pack._equipment.get_global_rect().grow(1).encloses(slot.get_global_rect()))
				check("equipped icon centred "+tag,slot.get_child(0).get_global_rect().get_center().distance_to(slot.get_global_rect().get_center())<1)
			await snap("equipment-"+tag)
			if pack._compact:pack._toggle_compact();await settle()
			pack.clear_inspection();await escape()
			check("Escape opens menu over pack "+tag,main._pause_menu.visible and paused and pack.visible)
			check("pause panel clears phone margins "+tag,main._pause_menu.content.get_global_rect().grow(1).encloses(main._pause_menu._panel.get_global_rect()))
			for control in [main._pause_menu._continue,main._pause_menu._options,main._pause_menu._save,main._pause_menu._close]:
				check("pause action touch target "+tag,control.size.x*pixels.x>=43.5 and control.size.y*pixels.y>=43.5)
			if shape.x==667:await snap("pause-"+tag)
			await escape()
	# More than twelve carried stacks must retain usable page controls and
	# pockets, including an over-capacity inventory the player needs to sort.
	party.supplies.add(load("res://data/items/torch.tres"),30);await settle()
	for shape in [Vector2i(844,390),Vector2i(667,375)]:
		for ui_scale in [1.0,1.3]:
			root.size=shape;root.content_scale_factor=ui_scale
			main._apply_safe_area();pack._fit_workspace();await settle()
			var pixels:=root.get_screen_transform().get_scale()
			for tile in pack._bag.slots:
				check("paged pocket remains touch sized",tile.size.x*pixels.x>=43.5 and tile.size.y*pixels.y>=43.5)
			for control in pack._pages.get_children():
				if control is Button:check("pagination touch target",control.size.x*pixels.x>=43.5 and control.size.y*pixels.y>=43.5)
			await snap("paged-%d-%s"%[shape.x,str(ui_scale)])
	var last:=pack._pages.get_children()[-1] as Button
	await press(last,true)
	check("touch opens second bag page",pack._page==1)
	await press(pack._pages.get_child(0),true)
	check("touch returns first bag page",pack._page==0)
	root.size=Vector2i(1278,590);root.content_scale_factor=1
	main._apply_safe_area();pack._fit_workspace();await settle()
	await press(pack._journal,true)
	check("book tap opens real quest log",main._quest_log.visible and pack.visible)
	await escape()
	check("quest Escape returns to pack",not main._quest_log.visible and pack.visible)
	pack.clear_inspection()
	var chosen: Companion=pack._selected_hero
	var clock:=Clock.new();main.add_child(clock)
	await press(pack._menu)
	check("gear opens pause menu",main._pause_menu.visible and paused)
	var ticks:=clock.ticks
	await create_timer(.2).timeout
	check("pause freezes gameplay processing",clock.ticks==ticks)
	await snap("pause-from-pack")
	await press(main._pause_menu._options,true)
	check("Options remains interactive while paused",main._settings.visible and paused)
	var previous: bool=PREFS.get_value("flashes")
	await press(main._settings._toggles.flashes,true)
	check("settings changes work while paused",PREFS.get_value("flashes")!=previous)
	await escape()
	check("Options Back returns to menu without resuming",not main._settings.visible and main._pause_menu.visible and paused)
	await escape()
	check("menu Escape returns to same hero and pack",not paused and pack.visible and pack._selected_hero==chosen)
	await press(pack._close)
	check("X still closes pack",not pack.visible)
	await escape()
	check("Esc opens menu from exploration",main._pause_menu.visible and paused)
	await press(main._pause_menu._continue,true)
	check("Continue resumes exploration",not paused and not main._pause_menu.visible and not pack.visible)
	await escape()
	await press(main._pause_menu._save,true)
	await create_timer(.3).timeout
	check("Save & exit uses real save and title",SAVE.exists() and current_scene.scene_file_path=="res://scenes/title.tscn" and not paused)
	FileAccess.open(out.path_join("validation.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"physical_iPhone":false},"  "))
	print("FIELD_KIT_V3 checks=",checks," failures=",failures.size())
	quit(0 if failures.is_empty() else 1)

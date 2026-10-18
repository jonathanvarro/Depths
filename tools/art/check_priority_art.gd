extends SceneTree
## Input-driven review of the live camp/Pack/chest plus canonical portrait lighting.
const OUT := "res://art/concepts/inventory-64-v1/"
const MARA_OUT := "res://art/concepts/mara-neutral-v1/"
var checks := 0
var failures: Array[String] = []
var captures: Array[String] = []
var main

func _initialize() -> void:
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	call_deferred("_run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		push_error(label)

func settle() -> void:
	for i in 5: await process_frame

func snap(path: String) -> void:
	await settle()
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(path)==OK,"Capture "+path)
	captures.append(path)

func button(node: Node, prefix: String) -> Button:
	for b in node.find_children("*","Button",true,false):
		if b.is_visible_in_tree() and b.text.begins_with(prefix):return b
	return null

func click(b: Button, touch := false) -> void:
	check(b != null,"Input target exists")
	if b == null:return
	var scroll := b.get_parent()
	while scroll and not scroll is ScrollContainer:scroll=scroll.get_parent()
	if scroll:scroll.ensure_control_visible(b)
	await settle()
	var pos := b.get_global_rect().get_center()
	if touch:
		for pressed in [true,false]:
			var e := InputEventScreenTouch.new()
			e.position=pos;e.index=0;e.pressed=pressed
			Input.parse_input_event(e)
			await process_frame
	else:
		var motion := InputEventMouseMotion.new();motion.position=pos
		Input.parse_input_event(motion)
		for pressed in [true,false]:
			var e := InputEventMouseButton.new()
			e.position=pos;e.button_index=MOUSE_BUTTON_LEFT;e.pressed=pressed
			Input.parse_input_event(e)
			await process_frame
	await settle()

func _run() -> void:
	# Inspect the actual stock/drop resource icons, not just a disconnected atlas.
	for folder in ["res://data/items/","res://data/gear/"]:
		for file in DirAccess.get_files_at(folder):
			if not file.ends_with(".tres"):continue
			var item = load(folder+file)
			check(item.icon != null,"Icon present: "+file)
			if item.icon:check(item.icon.get_size()==Vector2(64,64),"Native 64px: "+file)
	for viewport in [Vector2i(1280,720),Vector2i(1278,590)]:
		root.size=viewport
		var tag := "desk" if viewport.y==720 else "phone"
		main=load("res://scenes/main.tscn").instantiate()
		main.play_opening=false;main.floor_seed=31
		main.simulate_phone_safe_area=tag=="phone"
		root.add_child(main)
		await create_timer(0.5).timeout
		var ps = main._party_state
		var supplies = ps.supplies
		var ore: SupplyItem=load("res://data/items/copper_ore.tres")
		var ration: SupplyItem=load("res://data/items/ration.tres")
		var draught: SupplyItem=load("res://data/items/restorative_draught.tres")
		supplies.add(ore,1);supplies.gold=0
		main._end_expedition(main.Expedition.Ending.RETURNED)
		await process_frame
		await click(main._results._button,tag=="phone")
		await create_timer(0.2).timeout
		check(main._camp.visible,"Results reaches live camp "+tag)
		var site: Button=main._camp._buttons.smith
		check(site.get_theme_stylebox("focus") != site.get_theme_stylebox("normal"),"Site has distinct focus feedback")
		site.grab_focus()
		await snap(OUT+"camp-"+tag+".png")
		var before_time: int=ps.time_elapsed
		await click(site,tag=="phone")
		check(main._camp.is_open("smith"),"Click/tap site opens smith "+tag)
		check(ps.time_elapsed==before_time,"Browsing camp spends no time")
		var buy: Button=button(main._camp,"Buy")
		check(buy.disabled,"Unfunded purchase disabled")
		check(buy.tooltip_text.contains("Need"),"Unavailable purchase explains why")
		check(buy.get_global_rect().size.y>=44,"Purchase touch height >=44")
		await click(buy,tag=="phone")
		check(supplies.gear.is_empty() and supplies.gold==0,"Unavailable input cannot buy gear")
		await snap(OUT+"smith-unavailable-"+tag+".png")
		supplies.gold=100;main._camp._refresh_activity();await settle()
		await click(button(main._camp,"Buy"),tag=="phone")
		check(supplies.gear.size()==1 and supplies.gold==100-load("res://data/gear/plain_knife.tres").price,"One input buys one knife at its current price")
		await click(main._camp._back,tag=="phone")
		check(main._camp._buttons.smith.has_focus(),"Back restores site focus")
		await click(main._camp._buttons.supplies,tag=="phone")
		await snap(OUT+"merchant-"+tag+".png")
		await click(main._camp._back,tag=="phone")
		# Leave through the real cave/preparation flow before opening Pack.
		await click(main._camp._buttons.cave,tag=="phone")
		await click(button(main._camp,"Head back down"),tag=="phone")
		await click(button(main._preparation,"Enter the cave"),tag=="phone")
		await create_timer(0.2).timeout
		ps.add_member(main._camp_state.candidates[0]);ps.add_member(main._camp_state.candidates[1])
		for hero in ps.members:
			hero.strain=55;hero.hunger=80
			hero.add_injury(load("res://data/injuries/deep_wound.tres"))
		await settle()
		main._set_pack(true);await settle()
		check(main._pack.visible,"Live Pack opens "+tag)
		check(button(main._pack,"Close").has_focus(),"Pack keyboard focus starts on Close")
		await snap(OUT+"pack-"+tag+".png")
		check(main._pack._inventory_scroll.size.y>=100,"Pack inventory has usable scroll height")
		var use: Button=button(main._pack,"Sell it at camp")
		check(use != null and use.disabled,"Treasure shows unavailable-use reason")
		var ration_row: Control
		for row in main._pack._list.get_children():
			for label in row.find_children("*","Label",true,false):
				if label.text.begins_with(ration.display_name):ration_row=row
		var ration_count: int=supplies.count(ration)
		before_time=ps.time_elapsed
		await click(button(ration_row,"Use"),tag=="phone")
		check(supplies.count(ration)==ration_count-1 and ps.time_elapsed>before_time,"Usable item consumes one and advances its time")
		await snap(OUT+"pack-supplies-"+tag+".png")
		button(main._pack,"Close").grab_focus()
		for pressed in [true,false]:
			var accept := InputEventAction.new();accept.action="ui_accept";accept.pressed=pressed
			Input.parse_input_event(accept);await process_frame
		check(not main._pack.visible,"Keyboard activation closes Pack")
		for preset in ["neutral","warm","dim"]:
			for card in main._cards:card._portrait.set_illumination(preset)
			await snap(MARA_OUT+"live-cards-"+preset+"-"+tag+".png")
		# Chest is the live widget, with real mouse/touch event dispatch.
		main._chest.open("Art review chest",{draught:1,ration:1},ps)
		await settle()
		var count: int=supplies.count(draught)
		await click(button(main._chest,draught.display_name),tag=="phone")
		check(supplies.count(draught)==count+1 and not main._chest.contents.has(draught),"Tap transfers an item exactly once")
		await click(main._chest._take_all,tag=="phone")
		check(main._chest.is_empty() and main._chest._take_all.disabled,"Empty chest disables Take all")
		check(main._chest._chest_grid.get_child(0) is Label,"Empty chest displays explicit text")
		await snap(OUT+"chest-empty-"+tag+".png")
		main._chest.visible=false
		main.queue_free();main=null;await settle()
	await _portraits()
	var report := {"godot":"4.7.2","checks":checks,"failures":failures,"captures":captures,"physical_iPhone":false,"input":"mouse on desktop, screen touch on landscape-phone preview","known_shutdown_diagnostic":"SaveGame static script retained after Main is freed; reproduced by unchanged Main + _save_now baseline, independent of the portrait gallery."}
	FileAccess.open(OUT+"godot-validation.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  ")+"\n")
	print("PRIORITY_ART_CHECKS: ",checks," failures: ",failures.size())
	quit(0 if failures.is_empty() else 1)

func _portraits() -> void:
	var layers: PortraitSet=load("res://data/portraits/mara.tres")
	var underlayer: PortraitSet=load("res://art/portraits/mara-neutral-v1/underlayer.tres")
	for viewport in [Vector2i(1280,720),Vector2i(1278,590)]:
		root.size=viewport
		var canvas := Control.new();root.add_child(canvas)
		var back := ColorRect.new();back.color=Color("1b2421");back.size=Vector2(viewport);canvas.add_child(back)
		var views: Array[Control]=[]
		for i in 6:
			var view=load("res://scripts/portrait_view.gd").new()
			view.position=Vector2(30+(i%3)*370,40+(i/3)*300)
			view.size=Vector2(192,192) if i<3 else Vector2(96,96)
			canvas.add_child(view);view.show_portrait(layers);view._blink_timer.stop()
			view.set_illumination(["neutral","warm","dim"][i%3])
			views.append(view)
		await snap(MARA_OUT+"lighting-"+str(viewport.y)+".png")
		for view in views:
			check(view._rig.modulate==Color.WHITE,"Lighting excludes background rig")
			check(view._rig.get_child(0) is TextureRect and view._rig.get_child(0).texture==layers.background,"Background outside lit character")
			check(view._flash.get_parent()==view,"Hurt flash independent of lighting")
			view.set_condition("blood",true);view.set_condition("bandage",true)
			check(view._overlays.blood.visible and view._overlays.bandage.visible,"Conditions survive illumination")
			view.blink();view.talk(0.5)
			view._eye_tween.pause();view._eye_tween.custom_step(0.05)
			view._talk_tween.pause();view._talk_tween.custom_step(0.01)
		check(views[0]._eyes.texture != layers.eyes and views[0]._mouth.texture != layers.mouth,"Blink and talk animate new art")
		await snap(MARA_OUT+"conditions-talk-"+str(viewport.y)+".png")
		for view in views:
			view.show_portrait(layers);view._blink_timer.stop()
			view.set_condition("pallor",true);view.set_illumination("dim")
			check(view._overlays.pallor.visible,"Dim light preserves pallor")
		await snap(MARA_OUT+"pallor-dim-"+str(viewport.y)+".png")
		for view in views:
			view.show_portrait(underlayer);view._blink_timer.stop()
			view.set_illumination(["neutral","warm","dim"][views.find(view)%3])
			check(view.portrait_set.clothing.is_empty(),"Underlayer outfit variant is complete")
		await create_timer(0.6).timeout
		check(views[0]._eyes.texture==underlayer.eyes and views[0]._mouth.texture==underlayer.mouth,"Reconfigure cancels stale animation callbacks")
		await snap(MARA_OUT+"underlayer-"+str(viewport.y)+".png")
		canvas.queue_free();await settle()

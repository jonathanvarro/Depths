extends SceneTree
## #271: live tent input/consequences and shared menu presentation contracts.
const UI := preload("res://scripts/ui_theme.gd")
const SETTINGS := preload("res://scripts/settings.gd")
const SAVE := preload("res://scripts/save_game.gd")
var checks := 0
var failures: Array[String] = []
var output := ""

func _initialize() -> void:
	SAVE.set_path("res://build/tent-brass-check/save.dat")
	Engine.set_meta("depths_settings",SETTINGS.DEFAULTS.duplicate())
	Engine.set_meta("depths_settings_loaded",true)
	UI.install()
	var args := OS.get_cmdline_user_args()
	output = args[0] if not args.is_empty() else "res://build/tent-brass-check"
	DirAccess.make_dir_recursive_absolute(output)
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:failures.append(label);push_error(label)

func settle() -> void:
	for i in 8:await process_frame

func snap(label: String) -> void:
	if DisplayServer.get_name()=="headless":return
	await settle()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(label+".png"))

func press(button: Button, touch: bool) -> void:
	var at := button.get_global_rect().get_center()
	for down in [true,false]:
		if touch:
			var event := InputEventScreenTouch.new()
			event.index=0;event.position=at;event.pressed=down
			root.push_input(event,true)
		else:
			var event := InputEventMouseButton.new()
			event.button_index=MOUSE_BUTTON_LEFT;event.position=at;event.pressed=down
			root.push_input(event,true)
		await process_frame
	if button.has_meta("tent_target"):
		var tent=button.get_parent()
		check(tent._pressed_id==button.get_meta("tent_target"),"press lights the chosen object before acting")
		tent._activate(button.get_meta("tent_target")) # repeat press cannot act twice
		if DisplayServer.get_name()!="headless":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(output.path_join("highlight-"+str(button.get_meta("tent_target"))+".png"))
	await create_timer(.16).timeout
	await settle()

func run() -> void:
	var theme := UI.make()
	for type in ["Button","OptionButton","CheckButton","CheckBox","ItemRow","PrimaryAction"]:
		for state in UI.Brass.STATES:
			var style := theme.get_stylebox(state,type)
			check(style is StyleBoxTexture,"%s/%s uses brass" % [type,state])
			if style is StyleBoxTexture:
				check(style.get_texture_margin(SIDE_LEFT)==12,"fixed corner width")
	check(not theme.get_stylebox("focus","Button").draw_center,"focus preserves the control face")
	var title=load("res://scenes/title.tscn").instantiate()
	root.size=Vector2i(1280,720)
	root.add_child(title)
	await settle()
	check(title._begin.get_meta("reliquary_edge")==UI.Brass.Edge.LEFT,"title controls have a flat left edge")
	await snap("title-1280")
	title.queue_free()
	await create_timer(.2).timeout
	var main=load("res://scenes/main.tscn").instantiate()
	main.play_opening=false;main.floor_seed=23;main.wandering=false
	root.add_child(main)
	await create_timer(.6).timeout
	main._camp.open(main._camp_state,main._party_state)
	for dimensions in [Vector2i(1280,720),Vector2i(1278,590),Vector2i(844,390),Vector2i(667,375)]:
		for text_size in ["Normal","Larger"]:
			root.size=dimensions
			SETTINGS.set_value("text_size",text_size,self)
			main.simulate_phone_safe_area=dimensions.y<720
			main._apply_safe_area()
			main._camp.open_activity("rest")
			await settle()
			main._camp._fit()
			await settle()
			var tent=main._camp._tent_view
			check(is_instance_valid(tent),"tent opens at %s %s" % [dimensions,text_size])
			if not is_instance_valid(tent):continue
			for id in ["rest","store"]:
				var button: Button=tent._buttons[id]
				var rect:=button.get_global_rect()
				check(rect.size.x>=43.5 and rect.size.y>=43.5,"physical %s target is at least 44px" % id)
				check(main._camp._scroll.get_global_rect().grow(1).encloses(rect),"%s remains within the tent" % id)
			check(main._camp._scroll.get_v_scroll_bar().max_value<=main._camp._scroll.size.y+1,"tent requires no scroll")
			check(main._camp._back.get_meta("reliquary_edge")==UI.Brass.Edge.RIGHT,"camp Back has flat right edge")
			await snap("tent-%d-%s" % [dimensions.x,text_size.to_lower()])
	SETTINGS.set_value("text_size","Normal",self)
	root.size=Vector2i(844,390)
	main._apply_safe_area()
	main._camp._fit()
	await settle()
	var hero: Companion=main._party_state.members[0]
	hero.health=2;hero.strain=60;hero.hunger=20
	var day: int=main._camp_state.day
	await press(main._camp._tent_view._buttons.rest,true)
	check(main._camp_state.day==day+1,"touch on cot advances exactly one day")
	check(hero.health==hero.effective_max_health() and hero.strain==0 and hero.hunger==0,"existing rest recovery is preserved")
	await press(main._camp._tent_view._buttons.store,false)
	check(main._camp._stash_view.visible and not main._camp._activity.visible,"mouse on chest opens the real stash")
	main._camp._stash_view.closed.emit()
	await settle()
	check(main._camp._activity.visible and is_instance_valid(main._camp._tent_view),"stash Close returns to the tent")
	await press(main._camp._back,true)
	check(not main._camp._activity.visible,"header Back returns to camp")
	FileAccess.open(output.path_join("validation.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"physical_iPhone":false},"\t"))
	main.queue_free()
	await create_timer(.2).timeout
	print("TENT_BRASS checks=%d failures=%d" % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)

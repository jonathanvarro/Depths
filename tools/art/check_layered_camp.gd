extends SceneTree
## #108: independent sites, persisted presence, local animation and live input.
const CS := preload("res://scripts/camp_state.gd")
const SG := preload("res://scripts/save_game.gd")
const OUT := "res://art/concepts/camp-layered-v3/"
var checks := 0
var failures: Array[String]=[]
var captures: Array[String]=[]

func _initialize() -> void:
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	call_deferred("_run")

func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures.append(label);push_error(label)

func settle() -> void:
	for i in 5:await process_frame

func snap(name: String) -> void:
	await settle();await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(OUT+name+".png")==OK,"Capture "+name)
	captures.append(name)

func mouse(button: Button) -> void:
	var event:=InputEventMouseButton.new();event.position=button.get_global_rect().get_center()
	event.button_index=MOUSE_BUTTON_LEFT;event.pressed=true
	Input.parse_input_event(event);await settle()
	event.pressed=false;Input.parse_input_event(event);await settle()

func touch(button: Button) -> void:
	var event:=InputEventScreenTouch.new();event.index=0;event.position=button.get_global_rect().get_center();event.pressed=true
	Input.parse_input_event(event);await settle()
	event.pressed=false;Input.parse_input_event(event);await settle()

func _run() -> void:
	var legacy=CS.new()
	check(CS.SITE_IDS.all(func(id):return legacy.site_present(id)),"Default and old saves preserve existing services")
	legacy.set_site_present("supplies",false);legacy.set_site_present("smith",false)
	var saved: Dictionary=SG.pack_object(legacy)
	var restored=CS.new();SG.unpack_into(restored,saved)
	check(not restored.site_present("supplies") and not restored.site_present("smith") and restored.site_present("rest"),"Existing save format persists explicit arrival flags")
	check(not restored.site_present("unknown"),"Unknown site cannot be opened")
	for resolution in [Vector2i(1280,720),Vector2i(1278,590),Vector2i(1334,750)]:
		root.size=resolution
		var tag: String="desktop" if resolution.x==1280 else str(resolution.x)
		var main=load("res://scenes/main.tscn").instantiate()
		main.play_opening=false;main.floor_seed=31;main.simulate_phone_safe_area=resolution.x!=1280
		root.add_child(main);await create_timer(.25).timeout
		main._ending=true
		var camp=main._camp_state;var screen=main._camp
		screen.open(camp,main._party_state);await settle()
		var day: int=camp.day;var elapsed: int=main._party_state.time_elapsed
		var oil: float=main._party_state.supplies.oil
		check(screen._canvas.get_child(0).light_mask==2,"Terrain uses artwork light mask "+tag)
		var targets: Array=screen._buttons.values()
		for i in targets.size():
			check(targets[i].get_global_rect().size.y>=44,"Site touch size "+str(i)+tag)
			check(root.get_visible_rect().encloses(targets[i].get_global_rect()),"Site fits safe viewport "+str(i)+tag)
			for j in range(i+1,targets.size()):check(not targets[i].get_global_rect().intersects(targets[j].get_global_rect()),"Independent targets "+str(i)+"/"+str(j)+tag)
		await snap("all-sites-"+tag)
		for id in CS.SITE_IDS:
			await mouse(screen._buttons[id]);check(screen._current==id,"Mouse opens "+id+tag)
			screen._close_activity();await settle()
			await touch(screen._buttons[id]);check(screen._current==id,"Touch opens "+id+tag)
			screen._close_activity();await settle()
			camp.set_site_present(id,false);await settle()
			check(not screen._site_art[id].visible and not screen._buttons[id].visible and screen._buttons[id].disabled,"Missing site has no art/target "+id+tag)
			screen._buttons[id].pressed.emit();check(screen._current=="","Hidden site's action is rejected "+id+tag)
			check(screen._site_art[id].find_children("*","PointLight2D",true,false).all(func(l):return not l.is_visible_in_tree()),"Missing site's lamps disappear "+id+tag)
			camp.set_site_present(id,true);await settle()
		# The story can remove an active service; Back cannot reveal its target.
		screen.open_activity("smith");camp.set_site_present("smith",false);await settle()
		check(screen._current=="" and not screen._activity.visible and not screen._buttons.smith.visible,"Removal closes active service "+tag)
		camp.set_site_present("smith",true)
		for id in CS.SITE_IDS:camp.set_site_present(id,false)
		await settle();await snap("terrain-only-"+tag)
		check(screen._buttons.values().all(func(b):return b.disabled and not b.visible),"Empty landscape has no service hotspots "+tag)
		check(not screen._dressing._warmth.visible and not screen._dressing._figures[0].visible,"Empty landscape has no hearth light or people "+tag)
		# Presentation fixture only. No arrival day or story order is asserted.
		for id in ["rest","fire","cave"]:camp.set_site_present(id,true)
		await snap("partial-fixture-"+tag)
		for id in CS.SITE_IDS:camp.set_site_present(id,true)
		camp.recovering[main._party_state.members[0]]=camp.day+1;screen._update_site_art();await settle()
		check(screen._site_art.treatment.get_node("OccupiedCot").visible,"Recovery overlays registered patient cot "+tag)
		check(screen._site_art.cave.get_node("Notice").visible==camp.contract.has("enemy"),"Contract controls paper notice "+tag)
		await snap("recovery-"+tag)
		camp.recovering.clear();screen._update_site_art()
		var candidates: Array=camp.candidates.duplicate();camp.candidates.clear();screen._update_site_art()
		check(screen._dressing._figures.all(func(s):return not s.visible),"No baked recruits after hiring "+tag)
		camp.candidates.assign(candidates);screen._update_site_art()
		root.content_scale_factor=1.3;await settle();await snap("all-sites-"+tag+"-larger")
		for button in screen._buttons.values():check(root.get_visible_rect().encloses(button.get_global_rect()) and button.get_global_rect().size.y>=44,"Larger safe site "+button.text+tag)
		for button in [screen._save_button,screen._settings_button]:check(root.get_visible_rect().encloses(button.get_global_rect()) and button.get_global_rect().size.y>=43.9,"Larger global control "+button.text+tag)
		screen.open_activity("supplies");await settle();await snap("merchant-"+tag+"-larger")
		check(screen._back.get_global_rect().size.y>=43.9,"Larger Back touch size "+tag)
		screen._close_activity();root.content_scale_factor=1.0;await settle()
		var lantern=screen._site_art.supplies.get_node("Lantern0")
		var fire: AnimatedSprite2D=screen._site_art.fire.get_node("FlameAnchor/Flames")
		var energy: float=lantern.energy;var frame: int=fire.frame
		await create_timer(.42).timeout
		check(not is_equal_approx(energy,lantern.energy) and lantern.energy>=lantern.base_energy*.89 and lantern.energy<=lantern.base_energy*1.11,"Subtle bounded lantern animation "+tag)
		check(fire.is_playing() and frame!=fire.frame,"Hearth flame animation "+tag)
		check(lantern.range_item_cull_mask==2 and screen._buttons.supplies.light_mask==1,"Glows exclude interface "+tag)
		screen.animate_lights=false;await settle()
		energy=lantern.energy;frame=fire.frame
		await create_timer(.2).timeout
		check(energy==lantern.energy and frame==fire.frame and not fire.is_playing(),"Still mode freezes glow/flames "+tag)
		screen.animate_lights=true;await settle()
		screen.visible=false;await settle()
		var phase: float=lantern._elapsed;frame=fire.frame
		await create_timer(.2).timeout
		check(phase==lantern._elapsed and frame==fire.frame,"Hidden camp pauses animation "+tag)
		screen.visible=true;await settle()
		check(camp.day==day and main._party_state.time_elapsed==elapsed and main._party_state.supplies.oil==oil,"Presentation spends no days/time/oil "+tag)
		if resolution.x==1280:
			DirAccess.make_dir_recursive_absolute("res://build/camp-layered/animation")
			for i in 24:
				await create_timer(.08).timeout;await RenderingServer.frame_post_draw
				var image:=root.get_texture().get_image()
				image.resize(640,360,Image.INTERPOLATE_NEAREST)
				image.save_png("res://build/camp-layered/animation/%02d.png"%i)
		main.queue_free();await create_timer(.2).timeout
	FileAccess.open(OUT+"godot-validation.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"captures":captures,"godot":Engine.get_version_info().string,"physical_iPhone":false,"partial_camp":"Explicit presentation fixture only, not a story schedule."},"  ")+"\n")
	print("LAYERED_CAMP: ",checks," failures: ",failures.size()," captures: ",captures.size())
	quit(0 if failures.is_empty() else 1)

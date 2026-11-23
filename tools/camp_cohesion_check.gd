extends SceneTree
## #286/#289: native layout, input, occupancy and sharp inventory currency.
const PREFS := preload("res://scripts/settings.gd")
var main
var output: String
var checks:=0
var failures: Array[String]=[]

func _initialize() -> void:
	output=OS.get_cmdline_user_args()[0] if not OS.get_cmdline_user_args().is_empty() else "res://build/camp-cohesion-check"
	DirAccess.make_dir_recursive_absolute(output)
	PREFS.set_value("flashes",false)
	call_deferred("run")

func check(label: String, ok: bool) -> void:
	checks+=1
	print("PASS " if ok else "FAIL ",label)
	if not ok:failures.append(label)

func settle() -> void:
	for i in 10:await process_frame

func snap(label: String) -> void:
	await settle()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(label+".png"))

func press(button: Button,touch: bool) -> void:
	var at:=button.get_global_rect().get_center()
	for down in [true,false]:
		if touch:
			var event:=InputEventScreenTouch.new();event.index=0;event.position=at;event.pressed=down
			root.push_input(event,true)
		else:
			var event:=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.position=at;event.pressed=down
			root.push_input(event,true)
		await process_frame
	await settle()

func run() -> void:
	main=load("res://scenes/main.tscn").instantiate()
	main.play_opening=false;main.floor_seed=11;main.wandering=false
	root.add_child(main)
	await create_timer(.6).timeout
	var camp=main._camp_state
	var party=main._party_state
	main._camp_loop()
	await settle()
	var screen=main._camp
	var flames: AnimatedSprite2D=screen._site_art.fire.get_node("FlameAnchor/Flames")
	check("effects off holds camp flame",not screen.animate_lights and not flames.is_playing() and flames.frame==0)
	PREFS.set_value("flashes",true);main._settings.closed.emit();await settle()
	check("settings return resumes camp flame",screen.animate_lights and flames.is_playing())
	PREFS.set_value("flashes",false);main._settings.closed.emit();await settle()
	check("settings return freezes camp flame",not flames.is_playing() and flames.frame==0)
	check("tent and fire use cohesive siblings",screen._site_art.rest.scene_file_path.contains("cohesive-v5") and screen._site_art.fire.scene_file_path.contains("cohesive-v5"))
	check("no floating meal overlay",screen._dressing.find_child("meal",true,false)==null)
	var base: Sprite2D=screen._site_art.fire.get_node("Base")
	var flame: Node2D=screen._site_art.fire.get_node("FlameAnchor")
	var coal_centre: Vector2=base.position+base.texture.get_size()*base.scale*Vector2(.50,.75)
	check("flame meets the actual imported hearth",coal_centre.distance_to(flame.position)<3)
	var tent_base: Sprite2D=screen._site_art.rest.get_node("Base")
	var tent_extent:=tent_base.texture.get_size()*tent_base.scale
	check("tent keeps its full footprint after texture limiting",tent_extent.x>190 and tent_extent.y>105 and tent_extent.y<112)
	var candidates: Array=camp.candidates.duplicate()
	for count in [0,1,3]:
		camp.candidates.clear()
		for i in mini(count,candidates.size()):camp.candidates.append(candidates[i])
		screen._update_site_art()
		check("occupants follow candidates "+str(count),screen._dressing._figures.filter(func(s):return s.visible).size()==mini(count,2))
		await snap("camp-candidates-"+str(count))
	camp.candidates.assign(candidates)
	camp.begin_arrivals();screen._update_site_art()
	check("unearned services remain hidden",not screen._buttons.supplies.visible and not screen._buttons.treatment.visible and not screen._buttons.smith.visible)
	for dimensions in [Vector2i(1280,720),Vector2i(1278,590),Vector2i(844,390),Vector2i(667,375)]:
		for text_size in ["Normal","Larger"]:
			root.size=dimensions
			PREFS.set_value("text_size",text_size,self)
			main.simulate_phone_safe_area=dimensions.y<720
			main._apply_safe_area();screen._fit()
			await settle()
			var a: Rect2=main._pack_button.get_global_rect()
			var b: Rect2=screen._pack_button.get_global_rect()
			check("same Pack position %s %s"%[dimensions,text_size],a.position.distance_to(b.position)<1.0)
			check("same Pack size %s %s"%[dimensions,text_size],a.size.distance_to(b.size)<1.0)
			check("Pack physical touch target %s %s"%[dimensions,text_size],b.size.x>=44 and b.size.y>=44)
			check("Pack clears day/gold %s %s"%[dimensions,text_size],not b.intersects(screen._day_label.get_global_rect()))
			await snap("camp-%d-%s"%[dimensions.x,text_size.to_lower()])
			await press(screen._pack_button,dimensions.y<720)
			check("Pack responds to actual pointer %s %s"%[dimensions,text_size],main._pack.visible)
			main._set_pack(false)
	PREFS.set_value("text_size","Normal",self)
	root.size=Vector2i(1278,590);main._apply_safe_area();screen._fit();await settle()
	party.supplies.gold=10;camp.stash.gold=23
	screen.open_activity("rest")
	await settle()
	check("approved tent interior remains",is_instance_valid(screen._tent_view))
	screen._open_stash()
	await settle()
	var stash=screen._stash_view
	var coin: Texture2D=load("res://art/items/currency-v2/gold.png")
	check("large currency picture is sharp and transparent",coin.get_width()>=512 and coin.get_image().get_pixel(0,0).a==0)
	check("both stash pictures use new coin",stash._left_entries[0].icon==coin and stash._bag_entries[0].icon==coin)
	check("counts remain authoritative",stash._left_entries[0].count==23 and stash._bag_entries[0].count==10)
	await snap("gold-in-stash-phone")
	stash._move({"key":"stash_gold"},"left")
	check("take gold preserves economy",party.supplies.gold==33 and camp.stash.gold==0)
	stash._move({"key":"pack_gold"},"right")
	check("store gold preserves economy",party.supplies.gold==0 and camp.stash.gold==33)
	main.queue_free();await create_timer(.2).timeout
	FileAccess.open(output.path_join("validation.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"physical_iPhone":false},"  "))
	print("CAMP_COHESION checks=",checks," failures=",failures.size())
	quit(0 if failures.is_empty() else 1)

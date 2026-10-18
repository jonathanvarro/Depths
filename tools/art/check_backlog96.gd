extends SceneTree
## Real resource, state and renderer checks for #96; outputs stay with the art.
const OUT := "res://art/concepts/backlog96-v1/"
const CS := preload("res://scripts/combat_state.gd")
const Supplies := preload("res://scripts/supplies.gd")
const Glyphs := preload("res://art/ui/backlog96-v1/glyphs.gd")
var checks := 0
var failures: Array[String] = []
var captures: Array[String] = []

func _initialize() -> void:
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	call_deferred("_run")

func check(ok: bool, label: String) -> void:
	checks+=1
	if not ok:failures.append(label);push_error(label)

func settle() -> void:
	for i in 5:await process_frame

func snap(name: String) -> void:
	await settle();await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(OUT+name+".png")==OK,"Capture "+name)
	captures.append(name)

func make_main(phone: bool):
	var main=load("res://scenes/main.tscn").instantiate()
	main.play_opening=false;main.use_debug_layout=true;main.floor_seed=31
	main.environment_theme=load("res://themes/cave.tres")
	main.simulate_phone_safe_area=phone
	root.add_child(main);await create_timer(0.25).timeout
	main._party.place(main._map,Vector2i(7,1))
	return main

func _run() -> void:
	var catalog: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://art/props/cave-events-v1/catalog.json"))
	check(Glyphs.INTENT.size()==CS.INTENT_TEXT.size(),"All current intentions have art")
	for group in ["status","intent","map"]:
		for file in DirAccess.get_files_at("res://art/ui/backlog96-v1/"+group):
			if not file.ends_with(".png"):continue
			var texture: Texture2D=load("res://art/ui/backlog96-v1/"+group+"/"+file)
			check(texture.get_size()==Vector2(32,32),"Native 32px glyph "+file)
	for event_name in catalog.events:
		var event: RoomEvent=load("res://data/events/"+event_name+".tres")
		check(event.prop != null,"Event has art: "+event_name)
		if event.prop:
			var prop=event.prop.instantiate();root.add_child(prop)
			check(prop is Node3D,"Prop has world floor origin: "+event_name)
			if "state" in prop:
				prop.state="empty";await settle()
				if prop.has_node("Pack"):check(prop.get_node("Pack/Sprite").animation==&"searched","Resolved pack changes drawing")
				else:check(prop.get_node("Sprite").texture==prop.empty_texture,"Resolved cairn shows open empty bundle")
			prop.queue_free();await process_frame
	for name in ["starved_rat","small_spider"]:
		var type: EnemyType=load("res://data/enemies/"+name+".tres")
		var enemy=type.scene.instantiate();root.add_child(enemy)
		var sprite: AnimatedSprite3D=enemy.get_node("Sprite")
		for pose in ["idle","attack","hurt"]:
			check(sprite.sprite_frames.has_animation(pose),name+" pose "+pose)
			var texture: Texture2D=sprite.sprite_frames.get_frame_texture(pose,0)
			check(texture.get_size()==Vector2(128,128),name+" 128px "+pose)
		check(is_equal_approx(sprite.position.y/sprite.pixel_size,56.0),name+" shared floor pivot")
		enemy.queue_free();await process_frame
	for phone in [false,true]:
		root.size=Vector2i(1278,590) if phone else Vector2i(1280,720)
		var tag := "phone" if phone else "desktop"
		var main=await make_main(phone)
		var foreground := CanvasLayer.new();main.add_child(foreground)
		var lantern=load("res://art/props/lantern-v1/held.tscn").instantiate()
		lantern.position=Vector2(root.size.x-540,root.size.y-280)
		foreground.add_child(lantern)
		var supplies=main._party_state.supplies
		supplies.has_lantern=true;supplies.source=Supplies.Source.LANTERN
		var before_time: int=main._party_state.time_elapsed
		for value in [100.0,25.0,5.0,0.0]:
			supplies.oil=value;lantern.apply_supplies(supplies)
			var expected: String="steady" if value==100 else ("dim" if value==25 else ("nearly-out" if value==5 else "unlit"))
			check(lantern.state==expected,"Lantern uses real oil: "+expected)
			check(main._party_state.time_elapsed==before_time and supplies.oil==value,"Presentation spends no time/oil")
			await snap("lantern-"+expected+"-"+tag)
		supplies.source=Supplies.Source.TORCH;lantern.apply_supplies(supplies)
		check(not lantern.visible,"Torch source hides held lantern")
		supplies.source=Supplies.Source.LANTERN;supplies.oil=100;lantern.apply_supplies(supplies)
		var frame: int=lantern.get_node("FlameAnchor/Flames").frame
		await create_timer(0.2).timeout
		check(lantern.get_node("FlameAnchor/Flames").frame != frame,"Shared flame animation advances")
		foreground.queue_free();await settle()
		# Same environment/camera and light, a single scene swapped at a fixed floor origin.
		for id in ["goblin-stash","old-workings","idol-niche","dry-alcove","tripwire","hollow-floor","daylight-exit"]:
			var path: String="res://art/features/daylight-exit-v1/scene.tscn" if id=="daylight-exit" else catalog.props[id].scene
			var prop: Node3D=load(path).instantiate()
			var forward: Vector3=-main._party.camera.global_transform.basis.z
			forward.y=0
			prop.position=main._party.position+forward.normalized()*2.0
			main._level.add_child(prop)
			await snap("prop-"+id+"-"+tag)
			if "state" in prop:
				prop.state="empty";await snap("prop-"+id+"-empty-"+tag)
			prop.queue_free();await settle()
		# The current #95 trait alone controls whether traps are revealed.
		for cell in main._map.events:
			if main._map.events[cell].kind==3:check(main._props.has(cell)==main._party_state.has_trait("keen_eyes"),"Trap visibility follows actual party trait")
		var held_trait_id: String=main._party_state.members[0].trait_id
		main._party_state.members[0].trait_id="";main._build_level();await settle()
		for cell in main._map.events:
			if main._map.events[cell].kind==3:check(not main._props.has(cell),"No detection trait leaves trap hidden")
		main._party_state.members[0].trait_id=held_trait_id;main._build_level();await settle()
		main._camp.open(main._camp_state,main._party_state)
		check(main._camp._site_art.cave.get_node("Base").texture.resource_path.contains("contract-notice"),"Posted contract follows camp state")
		await snap("camp-notice-"+tag)
		var hero: Companion=main._party_state.members[0]
		main._camp_state.recovering[hero]=main._camp_state.day+2
		main._camp._update_site_art()
		check(main._camp._site_art.treatment.get_node("Base").texture.resource_path.contains("nurse-occupied"),"Recovering patient occupies cot")
		await snap("camp-occupied-"+tag)
		if phone:
			root.content_scale_factor=1.3;await settle();main._camp._fit()
			await snap("camp-occupied-phone-larger")
			root.content_scale_factor=1.0;await settle()
		main._camp_state.recovering.clear();main._camp_state.queen_defeated=true;main._camp._update_site_art()
		check(main._camp._site_art.treatment.get_node("Base").texture.resource_path.ends_with("/treatment.png"),"Empty cot restored")
		check(main._camp._site_art.cave.get_node("Base").texture.resource_path.ends_with("/cave.png"),"Completed contract notice removed")
		main.queue_free();await settle()
		for enemy_name in ["starved_rat","small_spider","goblin"]:
			main=await make_main(phone)
			main._party_state.members[0].initiative=100
			var types: Array[EnemyType]=[load("res://data/enemies/"+enemy_name+".tres")]
			var state=CS.new(main._party_state,types)
			if enemy_name=="goblin":state.foes[0].intent=CS.Intent.HEAVY
			main._place_foes(state.foes);main._in_combat=true;main._party.locked=true;main._touch_pad.visible=false
			main._combat.run(state,main._cards);await create_timer(0.15).timeout
			var target: Button=main._combat._tags[state.foes[0]]
			check(target.icon==Glyphs.intention(state.foes[0].intent),"Actual combat tag uses intention glyph")
			check(target.text.contains(CS.intent_text(state.foes[0])),"Intention text remains")
			await snap("combat-"+enemy_name+"-"+tag)
			if phone and enemy_name=="goblin":
				root.content_scale_factor=1.3;await snap("combat-heavy-phone-larger")
				root.content_scale_factor=1.0;await settle()
			if enemy_name!="goblin":
				var sprite: AnimatedSprite3D=state.foes[0].node.get_node("Sprite")
				for pose in ["attack","hurt"]:
					sprite.play(pose);await snap("combat-"+enemy_name+"-"+pose+"-"+tag)
			main.queue_free();await settle()
		await _cards(tag)
		await _coin(tag)
	var report := {"godot":"4.7.2","checks":checks,"failures":failures,"captures":captures,"physical_iPhone":false,"world_prop_captures":"Fixed camera floor previews; trap assets shown only in isolated review."}
	FileAccess.open(OUT+"godot-validation.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  ")+"\n")
	print("BACKLOG96_CHECKS: ",checks," failures: ",failures.size()," captures: ",captures.size())
	quit(0 if failures.is_empty() else 1)

func _cards(tag: String) -> void:
	var canvas := CanvasLayer.new();root.add_child(canvas)
	var background := ColorRect.new();background.color=Color("1b2420");background.size=Vector2(root.size);canvas.add_child(background)
	for i in 3:
		var hero: Companion=load("res://data/companions/mara.tres").duplicate(true)
		hero.display_name=["Bleeding","Wounded","Unconscious"][i]
		hero.health=0 if i==2 else 3;hero.main_hero=true;hero.bleeding=i==0
		if i<2:
			hero.add_injury(load("res://data/injuries/deep_wound.tres"));hero.add_injury(load("res://data/injuries/limp.tres"))
			hero.add_effect_over_time("health",4,20)
			if i==1:hero.dress_injury()
		var card=load("res://scripts/party_card.gd").new();card.position=Vector2(150+i*310,150);card.custom_minimum_size=Vector2(220,180)
		canvas.add_child(card);card.show_companion(hero);await settle()
		for icon in card._icons.get_children():check(icon is TextureRect and icon.texture != null,"Actual party card uses status artwork")
	await snap("status-cards-"+tag);canvas.queue_free();await settle()

func _coin(tag: String) -> void:
	var coin=load("res://scripts/coin_flip.gd").new();root.add_child(coin)
	for chance in [1.0,0.0]:
		coin.flip("A dangerous chance","Safe passage","A painful price",chance)
		await settle();coin._flip.pressed.emit();await create_timer(2.8).timeout
		check(coin._done.visible and coin._face_heads==(chance==1.0),"Authored coin follows actual outcome")
		await snap("coin-"+("heads" if chance==1 else "tails")+"-"+tag)
		coin._done.pressed.emit();await settle()
	coin.queue_free();await settle()

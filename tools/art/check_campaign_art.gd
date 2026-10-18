extends SceneTree
## Actual asset consumers, discovery safety and phone presentation checks.
const OUT := "res://art/concepts/campaign-v1/"
const CS := preload("res://scripts/combat_state.gd")
const DM := preload("res://scripts/dungeon_map.gd")
const MAP := preload("res://scripts/minimap.gd")
const PV := preload("res://scripts/portrait_view.gd")
const SUP := preload("res://scripts/supplies.gd")
var checks := 0
var failures: Array[String]=[]
var captures: Array[String]=[]

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
func main_scene(phone: bool):
	var main=load("res://scenes/main.tscn").instantiate()
	main.play_opening=false;main.use_debug_layout=true;main.floor_seed=31;main.simulate_phone_safe_area=phone
	main.environment_theme=load("res://themes/cave.tres")
	root.add_child(main);await create_timer(.25).timeout
	main._party.place(main._map,Vector2i(7,1))
	return main

func _run() -> void:
	for name in ["corin","alwen"]:
		var hero: Companion=load("res://data/companions/"+name+".tres")
		check(hero.portrait_set.resource_path=="res://data/portraits/"+name+".tres",name+" live portrait resource")
		var set: PortraitSet=hero.portrait_set
		check(set.blink_frames.size()==2 and set.talk_frames.size()==3,name+" complete facial animation")
		for texture in [set.body,set.head,set.eyes,set.mouth,set.light_shadow,set.light_highlight]+set.blink_frames+set.talk_frames+set.conditions.values():
			check(texture!=null and texture.get_size()==Vector2(192,192),name+" full canvas layer")
	for name in ["rush","recover","beat","webbed","venom","guard","drummed","armour","miss","heart","nerves","rest"]:
		var texture: Texture2D=load("res://art/ui/visual105-v1/"+name+".png")
		check(texture.get_size()==Vector2(32,32),"Live glyph "+name)
	for id in ["broken_short_sword","cracked_staff","padded_coat","leather_jerkin"]:
		var gear: Equipment=load("res://data/gear/"+id+".tres")
		check(gear.icon!=null and gear.icon.get_size()==Vector2(64,64),"Live equipment icon "+id)
	for id in ["goblin_queen","goblin_archer","goblin_guard","great_rat","webspinner","goblin_drummer"]:
		var type: EnemyType=load("res://data/enemies/"+id+".tres")
		check(type.scene.resource_path.contains("campaign-v1"),"Live enemy art "+id)
		check(type.tint==Color.WHITE and type.sprite_scale==1.0,"No placeholder tint/scale "+id)
		var node=type.scene.instantiate();root.add_child(node)
		var sprite: AnimatedSprite3D=node.get_node("Sprite")
		for pose in ["idle","attack","hurt"]:
			check(sprite.sprite_frames.has_animation(pose),id+" pose "+pose)
			check(sprite.sprite_frames.get_frame_texture(pose,0).get_size()==Vector2(128,128),id+" native frame "+pose)
		check(is_equal_approx(sprite.position.y/sprite.pixel_size,56),id+" ground pivot")
		if id=="goblin_queen":
			node.set_combat_state(true,false);check(sprite.sprite_frames==node.enraged_frames,"Queen changes phase frames")
			sprite.play("hurt");node.set_combat_state(true,false);check(sprite.animation==&"hurt","Phase sync preserves hurt")
			node.set_combat_state(false,false);check(sprite.sprite_frames!=node.enraged_frames,"Queen normal phase restores")
		elif id=="goblin_guard":
			node.set_combat_state(false,true);check(sprite.animation==&"brace","Guard brace pose")
			sprite.play("attack");node.set_combat_state(false,true);check(sprite.animation==&"attack","Brace sync preserves bash")
		elif id=="goblin_archer":check(sprite.sprite_frames.get_frame_count("attack")==2,"Archer draws and releases")
		node.queue_free();await settle()
	await _map_invariants()
	for phone in [false,true]:
		root.size=Vector2i(1278,590) if phone else Vector2i(1280,720)
		var tag: String="phone" if phone else "desktop"
		await _portraits(tag)
		var main=await main_scene(phone)
		var held=main._safe_area.get_node("HeldLight")
		var supplies=main._party_state.supplies
		var before_time: int=main._party_state.time_elapsed
		supplies.source=SUP.Source.LANTERN;supplies.has_lantern=true
		for oil in [100.0,25.0,5.0,0.0]:
			supplies.oil=oil;await settle()
			check(held._lantern.visible and not held._torch.visible,"Actual held lantern source "+str(oil))
			check(supplies.oil==oil and main._party_state.time_elapsed==before_time,"Held art spends no fuel/time")
			await snap("held-lantern-"+str(int(oil))+"-"+tag)
		supplies.source=SUP.Source.TORCH;supplies.torch_left=40;await settle()
		check(held._torch.visible and not held._lantern.visible,"Actual held torch source")
		await snap("held-torch-"+tag)
		main._set_pack(true);await settle();check(not held.visible,"Held light hides in Pack");main._set_pack(false)
		for y in main._map.height:
			for x in main._map.width:main._map.explored[Vector2i(x,y)]=true
		for cell in main._map.events:main._map.discovered[cell]=true
		var first: Vector2i=main._map.events.keys()[0];main._map.triggered[first]=true
		for facing in 4:
			main._full_map_view.on_party_moved(main._party.cell,facing)
			main._set_full_map(true);await snap("map-facing-"+str(facing)+"-"+tag)
		check(not held.visible,"Held light hides on full map")
		check(main._full_map_close.get_global_rect().size.y>=52,"Map close touch size")
		main._full_map_close.pressed.emit();check(not main._full_map.visible and not main._party.locked,"Close map restores movement")
		main._set_full_map(true)
		var escape:=InputEventKey.new();escape.keycode=KEY_ESCAPE;escape.pressed=true;Input.parse_input_event(escape);await settle()
		check(not main._full_map.visible,"Escape closes map")
		await _camp(main,tag,phone)
		main._camp.visible=false;main._ending=false;main._party.locked=false
		main.use_debug_layout=false;main._go_to_floor(3,main.Arrival.FROM_ABOVE);await settle()
		check(main._level.find_children("*watch-post*","Node3D",true,false).size()>0,"Outskirts uses authored props")
		await snap("outskirts-"+tag)
		main._go_to_floor(4,main.Arrival.FROM_ABOVE);await settle()
		check(main._level.find_children("*throne*","Node3D",true,false).size()>0,"Hall has throne")
		check(main.environment_theme.wall_material.resource_path.contains("fortress-v1"),"Actual fortress materials")
		await snap("fortress-entry-"+tag)
		_place_review_camera(main)
		main._message_label.modulate.a=0.0
		for id in ["goblin_queen","goblin_archer","goblin_guard","great_rat","webspinner","goblin_drummer"]:
			var types: Array[EnemyType]=[load("res://data/enemies/"+id+".tres")]
			var state=CS.new(main._party_state,types)
			main._place_foes(state.foes);main._in_combat=true;main._party.locked=true;main._touch_pad.visible=false
			main._party_state.members[0].initiative=100
			main._combat.run(state,main._cards);await create_timer(.1).timeout
			await snap("combat-"+id+"-"+tag)
			if id=="goblin_queen":
				state.foes[0].enraged=true;await settle()
				check(state.foes[0].node.get_node("Sprite").sprite_frames==state.foes[0].node.enraged_frames,"Actual combat drives queen phase")
				await snap("combat-queen-enraged-"+tag)
			elif id=="goblin_guard":
				state.foes[0].shielded=true;await settle()
				check(state.foes[0].node.get_node("Sprite").animation==&"brace","Actual combat drives guard pose")
			main._combat.visible=false;main._in_combat=false
			state.foes[0].node.queue_free();main._combat._state=null;await settle()
		main._results.show_brief("The goblin queen is dead","The fortress is broken. The drums fall silent.","Continue",load("res://art/illustrations/fortress-v1/victory.png"))
		await snap("victory-"+tag)
		check(root.get_visible_rect().encloses(main._results._button.get_global_rect()),"Victory action fits "+tag)
		main.queue_free();await settle()
		var choice=load("res://scripts/hero_select.gd").new();choice.simulate_phone_safe_area=phone;root.add_child(choice);choice.open();await snap("hero-choice-"+tag)
		for button in choice.find_children("*","Button",true,false):
			if button.text.begins_with("Wake as"):check(root.get_visible_rect().encloses(button.get_global_rect()),"Hero choice action fits "+tag)
		if phone:
			root.content_scale_factor=1.3;await snap("hero-choice-phone-larger")
			for button in choice.find_children("*","Button",true,false):
				if button.text.begins_with("Wake as"):check(root.get_visible_rect().encloses(button.get_global_rect()),"Hero choice action fits Larger")
			root.content_scale_factor=1.0
		choice.queue_free();await settle()
	FileAccess.open(OUT+"godot-validation.json",FileAccess.WRITE).store_string(JSON.stringify({"godot":"4.7.2","checks":checks,"failures":failures,"captures":captures,"physical_iPhone":false,"audio_listening":false},"  ")+"\n")
	print("CAMPAIGN_ART_CHECKS: ",checks," failures: ",failures.size()," captures: ",captures.size())
	quit(0 if failures.is_empty() else 1)

## A room with space for both visual rows; an entrance corridor hides the back.
func _place_review_camera(main) -> void:
	for y in range(1,main._map.height-1):
		for x in range(1,main._map.width-1):
			var cell:=Vector2i(x,y)
			if not main._map._is_room_cell(cell) or main._map.content_at(cell)!=0:continue
			for direction in 4:
				var forward: Vector2i=main.Party.DIRECTIONS[direction]
				if main._map.is_passable(cell+forward) and main._map.is_passable(cell+forward*2):
					main._party.place(main._map,cell)
					main._party.facing=direction;main._party.rotation.y=-direction*PI/2.0
					return

func _portraits(tag: String) -> void:
	var canvas:=CanvasLayer.new();root.add_child(canvas)
	var views: Array=[]
	for row in 2:
		var name: String=["corin","alwen"][row]
		for column in 3:
			var view=PV.new();view.position=Vector2(250+column*235,40+row*245);view.size=Vector2(192,192)
			canvas.add_child(view);view.show_portrait(load("res://data/portraits/"+name+".tres"),null)
			view.set_illumination(["neutral","warm","dim"][column]);views.append(view)
	await snap("portrait-lighting-"+tag)
	var first=views[0];first.blink();first.talk(.45)
	first._eye_tween.pause();first._talk_tween.pause()
	first._eye_tween.custom_step(.02);first._talk_tween.custom_step(.02)
	check(first._eyes.texture in first.portrait_set.blink_frames,"Corin blink is consumed")
	check(first._mouth.texture in first.portrait_set.talk_frames,"Corin talk is consumed")
	for i in views.size():views[i].set_condition(["blood","dirt","bandage","pallor"][i%4],true)
	await snap("portrait-conditions-"+tag)
	for view in views:check(view._light_shadow.get_parent()==view._character,"Light excludes portrait background")
	canvas.queue_free();await settle()

func _map_invariants() -> void:
	var rows:=PackedStringArray(["#######","#S..###","###.###","###..>#","#######"])
	var a=DM.new(rows);a.explored={Vector2i(1,1):true,Vector2i(2,1):true,Vector2i(1,0):true,Vector2i(2,0):true}
	var b=DM.new(PackedStringArray(["#######","#S..#.#","#.#...#","#..C..#","#######"]))
	b.explored=a.explored.duplicate()
	var first=MAP.new();first.setup(a);first._cache_geometry()
	var second=MAP.new();second.setup(b);second.full_view=true;second._cache_geometry()
	check(first._known_floor.size()==2,"Only explored floors become ink")
	check(first._edges.size()==6,"Joined floors have no shared grid edge")
	check(first._edges==second._edges,"Unknown layout/content changes reveal no geometry")
	check(first._notes().is_empty() and second._notes().is_empty(),"Unknown discoveries do not become notes")
	var geometry: Array=first._edges.duplicate(true)
	first.on_party_moved(Vector2i(2,1),3);first._cache_geometry();check(first._edges==geometry,"Turning does not randomize ink")
	check(MAP.marker_for(2,false)!=MAP.marker_for(2,true),"Searched chest has distinct mark")
	check(MAP.GLYPHS.closed!=MAP.GLYPHS.blocked,"Closed and blocked have distinct shapes")
	first.free();second.free()

func _camp(main,tag: String,phone: bool) -> void:
	main._ending=true;main._camp.open(main._camp_state,main._party_state);await settle()
	check(not main._safe_area.get_node("HeldLight").visible,"Held light hides at camp")
	check(main._camp._dressing._figures[0].visible,"Real waiting recruits give presence")
	await snap("camp-after-"+tag)
	var targets: Array=main._camp._buttons.values()
	for i in targets.size():
		check(targets[i].get_global_rect().size.y>=44,"Camp touch target "+str(i))
		for j in range(i+1,targets.size()):check(not targets[i].get_global_rect().intersects(targets[j].get_global_rect()),"Camp targets remain separate")
	var warmth=main._camp._dressing.get_node("FireWarmth")
	check(warmth.range_item_cull_mask==2 and main._camp._buttons.fire.light_mask==1,"Camp warmth excludes controls")
	var pointer:=InputEventMouseButton.new();pointer.button_index=MOUSE_BUTTON_LEFT;pointer.pressed=true;pointer.position=main._camp._buttons.supplies.get_global_rect().get_center()
	Input.parse_input_event(pointer);await settle();pointer.pressed=false;Input.parse_input_event(pointer);await settle()
	check(main._camp._current=="supplies","Dressing preserves real mouse camp selection")
	main._camp._close_activity();await settle()
	var touch:=InputEventScreenTouch.new();touch.index=0;touch.pressed=true;touch.position=main._camp._buttons.fire.get_global_rect().get_center()
	Input.parse_input_event(touch);await settle();touch.pressed=false;Input.parse_input_event(touch);await settle()
	check(main._camp._current=="fire","Dressing preserves real touch camp selection")
	main._camp._close_activity();await settle()
	var candidates: Array=main._camp_state.candidates.duplicate();main._camp_state.candidates.clear();main._camp._update_site_art()
	check(not main._camp._dressing._figures[0].visible and not main._camp._dressing._figures[1].visible,"No fake recruits when fire is empty")
	main._camp_state.candidates.assign(candidates);main._camp._update_site_art()
	main._camp_state.recovering[main._party_state.members[0]]=main._camp_state.day+1;main._camp._update_site_art()
	await snap("camp-after-recovery-"+tag)
	if phone:
		root.content_scale_factor=1.3;await snap("camp-after-phone-larger");root.content_scale_factor=1.0;await settle()

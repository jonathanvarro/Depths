extends "res://tools/art/check_monster_art.gd"
## Reuse the existing isolated BattleStage/CombatScreen fixture, never Main.
const ELF_OUT := "res://art/concepts/elves-v1/"
const PORTRAIT := preload("res://scripts/portrait_view.gd")
func snap(name: String) -> void:
	if label:label.text=name+" / art fixture only"
	await settle();await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(ELF_OUT+name+".png")==OK,"Captured "+name)
	captures.append(name+".png")
func _run() -> void:
	for pixels in [192,96]:
		root.size=Vector2i(1152,432) if pixels==192 else Vector2i(1278,590)
		var controls: Array=[]
		for row in 2:
			var id: String=["elf-man","elf-woman"][row]
			var rig: PortraitSet=load("res://data/portraits/elves-v1/"+id+".tres")
			check(rig.rig_kind=="Unique" and rig.face_id==StringName(id),"Unique fitted head "+id)
			check(rig.blink_frames.size()==2 and rig.talk_frames.size()==3,"Complete facial drawings "+id)
			for col in 6:
				var view=PORTRAIT.new();root.add_child(view);controls.append(view)
				view.position=Vector2(col*pixels,row*(pixels+24)+24);view.size=Vector2(pixels,pixels)
				view.show_portrait(rig);view.set_animated(false)
				if col in [1,2]:view._eyes.texture=rig.blink_frames[col-1]
				if col>=3:view._mouth.texture=rig.talk_frames[col-3]
				var title:=Label.new();root.add_child(title);controls.append(title)
				title.position=view.position-Vector2(0,24);title.add_theme_font_size_override("font_size",12)
				title.text=["Rest","Half","Closed","Small","Open","Round"][col]
		await snap("runtime-held-"+str(pixels))
		for control in controls:control.queue_free()
		await settle()
	root.size=Vector2i(1152,460)
	var views: Array=[]
	for row in 2:
		var rig: PortraitSet=load("res://data/portraits/elves-v1/"+["elf-man","elf-woman"][row]+".tres")
		for col in 3:
			var view=PORTRAIT.new();root.add_child(view);views.append(view)
			view.position=Vector2(170+col*300,row*220+16);view.size=Vector2(192,192)
			view.show_portrait(rig);view.set_illumination(["neutral","warm","dim"][col])
			check(view._light_shadow!=null and view._light_highlight!=null,"Separate runtime light masks")
			view.blink();view.talk(.7)
	await create_timer(.06).timeout;await snap("runtime-lighting")
	await create_timer(.8).timeout
	for view in views:
		check(view._eyes.texture==view.portrait_set.eyes and view._mouth.texture==view.portrait_set.mouth,"Playback returns exactly to rest")
		view.talk(1);view.hide()
		check(view._eyes.texture==view.portrait_set.eyes and view._mouth.texture==view.portrait_set.mouth,"Hidden playback resets coherently")
		view.queue_free()
	await settle()
	world=Node3D.new();root.add_child(world)
	var environment:=Environment.new();environment.background_mode=Environment.BG_COLOR;environment.background_color=Color("12110e")
	environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;environment.ambient_light_color=Color.WHITE;environment.ambient_light_energy=.35
	var env:=WorldEnvironment.new();env.environment=environment;world.add_child(env)
	camera=Camera3D.new();world.add_child(camera);camera.position=Vector3(0,1.2,0);camera.fov=70;camera.current=true
	var light:=OmniLight3D.new();world.add_child(light);light.position=Vector3(-.4,1.8,.2);light.light_color=Color(1,.8,.58);light.light_energy=1.4;light.omni_range=12
	var stage:=STAGE.new();camera.add_child(stage);stage.fit(camera);await stage.enter(false)
	ui=CanvasLayer.new();root.add_child(ui)
	var row:=HBoxContainer.new();ui.add_child(row);row.add_theme_constant_override("separation",10)
	party=PARTY.new()
	for i in 3:
		party.add_member(load("res://data/companions/"+["mara","corin","alwen"][i]+".tres"))
		var hero: Companion=party.members[-1];hero.speed_base=1000;hero.refresh_stats()
		hero.portrait_set=load("res://data/portraits/elves-v1/"+(["elf-man","elf-woman","elf-man"][i])+".tres")
		var card:=CARD.new();row.add_child(card);card.show_companion(hero);cards.append(card)
	label=Label.new();ui.add_child(label);label.position=Vector2(18,52)
	entries["elf-swordswoman"]={"scene":"res://art/enemies/elves-v1/swordswoman/scene.tscn"}
	for phone in [false,true]:
		root.size=Vector2i(1278,590) if phone else Vector2i(1280,720);row.position=Vector2(18,root.size.y-178)
		await fight(["elf-swordswoman"])
		var node: Node3D=state.foes[0].node;var sprite: AnimatedSprite3D=node.get_node("Sprite")
		check(sprite.shaded and sprite.billboard==1 and sprite.texture_filter==0,"World-lit nearest combat art")
		check(is_equal_approx(sprite.position.y,56*sprite.pixel_size),"Native floor pivot 64,120")
		check(node.find_children("*","CollisionObject3D",true,false).is_empty(),"No new collision")
		screen._busy[state.foes[0]]=true
		for pose in ["idle","attack","hurt"]:
			check(sprite.sprite_frames.has_animation(pose),"Imported combat pose "+pose)
			sprite.play(pose);sprite.pause();clear_panel(node)
			await snap("combat-"+pose+("-phone" if phone else "-desktop"))
	if screen:screen.free()
	if actors:actors.free()
	ui.queue_free();world.queue_free();await settle()
	var file:=FileAccess.open(ELF_OUT+"godot-validation.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"issue":131,"checks":checks,"failed":failures.size(),"failures":failures,"captures":captures},"\t"));file.close()
	print("ELVES_GODOT: ",checks," checks, ",failures.size()," failed, ",captures.size()," captures")
	quit(1 if not failures.is_empty() else 0)

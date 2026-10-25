extends "res://tools/art/check_monster_art.gd"
## Isolated real battle UI/actors. Never loads Main, settings or a save.
const REVIEW := "res://art/concepts/combat-fog-v1/"

func snap(name: String) -> void:
	await settle()
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(REVIEW+name+".png")==OK,"Capture "+name)
	captures.append(name+".png")

func _run() -> void:
	preload("res://scripts/ui_theme.gd").install()
	world=Node3D.new();root.add_child(world)
	var environment:=Environment.new()
	environment.background_mode=Environment.BG_COLOR
	environment.background_color=Color("544333")
	environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color=Color.WHITE
	environment.ambient_light_energy=0.45
	var env:=WorldEnvironment.new();env.environment=environment;world.add_child(env)
	camera=Camera3D.new();world.add_child(camera)
	camera.position=Vector3(0,1.2,0);camera.fov=70;camera.current=true
	var light:=OmniLight3D.new();world.add_child(light)
	light.position=Vector3(-0.4,1.8,0.2);light.light_color=Color(1,0.8,0.58)
	light.light_energy=1.4;light.omni_range=12
	var stage:=STAGE.new();camera.add_child(stage);stage.fit(camera)
	ui=CanvasLayer.new();root.add_child(ui)
	var row:=HBoxContainer.new();ui.add_child(row)
	row.add_theme_constant_override("separation",10)
	party=PARTY.new()
	for id in ["mara","corin","alwen"]:
		party.add_member(load("res://data/companions/"+id+".tres"))
		var hero:Companion=party.members[-1]
		hero.speed_base=1000;hero.refresh_stats()
		var card:=CARD.new();row.add_child(card);card.show_companion(hero);cards.append(card)
	for shape in [Vector2i(1280,720),Vector2i(1278,590)]:
		root.size=shape;row.position=Vector2(18,shape.y-178)
		await fight(["goblin_brute","hollow_miner"])
		stage.visible=true;stage.set_process(false)
		for step in [0,3,6,9]:
			stage._material.set_shader_parameter("surge",1.0)
			stage._material.set_shader_parameter("progress",float(step)/9.0)
			await snap("surge-%d-%d"%[shape.x,step])
		await stage.exit()
		check(not stage.visible and not stage.is_processing(),"Exit clears stage and stops motion")
		await stage.enter(true)
		check(stage.is_up() and stage.is_processing(),"Real entry completes with motion")
		await create_timer(0.3).timeout
		check(stage._clock>0.2,"Backdrop advances independently of game time")
		await snap("combat-%d"%shape.x)
		var rendered:=root.get_texture().get_image()
		check(rendered.get_pixel(2,100).get_luminance()<0.12 and rendered.get_pixel(shape.x-3,100).get_luminance()<0.12,"Stage covers both viewport edges after resize")
		for foe in state.foes:
			for sprite:SpriteBase3D in foe.node.find_children("*","SpriteBase3D",true,false):
				check(sprite.render_priority>stage._material.render_priority and sprite.no_depth_test,"Enemy remains above stage")
		await stage.exit()
		await stage.enter(false)
		var phase:float=stage._material.get_shader_parameter("phase")
		await create_timer(0.3).timeout
		check(not stage.is_processing() and stage._material.get_shader_parameter("phase")==phase,"Effects off freezes settled bank")
		check(stage._material.get_shader_parameter("surge")==0.0,"Effects off uses plain fade")
		await snap("still-%d"%shape.x)
		await stage.exit()
	var image:=STAGE.SURGE.get_image()
	check(image.get_size()==Vector2i(1280,540),"Ten-state atlas fits small texture budget")
	for p in [Vector2i(0,0),Vector2i(160,90),Vector2i(319,179)]:
		check(image.get_pixelv(p).a==0.0,"Entry starts clear")
		check(image.get_pixelv(p+Vector2i(320,360)).a==1.0,"Last state covers full stage")
	var file:=FileAccess.open(REVIEW+"validation.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"captures":captures,"physical_phone":false},"\t")+"\n")
	file.close()
	screen.free();ui.free();world.free();state=null;party=null;cards.clear()
	await process_frame
	print("COMBAT_FOG: checks=%d failures=%d"%[checks,failures.size()])
	quit(0 if failures.is_empty() else 1)

extends SceneTree
## Shipping Main integration with a private fixture slot, no owner save/settings.
const SAVE:=preload("res://scripts/save_game.gd")
const OUT:="res://art/concepts/interface/combined-live-v1/"
var checks:=0
var failures:Array[String]=[]
var captures:Array[String]=[]

func _initialize() -> void:
	SAVE.set_path("res://build/kit-review/main-save.dat")
	SAVE.set_continue_requested(false)
	Engine.set_meta("depths_settings",preload("res://scripts/settings.gd").DEFAULTS.duplicate())
	Engine.set_meta("depths_settings_loaded",true)
	call_deferred("run")

func check(ok:bool,label:String) -> void:
	checks+=1
	if not ok:failures.append(label);push_error(label)

func settle() -> void:
	for i in 10:await process_frame

func snap(name:String) -> void:
	await settle();await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(OUT+name+".png")==OK,"Capture "+name)
	captures.append(name+".png")

func run() -> void:
	for shape in [Vector2i(1280,720),Vector2i(1278,590)]:
		root.size=shape
		var main=load("res://scenes/main.tscn").instantiate()
		main.play_opening=false;main.floor_seed=11;main.use_debug_layout=true
		main.simulate_phone_safe_area=shape.y==590
		root.add_child(main);await create_timer(0.5).timeout
		var ps=main._party_state
		ps.supplies.gold=39;ps.supplies.oil=30
		var oil:SupplyItem=load("res://data/items/oil_flask.tres")
		ps.supplies.add(oil,2)
		ps.supplies.gear.append(load("res://data/gear/simple_spear.tres"))
		main._set_pack(true);await settle()
		check(main._pack.visible and main._party.locked,"Main opens and locks movement")
		check(main._pack._hero_row.get_child_count()==ps.members.size(),"Only real party portraits are shown")
		for scale_factor in [1.0,1.3]:
			root.content_scale_factor=scale_factor;main._apply_safe_area();main._pack.refresh();await settle()
			var tag:="main-%d-%s"%[shape.x,"larger" if scale_factor>1 else "normal"]
			for b:Button in main._pack.find_children("*","Button",true,false):
				if not b.is_visible_in_tree() or b.disabled:continue
				check(main._safe_area.get_global_rect().encloses(b.get_global_rect()),"Main safe-area target "+tag)
			await snap(tag)
		main._pack.inspect_item(oil);await settle()
		var before_time:int=ps.time_elapsed
		var before_count:int=ps.supplies.count(oil)
		for action in main._pack._detail_actions.get_children():
			if action.get_meta("kit_focus","")=="action:use":action.pressed.emit();break
		await settle()
		check(ps.time_elapsed==before_time+oil.use_time and ps.supplies.count(oil)==before_count-1 and ps.supplies.oil>30,"Shipping Pack uses actual supply rules")
		main._pack._close.pressed.emit();await settle()
		check(not main._pack.visible and not main._party.locked,"Close returns to exploration")
		main.queue_free();await settle();ps=null;main=null;root.content_scale_factor=1.0
	# Let the game's already-running dialogue/tip timers release captured
	# resources after Main is freed, rather than counting them as shutdown leaks.
	await create_timer(7.0).timeout
	var file:=FileAccess.open(OUT+"main-validation.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"captures":captures,"physical_iPhone":false,"fixture_save":"res://build/kit-review/main-save.dat","shutdown_note":"Main teardown reports CanvasItem/ObjectDB/resource leaks; isolated Pack and fog fixtures finish cleanly. Behaviour assertions are separate from teardown."},"\t")+"\n");file.close()
	print("COMBINED_MAIN: checks=%d failures=%d"%[checks,failures.size()])
	quit(0 if failures.is_empty() else 1)

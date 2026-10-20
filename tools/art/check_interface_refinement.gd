extends SceneTree
## #112: focused checks/captures of shipping Pack and Preparation, not the browser study.
const OUT="res://art/concepts/interface/live-refinement-v1/"
var checks:=0
var failures:Array[String]=[]

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	call_deferred("_run")

func check(ok:bool,label:String) -> void:
	checks+=1
	if not ok:failures.append(label);push_error(label)

func settle() -> void:
	for i in 8:await process_frame

func snap(label:String) -> void:
	await settle();await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(OUT+label+".png")==OK,"Capture "+label)

func _run() -> void:
	var settings=load("res://scripts/settings.gd")
	for shape in [Vector2i(1280,720),Vector2i(1278,590)]:
		root.size=shape
		for size_name in ["Normal","Larger"]:
			settings.set_value("text_size",size_name,self)
			var main=load("res://scenes/main.tscn").instantiate();main.play_opening=false;main.floor_seed=11;main.simulate_phone_safe_area=shape.y==590;root.add_child(main);await settle()
			var party=main._party_state
			party.supplies.gold=84
			party.supplies.gear.append(load("res://data/gear/plain_knife.tres"))
			main._set_pack(true);await settle()
			var pack=main._pack
			check(pack._time_label.text=="84","Amount without repeated currency prose")
			check(not pack._light_note.visible and pack._lantern_label.text.contains("oil"),"Fuel remains visible, secondary help omitted")
			var controls=pack.find_children("*","Button",true,false)
			check(controls.any(func(b):return b.accessibility_name=="Settings" and b.icon!=null),"Named settings icon")
			check(controls.any(func(b):return b.accessibility_name=="Close pack" and b.icon!=null),"Named close icon")
			for button in controls:
				if button.accessibility_name not in ["Settings","Close pack"]:continue
				var rect:Rect2=button.get_global_rect()
				check(rect.size.x>=44 and rect.size.y>=44 and Rect2(Vector2.ZERO,Vector2(shape)).encloses(rect),"Header target fits")
			await snap("pack-%d-%s"%[shape.x,size_name])
			main._set_pack(false);main._preparation.show_for(2,party);await settle()
			var names=main._preparation.find_children("*","Label",true,false).filter(func(label):return label.text==party.members[0].display_name)
			check(names.size()==1,"Preparation identity occurs once")
			check(main._preparation._supplies.get_parent() is ScrollContainer,"Supply list scrolls independently")
			await snap("preparation-%d-%s"%[shape.x,size_name])
			main.queue_free();await settle()
	settings.set_value("text_size","Normal",self)
	var file=FileAccess.open(OUT+"validation.json",FileAccess.WRITE);file.store_string(JSON.stringify({"checks":checks,"failures":failures,"captures":8,"physical_phone_test":false},"\t")+"\n");file.close()
	print("INTERFACE_REFINEMENT: checks=%d failures=%d"%[checks,failures.size()])
	quit(0 if failures.is_empty() else 1)

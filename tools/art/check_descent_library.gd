extends SceneTree
var checks := 0
var failures: Array[String] = []
const OUT := "res://art/concepts/descent-production-v1/"

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks+=1
	if not ok:
		failures.append(label)
		push_error(label)

func run() -> void:
	for path in ["underhound-v2","borrowed-pack-v1"]:
		var node=load("res://art/enemies/"+path+"/scene.tscn").instantiate()
		root.add_child(node)
		var s: AnimatedSprite3D=node.get_node("Sprite")
		check(s.sprite_frames.get_animation_names().size()==(6 if path=="underhound-v2" else 5),path+" complete poses")
		var origin:=s.position
		for pose in s.sprite_frames.get_animation_names():
			s.play(pose);s.pause()
			check(s.position==origin,path+" fixed origin "+pose)
			check(s.sprite_frames.get_frame_count(pose)==1,path+" single drawing "+pose)
			check(node.get_meta("visual_height")>node.get_meta("art_height"),path+" tag clearance "+pose)
		check(s.shaded and s.texture_filter==BaseMaterial3D.TEXTURE_FILTER_NEAREST,path+" lighting/filter")
		node.free()
	var stone=load("res://art/props/ancient-stonework-v1/scene.tscn").instantiate()
	root.add_child(stone)
	check(stone.get_child_count()==2,"Two stone layers, no light or collision")
	check(not stone.is_processing(),"Still by default")
	stone.set_phase(0.0);var low:float=stone.get_node("Pulse").modulate.a
	stone.set_phase(PI);check(stone.get_node("Pulse").modulate.a>low,"Pulse peak")
	stone.set_motion(true);check(stone.is_processing(),"Motion enabled explicitly")
	stone.set_motion(false);check(not stone.is_processing() and is_equal_approx(stone.get_node("Pulse").modulate.a,low),"Still resets phase")
	stone.set_effects(false);check(not stone.get_node("Pulse").visible,"Reduced effects hide overlay")
	check(stone.get_node("Stone").texture.get_size()==Vector2(192,192),"Stone native192")
	stone.free()
	FileAccess.open(OUT+"headless-validation.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures},"  ")+"\n")
	print("DESCENT_LIBRARY ",checks," failures=",failures.size())
	quit(0 if failures.is_empty() else 1)

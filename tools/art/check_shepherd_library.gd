extends SceneTree
var checks:=0
var failures:Array[String]=[]
const OUT:="res://art/concepts/shepherd-gate-v1/"
func _initialize() -> void:
	call_deferred("run")
func check(ok:bool,label:String) -> void:
	checks+=1
	if not ok:
		failures.append(label);push_error(label)
func run() -> void:
	for folder in ["marrow-shepherd-v1","unfinished-hound-v1"]:
		var actor=load("res://art/enemies/"+folder+"/scene.tscn").instantiate()
		root.add_child(actor)
		var s:AnimatedSprite3D=actor.get_node("Sprite")
		var pos:=s.position
		check(s.sprite_frames.get_animation_names().size()==(6 if folder=="marrow-shepherd-v1" else 3),folder+" full coverage")
		for pose in s.sprite_frames.get_animation_names():
			s.play(pose);s.pause()
			check(s.position==pos,folder+" fixed position "+pose)
			check(s.sprite_frames.get_frame_count(pose)==1,folder+" one drawing "+pose)
			check(actor.get_meta("visual_height")>actor.get_meta("art_height"),folder+" tag clearance "+pose)
		check(s.shaded and s.texture_filter==BaseMaterial3D.TEXTURE_FILTER_NEAREST,folder+" lit nearest")
		actor.free()
	var gate=load("res://art/props/reservoir-flow-gate-v1/scene.tscn").instantiate()
	gate.state="empty";root.add_child(gate)
	var s:Sprite3D=gate.get_node("Sprite")
	check(s.texture.resource_path.ends_with("open.png"),"Resolved state before ready")
	var pos:=s.position;var pixel:=s.pixel_size
	gate.state="closed";check(s.texture.resource_path.ends_with("closed.png"),"Ready state")
	gate.state="empty";check(s.texture.resource_path.ends_with("open.png"),"Resolved state")
	check(s.position==pos and s.pixel_size==pixel,"State registration fixed")
	check(s.billboard==BaseMaterial3D.BILLBOARD_DISABLED,"Fixed wall mount")
	check(is_equal_approx(s.pixel_size*192,2.0),"Two-metre canvas")
	check(s.texture.get_image().get_pixel(96,110).a>0.99,"Opaque open aperture")
	check(gate.get_child_count()==1,"No water rules, collision or lights")
	gate.free()
	FileAccess.open(OUT+"headless-validation.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures},"  ")+"\n")
	print("SHEPHERD_LIBRARY ",checks," failures=",failures.size())
	quit(0 if failures.is_empty() else 1)

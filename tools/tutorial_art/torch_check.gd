extends "res://tools/mine_polish/capture.gd"
const Dressing := preload("res://scripts/dressing.gd")
const Prefs := preload("res://scripts/settings.gd")
var fails:=0
var checks:=0

func check(label: String, ok: bool) -> void:
	checks+=1
	if not ok:fails+=1
	print("PASS " if ok else "FAIL ",label)

func run() -> void:
	Prefs.set_value("flashes",false)
	setup(true)
	for id in ["burnt-sconce","goblin-torch-lit"]:
		for facing in 4:
			var yaw: float=facing*PI/2
			var at:=Vector3(0,1.6,0)
			var node:=Dressing._put(stage,id,at,yaw)
			check(id+" real wall geometry "+str(facing),node.scene_file_path.contains("wall-torch-3d-v1") and node.find_children("*","SpriteBase3D",true,false).is_empty())
			check(id+" retains mount "+str(facing),node.position==at and is_equal_approx(node.rotation.y,yaw) and node.get_meta("dressing_id")==id)
			check(id+" fits wall envelope "+str(facing),bounds(node).end.y<2.15 and bounds(node).position.y>1.2)
			var light: OmniLight3D=node.get_node("MoodLight")
			check(id+" original light state "+str(facing),light.visible==(id=="goblin-torch-lit") and is_equal_approx(light.omni_range,1.5) and is_equal_approx(light.light_energy,.4))
			node.free()
	var lit=load(Dressing.MODELS["goblin-torch-lit"]).instantiate();stage.add_child(lit)
	for i in 4:await process_frame
	check("effects off holds torch flame exactly",lit._phase==0 and is_equal_approx(lit.get_node("MoodLight").light_energy,.4))
	Prefs.set_value("flashes",true)
	for i in 4:await process_frame
	check("live preference starts flame motion",lit._phase>0)
	Prefs.set_value("flashes",false)
	for i in 4:await process_frame
	check("live preference returns to stable frame",lit._phase==0)
	stage.free()
	print("WALL_TORCH checks=",checks," fails=",fails)
	quit(0 if fails==0 else 1)

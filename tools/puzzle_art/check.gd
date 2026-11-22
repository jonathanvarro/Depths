extends "res://tools/mine_polish/capture.gd"
const FACTORY := preload("res://scripts/puzzle_props.gd")
const MAP := preload("res://scripts/dungeon_map.gd")
const ART := "res://art/props/puzzle-fittings-v1/"
var checks := 0
var failures: Array[String] = []

func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures.append(label);push_error(label)

func run() -> void:
	root.size=Vector2i(1280,720)
	for id in ["barred-door","locked-door","lever","recovered-key"]:
		show_asset(ART+id+".tscn")
		check(subject.find_children("*","CollisionObject3D",true,false).is_empty(),"art has no collision authority")
		check(subject.has_method("set_open") and subject.has_method("set_motion"),"state API is available")
		var closed:=bounds(subject)
		check(closed.size.x<=2.2 and closed.size.y<=2.44,"fittings stay within their original mount envelope")
		await snap(id+"-closed")
		if id.begins_with("barred"):
			camera.position.z*=-1;camera.look_at(closed.get_center())
			await snap(id+"-reverse")
			camera.position.z*=-1;camera.look_at(closed.get_center())
		subject.set_open(true,false)
		check(subject._opened,"restored state is immediate")
		if id=="recovered-key":
			check(not subject.get_node("Key").visible,"taking key removes its mesh and existing glint together")
		else:
			var pivot: Node3D=subject.get_node("Pivot" if id=="lever" else "Hinge")
			var target:=pivot.rotation
			check(target.length()>.5,"open/pulled pose differs from closed")
			subject.set_open(false,false);subject.set_motion(true);subject.set_open(true)
			await create_timer(.16).timeout
			var mid:=pivot.rotation
			check(mid.length()>0 and mid.length()<target.length(),"hinge moves continuously")
			subject.set_open(false)
			check(pivot.rotation.is_equal_approx(mid),"reversing motion has no snap")
			subject.set_open(true);subject.set_motion(false)
			check(pivot.rotation.is_equal_approx(target),"still mode finishes the latest state exactly")
		await snap(id+"-open")
		subject.set_open(false,false)
		check(subject.get_node("Key").visible if id=="recovered-key" else true,"key can be restored")
	for across in [false,true]:
		var map=MAP.new(PackedStringArray(["#####","#.D.#","#####"]) if across else PackedStringArray(["#####","##.##","##D##","##S##","#####"]))
		var cell:=Vector2i(2,1) if across else Vector2i(2,2)
		for side in [-1,1]:
			for kind in ["oneway","key"]:
				var offset:=Vector2i(side,0) if across else Vector2i(0,side)
				var puzzle: Dictionary={"kind":kind,"door":cell,"bolt":cell+offset}
				var piece: Node3D=FACTORY.build(puzzle,"door",map,2.0,2.4)
				stage.add_child(piece)
				var expected:=float(-side if across else side)
				check(piece.bolt_side==expected,"bolt face keeps the original orientation in both corridor axes")
				check(is_equal_approx(piece.rotation.y,PI/2 if across else 0.0),"door spans the correct corridor axis")
				piece.set_open(true,false)
				check(is_equal_approx(piece.get_node("Hinge").rotation.y,-expected*deg_to_rad(100)),"door swings in the original direction")
				piece.free()
	# The key and lever remain mounted toward the room, not inside the rock.
	for side in [Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]:
		var map=MAP.new(PackedStringArray(["#####","#,,,#","#,,,#","#,,,#","#####"]))
		var cell:=Vector2i(2,2)
		# Provide exactly one neighbouring wall to exercise each mounting face.
		map._rows[cell.y+side.y]=map._rows[cell.y+side.y].substr(0,cell.x+side.x)+"#"+map._rows[cell.y+side.y].substr(cell.x+side.x+1)
		for part in ["lever","key"]:
			var piece: Node3D=FACTORY.build({part:cell},part,map,2.0,2.4)
			stage.add_child(piece)
			var at:=Vector3(cell.x*2.0,0,cell.y*2.0)+Vector3(side.x,0,side.y)*(0.72 if part=="lever" else .60)
			check(piece.position.is_equal_approx(at),"wall mount position retained")
			check(is_equal_approx(piece.rotation.y,atan2(-float(side.x),-float(side.y))),"wall fitting faces the room")
			piece.free()
	for size in [Vector2i(844,390),Vector2i(667,375)]:
		root.size=size
		for id in ["barred-door","lever","recovered-key"]:
			show_asset(ART+id+".tscn","closed",false)
			await snap(id+"-phone-"+str(size.x))
	stage.free()
	FileAccess.open(output.path_join("puzzle-validation.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"physical_iPhone":false},"\t"))
	print("PUZZLE_ART checks=",checks," failures=",failures.size())
	quit(0 if failures.is_empty() else 1)

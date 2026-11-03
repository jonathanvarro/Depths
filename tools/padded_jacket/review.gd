extends "res://review_base.gd"
var outfit:="jacket"
var outfit_choice:OptionButton

func _ready()->void:
	super._ready()
	selectors.view.add_item("Garment detail")
	garment_buttons[0].text="Upper"
	var row:HBoxContainer=garment_buttons[0].get_parent()
	outfit_choice=choice(row,["Padded jacket","Plain tunic"],145)
	row.move_child(outfit_choice,0)
	outfit_choice.item_selected.connect(func(index):set_outfit("jacket" if index==0 else "tunic"))
	set_outfit("jacket")

func set_outfit(value:String)->void:
	outfit=value
	for actor in actors:actor.set_outfit(value)
	set_garments(selected_bits)

func aim(camera:Camera3D,actor:Node3D,aspect:float,portrait:bool)->void:
	if view_index!=2 or portrait:
		super.aim(camera,actor,aspect,portrait)
		return
	var direction:Vector3=[Vector3(0,0,1),Vector3(.65,0,1),Vector3(1,0,0),Vector3(0,0,-1)][angle_index].normalized()
	var hips:Vector3=actor.skeleton.to_global(actor.skeleton.get_bone_global_pose(actor.skeleton.find_bone("mixamorig_Hips")).origin)
	var focus:Vector3=hips.lerp(actor.head_position(),.38)
	camera.position=focus+direction*10;camera.look_at(focus)
	camera.size=maxf(1.85,1.25/maxf(.2,aspect))*actor.display_scale

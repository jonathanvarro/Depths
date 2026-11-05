extends "res://review.gd"
## Contact reference for the aligned chair sequence.
const STOOL = preload("res://stool.tscn")
const SEAT_HEIGHT := 0.43
var stools: Array[Node3D] = []

func _ready() -> void:
	super._ready()
	for actor in actors:
		var joins: Array = actor.join_times("chair_sequence")
		actor.set_motion("chair_sequence", float(joins[0]) + 0.1)
		var hips: Vector3 = actor.to_global(actor.hips_local())
		var stool: Node3D = STOOL.instantiate()
		actor.get_parent().add_child(stool)
		stool.position = Vector3(hips.x, 0, hips.z + 0.025)
		stools.append(stool)
		print("STOOL_REFERENCE ", actor.fit, " seat_y=", SEAT_HEIGHT, " position=", stool.position)
	angle_index = 2
	selectors.angle.select(2)
	var chair_index: int = MOTIONS.find("chair_sequence")
	selectors.motion.select(chair_index)
	set_motion("chair_sequence", float(actors[0].join_times("chair_sequence")[0]) + 0.1, true)

func _process(delta: float) -> void:
	super._process(delta)
	for stool in stools:
		stool.visible = current_motion == "chair_sequence"

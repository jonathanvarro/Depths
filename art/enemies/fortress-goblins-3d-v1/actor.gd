extends "res://art/enemies/combat-roster-3d-v1/actor.gd"
## The King's longer gestures hold their meaningful frame in still mode.

const KING_STILL := {"plant": 15.0 / 24.0, "attack": 18.0 / 24.0, "hurt": 4.0 / 24.0}

func play(pose: String) -> void:
	super.play(pose)
	if is_node_ready() and not animate_motion and KING_STILL.has(pose):
		sample(pose, KING_STILL[pose])

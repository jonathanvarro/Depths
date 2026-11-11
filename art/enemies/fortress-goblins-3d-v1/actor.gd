extends "res://art/enemies/combat-roster-3d-v1/actor.gd"
## The King study holds the weight-bearing pose when motion is off.

func play(pose: String) -> void:
	super.play(pose)
	if is_node_ready() and pose == "plant" and not animate_motion:
		sample("plant",15.0 / 24.0)

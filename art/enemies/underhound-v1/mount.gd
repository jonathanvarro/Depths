extends "res://art/enemies/monsters-v1/pose_bounds.gd"
## The combat tag centres on its anchor. Leave room above the high rib arch
## at Larger phone text, without changing the sprite's scale or floor origin.
const TAG_HEADROOM:=0.12

func _update_bounds() -> void:
	super._update_bounds()
	var actual:float=get_meta("visual_height")
	set_meta("art_height",actual)
	set_meta("visual_height",actual+TAG_HEADROOM)

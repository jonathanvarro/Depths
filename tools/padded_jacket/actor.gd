extends "res://actor_base.gd"
## Two alternative upper garments on one unchanged skeleton/body partition.
var outfit:="jacket"

func set_outfit(value:String)->void:
	assert(value in ["tunic","jacket"],"Unknown outfit")
	outfit=value
	set_garments(selected_bits)

func set_garments(bits:int)->void:
	super.set_garments(bits)
	for entry in record.garments:
		if str(entry.get("outfit","both")) not in ["both",outfit]:
			meshes[str(entry.name)].visible=false

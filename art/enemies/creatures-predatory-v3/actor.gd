extends "res://art/enemies/creatures-refined-v2/actor.gd"
## #294: revised rats keep the same APIs; grounded bats retain wing silhouette.
const COAT:=preload("res://art/enemies/creatures-predatory-v3/fur.tres")
const EYE_DETAIL:=preload("res://art/enemies/creatures-predatory-v3/details.gdshader")

func _ready() -> void:
	super._ready()
	if not flying:
		for material in surfaces:
			if material.shader==FUR.shader and int(material.get_shader_parameter("surface_kind"))==0:
				material.shader=COAT.shader
			elif int(material.get_shader_parameter("surface_kind"))==2:
				material.shader=EYE_DETAIL
				material.render_priority=1

func tag_clearance() -> float:
	return .34 if flying and current_pose in ["landed","bite","hurt-ground","fall-ground"] else .12

func _process(delta: float) -> void:
	super._process(delta)
	if flying:
		var grounded:=current_pose in ["landed","bite","hurt-ground","fall-ground"]
		for material in surfaces:
			if material.shader==FUR.shader:material.set_shader_parameter("pose_readability",.18 if grounded else 0.0)

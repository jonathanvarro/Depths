extends MeshInstance3D
## #166 visual-only surface. The caller owns which cells flood and when they drain.
const SHALLOW = preload("res://art/textures/drowned-water-v1/shallow.tres")
const DEEP = preload("res://art/textures/drowned-water-v1/deep.tres")
@export var deep := false
@export var cell_size := 2.0
@export var motion_enabled := true

func _ready() -> void:
	_build()

## World-grid registration keeps adjoining animated deep tiles in phase.
## Retains Galleries.water_plane's y0.12; shallow art is a thin floor layer.
func configure(cell: Vector2i, size: float, animate := true) -> void:
	cell_size = size
	motion_enabled = animate
	position = Vector3(cell.x * size, 0.12 if deep else 0.018, cell.y * size)
	_build()

func _build() -> void:
	var plane := PlaneMesh.new()
	plane.size = Vector2(cell_size, cell_size)
	if deep:
		var material: ShaderMaterial = DEEP.duplicate()
		material.set_shader_parameter("motion_enabled", motion_enabled)
		plane.material = material
	else:
		plane.material = SHALLOW
	mesh = plane
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

## Existing reduced-effects callers can freeze the water without hiding depth.
func set_motion(enabled: bool) -> void:
	motion_enabled = enabled
	if mesh and mesh.material is ShaderMaterial:
		mesh.material.set_shader_parameter("motion_enabled", enabled)

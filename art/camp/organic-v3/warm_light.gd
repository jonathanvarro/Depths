extends PointLight2D
## Small, local camp light. No RNG, time costs or screen-wide flashes.
@export var base_energy := 0.35
@export var phase := 0.0
@export var animate_glow := true
@export var core_size := Vector2.ZERO
var _elapsed := 0.0

func _ready() -> void:
	range_item_cull_mask=2
	color=Color(1.0,.56,.25)
	var gradient:=Gradient.new()
	gradient.colors=PackedColorArray([Color(1,1,1,.65),Color(1,1,1,0)])
	var falloff:=GradientTexture2D.new()
	falloff.width=64;falloff.height=64;falloff.fill=GradientTexture2D.FILL_RADIAL
	falloff.fill_from=Vector2(.5,.5);falloff.fill_to=Vector2(1,.5)
	falloff.gradient=gradient;texture=falloff
	energy=base_energy

func _process(delta: float) -> void:
	if not is_visible_in_tree():return
	if animate_glow:
		_elapsed+=delta
		var t:=_elapsed+phase
		energy=base_energy*(1.0+.07*sin(t*1.7)+.03*sin(t*3.9))
	else:energy=base_energy
	if core_size!=Vector2.ZERO:queue_redraw()

func _draw() -> void:
	if core_size==Vector2.ZERO:return
	var strength:=clampf(energy/base_energy,.85,1.15)
	draw_rect(Rect2(-core_size*.5,core_size),Color(1,.69,.27,.82*strength))

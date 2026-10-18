extends Node2D
## Static presence follows actual available recruits; no new NPC simulation.
var _figures: Array[Sprite2D]=[]
var _meal: Sprite2D

func setup(canvas: Node, fire: Node2D) -> void:
	_sprite("drying-cloth",Vector2(447,175),.65)
	_figures.append(_sprite("seated-a",Vector2(485,293),.70))
	var second:=_sprite("seated-b",Vector2(578,308),.70)
	second.flip_h=true
	_figures.append(second)
	_meal=_sprite("meal",Vector2(508,311),.44)
	# A separate local light affects artwork only, leaving text/targets alone.
	canvas.get_child(0).light_mask=2
	fire.get_node("Base").light_mask=2
	var gradient:=Gradient.new()
	gradient.colors=PackedColorArray([Color(1,1,1,.34),Color(1,1,1,0)])
	var falloff:=GradientTexture2D.new()
	falloff.width=128;falloff.height=128;falloff.fill=GradientTexture2D.FILL_RADIAL
	falloff.fill_from=Vector2(.5,.5);falloff.fill_to=Vector2(1,.5);falloff.gradient=gradient
	var warmth:=PointLight2D.new()
	warmth.name="FireWarmth"
	warmth.texture=falloff;warmth.texture_scale=1.2
	warmth.color=Color(1,.50,.21);warmth.energy=.30
	warmth.range_item_cull_mask=2;warmth.position=Vector2(525,293)
	add_child(warmth)

func _sprite(id: String, at: Vector2, amount: float) -> Sprite2D:
	var sprite:=Sprite2D.new()
	sprite.name=id
	sprite.texture=load("res://art/camp/occupancy-v1/"+id+".png")
	sprite.centered=false;sprite.offset=Vector2(-32,-56)
	sprite.position=at;sprite.scale=Vector2.ONE*amount
	sprite.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;sprite.light_mask=2
	add_child(sprite)
	return sprite

func refresh(camp) -> void:
	for i in _figures.size():_figures[i].visible=i<camp.candidates.size()
	_meal.visible=not camp.candidates.is_empty()

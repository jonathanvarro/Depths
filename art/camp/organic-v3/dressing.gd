extends Node2D
## Figures and light remain separate from the permanent landscape and hearth.
const WarmLight := preload("res://art/camp/organic-v3/warm_light.gd")
var _figures: Array[Sprite2D]=[]
var _meal: Sprite2D
var _warmth: PointLight2D
var animate_lights := true:
	set(value):
		animate_lights=value
		if _warmth:_warmth.animate_glow=value

func setup(_canvas: Node, _fire: Node2D) -> void:
	_figures.append(_sprite("seated-a",Vector2(353,255),.65))
	var second:=_sprite("seated-b",Vector2(451,263),.65)
	second.flip_h=true;_figures.append(second)
	_meal=_sprite("meal",Vector2(389,271),.40)
	_warmth=WarmLight.new();_warmth.name="FireWarmth"
	_warmth.position=Vector2(399,247);_warmth.base_energy=.32
	_warmth.texture_scale=1.7;_warmth.phase=2.1
	_warmth.animate_glow=animate_lights
	add_child(_warmth)

func _sprite(id: String, at: Vector2, amount: float) -> Sprite2D:
	var sprite:=Sprite2D.new();sprite.name=id
	sprite.texture=load("res://art/camp/occupancy-v1/"+id+".png")
	sprite.centered=false;sprite.offset=Vector2(-32,-56)
	sprite.position=at;sprite.scale=Vector2.ONE*amount
	sprite.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;sprite.light_mask=2
	add_child(sprite);return sprite

func refresh(camp) -> void:
	var present: bool=camp.site_present("fire")
	for i in _figures.size():_figures[i].visible=present and i<camp.candidates.size()
	_meal.visible=present and not camp.candidates.is_empty()
	_warmth.visible=present

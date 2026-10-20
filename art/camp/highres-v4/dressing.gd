extends "res://art/camp/organic-v3/dressing.gd"
## Higher-density source textures preserve the same figure/contact geometry.
func _sprite(id: String, at: Vector2, amount: float) -> Sprite2D:
	var sprite:=Sprite2D.new();sprite.name=id
	sprite.texture=load("res://art/camp/highres-v4/"+id+".png")
	sprite.centered=false;sprite.offset=Vector2(-80,-140)
	sprite.position=at;sprite.scale=Vector2.ONE*amount*.4
	sprite.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR;sprite.light_mask=2
	add_child(sprite);return sprite

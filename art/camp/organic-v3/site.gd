extends Node2D
## Independent site artwork, light and fire animation follow parent visibility.
@export var animate_lights := true:
	set(value):
		animate_lights=value
		if is_node_ready():_sync()

func _ready() -> void:
	visibility_changed.connect(_sync)
	_sync()

func _sync() -> void:
	for light in find_children("*","PointLight2D",true,false):
		light.animate_glow=animate_lights
	var flames:=get_node_or_null("FlameAnchor/Flames") as AnimatedSprite2D
	if flames:
		if animate_lights and is_visible_in_tree():flames.play(&"burn")
		else:
			flames.pause()
			if not animate_lights:flames.frame=0

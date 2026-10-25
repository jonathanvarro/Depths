extends Control
## The approved twelve-compartment bag, reused with real inventory pages.
const BAG := preload("res://art/ui/physical-kit-v1/bag.png")
var slots: Array[Button] = []
var art_rect := Rect2()

func _init() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	resized.connect(_fit)

func _draw() -> void:
	draw_texture_rect(BAG,art_rect,false)

func _fit() -> void:
	var scale_factor:=minf(size.x/768.0,size.y/512.0)
	var extent:=Vector2(768,512)*scale_factor
	art_rect=Rect2((size-extent)*0.5,extent)
	for i in slots.size():
		var slot:=slots[i]
		slot.position=art_rect.position+art_rect.size*Vector2(0.19+0.155*(i%4),0.22+0.197*(i/4))
		slot.size=art_rect.size*Vector2(0.155,0.197)
	queue_redraw()

func clear_slots() -> void:
	for slot in slots:
		remove_child(slot)
		slot.queue_free()
	slots.clear()

func add_slot(button: Button) -> void:
	slots.append(button)
	add_child(button)
	_fit()

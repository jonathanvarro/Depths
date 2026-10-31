extends Control
## The approved twelve-compartment bag, reused with real inventory pages.
const BAG := preload("res://art/ui/physical-kit-v1/bag.png")
var slots: Array[Button] = []
var art_rect := Rect2()
## Pack can crop the loose flap/straps to favour large pockets. Trade keeps
## the original full-bag framing unless its caller explicitly opts in.
var pocket_focus := false

func _init() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	resized.connect(_fit)

func _draw() -> void:
	draw_texture_rect(BAG,art_rect,false)

func _fit() -> void:
	var framing:=Vector2(768,512)*Vector2(0.74,0.76) if pocket_focus else Vector2(768,512)
	var scale_factor:=minf(size.x/framing.x,size.y/framing.y)
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

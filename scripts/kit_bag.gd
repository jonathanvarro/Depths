extends Control
## The approved twelve-compartment bag, reused with real inventory pages.
const BAG := preload("res://art/ui/physical-kit-v1/bag.png")
const FITTED_BAG := preload("res://art/ui/field-kit-v3/bag.png")
## A short flap and close straps leave room for twelve usable pockets on phones.
## Trade keeps its established art/registration unless explicitly selected.
var fitted_art := false
var slots: Array[Button] = []
var art_rect := Rect2()
## Pack can crop the loose flap/straps to favour large pockets. Trade keeps
## the original full-bag framing unless its caller explicitly opts in.
var pocket_focus := false

func _init() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	resized.connect(_fit)

func _draw() -> void:
	draw_texture_rect(FITTED_BAG if fitted_art else BAG,art_rect,false)

func _fit() -> void:
	var dimensions: Vector2=FITTED_BAG.get_size() if fitted_art else Vector2(768,512)
	var framing:=dimensions*Vector2(0.74,0.76) if pocket_focus and not fitted_art else dimensions
	var scale_factor:=minf(size.x/framing.x,size.y/framing.y)
	var extent:=dimensions*scale_factor
	art_rect=Rect2((size-extent)*0.5,extent)
	for i in slots.size():
		var slot:=slots[i]
		var first:=Vector2(.124,.164) if fitted_art else Vector2(.19,.22)
		var cell:=Vector2(.195,.228) if fitted_art else Vector2(.155,.197)
		slot.position=art_rect.position+art_rect.size*(first+cell*Vector2(i%4,i/4))
		slot.size=art_rect.size*cell
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

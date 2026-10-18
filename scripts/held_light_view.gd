extends Node2D
## Existing torch/lantern art follows real supplies; it never spends fuel.
var _main: WeakRef
var _torch: Node2D
var _lantern: Node2D

func setup(main: Node) -> void:
	_main=weakref(main)
	_torch=preload("res://art/props/torch-v1/held.tscn").instantiate()
	_lantern=preload("res://art/props/lantern-v1/held.tscn").instantiate()
	add_child(_torch)
	add_child(_lantern)

func _process(_delta: float) -> void:
	var main=_main.get_ref() if _main else null
	if main==null or not is_instance_valid(main._party):return
	visible=not (main._ending or main._in_combat or main._pack.visible or main._chest.visible or main._full_map.visible or main._event_screen.visible or main._camp.visible or main._preparation.visible)
	if not visible:return
	var supplies=main._party_state.supplies
	_torch.apply_supplies(supplies)
	_lantern.apply_supplies(supplies)
	var amount:=clampf(main._safe_area.size.y*.38/256.0,.60,.95)
	scale=Vector2.ONE*amount
	position=Vector2(main._touch_pad.position.x-128*amount-18,main._safe_area.size.y-256*amount-12)

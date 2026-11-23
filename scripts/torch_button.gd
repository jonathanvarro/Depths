extends Button
## The HUD's torch button (owner, 2026-11-22), beside Pack: lights a torch
## in one press and shows, as a thin bar along its foot, how much light is
## left (the held torch, else the lantern's oil). The count is how many
## torches are in the pack. Pressing it is main.gd's _quick_torch (T).

const TORCH := preload("res://data/items/torch.tres")
const Supplies := preload("res://scripts/supplies.gd")

var party_state
var _shown := []


func _init() -> void:
	custom_minimum_size = Vector2(112, 52)
	focus_mode = Control.FOCUS_NONE
	modulate.a = 0.8
	tooltip_text = "Light a fresh torch (T). The bar shows the light left."


## 0-1: what's left of the light the party holds now.
func light_left() -> float:
	if party_state == null:
		return 0.0
	var s = party_state.supplies
	if s.torch_lit():
		return clampf(s.torch_left / Supplies.TORCH_BURN_TIME, 0.0, 1.0)
	if s.source == Supplies.Source.LANTERN:
		return clampf(s.oil / Supplies.LANTERN_CAPACITY, 0.0, 1.0)
	return 0.0


func _process(_delta: float) -> void:
	if party_state == null:
		return
	var count: int = party_state.supplies.count(TORCH)
	var state := [count, snappedf(light_left(), 0.01)]
	if state == _shown:
		return
	_shown = state
	text = "Torch ×%d" % count
	disabled = count == 0
	accessibility_name = "Light a torch, %d left" % count
	queue_redraw()


func _draw() -> void:
	var fraction := light_left()
	var bar := Rect2(10, size.y - 9, size.x - 20, 4)
	draw_rect(bar, Color(0, 0, 0, 0.55))
	var colour := Color("f2b25a") if fraction > 0.2 else Color("d0643c")
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * fraction, bar.size.y)), colour)

extends Control
## The coin flip (#77): at rare, high-stakes moments the outcome is decided
## in the open. The player sees what heads and tails mean and the odds,
## presses Flip (there's no turning it down), watches it spin and land.
##
## Owner decisions (#77): one coin; only rare, high-stakes moments; hero
## traits or trinkets can bend the odds; no turning down. Heads is always
## the good side. Neutral crown/skull art is supplied by #96.

## Flip() result: true for heads (the good outcome).
signal landed(heads: bool)

const COLOR_TEXT := Color("f0e2bb")
const COLOR_DIM := Color(0.85, 0.8, 0.7, 0.75)
const GOLD := Color("d9a441")
const GOLD_DARK := Color("8a5d1c")
const COIN_RADIUS := 64.0
const HEADS_TEXTURE := preload("res://art/ui/coin-v1/heads.png")
const TAILS_TEXTURE := preload("res://art/ui/coin-v1/tails.png")
const SPINS := 9
const SPIN_SECONDS := 1.6

var _title: Label
var _sides: Label
var _odds: Label
var _result: Label
var _coin: Control
var _flip: Button
var _done: Button
var _face_heads := true
var _player: AudioStreamPlayer


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.02, 0.02, 0.94)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(column)
	_title = _label(26, COLOR_TEXT)
	column.add_child(_title)
	_coin = Control.new()
	_coin.custom_minimum_size = Vector2(COIN_RADIUS * 2 + 8, COIN_RADIUS * 2 + 8)
	_coin.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_coin.pivot_offset = _coin.custom_minimum_size / 2.0
	_coin.draw.connect(_draw_coin)
	column.add_child(_coin)
	_sides = _label(19, COLOR_DIM)
	column.add_child(_sides)
	_odds = _label(17, COLOR_DIM)
	column.add_child(_odds)
	_result = _label(24, GOLD)
	column.add_child(_result)
	_flip = _button("Flip the coin")
	column.add_child(_flip)
	_done = _button("Continue")
	column.add_child(_done)
	_player = AudioStreamPlayer.new()
	_player.bus = "Effects"
	_player.stream = load("res://audio/placeholder/coin.wav") if ResourceLoader.exists("res://audio/placeholder/coin.wav") else null
	add_child(_player)
	visible = false


## Shows the coin, waits for the player to flip it, and returns heads.
## `heads_chance` is usually 0.5; luck can bend it.
func flip(title: String, heads_text: String, tails_text: String, heads_chance := 0.5, odds_note := "") -> bool:
	_title.text = title
	_sides.text = "Heads: %s\nTails: %s" % [heads_text, tails_text]
	_odds.text = "Heads %d%%%s" % [roundi(heads_chance * 100), ("  ·  " + odds_note) if odds_note != "" else ""]
	_result.text = ""
	_face_heads = true
	_coin.scale = Vector2.ONE
	_coin.queue_redraw()
	_flip.visible = true
	_done.visible = false
	visible = true
	_flip.grab_focus.call_deferred()
	await _flip.pressed
	_flip.visible = false
	var heads := randf() < heads_chance
	if _player.stream:
		_player.play()
	# Spin: squash to an edge and open again, swapping faces each half turn.
	var spin := create_tween()
	for i in SPINS:
		var half := SPIN_SECONDS / SPINS / 2.0 * (1.0 + i * 0.12)  # slowing down
		spin.tween_property(_coin, "scale:x", 0.05, half)
		spin.tween_callback(func():
			_face_heads = not _face_heads if i < SPINS - 1 else heads
			_coin.queue_redraw())
		spin.tween_property(_coin, "scale:x", 1.0, half)
	await spin.finished
	_result.text = "Heads!" if heads else "Tails."
	_result.add_theme_color_override("font_color", GOLD if heads else Color("d0543a"))
	_done.visible = true
	_done.grab_focus.call_deferred()
	await _done.pressed
	visible = false
	landed.emit(heads)
	return heads


## Heads: the king's crown. Tails: a skull.
func _draw_coin() -> void:
	var texture: Texture2D = HEADS_TEXTURE if _face_heads else TAILS_TEXTURE
	var extent := Vector2.ONE * COIN_RADIUS
	_coin.draw_texture_rect(texture,Rect2(_coin.size/2.0-extent,extent*2),false)


func _label(size: int, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(520, 0)
	return label


func _button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(220, 60)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", 22)
	return button

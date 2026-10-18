extends Control
## An opened chest beside the pack (#69): drag an item from the chest into
## the pack, tap it to move it, or use the take-all button (an icon) to
## move everything. Closing leaves anything not taken behind.

signal closed
## An item was moved into the pack.
signal took(item: SupplyItem, quantity: int)

const COLOR_TEXT := Color("e8d9b0")
const COLOR_DIM_TEXT := Color(0.85, 0.8, 0.7, 0.65)
const TILE_SIZE := Vector2(120, 120)

var content: MarginContainer  # main.gd keeps this inside the safe area
## What's still in the chest: SupplyItem -> quantity.
var contents := {}

var _party  # party_state.gd
var _title: Label
var _chest_grid: GridContainer
var _pack_grid: GridContainer
var _pack_panel: PanelContainer
var _take_all: Button


func _init() -> void:
	_build()
	visible = false


func open(title: String, items: Dictionary, party_state) -> void:
	_party = party_state
	contents = items.duplicate()
	_title.text = title
	visible = true
	refresh()


func is_empty() -> bool:
	return contents.values().all(func(n): return n <= 0)


func take(item: SupplyItem) -> void:
	var quantity: int = contents.get(item, 0)
	if quantity <= 0:
		return
	contents.erase(item)
	_party.supplies.add(item, quantity)
	took.emit(item, quantity)
	refresh()


func take_all() -> void:
	for item in contents.keys():
		take(item)


func refresh() -> void:
	for child in _chest_grid.get_children():
		child.queue_free()
	for child in _pack_grid.get_children():
		child.queue_free()
	for item: SupplyItem in contents:
		if contents[item] > 0:
			_chest_grid.add_child(_tile(item, contents[item], true))
	if is_empty():
		_chest_grid.add_child(_label("Empty.", 20, COLOR_DIM_TEXT))
	for item: SupplyItem in _party.supplies.items:
		if _party.supplies.count(item) > 0:
			_pack_grid.add_child(_tile(item, _party.supplies.count(item), false))
	_take_all.disabled = is_empty()
	_take_all.get_child(0).queue_redraw()


func _tile(item: SupplyItem, quantity: int, in_chest: bool) -> Control:
	var tile := Button.new()
	tile.custom_minimum_size = TILE_SIZE
	tile.focus_mode = Control.FOCUS_ALL
	tile.tooltip_text = "%s\n%s" % [item.display_name, item.description]
	tile.icon = item.icon
	tile.expand_icon = true
	tile.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tile.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	tile.text = "%s ×%d" % [item.display_name, quantity]
	tile.add_theme_font_size_override("font_size", 15)
	tile.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tile.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if in_chest:
		tile.pressed.connect(take.bind(item))  # tap to take
		tile.set_drag_forwarding(func(_at): return _start_drag(item), Callable(), Callable())
	else:
		tile.mouse_filter = Control.MOUSE_FILTER_PASS  # drops land on the pack panel
		tile.disabled = true
	return tile


func _start_drag(item: SupplyItem) -> Variant:
	var preview := TextureRect.new()
	preview.texture = item.icon
	preview.custom_minimum_size = Vector2(72, 72)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	preview.modulate.a = 0.85
	set_drag_preview(preview)
	return {"chest_item": item}


func _can_drop_on_pack(_at: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.has("chest_item")


func _drop_on_pack(_at: Vector2, data: Variant) -> void:
	take(data["chest_item"])


func _build() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.color = Color(0.03, 0.03, 0.03, 0.92)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	content = MarginContainer.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "top", "right", "bottom"]:
		content.add_theme_constant_override("margin_" + side, 32)
	add_child(content)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	content.add_child(column)

	var header := HBoxContainer.new()
	column.add_child(header)
	_title = _label("Chest", 30, COLOR_TEXT)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_title)
	var close := Button.new()
	close.text = "Close"
	close.custom_minimum_size = Vector2(120, 52)
	close.focus_mode = Control.FOCUS_ALL
	close.add_theme_font_size_override("font_size", 20)
	close.pressed.connect(func(): closed.emit())
	header.add_child(close)
	visibility_changed.connect(func():
		if visible: close.grab_focus())

	var sides := HBoxContainer.new()
	sides.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sides.add_theme_constant_override("separation", 16)
	column.add_child(sides)
	var chest_panel := _panel("In the chest")
	sides.add_child(chest_panel)
	_chest_grid = chest_panel.get_meta("grid")

	# Take all: an arrow sweeping into the pack, drawn as an icon.
	var middle := CenterContainer.new()
	sides.add_child(middle)
	_take_all = Button.new()
	_take_all.custom_minimum_size = Vector2(88, 88)
	_take_all.focus_mode = Control.FOCUS_ALL
	_take_all.tooltip_text = "Take everything"
	_take_all.pressed.connect(take_all)
	var glyph := Control.new()
	glyph.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glyph.draw.connect(_draw_take_all.bind(glyph))
	_take_all.add_child(glyph)
	middle.add_child(_take_all)

	_pack_panel = _panel("Your pack")
	_pack_panel.set_drag_forwarding(Callable(), _can_drop_on_pack, _drop_on_pack)
	sides.add_child(_pack_panel)
	_pack_grid = _pack_panel.get_meta("grid")


## Two chevrons pointing right, into an open pack.
func _draw_take_all(glyph: Control) -> void:
	var c := glyph.size / 2.0
	var color := COLOR_TEXT if not _take_all.disabled else Color(COLOR_TEXT, 0.35)
	for dx in [-22.0, -6.0]:
		glyph.draw_polyline(PackedVector2Array([c + Vector2(dx, -14), c + Vector2(dx + 12, 0), c + Vector2(dx, 14)]), color, 5.0)
	var bag := Rect2(c + Vector2(10, -12), Vector2(20, 26))
	glyph.draw_rect(bag, color, false, 4.0)
	glyph.draw_line(bag.position + Vector2(4, 0), bag.position + Vector2(4, -6), color, 3.0)
	glyph.draw_line(bag.position + Vector2(16, 0), bag.position + Vector2(16, -6), color, 3.0)


func _panel(heading: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.065, 0.05, 0.9)
	style.border_color = Color(0.35, 0.27, 0.18, 0.9)
	style.set_border_width_all(1)
	style.set_content_margin_all(12)
	panel.add_theme_stylebox_override("panel", style)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	column.mouse_filter = Control.MOUSE_FILTER_PASS
	panel.add_child(column)
	column.add_child(_label(heading, 22, COLOR_TEXT))
	var grid := GridContainer.new()
	grid.columns = 3
	grid.mouse_filter = Control.MOUSE_FILTER_PASS
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	column.add_child(grid)
	panel.set_meta("grid", grid)
	return panel


func _label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label

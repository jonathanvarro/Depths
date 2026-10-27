extends "res://scripts/field_menu.gd"
## Read-only quest journal; hidden entries still come solely from Quests.in_log().
const Quests := preload("res://scripts/quests.gd")
const PAPER := preload("res://art/ui/map-v1/parchment.png")
const INK := Color("30291e")

var _camp
var _list: VBoxContainer
var _list_scroll: ScrollContainer
var _detail_scroll: ScrollContainer
var _paper: Control
var _detail: VBoxContainer
var _back: Button
var _buttons: Dictionary = {}
var _selected_id := ""
var _compact := false
var _detail_open := false

func _init() -> void:
	super()
	_heading.text = "Quest log"
	_symbol.texture = preload("res://art/ui/controls-v1/journal.svg")
	_back = action_button("All quests")
	_back.pressed.connect(_show_list)
	_header.add_child(_back)
	_header.move_child(_back, _header.get_child_count() - 2)
	_list_scroll = ScrollContainer.new()
	_list_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_list_scroll.follow_focus = true
	_body.add_child(_list_scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 6)
	_list_scroll.add_child(_list)
	_paper = Control.new()
	_body.add_child(_paper)
	var page := TextureRect.new()
	page.texture = PAPER
	page.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	page.stretch_mode = TextureRect.STRETCH_SCALE
	page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	page.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_paper.add_child(page)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]: margin.add_theme_constant_override("margin_" + side, 30)
	for side in ["top", "bottom"]: margin.add_theme_constant_override("margin_" + side, 25)
	_paper.add_child(margin)
	_detail_scroll = ScrollContainer.new()
	_detail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_detail_scroll.follow_focus = true
	_detail_scroll.focus_mode = Control.FOCUS_ALL
	margin.add_child(_detail_scroll)
	_detail = VBoxContainer.new()
	_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail.add_theme_constant_override("separation", 12)
	_detail_scroll.add_child(_detail)

func _clear(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()

func open(camp) -> void:
	_camp = camp
	var ids: Array = Quests.in_log(camp)
	# Stable INFO order within each group.
	ids = ids.filter(func(id): return Quests.stage(camp, id) != Quests.Stage.RESOLVED) + ids.filter(func(id): return Quests.stage(camp, id) == Quests.Stage.RESOLVED)
	_clear(_list)
	_buttons.clear()
	var last_group := ""
	for id: String in ids:
		var done := Quests.stage(camp, id) == Quests.Stage.RESOLVED
		var group := "Completed" if done else "Open"
		if group != last_group:
			var section := text_label(group, 17, Kit.MUTED)
			_list.add_child(section)
			last_group = group
		var button := action_button("")
		button.toggle_mode = true
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.theme_type_variation = "ItemRow"
		var row := VBoxContainer.new()
		row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		row.offset_left = 12; row.offset_right = -12
		row.offset_top = 9; row.offset_bottom = -9
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(row)
		var title := text_label(Quests.INFO[id]["title"], 20, Kit.MUTED if done else Kit.TEXT)
		row.add_child(title)
		var meta := text_label("Floor %d" % Quests.INFO[id]["floor"], 16, Kit.MUTED)
		row.add_child(meta)
		button.custom_minimum_size.y = 78
		button.tooltip_text = Quests.INFO[id]["title"]
		button.accessibility_name = Quests.INFO[id]["title"]
		button.pressed.connect(select_quest.bind(id))
		_list.add_child(button)
		_buttons[id] = button
	if not ids.has(_selected_id): _selected_id = ids[0] if not ids.is_empty() else ""
	_detail_open = false
	_list_scroll.scroll_vertical = 0
	_draw_detail()
	begin_open()

func select_quest(id: String) -> void:
	if not _buttons.has(id): return
	_selected_id = id
	_detail_open = true
	_draw_detail()
	_layout_body()
	if _compact: _back.grab_focus.call_deferred()

func _draw_detail() -> void:
	_clear(_detail)
	_detail_scroll.scroll_vertical = 0
	for id in _buttons: _buttons[id].set_pressed_no_signal(id == _selected_id)
	if _selected_id.is_empty():
		_detail.add_child(text_label("No quests recorded.", 24, INK))
		return
	var info: Dictionary = Quests.INFO[_selected_id]
	var stage: int = Quests.stage(_camp, _selected_id)
	var status := "Completed" if stage == Quests.Stage.RESOLVED else ("Offered" if stage == Quests.Stage.OFFERED else "In progress")
	_detail.add_child(text_label(status + " · Floor %d" % info["floor"], 17, Color("65503b")))
	var heading := text_label(info["title"], 26, INK)
	heading.add_theme_font_override("font", Kit.HEADING)
	_detail.add_child(heading)
	if info["giver"] != "": _detail.add_child(text_label("From " + info["giver"], 18, Color("65503b")))
	_detail.add_child(text_label(Quests.next_step(_camp, _selected_id), 23, INK))

func _show_list() -> void:
	_detail_open = false
	_layout_body()
	if _buttons.has(_selected_id): _buttons[_selected_id].grab_focus.call_deferred()

func cancel() -> void:
	if _compact and _detail_open: _show_list()
	else: super.cancel()

func _layout_body() -> void:
	if not _list_scroll: return
	var was_compact := _compact
	_compact = _body.size.x < 650
	_back.visible = _compact and _detail_open
	_list_scroll.visible = not _compact or not _detail_open
	_paper.visible = not _compact or _detail_open
	if _compact:
		_list_scroll.position = Vector2.ZERO; _list_scroll.size = _body.size
		_paper.position = Vector2.ZERO; _paper.size = _body.size
	else:
		var width := clampf(_body.size.x * 0.34, 235, 350)
		_list_scroll.position = Vector2.ZERO
		_list_scroll.size = Vector2(width, _body.size.y)
		_paper.position = Vector2(width + 14, 0)
		_paper.size = Vector2(maxf(0, _body.size.x - width - 14), _body.size.y)
	if was_compact != _compact and is_visible_in_tree():
		if _compact and _detail_open: _back.grab_focus.call_deferred()
		elif _buttons.has(_selected_id): _buttons[_selected_id].grab_focus.call_deferred()
		else: _close.grab_focus.call_deferred()

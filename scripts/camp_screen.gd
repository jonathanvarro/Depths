extends Control
## The campsite (#40): ChatGPT's clearing (art/camp/cave-camp-v1) with six
## places to tap - merchant, nurse, cave path, your tent, apprentice smith
## and the recruitment fire. Each opens an activity view with Back. The
## rules live in camp_state.gd; this only shows them and passes choices on.
##
## Opening, looking and leaving cost nothing; anything that does (resting
## moves the day on) says so on its button first.

## The player chose to head back down (cave path).
signal cave_chosen

const DIR := "res://art/camp/cave-camp-v1/"
const HEADING := preload("res://art/fonts/heading-cinzel.tres")
const BODY := preload("res://art/fonts/body-source-sans.tres")
const ACTION := preload("res://art/fonts/action-source-sans.tres")
const TEXT := Color("e6dac1")
const MUTED := Color("b3a78f")
const AMBER := Color("dbb477")
const CANVAS := Vector2(640, 360)
## The apprentice's starter stock, shown until there's gold (#42).
const SMITH_STOCK := ["a plain knife", "a simple spear", "a woodcutter's axe", "a rough wooden shield"]

var content: Control  # main.gd keeps this inside the safe area

var _camp  # camp_state.gd
var _party  # party_state.gd
var _wanted := {}  # SupplyItem -> amount the merchant tops up to
var _canvas: Control
var _buttons := {}  # site id -> Button
var _sites := {}  # site id -> layout entry
var _day_label: Label
var _activity: Panel
var _activity_title: Label
var _portrait: TextureRect
var _scroll: ScrollContainer
var _body: VBoxContainer
var _back: Button
var _current := ""
var _last_site := ""


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var backdrop := ColorRect.new()
	backdrop.color = Color("101715")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	content = Control.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(content)
	_canvas = Control.new()
	_canvas.size = CANVAS
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(_canvas)
	var scenery := TextureRect.new()
	scenery.texture = load(DIR + "clearing.png")
	scenery.size = CANVAS
	scenery.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.add_child(scenery)
	var layout: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DIR + "layout.json"))
	for site in layout["sites"]:
		_add_site(site)
	var title := _label("Relief camp", HEADING, 18, TEXT)
	title.position = Vector2(20, 8)
	_canvas.add_child(title)
	_day_label = _label("", HEADING, 16, AMBER)
	_day_label.position = Vector2(560, 10)
	_day_label.size = Vector2(64, 24)
	_day_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_canvas.add_child(_day_label)
	_build_activity()
	content.resized.connect(_fit)
	visible = false


## Shows the clearing. `wanted` is what the merchant tops the pack up to.
func open(camp, party, wanted: Dictionary) -> void:
	_camp = camp
	_party = party
	_wanted = wanted
	visible = true
	_close_activity()
	_fit()
	_buttons["cave"].grab_focus.call_deferred()


func is_open(id: String) -> bool:
	return _current == id


func _add_site(site: Dictionary) -> void:
	var id: String = site["id"]
	_sites[id] = site
	var r: Array = site["rect"]
	var rect := Rect2(r[0], r[1], r[2], r[3])
	var art: Node2D = load(DIR + id + ".tscn").instantiate()
	art.position = Vector2(rect.get_center().x, rect.end.y - 24)
	art.scale = Vector2.ONE * float(site["scale"])
	_canvas.add_child(art)
	# The whole site and its label are one target (keyboard, mouse, touch).
	var button := Button.new()
	button.position = rect.position
	button.size = rect.size
	button.text = site["label"]
	button.add_theme_font_override("font", ACTION)
	button.add_theme_font_size_override("font_size", 14)
	button.add_theme_color_override("font_color", TEXT)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_focus_color", Color.WHITE)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0, 0, 0, 0)
	normal.content_margin_top = rect.size.y - 22
	button.add_theme_stylebox_override("normal", normal)
	for state in ["hover", "pressed", "focus"]:
		var highlight := normal.duplicate() as StyleBoxFlat
		highlight.bg_color = Color(0.7, 0.49, 0.22, 0.1)
		highlight.border_color = Color("bc9b60")
		highlight.set_border_width_all(1)
		button.add_theme_stylebox_override(state, highlight)
	var strip := ColorRect.new()  # a readable label strip over the dark scenery
	strip.color = Color(0.04, 0.06, 0.05, 0.86)
	strip.position = Vector2(4, rect.size.y - 21)
	strip.size = Vector2(rect.size.x - 8, 20)
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	strip.show_behind_parent = true
	button.add_child(strip)
	button.pressed.connect(open_activity.bind(id))
	_canvas.add_child(button)
	_buttons[id] = button


## Scales the 640 x 360 scene to fit the safe area, centred.
func _fit() -> void:
	var room := content.size
	if room.x <= 0.0 or room.y <= 0.0:
		return
	var ratio := minf(room.x / CANVAS.x, room.y / CANVAS.y)
	_canvas.scale = Vector2.ONE * ratio
	_canvas.position = (room - CANVAS * ratio) / 2.0


func _build_activity() -> void:
	_activity = Panel.new()
	_activity.position = Vector2(36, 24)
	_activity.size = Vector2(568, 316)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("1b2421")
	style.border_color = Color("938263")
	style.set_border_width_all(1)
	_activity.add_theme_stylebox_override("panel", style)
	_canvas.add_child(_activity)
	_activity_title = _label("", HEADING, 20, TEXT)
	_activity_title.position = Vector2(18, 10)
	_activity.add_child(_activity_title)
	_back = _button("Back to camp")
	_back.position = Vector2(420, 10)
	_back.size = Vector2(136, 30)
	_back.pressed.connect(_close_activity)
	_activity.add_child(_back)
	_portrait = TextureRect.new()
	_portrait.position = Vector2(10, 56)
	_portrait.size = Vector2(200, 200)
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_activity.add_child(_portrait)
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_activity.add_child(_scroll)
	_body = VBoxContainer.new()
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_theme_constant_override("separation", 8)
	_scroll.add_child(_body)
	_activity.visible = false


func open_activity(id: String) -> void:
	_current = id
	_last_site = id
	for button in _buttons.values():
		button.visible = false
	var site: Dictionary = _sites[id]
	_activity_title.text = site["label"]
	var npc: String = site["npc"]
	_portrait.texture = load(DIR + npc + ".png") if npc != "" else null
	var left := 222.0 if npc != "" else 18.0
	_scroll.position = Vector2(left, 50)
	_scroll.size = Vector2(_activity.size.x - left - 14, _activity.size.y - 62)
	_activity.visible = true
	_refresh_activity()
	_back.grab_focus()


func _close_activity() -> void:
	_current = ""
	_activity.visible = false
	for button in _buttons.values():
		button.visible = true
	_day_label.text = "Day %d" % _camp.day if _camp else ""
	if _buttons.has(_last_site) and visible:
		_buttons[_last_site].grab_focus.call_deferred()


func _refresh_activity() -> void:
	_day_label.text = "Day %d" % _camp.day
	for child in _body.get_children():
		_body.remove_child(child)
		child.queue_free()
	match _current:
		"supplies": _merchant()
		"smith": _smith()
		"treatment": _nurse()
		"rest": _tent()
		"fire": _fire()
		"cave": _cave_path()


func _merchant() -> void:
	_text("\"Short on supplies? I'll see you right. Pay me when there's coin to pay with.\"")
	if not _camp.can_restock():
		_text("He's already topped up your pack today. Come back tomorrow.", MUTED)
		return
	var missing: Dictionary = _camp.restock_preview(_party, _wanted)
	if missing.is_empty():
		_text("Your pack already holds everything he'd give you.", MUTED)
		return
	_text("He'll top up your pack: " + _list_items(missing) + ".", MUTED)
	var take := _button("Top up the pack (once a day)")
	take.pressed.connect(func():
		var given: Dictionary = _camp.restock(_party, _wanted)
		_refresh_activity()
		_text("Added " + _list_items(given) + ".", AMBER))
	_body.add_child(take)


func _smith() -> void:
	_text("The apprentice has little to show yet: %s." % ", ".join(PackedStringArray(SMITH_STOCK)))
	_text("Nothing is for sale until you can pay.", MUTED)


func _nurse() -> void:
	for hero: Companion in _party.living_members():
		if _camp.is_recovering(hero):
			_text("%s is resting here until day %d." % [hero.display_name, _camp.ready_on(hero)])
		elif hero.injuries.is_empty():
			_text("%s has no lasting injuries." % hero.display_name, MUTED)
		else:
			var names := ", ".join(PackedStringArray(hero.injuries.map(func(i: Injury): return i.display_name.to_lower())))
			var days: int = _camp.treatment_days(hero)
			_text("%s: %s. Untreated, %s can still go back in." % [hero.display_name, names, hero.display_name])
			var treat := _button("Treat %s (out of play %d day%s)" % [hero.display_name, days, "" if days == 1 else "s"])
			treat.pressed.connect(func():
				_camp.treat(hero)
				_refresh_activity())
			_body.add_child(treat)


func _tent() -> void:
	_text("Rest until tomorrow: everyone recovers fully. By morning the cave will have shifted.")
	var rest := _button("Rest until day %d" % (_camp.day + 1))
	rest.pressed.connect(func():
		_camp.rest(_party)
		_refresh_activity()
		_text("A night's rest. It's day %d." % _camp.day, AMBER))
	_body.add_child(rest)
	_body.add_child(_label("Stash", HEADING, 16, TEXT))
	_text("Stored items stay here, whatever happens down there.", MUTED)
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 12)
	_body.add_child(columns)
	var pack := _column(columns, "In your pack")
	var stash := _column(columns, "In the stash")
	for item: SupplyItem in _party.supplies.items:
		if _party.supplies.count(item) > 0:
			_row(pack, "%s ×%d" % [item.display_name, _party.supplies.count(item)], "Store", _camp.store.bind(_party, item))
	for item: Equipment in _party.supplies.gear:
		_row(pack, item.display_name, "Store", _camp.store_gear.bind(_party, item))
	for item: SupplyItem in _camp.stash.items:
		if _camp.stash.count(item) > 0:
			_row(stash, "%s ×%d" % [item.display_name, _camp.stash.count(item)], "Take", _camp.withdraw.bind(_party, item))
	for item: Equipment in _camp.stash.gear:
		_row(stash, item.display_name, "Take", _camp.withdraw_gear.bind(_party, item))
	if pack.get_child_count() == 1:
		pack.add_child(_label("Empty.", BODY, 12, MUTED))
	if stash.get_child_count() == 1:
		stash.add_child(_label("Empty.", BODY, 12, MUTED))


## Recruits by the fire (#41): who they are, their strength and weakness,
## and Invite; then the party, where recruits can be sent away.
func _fire() -> void:
	var full: bool = _party.free_slots() <= 0
	if _camp.candidates.is_empty():
		_text("No one is by the fire today.", MUTED)
	else:
		_text("Others who made it to the camp sit by the fire. Any of them would join you - for now, for nothing.")
	for recruit: Companion in _camp.candidates:
		_recruit_row(recruit, full)
	_body.add_child(_label("Your party", HEADING, 16, TEXT))
	if _party.members.is_empty():
		_text("No one. Invite someone to go down with you.", AMBER)
	for hero: Companion in _party.members:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var about := _label("%s · %s · %d/%d health" % [hero.display_name, hero.role, hero.health, hero.effective_max_health()], BODY, 12, TEXT)
		about.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(about)
		if hero.founder:
			row.add_child(_label("Stays", ACTION, 12, MUTED))
		else:
			var dismiss := _button("Dismiss")
			dismiss.pressed.connect(func():
				_camp.dismiss(_party, hero)
				_refresh_activity())
			row.add_child(dismiss)
		_body.add_child(row)


func _recruit_row(recruit: Companion, full: bool) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var face := TextureRect.new()
	face.texture = recruit.portrait
	face.custom_minimum_size = Vector2(56, 56)
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	face.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_child(face)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 0)
	info.add_child(_label("%s · %s" % [recruit.display_name, recruit.role], ACTION, 14, TEXT))
	var traits := _label("Strength: %s · Weakness: %s" % [recruit.strength, recruit.weakness], BODY, 11, AMBER)
	traits.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(traits)
	var damage := str(recruit.attack_min) if recruit.attack_min == recruit.attack_max else "%d-%d" % [recruit.attack_min, recruit.attack_max]
	var numbers := _label("%d health · %s damage · %d%% to hit · speed %d" % [recruit.max_health, damage, roundi(recruit.accuracy * 100), recruit.initiative], BODY, 11, MUTED)
	info.add_child(numbers)
	var about := _label(recruit.personality, BODY, 11, MUTED)
	about.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(about)
	row.add_child(info)
	var invite := _button("Party full" if full else "Invite")
	invite.disabled = full
	invite.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	invite.pressed.connect(func():
		_camp.hire(_party, recruit)
		_refresh_activity())
	row.add_child(invite)
	_body.add_child(row)


func _cave_path() -> void:
	var going: Array[Companion] = _camp.available(_party)
	for hero: Companion in _party.living_members():
		if _camp.is_recovering(hero):
			_text("%s is recovering with the nurse until day %d." % [hero.display_name, _camp.ready_on(hero)], MUTED)
		else:
			var hurt := " · untreated: " + ", ".join(PackedStringArray(hero.injuries.map(func(i: Injury): return i.display_name.to_lower()))) if not hero.injuries.is_empty() else ""
			_text("%s: %d/%d health%s" % [hero.display_name, hero.health, hero.effective_max_health(), hurt])
	if _party.members.is_empty():
		_text("Your party is gone. Find companions at the fire.", AMBER)
		return
	if going.is_empty():
		_text("No one is fit to go. Rest in your tent to pass the days.", AMBER)
		return
	var staying: int = _party.living_members().size() - going.size()
	if staying > 0:
		_text("Anyone still recovering stays with the nurse.", MUTED)
	var down := _button("Head back down")
	down.pressed.connect(func(): cave_chosen.emit())
	_body.add_child(down)


func _unhandled_input(event: InputEvent) -> void:
	if visible and _current != "" and event.is_action_pressed("ui_cancel"):
		_close_activity()
		get_viewport().set_input_as_handled()


func _column(parent: Control, heading: String) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 4)
	column.add_child(_label(heading, ACTION, 13, AMBER))
	parent.add_child(column)
	return column


func _row(column: VBoxContainer, text: String, action: String, on_press: Callable) -> void:
	var row := HBoxContainer.new()
	var name := _label(text, BODY, 12, TEXT)
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(name)
	var button := _button(action)
	button.custom_minimum_size = Vector2(52, 26)
	button.pressed.connect(func():
		on_press.call()
		_refresh_activity())
	row.add_child(button)
	column.add_child(row)


func _list_items(items: Dictionary) -> String:
	var parts := PackedStringArray()
	for item: SupplyItem in items:
		parts.append("%s ×%d" % [item.display_name.to_lower(), items[item]])
	return ", ".join(parts)


func _text(text: String, color := TEXT) -> void:
	var label := _label(text, BODY, 13, color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(_scroll.size.x - 8, 0)
	_body.add_child(label)


func _button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 30)
	button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	button.add_theme_font_override("font", ACTION)
	button.add_theme_font_size_override("font_size", 13)
	return button


func _label(text: String, font: Font, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

extends Control
## Plays a Conversation (#122, #123): the speaker's portrait and name, a
## page of lines, and reply buttons. Replies can move quests on (quests.gd).
## `play()` returns when the conversation ends.

signal _replied(reply)
signal finished

const Quests := preload("res://scripts/quests.gd")
const TEXT := Color("e8d9b0")
const PORTRAIT := Vector2(160, 160)

var _portrait: TextureRect
var _backdrop: TextureRect
var _name: Label
var _text: Label
var _replies: VBoxContainer
var _hero: Companion
var _camp


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	_backdrop = TextureRect.new()
	_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_backdrop.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_backdrop)
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.8)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(720, 0)
	center.add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	panel.add_child(row)
	_portrait = TextureRect.new()
	_portrait.custom_minimum_size = PORTRAIT
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_portrait.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_child(_portrait)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(column)
	_name = Label.new()
	_name.theme_type_variation = "PageTitle"
	_name.add_theme_font_size_override("font_size", 26)
	_name.add_theme_color_override("font_color", TEXT)
	column.add_child(_name)
	_text = Label.new()
	_text.add_theme_font_size_override("font_size", 20)
	_text.add_theme_color_override("font_color", TEXT)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.custom_minimum_size = Vector2(500, 0)
	column.add_child(_text)
	_replies = VBoxContainer.new()
	_replies.add_theme_constant_override("separation", 8)
	column.add_child(_replies)


## Plays `talk` to the end, applying replies to `camp`'s quests.
func play(talk: Conversation, hero: Companion, camp) -> void:
	_hero = hero
	_camp = camp
	_portrait.texture = talk.portrait
	_backdrop.texture = talk.backdrop
	_backdrop.visible = talk.backdrop != null
	_portrait.visible = talk.portrait != null
	_name.text = talk.speaker
	visible = true
	var page := 0
	while page >= 0 and page < talk.pages.size():
		var reply = await _show_page(talk.pages[page])
		page = reply.next if reply else -1
	visible = false
	_backdrop.texture = null
	finished.emit()


func _show_page(page: ConversationPage):
	_text.text = _fill(page.text)
	for child in _replies.get_children():
		_replies.remove_child(child)
		child.queue_free()
	var replies: Array = page.replies
	if replies.is_empty():
		replies = [null]  # just "Go on"
	var first: Button = null
	for reply in replies:
		var button := Button.new()
		button.text = _fill(reply.label) if reply else "Go on"
		button.custom_minimum_size = Vector2(0, 52)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(func(): _replied.emit(reply))
		_replies.add_child(button)
		if first == null:
			first = button
	first.grab_focus.call_deferred()  # keyboard: Enter picks the first reply
	var chosen = await _replied
	if chosen and chosen.quest != "":
		if chosen.stage >= 0:
			Quests.set_stage(_camp, chosen.quest, chosen.stage)
		if chosen.flag != "":
			Quests.set_flag(_camp, chosen.quest, chosen.flag)
	return chosen


## Fills in the main hero's name and pronouns.
func _fill(text: String) -> String:
	if _hero == null:
		return text
	var p := _hero.pronouns
	return text.replace("{hero}", _hero.display_name).replace("{They}", p[0].capitalize()) \
			.replace("{they}", p[0]).replace("{them}", p[1]).replace("{their}", p[2])


## Picks a reply by its label (for tests and the playtest bot).
func choose(label: String) -> bool:
	for button: Button in _replies.get_children():
		if button.text.begins_with(label):
			button.pressed.emit()
			return true
	return false

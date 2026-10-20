extends Control
## Plays a Conversation (#122, #123), at camp or down in the mine.
##
## Layout (owner, 2026-10-20):
## - The people you talk to stand large on the right, one or two of them.
##   Whoever is speaking is lit and slightly larger; the other dims.
## - Your party stays in the lower left, where their cards always are. Your
##   hero lights up when they speak or you choose a reply.
## - The world behind fades slightly while the conversation lasts and
##   returns when it ends.
## Replies can move quests on (quests.gd). `play()` returns at the end.

signal _replied(reply)
signal finished

const Quests := preload("res://scripts/quests.gd")
const TEXT := Color("e8d9b0")
const MUTED := Color(0.85, 0.8, 0.7, 0.75)
const GOLD := Color("f2c94c")
const NPC_SIZE := Vector2(240, 240)
const HERO_SIZE := Vector2(104, 148)  # covers a party card
const DIM := Color(0.42, 0.42, 0.42)
const FADE := 0.25

var _backdrop: TextureRect
var _shade: ColorRect
var _npcs: HBoxContainer  # one frame per person on the right
var _heroes: HBoxContainer  # the party, lower left
var _box: PanelContainer
var _name: Label  # who is speaking now
var _text: Label
var _replies: VBoxContainer
var _portrait: TextureRect  # the first person's portrait (kept for tools)
var _hero: Companion
var _camp
var _frames := {}  # "npc", "npc2", Companion -> frame


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
	_shade = ColorRect.new()
	_shade.color = Color(0, 0, 0, 0.0)
	_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_shade.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_shade)
	# The people you talk to: right side, above the text.
	_npcs = HBoxContainer.new()
	_npcs.add_theme_constant_override("separation", 16)
	_npcs.alignment = BoxContainer.ALIGNMENT_END
	_npcs.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_npcs.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_npcs.position = Vector2(-24, 40)
	_npcs.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_npcs)
	# Your party: lower left, where the cards sit.
	_heroes = HBoxContainer.new()
	_heroes.add_theme_constant_override("separation", 8)  # as the party cards
	_heroes.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	_heroes.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_heroes.position = Vector2(16, -16)  # over the party cards
	_heroes.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_heroes)
	# What's said, and the replies: along the bottom, right of the party.
	_box = PanelContainer.new()
	_box.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_box.offset_left = 380
	_box.offset_right = -24
	_box.offset_bottom = -18
	add_child(_box)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	_box.add_child(column)
	_name = Label.new()
	_name.theme_type_variation = "PageTitle"
	_name.add_theme_font_size_override("font_size", 24)
	_name.add_theme_color_override("font_color", TEXT)
	column.add_child(_name)
	_text = Label.new()
	_text.add_theme_font_size_override("font_size", 20)
	_text.add_theme_color_override("font_color", TEXT)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_text)
	_replies = VBoxContainer.new()
	_replies.add_theme_constant_override("separation", 8)
	column.add_child(_replies)
	_portrait = TextureRect.new()  # filled by play(); lives inside the first frame


## Plays `talk` to the end, applying replies to `camp`'s quests. `hero`
## is the player's main hero; `party` (optional) are all shown lower left.
func play(talk: Conversation, hero: Companion, camp, party: Array = []) -> void:
	_hero = hero
	_camp = camp
	_backdrop.texture = talk.backdrop
	_backdrop.visible = talk.backdrop != null
	_build_frames(talk, party if not party.is_empty() else ([hero] if hero else []))
	_shade.color.a = 0.0
	modulate.a = 0.0
	visible = true
	var fade := create_tween().set_parallel()
	fade.tween_property(self, "modulate:a", 1.0, FADE)
	fade.tween_property(_shade, "color:a", 0.45, FADE)  # the world fades, but stays
	var page := 0
	while page >= 0 and page < talk.pages.size():
		var reply = await _show_page(talk, talk.pages[page])
		page = reply.next if reply else -1
	var out := create_tween()
	out.tween_property(self, "modulate:a", 0.0, FADE)
	await out.finished
	visible = false
	_backdrop.texture = null
	finished.emit()


func _build_frames(talk: Conversation, party: Array) -> void:
	for box in [_npcs, _heroes]:
		for child in box.get_children():
			box.remove_child(child)
			child.queue_free()
	_frames.clear()
	if talk.portrait:
		_frames["npc"] = _frame(_npcs, talk.portrait, talk.speaker, NPC_SIZE)
	if talk.second_portrait:
		_frames["npc2"] = _frame(_npcs, talk.second_portrait, talk.second_speaker, NPC_SIZE)
	_portrait.texture = talk.portrait
	_portrait.visible = talk.portrait != null
	for member in party:
		if member is Companion:
			_frames[member] = _frame(_heroes, member.portrait, member.display_name, HERO_SIZE)


## A portrait with a name plate; lit or dimmed by _light().
func _frame(parent: Control, picture: Texture2D, label: String, size: Vector2) -> PanelContainer:
	var frame := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.045, 0.04, 0.92)
	style.border_color = Color(0.35, 0.27, 0.18, 0.9)
	style.set_border_width_all(2)
	style.set_content_margin_all(4)
	frame.add_theme_stylebox_override("panel", style)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 2)
	frame.add_child(column)
	var face := TextureRect.new()
	face.texture = picture
	face.custom_minimum_size = size
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	face.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	column.add_child(face)
	var name := Label.new()
	name.text = label
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name.add_theme_font_size_override("font_size", 16 if size.x < 200 else 18)
	name.add_theme_color_override("font_color", TEXT)
	column.add_child(name)
	parent.add_child(frame)
	return frame


## Lights whoever is speaking and dims everyone else. `who`: "npc", "npc2",
## a Companion, or "" (narration: the people on the right half-lit).
func _light(who) -> void:
	for key in _frames:
		var frame: PanelContainer = _frames[key]
		var lit: bool = typeof(key) == typeof(who) and key == who
		var dim_to: Color = Color(0.75, 0.75, 0.75) if who is String and who == "" and key is String else DIM
		var style := frame.get_theme_stylebox("panel") as StyleBoxFlat
		style.border_color = GOLD if lit else Color(0.35, 0.27, 0.18, 0.9)
		frame.pivot_offset = frame.size / 2.0
		var tween := frame.create_tween().set_parallel()
		tween.tween_property(frame, "modulate", Color.WHITE if lit else dim_to, 0.15)
		tween.tween_property(frame, "scale", Vector2(1.06, 1.06) if lit else Vector2.ONE, 0.15)


func _show_page(talk: Conversation, page: ConversationPage):
	var who = page.speaker
	match page.speaker:
		"npc":
			_name.text = talk.speaker
		"npc2":
			_name.text = talk.second_speaker
		"hero":
			who = _hero
			_name.text = _hero.display_name if _hero else ""
		_:
			who = ""
			_name.text = ""
	_name.visible = _name.text != ""
	_light(who)
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
		button.custom_minimum_size = Vector2(0, 50)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(func(): _replied.emit(reply))
		_replies.add_child(button)
		if first == null:
			first = button
	first.grab_focus.call_deferred()  # keyboard: Enter picks the first reply
	var chosen = await _replied
	if chosen and _hero and chosen.label.begins_with("\""):
		_light(_hero)  # your hero speaks the reply
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

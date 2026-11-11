extends Control
## Plays a Conversation (#122, #123), at camp or down in the mine.
##
## Layout (owner, 2026-10-20; restaged #228, 2026-11-03):
## - The people you talk to stand just right of centre, one or two of them.
##   Whoever is speaking is lit and slightly larger; the other dims.
## - What they say goes in a speech bubble left of centre, near the top,
##   pointing at them. Narration ("Soldiers stand...") has its own plain
##   caption there, with no tail and no name.
## - Your party stays in the lower left, where their cards always are. What
##   your hero says goes in a bubble near the bottom, pointing at them; it
##   stays on screen, greyed, while the other person answers.
## - Reply buttons are short summaries; the line actually spoken depends on
##   who you woke up as (ConversationReply.said_by).
## - The world behind fades slightly while the conversation lasts and
##   returns when it ends.
## Replies can move quests on (quests.gd). `play()` returns at the end.

signal _replied(reply)
signal _beat_done
signal finished

const Quests := preload("res://scripts/quests.gd")
const Settings := preload("res://scripts/settings.gd")
const PortraitView := preload("res://scripts/portrait_view.gd")
const TEXT := Color("e8d9b0")
const MUTED := Color(0.85, 0.8, 0.7, 0.75)
const GOLD := Color("f2c94c")
const NPC_SIZE := Vector2(240, 240)
const HERO_SIZE := Vector2(104, 148)  # covers a party card
const DIM := Color(0.42, 0.42, 0.42)
const GREYED := Color(0.6, 0.6, 0.6, 0.8)  # a line already said
const FADE := 0.25
const BUBBLE := Color(0.07, 0.06, 0.05, 0.94)
const BUBBLE_EDGE := Color(0.55, 0.43, 0.27, 0.95)
const CAPTION := Color(0.02, 0.02, 0.02, 0.78)  # narration: no border, no tail
const NPC_CENTRE := 0.66  # where the people stand, as a share of the width
const BUBBLE_LEFT := 0.06


## A speech bubble's tail: a small triangle on one side of the bubble,
## pointing at whoever speaks. `side` is "right" or "left".
class Tail extends Control:
	var side := "right"

	func _draw() -> void:
		var w := size.x
		var h := size.y
		var points: PackedVector2Array
		if side == "right":
			points = PackedVector2Array([Vector2(0, 0), Vector2(w, h * 0.5), Vector2(0, h)])
		else:
			points = PackedVector2Array([Vector2(w, 0), Vector2(0, h), Vector2(w, h * 0.6)])
		draw_colored_polygon(points, BUBBLE)
		draw_polyline(points, BUBBLE_EDGE, 2.0)


var _backdrop: TextureRect
var _shade: ColorRect
var _npcs: HBoxContainer  # one frame per person, right of centre
var _heroes: HBoxContainer  # the party, lower left
var _say: PanelContainer  # their speech bubble (or the narration caption)
var _say_style: StyleBoxFlat
var _say_tail: Tail
var _name: Label  # who is speaking in the top bubble
var _text: Label  # what they say (or the narration)
var _box: VBoxContainer  # the party's bubble and the replies, along the bottom
var _said: PanelContainer  # the party's speech bubble
var _said_tail: Tail
var _said_name: Label
var _said_text: Label
var _replies: VBoxContainer
var _portrait: TextureRect  # the first person's portrait (kept for tools)
var _hero: Companion
var _camp
var _talk: Conversation
var _frames := {}  # "npc", "npc2", Companion -> frame
## How long the hero's chosen line shows, lit, before the answer comes
## (seconds per character, from 0.8 s up to 2.5 s). A click or key skips it.
## Headless test runs skip it.
var reply_beat := 0.03
var _in_beat := false
## The vision tint (vision_filter.gd), set by main.gd: a Conversation with
## `vision` ticked plays inside it.
var vision: CanvasLayer


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	if "--script" in OS.get_cmdline_args():
		reply_beat = 0.0
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
	_shade.gui_input.connect(_on_shade_input)
	add_child(_shade)
	# The people you talk to: just right of centre, near the top.
	_npcs = HBoxContainer.new()
	_npcs.add_theme_constant_override("separation", 16)
	_npcs.alignment = BoxContainer.ALIGNMENT_CENTER
	_npcs.anchor_left = NPC_CENTRE
	_npcs.anchor_right = NPC_CENTRE
	_npcs.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_npcs.offset_top = 28
	_npcs.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_npcs.resized.connect(_place)
	add_child(_npcs)
	# Your party: lower left, where the cards sit.
	_heroes = HBoxContainer.new()
	_heroes.add_theme_constant_override("separation", 8)  # as the party cards
	_heroes.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	_heroes.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_heroes.position = Vector2(16, -16)  # over the party cards
	_heroes.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_heroes)
	# Their words: a bubble left of centre, near the top, pointing at them.
	_say = _bubble()
	_say_style = _say.get_theme_stylebox("panel")
	_say.position = Vector2(0, 40)
	add_child(_say)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	_say.add_child(column)
	_name = _bubble_label(20, GOLD)
	_name.theme_type_variation = "PageTitle"
	column.add_child(_name)
	_text = _bubble_label(20, TEXT)
	column.add_child(_text)
	_say_tail = Tail.new()
	_say_tail.side = "right"
	_say_tail.size = Vector2(22, 26)
	_say_tail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_say_tail.top_level = true  # not stretched by the bubble; fades with it
	_say.add_child(_say_tail)
	_say.item_rect_changed.connect(_place_tails)
	# Your party's words and the replies: along the bottom, right of the party.
	_box = VBoxContainer.new()
	_box.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_box.alignment = BoxContainer.ALIGNMENT_END
	_box.add_theme_constant_override("separation", 10)
	_box.offset_left = 392
	_box.offset_right = -24
	_box.offset_bottom = -18
	add_child(_box)
	_said = _bubble()
	_box.add_child(_said)
	var said_column := VBoxContainer.new()
	said_column.add_theme_constant_override("separation", 4)
	_said.add_child(said_column)
	_said_name = _bubble_label(18, GOLD)
	said_column.add_child(_said_name)
	_said_text = _bubble_label(19, TEXT)
	said_column.add_child(_said_text)
	_said_tail = Tail.new()
	_said_tail.side = "left"
	_said_tail.size = Vector2(22, 22)
	_said_tail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_said_tail.top_level = true
	_said.add_child(_said_tail)
	_said.item_rect_changed.connect(_place_tails)
	_replies = VBoxContainer.new()
	_replies.add_theme_constant_override("separation", 8)
	_box.add_child(_replies)
	_portrait = TextureRect.new()  # filled by play(); lives inside the first frame
	resized.connect(_place)


## _portrait is never added to the tree, so free it with the screen (#249).
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE and is_instance_valid(_portrait) and _portrait.get_parent() == null:
		_portrait.free()


func _bubble() -> PanelContainer:
	var bubble := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = BUBBLE
	style.border_color = BUBBLE_EDGE
	style.set_border_width_all(2)
	style.set_corner_radius_all(14)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 12
	style.content_margin_bottom = 14
	bubble.add_theme_stylebox_override("panel", style)
	bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bubble.visible = false
	return bubble


func _bubble_label(font_size: int, colour: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", colour)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


## Their bubble runs from the left margin to just short of the first
## portrait; narration uses the same place without the tail.
func _place() -> void:
	var width := size.x
	var left := width * BUBBLE_LEFT
	var npc_left := width * NPC_CENTRE
	if _npcs.get_child_count() > 0:
		npc_left = _npcs.position.x
	var bubble_width: float = maxf(npc_left - 34.0 - left, 260.0)
	_say.position.x = left
	_say.custom_minimum_size.x = bubble_width
	_say.size = Vector2(bubble_width, 0)  # shrinks to fit this page's words
	# ...again once the words have wrapped to this width (the first time a
	# bubble opens they measured themselves narrower, and taller).
	_say.set_deferred("size", Vector2(bubble_width, 0))
	_place_tails()


func _place_tails() -> void:
	var say := _say.get_global_rect()
	var said := _said.get_global_rect()
	_say_tail.global_position = Vector2(say.end.x - 2, say.position.y + 28)
	_said_tail.global_position = Vector2(said.position.x - 20, said.end.y - 30)


func _on_shade_input(event: InputEvent) -> void:
	if _in_beat and event is InputEventMouseButton and event.pressed:
		_beat_done.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and _in_beat and (event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel")):
		get_viewport().set_input_as_handled()
		_beat_done.emit()


## Plays `talk` to the end, applying replies to `camp`'s quests. `hero`
## is the player's main hero; `party` (optional) are all shown lower left.
func play(talk: Conversation, hero: Companion, camp, party: Array = []) -> void:
	_hero = hero
	_camp = camp
	_talk = talk
	_say.visible = false
	_said.visible = false
	_backdrop.texture = talk.backdrop
	_backdrop.visible = talk.backdrop != null
	_build_frames(talk, party if not party.is_empty() else ([hero] if hero else []))
	_shade.color.a = 0.0
	modulate.a = 0.0
	visible = true
	var fade := create_tween().set_parallel()
	fade.tween_property(self, "modulate:a", 1.0, FADE)
	fade.tween_property(_shade, "color:a", 0.45, FADE)  # the world fades, but stays
	var dreaming: bool = talk.vision and vision != null
	if dreaming:
		vision.enter(Settings.get_value("flashes"))  # a memory or a dream: the cold blue
	var page := 0
	while page >= 0 and page < talk.pages.size():
		var reply = await _show_page(talk, talk.pages[page])
		page = reply.next if reply else -1
	var out := create_tween()
	out.tween_property(self, "modulate:a", 0.0, FADE)
	await out.finished
	if dreaming:
		await vision.exit()  # back to the present
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
	frame.set_meta("face", face)
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
	var speaker_name := ""
	match page.speaker:
		"npc":
			speaker_name = talk.speaker
		"npc2":
			speaker_name = talk.second_speaker
		"hero":
			who = _hero
		_:
			who = ""
	var text: String = page.text_by.get(_hero.display_name, page.text) if _hero else page.text
	if page.speaker == "hero":
		_speak_hero(_fill(text))
		if _say.visible:
			_say.modulate = GREYED  # what they said before stays, greyed
	else:
		_name.text = speaker_name
		_name.visible = speaker_name != ""
		_text.text = _fill(text)
		var narration := speaker_name == ""
		_say_tail.visible = not narration
		_say_style.bg_color = CAPTION if narration else BUBBLE
		_say_style.border_color = Color(0, 0, 0, 0) if narration else BUBBLE_EDGE
		_text.add_theme_color_override("font_color", MUTED if narration else TEXT)
		_say.visible = true
		_say.modulate = Color.WHITE
		if _said.visible:
			_said.modulate = GREYED  # your last words stay on screen, greyed
		_place.call_deferred()
	_light(who)
	_show_expression(page)
	_clear_replies()
	var replies: Array = page.replies
	if replies.is_empty():
		replies = [null]  # just "Go on"
	var first: Button = null
	for reply in replies:
		var button := Button.new()
		button.text = _fill(reply.label) if reply else "Go on"
		if reply and reply.accepts != "" and Quests.INFO.has(reply.accepts):
			# Taking on a quest is marked, so it's a clear choice (#228).
			button.text += "   -   Accept: " + Quests.INFO[reply.accepts].title
			button.add_theme_color_override("font_color", GOLD)
			button.add_theme_color_override("font_focus_color", GOLD)
			button.add_theme_color_override("font_hover_color", GOLD)
		button.custom_minimum_size = Vector2(0, 46)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(func(): _replied.emit(reply))
		_replies.add_child(button)
		if first == null:
			first = button
	first.grab_focus.call_deferred()  # keyboard: Enter picks the first reply
	var chosen = await _replied
	_clear_replies()
	if chosen and chosen.quest != "":
		if chosen.stage >= 0:
			Quests.set_stage(_camp, chosen.quest, chosen.stage)
		if chosen.flag != "":
			Quests.set_flag(_camp, chosen.quest, chosen.flag)
	var line: String = chosen.spoken_by(_hero) if chosen else ""
	if line != "":
		# Your hero says it, in their own words; the other side waits.
		_speak_hero(_fill(line))
		if _say.visible:
			_say.modulate = GREYED
		_light(_hero)
		await _beat(line)
	return chosen


## Shows `text` in the party's bubble, lit, as your hero's words.
func _speak_hero(text: String) -> void:
	_said_name.text = _hero.display_name if _hero else ""
	_said_name.visible = _said_name.text != ""
	_said_text.text = text
	_said.visible = true
	_said.modulate = Color.WHITE
	_place_tails.call_deferred()


func _clear_replies() -> void:
	for child in _replies.get_children():
		_replies.remove_child(child)
		child.queue_free()


## A short pause so your hero's line can be read before the answer. A
## click, tap or key ends it early.
func _beat(line: String) -> void:
	if reply_beat <= 0.0:
		return
	_in_beat = true
	var timer := get_tree().create_timer(clampf(line.length() * reply_beat, 0.8, 2.5))
	timer.timeout.connect(func():
		if _in_beat:
			_beat_done.emit())
	await _beat_done
	_in_beat = false


## A page's animated expression for the first speaker (#166): the static
## picture gives way to a PortraitView that blinks, and talks for the line
## when she's the one speaking. A page without one shows the picture again.
func _show_expression(page: ConversationPage) -> void:
	var frame: PanelContainer = _frames.get("npc")
	if frame == null:
		return
	var face: TextureRect = frame.get_meta("face")
	var view: Control = frame.get_meta("view") if frame.has_meta("view") else null
	if page.expression == null:
		face.visible = true
		if view:
			view.visible = false
		return
	if view == null:
		view = PortraitView.new()
		view.custom_minimum_size = face.custom_minimum_size
		face.add_sibling(view)
		frame.set_meta("view", view)
	if view.portrait_set != page.expression:
		view.show_portrait(page.expression)
	face.visible = false
	view.visible = true
	if page.speaker == "npc":
		view.talk(clampf(page.text.length() * 0.035, 0.8, 4.0))


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

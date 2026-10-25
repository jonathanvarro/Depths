extends PanelContainer
## One hero's portrait card: animated portrait, name, health bar, and small
## condition icons. An empty party slot shows as a faint placeholder.
## Kept deliberately quiet: supplies and details live elsewhere (#10).

const PortraitView := preload("res://scripts/portrait_view.gd")
const Glyphs := preload("res://art/ui/backlog96-v1/glyphs.gd")
const StrainRules := preload("res://scripts/strain.gd")
## Exploration conditions (#64): nerves for strain, a ration for hunger.
const NERVES_ICON := preload("res://art/ui/visual105-v1/nerves.png")
const RATION := preload("res://data/items/ration.tres")
const Quality := preload("res://scripts/quality.gd")
## Boon (false) and bane (true) marks when a Boon has no icon of its own (#133).
const BOON_MARKS := {false: preload("res://art/ui/boons-v1/boon.png"), true: preload("res://art/ui/boons-v1/bane.png")}

const PORTRAIT_SIZE := Vector2(96, 96)
const ICON_SIZE := 14.0
const COLOR_HEALTH := Color("a8322a")
const COLOR_HEALTH_LOW := Color("e0542f")
const COLOR_HEALTH_BACK := Color(0.12, 0.08, 0.07)
const EMPTY_ALPHA := 0.35
const COLOR_STRAIN := Color("8e6bb8")
## Card border per strain state: calm to alarmed.
const STRAIN_BORDERS := {
	StrainRules.State.STEADY: Color(0.35, 0.27, 0.18, 0.9),
	StrainRules.State.UNEASY: Color("b0893a"),
	StrainRules.State.SHAKEN: Color("d0682a"),
	StrainRules.State.PANICKING: Color("e0332a"),
}

## Condition identities; registered 32px glyphs display at 14px.
enum Icon { HEALING, WOUNDED, DOWN, INJURY_WOUND, INJURY_LIMP, BLEEDING }

## Tapped or clicked (#64): the hero's conditions, in words, for touch.
signal tapped(card)

var companion: Companion
## What each condition icon means, in words (#64), built with the icons.
var explanations: Array[String] = []

var _portrait: Control
var _name: Label
var _bar: ProgressBar
var _health_text: Label
var _icons: HBoxContainer
var _last_health := -1
var _style: StyleBoxFlat
var _strain_bar: ProgressBar
var _turn_marker: ColorRect
var _row_label: Label
## Show the hero's combat row (only meaningful with company, #72).
var show_row := false
## Fight-only conditions from the combat screen (#105): [texture, tooltip].
var _marks: Array = []


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP  # a tap explains the icons (#64)
	var style := StyleBoxFlat.new()
	_style = style
	style.bg_color = Color(0.06, 0.05, 0.05, 0.8)
	style.border_color = Color(0.35, 0.27, 0.18, 0.9)
	style.set_border_width_all(1)
	style.set_content_margin_all(4)
	add_theme_stylebox_override("panel", style)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 2)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(column)

	_turn_marker = ColorRect.new()  # gold bar: this hero's turn in combat
	_turn_marker.color = Color("e8c25a")
	_turn_marker.custom_minimum_size = Vector2(0, 4)
	_turn_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_turn_marker.visible = false
	column.add_child(_turn_marker)

	var frame := Control.new()  # the portrait, with condition icons over it
	frame.custom_minimum_size = PORTRAIT_SIZE
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(frame)
	_portrait = PortraitView.new()
	_portrait.custom_minimum_size = PORTRAIT_SIZE
	_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST  # same pixel clusters at card size
	frame.add_child(_portrait)

	var name_row := HBoxContainer.new()
	name_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(name_row)
	_name = Label.new()
	_name.add_theme_font_size_override("font_size", 18)
	_name.add_theme_color_override("font_color", Color("e8d9b0"))
	_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name.clip_text = true
	name_row.add_child(_name)
	_row_label = Label.new()
	_row_label.add_theme_font_size_override("font_size", 12)
	_row_label.add_theme_color_override("font_color", Color("b3a78f"))
	_row_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_row.add_child(_row_label)
	# Condition icons sit along the portrait's bottom edge, so a few of them
	# don't squeeze the name (#64).
	_icons = HBoxContainer.new()
	_icons.add_theme_constant_override("separation", 2)
	_icons.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_icons.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_icons.offset_top = -ICON_SIZE - 3
	_icons.offset_bottom = -2
	_icons.offset_left = 3
	_icons.alignment = BoxContainer.ALIGNMENT_END
	frame.add_child(_icons)

	_bar = ProgressBar.new()
	_bar.show_percentage = false
	_bar.custom_minimum_size = Vector2(PORTRAIT_SIZE.x, 17)
	_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var back := StyleBoxFlat.new()
	back.bg_color = COLOR_HEALTH_BACK
	_bar.add_theme_stylebox_override("background", back)
	column.add_child(_bar)
	_strain_bar = ProgressBar.new()
	_strain_bar.show_percentage = false
	_strain_bar.max_value = StrainRules.MAX
	_strain_bar.custom_minimum_size = Vector2(PORTRAIT_SIZE.x, 5)
	_strain_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var strain_back := StyleBoxFlat.new()
	strain_back.bg_color = COLOR_HEALTH_BACK
	var strain_fill := StyleBoxFlat.new()
	strain_fill.bg_color = COLOR_STRAIN
	_strain_bar.add_theme_stylebox_override("background", strain_back)
	_strain_bar.add_theme_stylebox_override("fill", strain_fill)
	column.add_child(_strain_bar)
	_health_text = Label.new()
	_health_text.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_health_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_health_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_health_text.add_theme_font_size_override("font_size", 14)
	_health_text.add_theme_color_override("font_shadow_color", Color.BLACK)
	_bar.add_child(_health_text)


func show_companion(hero: Companion) -> void:
	if hero != companion:
		companion = hero
		_last_health = -1
		_portrait.show_portrait(hero.portrait_set, hero.portrait)
	modulate.a = 1.0
	refresh()


func set_active(active: bool) -> void:
	_turn_marker.visible = active


func show_empty() -> void:
	companion = null
	_portrait.show_portrait(null, null)
	_name.text = "—"
	_row_label.text = ""
	_bar.value = 0
	_strain_bar.value = 0
	_style.border_color = STRAIN_BORDERS[StrainRules.State.STEADY]
	_health_text.text = ""
	_clear_icons()
	modulate.a = EMPTY_ALPHA


## Updates bar and icons from the companion; flashes the portrait on damage.
func refresh() -> void:
	if companion == null:
		return
	_name.text = companion.display_name
	# Level, a mark when ready to advance at camp (#47), and the row (#72).
	var ready := "+" if companion.level < 4 and companion.xp >= [0, 0, 80, 220, 440][mini(companion.level + 1, 4)] and companion.uses_stats else ""
	_row_label.text = "L%d%s%s" % [companion.level, ready, (" " + ("back" if companion.row == "back" else "front")) if show_row else ""]
	var cap := companion.effective_max_health()  # lowered by untreated injuries
	_bar.max_value = cap
	_bar.value = companion.health
	_health_text.text = "%d/%d" % [companion.health, cap]
	var fill := StyleBoxFlat.new()
	var low := companion.health * 2 <= cap
	fill.bg_color = COLOR_HEALTH_LOW if low else COLOR_HEALTH
	_bar.add_theme_stylebox_override("fill", fill)
	if _last_health >= 0 and companion.health < _last_health:
		_portrait.hurt()
	_last_health = companion.health
	# Strain: border colour, a darker portrait, pallor when shaken, and a
	# tremor when panicking.
	var state := companion.strain_state()
	_strain_bar.value = companion.strain
	_style.border_color = STRAIN_BORDERS[state]
	_style.set_border_width_all(1 if state == StrainRules.State.STEADY else 2)
	var shade := lerpf(1.0, 0.7, companion.strain / StrainRules.MAX)
	_portrait.modulate = Color(0.45, 0.45, 0.45) if not companion.is_alive() else Color(shade, shade, shade)
	_portrait.set_animated(companion.is_alive())
	_portrait.set_condition("pallor", companion.is_alive() and state >= StrainRules.State.SHAKEN)
	for overlay in companion.appearance:
		_portrait.set_condition(overlay, true)
	_portrait.set_tremble(companion.is_alive() and state == StrainRules.State.PANICKING)
	tooltip_text = "%s: %s" % [companion.display_name, StrainRules.NAMES[state]]

	_clear_icons()
	explanations.clear()
	if companion.is_alive() and companion.bleeding:
		_add_icon(Icon.BLEEDING, false, "Bleeding: loses health while walking")
	if companion.is_unconscious():
		_add_icon(Icon.DOWN, false, "Unconscious: a draught or a rest revives them")
	elif not companion.is_alive():
		_add_icon(Icon.DOWN)
	elif low and not companion.bleeding:
		_add_icon(Icon.WOUNDED)
	if companion.is_alive() and not companion.pending_effects.is_empty():
		_add_icon(Icon.HEALING)
	for injury in companion.injuries:
		var is_dressed := injury in companion.dressed
		var kind := Icon.INJURY_LIMP if injury.icon_kind == "limp" else Icon.INJURY_WOUND
		_add_icon(kind, is_dressed, "%s%s: %s" % [injury.display_name, " (dressed)" if is_dressed else "", injury.description])
		# Portrait overlays, if the art provides them.
		_portrait.set_condition(injury.portrait_condition, not is_dressed)
		_portrait.set_condition(injury.dressed_portrait_condition, is_dressed)
	# Strain and hunger as icons with what they do and what helps (#64).
	if companion.is_alive() and state > StrainRules.State.STEADY:
		var effect := roundi(StrainRules.EFFECTIVENESS[state] * 100)
		_add_condition(NERVES_ICON, STRAIN_BORDERS[state], "%s: fights at %d%%. Light, food and rest calm them." % [StrainRules.NAMES[state], effect])
	if companion.is_alive() and companion.is_hungry():
		var starving := companion.hunger >= StrainRules.STARVING_AFTER
		_add_condition(RATION.icon, Color("e0542f") if starving else Color.WHITE, ("Starving" if starving else "Hungry") + ": nerves fray faster. Eat a ration.")
	# A worn trinket (#135), and its curse if it has one.
	if companion.trinket:
		_add_condition(companion.trinket.icon, Color.WHITE, "Wears the %s (%s): %s" % [companion.trinket.display_name.to_lower(), Quality.tier_of(companion.trinket, companion), companion.trinket.effect.effects_text()], Quality.tier_of(companion.trinket, companion))
		if companion.is_cursed():
			_add_condition(BOON_MARKS[true], Color.WHITE, "Cursed - %s: %s It won't come off until it's cleansed." % [companion.trinket.curse.display_name, companion.trinket.curse.description])
	var bad_gear := companion.cursed_gear()
	if bad_gear:  # cursed weapons and armour (2026-10-22)
		_add_condition(BOON_MARKS[true], Color.WHITE, "Cursed %s - %s: %s It won't come off until it's cleansed." % [bad_gear.display_name.to_lower(), bad_gear.curse.display_name, bad_gear.curse.description])
	# Boons and banes (#133): what they do and how long they last.
	for entry in companion.boons:
		var boon: Boon = entry["boon"]
		_add_condition(boon.icon if boon.icon else BOON_MARKS[boon.bane], Color.WHITE,
				"%s (%s): %s" % [boon.display_name, boon.duration_text(entry["fights_left"]), boon.description])
	for mark in _marks:
		var icon := TextureRect.new()
		icon.texture = mark[0]
		icon.tooltip_text = mark[1]
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_icons.add_child(icon)


## Fight conditions (webbed, venom, defending) shown with the other icons.
func set_marks(marks: Array) -> void:
	if marks == _marks:
		return
	_marks = marks
	refresh()


## `tier`: an item's quality, framed with its border (#135).
func _add_condition(texture: Texture2D, tint: Color, tooltip: String, tier := "") -> void:
	explanations.append(tooltip)
	if tier != "" and tier != "common":
		var framed := Quality.framed(texture, tier, Vector2(ICON_SIZE - 4, ICON_SIZE - 4))
		framed.tooltip_text = tooltip
		framed.mouse_filter = Control.MOUSE_FILTER_PASS
		_icons.add_child(framed)
		return
	var icon := TextureRect.new()
	icon.texture = texture
	icon.modulate = tint
	icon.tooltip_text = tooltip
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_PASS
	_icons.add_child(icon)


## Something got worse (#64): a big icon rises from the portrait and fades,
## and the card shakes a little, so the change is seen rather than read.
func alert(texture: Texture2D, tint := Color.WHITE) -> void:
	if texture == null:
		return
	var icon := TextureRect.new()
	icon.texture = texture
	icon.modulate = tint
	icon.top_level = true
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.size = Vector2(48, 48)
	icon.pivot_offset = icon.size / 2.0
	icon.global_position = global_position + Vector2(size.x / 2.0 - 24.0, 20.0)
	icon.scale = Vector2(0.4, 0.4)
	add_child(icon)
	var tween := icon.create_tween()
	tween.tween_property(icon, "scale", Vector2(1.2, 1.2), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(icon, "global_position:y", icon.global_position.y - 70.0, 1.1).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(icon, "modulate:a", 0.0, 0.5).set_delay(0.6)
	tween.tween_callback(icon.queue_free)
	var shake := create_tween()
	var home := _portrait.position
	for i in 4:
		shake.tween_property(_portrait, "position:x", home.x + (4.0 if i % 2 == 0 else -4.0), 0.04)
	shake.tween_property(_portrait, "position:x", home.x, 0.04)


## The card's conditions as one line (#64): what each icon means, and what
## helps. Hover shows them one at a time; this is the touch route.
func condition_words() -> String:
	if companion == null:
		return ""
	if not companion.is_alive():
		return "%s has fallen." % companion.display_name
	if explanations.is_empty():
		return "%s is steady and unhurt." % companion.display_name
	return "%s - %s" % [companion.display_name, "  ·  ".join(explanations)]


func _gui_input(event: InputEvent) -> void:
	if companion and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		tapped.emit(self)
		accept_event()


func _clear_icons() -> void:
	for child in _icons.get_children():
		child.queue_free()


func _add_icon(kind: Icon, dressed := false, tooltip := "") -> void:
	var icon := TextureRect.new()
	var id: String = ["healing","wounded","down","deep-wound","limp","bleeding"][kind]
	if kind==Icon.DOWN and companion and companion.is_unconscious():id="unconscious"
	icon.texture=Glyphs.STATUS[id]
	icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	icon.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.tooltip_text = tooltip if tooltip != "" else Icon.keys()[kind].capitalize()
	if tooltip != "":
		explanations.append(tooltip)
	_icons.add_child(icon)
	if dressed:
		var band := TextureRect.new()
		band.texture=Glyphs.STATUS["dressed-overlay"]
		band.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		band.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		band.mouse_filter=Control.MOUSE_FILTER_IGNORE
		icon.add_child(band)

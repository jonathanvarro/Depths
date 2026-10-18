extends PanelContainer
## One hero's portrait card: animated portrait, name, health bar, and small
## condition icons. An empty party slot shows as a faint placeholder.
## Kept deliberately quiet: supplies and details live elsewhere (#10).

const PortraitView := preload("res://scripts/portrait_view.gd")
const StrainRules := preload("res://scripts/strain.gd")

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

## Condition icons, drawn as simple shapes (placeholder art).
enum Icon { HEALING, WOUNDED, DOWN, INJURY_WOUND, INJURY_LIMP, BLEEDING }
const ICON_COLORS := {
	Icon.BLEEDING: Color("e0221a"),
	Icon.HEALING: Color("6fa35a"),
	Icon.WOUNDED: Color("c0392b"),
	Icon.DOWN: Color("9a9a9a"),
	Icon.INJURY_WOUND: Color("e04a3a"),
	Icon.INJURY_LIMP: Color("e0902f"),
}
const COLOR_DRESSING := Color("f2efe6")

var companion: Companion

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


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
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

	_portrait = PortraitView.new()
	_portrait.custom_minimum_size = PORTRAIT_SIZE
	_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR  # downscaled 192px art
	column.add_child(_portrait)

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
	_icons = HBoxContainer.new()
	_icons.add_theme_constant_override("separation", 2)
	_icons.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_row.add_child(_icons)

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
	_row_label.text = ("back" if companion.row == "back" else "front") if show_row else ""
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
	_portrait.set_condition("pallor", companion.is_alive() and state >= StrainRules.State.SHAKEN)
	for overlay in companion.appearance:
		_portrait.set_condition(overlay, true)
	_portrait.set_tremble(companion.is_alive() and state == StrainRules.State.PANICKING)
	tooltip_text = "%s: %s" % [companion.display_name, StrainRules.NAMES[state]]

	_clear_icons()
	if companion.is_alive() and companion.bleeding:
		_add_icon(Icon.BLEEDING, false, "Bleeding: loses health as she walks")
	if not companion.is_alive():
		_add_icon(Icon.DOWN)
	elif low and not companion.bleeding:
		_add_icon(Icon.WOUNDED)
	if companion.is_alive() and not companion.pending_effects.is_empty():
		_add_icon(Icon.HEALING)
	for injury in companion.injuries:
		var is_dressed := injury in companion.dressed
		var kind := Icon.INJURY_LIMP if injury.icon_kind == "limp" else Icon.INJURY_WOUND
		_add_icon(kind, is_dressed, injury.display_name + (" (dressed)" if is_dressed else ""))
		# Portrait overlays, if the art provides them.
		_portrait.set_condition(injury.portrait_condition, not is_dressed)
		_portrait.set_condition(injury.dressed_portrait_condition, is_dressed)


func _clear_icons() -> void:
	for child in _icons.get_children():
		child.queue_free()


func _add_icon(kind: Icon, dressed := false, tooltip := "") -> void:
	var icon := Control.new()
	icon.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.tooltip_text = tooltip if tooltip != "" else Icon.keys()[kind].capitalize()
	icon.draw.connect(_draw_icon.bind(icon, kind, dressed))
	_icons.add_child(icon)


func _draw_icon(icon: Control, kind: Icon, dressed := false) -> void:
	var c := icon.size / 2.0
	var r := ICON_SIZE / 2.0
	var color: Color = ICON_COLORS[kind]
	match kind:
		Icon.HEALING:  # plus sign
			icon.draw_rect(Rect2(c - Vector2(r * 0.3, r), Vector2(r * 0.6, r * 2)), color)
			icon.draw_rect(Rect2(c - Vector2(r, r * 0.3), Vector2(r * 2, r * 0.6)), color)
		Icon.WOUNDED:  # blood drop
			icon.draw_circle(c + Vector2(0, r * 0.3), r * 0.6, color)
			icon.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r), c + Vector2(r * 0.55, r * 0.15), c + Vector2(-r * 0.55, r * 0.15)]), color)
		Icon.BLEEDING:  # a drop with drips falling from it
			icon.draw_circle(c + Vector2(-r * 0.2, -r * 0.05), r * 0.5, color)
			icon.draw_colored_polygon(PackedVector2Array([c + Vector2(-r * 0.2, -r), c + Vector2(r * 0.27, -r * 0.2), c + Vector2(-r * 0.67, -r * 0.2)]), color)
			icon.draw_circle(c + Vector2(r * 0.55, r * 0.45), r * 0.2, color)
			icon.draw_circle(c + Vector2(-r * 0.2, r * 0.8), r * 0.18, color)
		Icon.DOWN:  # cross
			icon.draw_line(c - Vector2(r, r) * 0.8, c + Vector2(r, r) * 0.8, color, 2.5)
			icon.draw_line(c + Vector2(-r, r) * 0.8, c + Vector2(r, -r) * 0.8, color, 2.5)
		Icon.INJURY_WOUND:  # gash: two slanted cuts
			icon.draw_line(c + Vector2(-r, -r * 0.3), c + Vector2(r * 0.3, r), color, 2.5)
			icon.draw_line(c + Vector2(-r * 0.3, -r), c + Vector2(r, r * 0.3), color, 2.5)
		Icon.INJURY_LIMP:  # bent leg
			icon.draw_polyline(PackedVector2Array([c + Vector2(-r * 0.2, -r), c + Vector2(r * 0.3, 0), c + Vector2(-r * 0.4, r)]), color, 2.5)
	if dressed:  # a white band across the icon
		icon.draw_rect(Rect2(c - Vector2(r, r * 0.22), Vector2(r * 2, r * 0.44)), COLOR_DRESSING)

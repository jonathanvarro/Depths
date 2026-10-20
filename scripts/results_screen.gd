extends Control
## End-of-expedition results (#17, redesigned 2026-10-20): how it ended, the
## trip as icon-and-number chips (gold, enemies, finds, what it cost), and a
## row per hero - health, experience, a level-up mark, nerves and new
## injuries - in place of the old text ledger. Also shows short story cards
## (show_brief).

signal continue_pressed

const Expedition := preload("res://scripts/expedition.gd")
const Progression := preload("res://scripts/progression.gd")
const Glyphs := preload("res://art/ui/backlog96-v1/glyphs.gd")
const COLOR_TEXT := Color("e8d9b0")
const COLOR_DIM_TEXT := Color(0.85, 0.8, 0.7, 0.85)
const COLOR_LOSS := Color("e28c7c")
const COLOR_GAIN := Color("bfe3a8")
const COLOR_AMBER := Color("f2c94c")
## Placeholder backdrop until ChatGPT's cave-mouth illustration lands.
const BACKDROP := preload("res://art/title/title-v1/background.png")
const ICONS := {
	"gold": preload("res://art/ui/coin-v1/heads.png"),
	"enemies": preload("res://art/ui/backlog96-v1/map/danger.png"),
	"events": preload("res://art/ui/backlog96-v1/map/object.png"),
	"deepest": preload("res://art/ui/backlog96-v1/map/down.png"),
	"health": preload("res://art/ui/visual105-v1/heart.png"),
	"nerves": preload("res://art/ui/visual105-v1/nerves.png"),
	"oil": preload("res://data/items/oil_flask.tres"),
}

## The minimap's glyphs (dark ink for parchment), lightened on this screen.
var MAP_GLYPHS: Array = [ICONS["enemies"], ICONS["events"], ICONS["deepest"]]

var content: MarginContainer  # main.gd keeps this inside the safe area

var _title: Label
var _subtitle: Label
var _button: Button
var _illustration: TextureRect
var _backdrop: TextureRect
var _tint: ColorRect
var _ledger: VBoxContainer  # chips and hero rows
var _chips: HFlowContainer
var _heroes: VBoxContainer


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.02, 0.02, 1.0)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	_backdrop = TextureRect.new()
	_backdrop.texture = BACKDROP
	_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_backdrop.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_backdrop)
	_tint = ColorRect.new()  # darkens the backdrop; warm or blood-dark by ending
	_tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_tint)
	content = MarginContainer.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "top", "right", "bottom"]:
		content.add_theme_constant_override("margin_" + side, 32)
	add_child(content)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	content.add_child(column)
	_title = _label(34, COLOR_TEXT)
	_title.theme_type_variation = "PageTitle"  # Cinzel heading (#51)
	column.add_child(_title)
	_subtitle = _label(20, COLOR_DIM_TEXT)
	_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_subtitle)
	_illustration = TextureRect.new()
	_illustration.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_illustration.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_illustration.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_illustration.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_illustration.custom_minimum_size = Vector2(0, 120)
	_illustration.visible = false
	column.add_child(_illustration)
	_ledger = VBoxContainer.new()
	_ledger.add_theme_constant_override("separation", 16)
	_ledger.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(_ledger)
	_chips = HFlowContainer.new()
	_chips.add_theme_constant_override("h_separation", 10)
	_chips.add_theme_constant_override("v_separation", 8)
	_ledger.add_child(_chips)
	_heroes = VBoxContainer.new()
	_heroes.add_theme_constant_override("separation", 8)
	_ledger.add_child(_heroes)
	_button = Button.new()
	_button.custom_minimum_size = Vector2(260, 60)
	_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	_button.focus_mode = Control.FOCUS_NONE
	_button.add_theme_font_size_override("font_size", 22)
	_button.pressed.connect(func(): continue_pressed.emit())
	column.add_child(_button)
	visible = false


## `quotes`: Companion -> a line they say on getting back (#118).
func show_results(ending: int, expedition, party, note: String, quotes := {}) -> void:
	_illustration.visible = false
	_ledger.visible = true
	_backdrop.visible = true
	var wiped := ending == Expedition.Ending.WIPED
	_tint.color = Color(0.12, 0.01, 0.01, 0.86) if wiped else Color(0.05, 0.04, 0.03, 0.8)
	_title.text = Expedition.TITLES[ending]
	var s: Dictionary = expedition.summary(party)
	_subtitle.text = "Expedition %d · %s" % [expedition.number, note]
	_clear(_chips)
	_clear(_heroes)
	# What the trip brought...
	if s["gold"] > 0:
		_chip(_chips, ICONS["gold"], "+%d" % s["gold"], true)
	if s["deepest"] > 0:
		_chip(_chips, ICONS["deepest"], "Floor %d" % s["deepest"], true)
	if s["enemies"] > 0:
		_chip(_chips, ICONS["enemies"], "×%d" % s["enemies"], true)
	if s["events"] > 0:
		_chip(_chips, ICONS["events"], "×%d" % s["events"], true)
	for item: SupplyItem in s["found"]:
		_chip(_chips, item.icon, "×%d" % s["found"][item], true)
	# ...and what it cost.
	for item: SupplyItem in s["used"]:
		_chip(_chips, item.icon, "−%d" % s["used"][item], false)
	if s["oil"] > 0:
		_chip(_chips, ICONS["oil"].icon, "−%d oil" % s["oil"], false)
	if s["retreats"] > 0:
		_chip(_chips, null, "Fled ×%d" % s["retreats"], false)
	for row in expedition.hero_rows(party):
		_heroes.add_child(_hero_row(row, quotes.get(row["hero"], "")))
	_button.text = "Begin again" if wiped else "To camp"
	visible = true


## A short ending with no tallies (the opening: "Barely survived", #56).
func show_brief(title: String, note: String, button: String, illustration: Texture2D=null) -> void:
	_illustration.texture = illustration
	_illustration.visible = illustration != null
	_ledger.visible = false
	_backdrop.visible = false
	_tint.color = Color(0, 0, 0, 0)
	_title.text = title
	_subtitle.text = note
	_button.text = button
	visible = true


## One hero: portrait, name, health, experience (with a level-up mark),
## nerves and new injuries - or that they didn't come back - and what
## they say about it.
func _hero_row(row: Dictionary, quote := "") -> Control:
	var hero: Companion = row["hero"]
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 10)
	var face := TextureRect.new()
	face.texture = hero.portrait
	face.custom_minimum_size = Vector2(56, 56)
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	face.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	line.add_child(face)
	var name := _label(20, COLOR_TEXT, hero.display_name)
	name.custom_minimum_size = Vector2(140, 0)
	name.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	line.add_child(name)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	line.add_child(column)
	var chips := HFlowContainer.new()
	chips.add_theme_constant_override("h_separation", 8)
	column.add_child(chips)
	if quote != "":
		var said := _label(18, COLOR_DIM_TEXT, "“%s”" % quote)
		said.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		column.add_child(said)
	if not row["back"]:
		face.modulate = Color(0.4, 0.3, 0.3)
		_chip(chips, Glyphs.STATUS["down"], "Did not come back", false)
		return line
	var change: int = row["health"] - row["health_from"]
	_chip(chips, ICONS["health"], "%d/%d" % [row["health"], hero.effective_max_health()] + ("  %+d" % change if change != 0 else ""), change >= 0)
	var xp: int = row["xp"] - row["xp_from"]
	if xp > 0:
		_chip(chips, null, "+%d XP" % xp, true)
	if Progression.ready_to_advance(hero):
		_chip(chips, null, "Level up at camp", true, COLOR_AMBER)
	var nerves: float = row["strain"] - row["strain_from"]
	if absf(nerves) >= 5.0:
		_chip(chips, ICONS["nerves"], "calmer" if nerves < 0 else "shaken", nerves < 0)
	for injury: Injury in row["new_injuries"]:
		_chip(chips, Glyphs.STATUS["limp" if injury.icon_kind == "limp" else "deep-wound"], injury.display_name, false)
	return line


## An icon and a number: green-edged for gains, red for losses.
func _chip(parent: Control, icon: Texture2D, text: String, good: bool, colour := Color(0, 0, 0, 0)) -> void:
	var chip := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.07, 0.06, 0.9)
	style.border_color = colour if colour.a > 0 else (Color("6fae5a") if good else Color("b5463a"))
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(4)
	style.content_margin_left = 6
	style.content_margin_right = 8
	chip.add_theme_stylebox_override("panel", style)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	chip.add_child(row)
	if icon:
		var picture := TextureRect.new()
		picture.texture = icon
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		picture.custom_minimum_size = Vector2(28, 28)
		if icon in MAP_GLYPHS:
			picture.material = _light_ink()  # map glyphs are drawn dark, for parchment
		row.add_child(picture)
	var label := _label(19, colour if colour.a > 0 else (COLOR_GAIN if good else COLOR_LOSS), text)
	label.size_flags_vertical = Control.SIZE_FILL
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(label)
	parent.add_child(chip)


var _ink: ShaderMaterial


## Paints a dark-ink glyph in the screen's light text colour, keeping its shape.
func _light_ink() -> ShaderMaterial:
	if _ink == null:
		_ink = ShaderMaterial.new()
		_ink.shader = Shader.new()
		_ink.shader.code = "shader_type canvas_item;
void fragment() { COLOR = vec4(0.89, 0.83, 0.68, texture(TEXTURE, UV).a); }"
	return _ink


func _clear(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()


func _label(size: int, color: Color, text := "") -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label

extends Control
## Title screen (#18), following ChatGPT's title study and typography
## proposal (docs/title-screen-and-typography.md, art/title/title-v1/).
## "Depths" is the working title.

const SafeArea := preload("res://scripts/safe_area.gd")
const DISPLAY := preload("res://art/fonts/title-cinzel.tres")
const ACTION := preload("res://art/fonts/action-source-sans.tres")
const BODY := preload("res://art/fonts/body-source-sans.tres")
const TEXT := Color("e6dac1")
const MUTED := Color("b3a78f")
const AMBER := Color("dbb477")
const GAME_SCENE := "res://scenes/main.tscn"

## Preview the iPhone layout (notch margins, no Quit) on Windows.
@export var simulate_phone := false

var _margin: MarginContainer
var _begin: Button
var _settings_screen: Control
var _hero_select: Control  # hero_select.gd (#95)


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var music := preload("res://scripts/music.gd").new()  # #54
	add_child(music)
	music.play.call_deferred("title")
	var phone := simulate_phone or OS.has_feature("mobile")

	var backdrop := TextureRect.new()
	backdrop.texture = preload("res://art/title/title-v1/background.png")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(backdrop)

	_margin = MarginContainer.new()
	_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_margin)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	column.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	column.add_theme_constant_override("separation", 12 if phone else 18)
	_margin.add_child(column)

	var title := Label.new()
	title.text = "DEPTHS"
	title.add_theme_font_override("font", DISPLAY)
	title.add_theme_font_size_override("font_size", 78 if phone else 96)
	title.add_theme_color_override("font_color", TEXT)
	column.add_child(title)
	var rule := ColorRect.new()
	rule.color = Color("806a48")
	rule.custom_minimum_size = Vector2(300, 1)
	column.add_child(rule)
	var gap := Control.new()
	gap.custom_minimum_size.y = 18 if phone else 26
	column.add_child(gap)

	# Continue a saved game (#45); a new game replaces the save.
	var SaveGame := preload("res://scripts/save_game.gd")
	var has_save: bool = SaveGame.exists()
	if has_save:
		var resume := _menu_button("Continue", 72 if phone else 56, true)
		resume.pressed.connect(func():
			SaveGame.set_continue_requested(true)
			get_tree().change_scene_to_file(GAME_SCENE))
		column.add_child(resume)
	_begin = _menu_button("New game (replaces your save)" if has_save else "Begin expedition", 72 if phone else 56, not has_save)
	# A new game starts by choosing who wakes in the dark (#95).
	_begin.pressed.connect(func(): _hero_select.open())
	column.add_child(_begin)
	var settings := _menu_button("Settings", 72 if phone else 56, false)
	settings.pressed.connect(func(): _settings_screen.open())
	column.add_child(settings)
	if not phone and not OS.has_feature("web"):  # iPhone apps and web pages don't quit themselves
		var quit := _menu_button("Quit", 56, false)
		quit.pressed.connect(func(): get_tree().quit())
		column.add_child(quit)

	# Settings (#52): applied before anything plays; the screen sits on top.
	var Settings := preload("res://scripts/settings.gd")
	Settings.apply(get_tree())
	_settings_screen = preload("res://scripts/settings_screen.gd").new()
	add_child(_settings_screen)
	_hero_select = preload("res://scripts/hero_select.gd").new()
	_hero_select.simulate_phone_safe_area=simulate_phone
	add_child(_hero_select)
	_hero_select.chosen.connect(_start_new_game)
	_apply_margins()
	get_viewport().size_changed.connect(_apply_margins)
	_begin.grab_focus()
	# For checking exported builds: `Depths.exe -- --begin` skips the title.
	if "--begin" in OS.get_cmdline_user_args():
		_start_new_game.call_deferred(_hero_select.HEROES[0])


func _apply_margins() -> void:
	var phone := simulate_phone or OS.has_feature("mobile")
	var insets := SafeArea.insets(get_viewport(), simulate_phone)
	_margin.add_theme_constant_override("margin_left", int(maxf(100.0 if phone else 88.0, insets.x + 24)))
	_margin.add_theme_constant_override("margin_right", int(maxf(64.0, insets.z + 24)))
	_margin.add_theme_constant_override("margin_top", 56 if phone else 128)
	_margin.add_theme_constant_override("margin_bottom", int(maxf(40.0, insets.w + 16)))


func _menu_button(text: String, height: int, primary: bool) -> Button:
	var button := Button.new()
	button.text = text
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size = Vector2(310, height)
	button.add_theme_font_override("font", ACTION)
	button.add_theme_font_size_override("font_size", 26)
	button.add_theme_color_override("font_color", AMBER if primary else TEXT)
	button.add_theme_color_override("font_hover_color", AMBER)
	button.add_theme_color_override("font_focus_color", AMBER)
	button.add_theme_color_override("font_disabled_color", Color(MUTED, 0.5))
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.06, 0.07, 0.06, 0.65)
	normal.border_color = Color("493f2d")
	normal.set_border_width(SIDE_BOTTOM, 1)
	normal.content_margin_left = 14
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("disabled", normal)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("29291e")
	hover.border_color = AMBER
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color(0, 0, 0, 0)
	focus.border_color = AMBER
	focus.set_border_width_all(2)
	button.add_theme_stylebox_override("focus", focus)
	return button


## A new game as `hero_path`: the old save goes, the chosen hero wakes.
func _start_new_game(hero_path: String) -> void:
	var SaveGame := preload("res://scripts/save_game.gd")
	SaveGame.delete()
	SaveGame.set_new_game_hero(hero_path)
	get_tree().change_scene_to_file(GAME_SCENE)

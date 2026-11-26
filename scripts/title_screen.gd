extends Control
## Title screen (#18), following ChatGPT's title study and typography
## proposal (docs/title-screen-and-typography.md, art/title/title-v1/).
## "Depths" is the working title.

const SafeArea := preload("res://scripts/safe_area.gd")
const UiTheme := preload("res://scripts/ui_theme.gd")
const DISPLAY := preload("res://art/fonts/title-cinzel.tres")
const ACTION := preload("res://art/fonts/action-source-sans.tres")
const BODY := preload("res://art/fonts/body-source-sans.tres")
const TEXT := Color("e6dac1")
const MUTED := Color("b7ab93")
const AMBER := Color("d7b174")
const GAME_SCENE := "res://scenes/main.tscn"

## Preview the iPhone layout (notch margins, no Quit) on Windows.
@export var simulate_phone := false

var _margin: MarginContainer
var _column: VBoxContainer
var _begin: Button
var _settings_screen: Control
var _hero_select: Control  # hero_select.gd (#95)
var _skip := false  # the hero screen was opened by "Skip the tutorial"


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
	var menu_scroll := ScrollContainer.new()
	menu_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	menu_scroll.follow_focus = true
	_margin.add_child(menu_scroll)
	var column := VBoxContainer.new()
	_column = column
	column.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	column.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	column.add_theme_constant_override("separation", 12 if phone else 18)
	menu_scroll.add_child(column)

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
	_begin.pressed.connect(func():
		_skip = false
		_hero_select.open())
	column.add_child(_begin)
	# Straight to camp, the opening escape taken as done (owner, 2026-11-21).
	var skip := _menu_button("Skip the tutorial", 72 if phone else 56, false)
	skip.pressed.connect(func():
		_skip = true
		_hero_select.open())
	column.add_child(skip)
	var settings := _menu_button("Settings", 72 if phone else 56, false)
	settings.pressed.connect(func():
		settings.grab_focus()
		_settings_screen.open())
	column.add_child(settings)
	if not phone and not OS.has_feature("web"):  # iPhone apps and web pages don't quit themselves
		var quit := _menu_button("Quit", 56, false)
		quit.pressed.connect(func(): get_tree().quit())
		column.add_child(quit)

	# Settings (#52): applied before anything plays; the screen sits on top.
	var Settings := preload("res://scripts/settings.gd")
	Settings.apply(get_tree())
	_settings_screen = preload("res://scripts/settings_screen.gd").new()
	var settings_layer := CanvasLayer.new()
	settings_layer.layer = 7
	add_child(settings_layer)
	settings_layer.add_child(_settings_screen)
	_hero_select = preload("res://scripts/hero_select.gd").new()
	_hero_select.simulate_phone_safe_area=simulate_phone
	add_child(_hero_select)
	_hero_select.chosen.connect(_start_new_game)
	_apply_margins()
	get_viewport().size_changed.connect(_apply_margins)
	_begin.grab_focus()
	# For checking exported builds: `Depths.exe -- --begin` skips the title;
	# `-- --continue` continues the save (with --save=<file>, a copy).
	if "--continue" in OS.get_cmdline_user_args() and has_save:
		SaveGame.set_continue_requested(true)
		get_tree().change_scene_to_file.call_deferred(GAME_SCENE)
	elif "--begin" in OS.get_cmdline_user_args():
		_start_new_game.call_deferred(_hero_select.HEROES[0])


func _apply_margins() -> void:
	var phone := simulate_phone or OS.has_feature("mobile")
	var insets := SafeArea.insets(get_viewport(), simulate_phone)
	if _settings_screen: _settings_screen.set_safe_area(insets)
	_margin.add_theme_constant_override("margin_left", int(maxf(100.0 if phone else 88.0, insets.x + 24)))
	_margin.add_theme_constant_override("margin_right", int(maxf(64.0, insets.z + 24)))
	var bottom := int(maxf(40.0 if not phone else 24.0, insets.w + 16))
	_margin.add_theme_constant_override("margin_bottom", bottom)
	# Every button stays on screen (owner, 2026-11-21: Quit fell off the
	# bottom of a short window): the top margin gives way first, then the
	# gaps between buttons.
	var height := get_viewport().get_visible_rect().size.y
	var top := 56 if phone else 128
	var gap := 12 if phone else 18
	_column.add_theme_constant_override("separation", gap)
	var needed := _column.get_combined_minimum_size().y
	var spare := height - bottom - needed
	if spare < top:
		top = maxi(16, int(spare))
		if spare < 16:
			var count := maxi(1, _column.get_child_count() - 1)
			gap = maxi(4, gap - int(ceil((16 - spare) / count)))
			_column.add_theme_constant_override("separation", gap)
	_margin.add_theme_constant_override("margin_top", top)


func _menu_button(text: String, height: int, primary: bool) -> Button:
	var button := Button.new()
	button.text = text
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size = Vector2(310, height)
	button.add_theme_font_override("font", UiTheme.FieldKit.HEADING)
	button.add_theme_font_size_override("font_size", 26)
	button.add_theme_color_override("font_color", AMBER if primary else TEXT)
	button.add_theme_color_override("font_hover_color", AMBER)
	button.add_theme_color_override("font_focus_color", AMBER)
	button.add_theme_color_override("font_disabled_color", Color(MUTED, 0.5))
	UiTheme.Brass.apply(button, UiTheme.Brass.Edge.LEFT, 14)
	return button


## A new game as `hero_path`: the old save goes, the chosen hero wakes.
func _start_new_game(hero_path: String) -> void:
	var SaveGame := preload("res://scripts/save_game.gd")
	SaveGame.delete()
	SaveGame.set_new_game_hero(hero_path)
	SaveGame.set_skip_opening(_skip)
	get_tree().change_scene_to_file(GAME_SCENE)

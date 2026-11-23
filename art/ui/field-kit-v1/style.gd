extends RefCounted
## Shared Field kit palette/type with owner-approved Reliquary brass controls.
const Brass := preload("res://art/ui/reliquary-brass-v1/style.gd")
const BODY := preload("res://art/fonts/body-source-sans.tres")
const ACTION := preload("res://art/fonts/action-source-sans.tres")
const HEADING := preload("res://art/fonts/heading-cinzel.tres")
const TEXT := Color("e6dac1")
const MUTED := Color("b7ab93")
const AMBER := Color("d7b174")
const SURFACE := Color("22231d")
const EDGE := Color("66543c")

static func plate(color: Color, edge: Color = EDGE, padding := 16) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = edge
	box.set_border_width_all(1)
	box.content_margin_left = padding
	box.content_margin_right = padding
	box.content_margin_top = padding
	box.content_margin_bottom = padding
	return box

static func make_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font = BODY
	theme.default_font_size = 22
	theme.set_color("font_color","Label",TEXT)
	theme.set_type_variation("PageTitle","Label")
	theme.set_font("font","PageTitle",HEADING)
	theme.set_font_size("font_size","PageTitle",34)
	theme.set_type_variation("ItemTitle","Label")
	theme.set_font("font","ItemTitle",HEADING)
	theme.set_font_size("font_size","ItemTitle",28)
	theme.set_type_variation("SecondaryText","Label")
	theme.set_color("font_color","SecondaryText",MUTED)
	theme.set_font_size("font_size","SecondaryText",20)
	theme.set_type_variation("Emphasis","Label")
	theme.set_font("font","Emphasis",ACTION)
	theme.set_color("font_color","Emphasis",AMBER)
	theme.set_font("font","Button",HEADING)
	theme.set_font_size("font_size","Button",24)
	theme.set_color("font_color","Button",TEXT)
	theme.set_color("font_hover_color","Button",TEXT)
	theme.set_color("font_focus_color","Button",TEXT)
	theme.set_color("font_disabled_color","Button",Color("9e9685"))
	for state in Brass.STATES:
		theme.set_stylebox(state,"Button",Brass.frame(state,Brass.Edge.CENTRE,12))
	theme.set_color("font_pressed_color","Button",AMBER)
	theme.set_color("font_hover_pressed_color","Button",AMBER)
	theme.set_type_variation("ItemRow","Button")
	for state in Brass.STATES:
		theme.set_stylebox(state,"ItemRow",Brass.frame(state,Brass.Edge.CENTRE,12))
	theme.set_type_variation("PrimaryAction","Button")
	for state in Brass.STATES:
		theme.set_stylebox(state,"PrimaryAction",Brass.frame("hover" if state=="normal" else state,Brass.Edge.CENTRE,12))
	theme.set_color("font_color","PrimaryAction",AMBER)
	theme.set_color("font_hover_color","PrimaryAction",TEXT)
	theme.set_color("font_focus_color","PrimaryAction",TEXT)
	return theme

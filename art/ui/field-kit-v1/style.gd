extends RefCounted
## Reusable visual proposal for #39. Not installed as the project's theme.
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
	theme.set_font("font","Button",ACTION)
	theme.set_font_size("font_size","Button",24)
	theme.set_color("font_color","Button",TEXT)
	theme.set_color("font_hover_color","Button",TEXT)
	theme.set_color("font_focus_color","Button",TEXT)
	theme.set_color("font_disabled_color","Button",Color("9e9685"))
	theme.set_stylebox("normal","Button",plate(Color("303027"),EDGE,12))
	theme.set_stylebox("hover","Button",plate(Color("3d392b"),AMBER,12))
	theme.set_stylebox("pressed","Button",plate(Color("584a31"),AMBER,12))
	theme.set_stylebox("disabled","Button",plate(Color("282921"),Color("494538"),12))
	var focus := plate(Color(0,0,0,0),AMBER,0)
	focus.set_border_width_all(2)
	theme.set_stylebox("focus","Button",focus)
	theme.set_type_variation("ItemRow","Button")
	theme.set_stylebox("normal","ItemRow",plate(Color("292a22"),Color("464638"),12))
	theme.set_stylebox("pressed","ItemRow",plate(Color("51432d"),AMBER,12))
	theme.set_type_variation("PrimaryAction","Button")
	theme.set_stylebox("normal","PrimaryAction",plate(AMBER,AMBER,12))
	theme.set_color("font_color","PrimaryAction",Color("201f18"))
	theme.set_color("font_hover_color","PrimaryAction",Color("201f18"))
	theme.set_color("font_focus_color","PrimaryAction",Color("201f18"))
	theme.set_stylebox("hover","PrimaryAction",plate(Color("e4c48e"),AMBER,12))
	var action_focus := plate(Color(0,0,0,0),Color("201f18"),0)
	action_focus.set_border_width_all(3)
	theme.set_stylebox("focus","PrimaryAction",action_focus)
	return theme

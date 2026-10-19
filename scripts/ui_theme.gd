extends RefCounted
## The shared interface style (#51): ChatGPT's Field kit (art/ui/field-kit-v1)
## installed on the whole window, so every screen gets the same fonts,
## buttons, panels, bars and tooltips. Screens can still override sizes and
## colours; headings opt in with theme_type_variation = "PageTitle" or
## "ItemTitle" (Cinzel).

const FieldKit := preload("res://art/ui/field-kit-v1/style.gd")

## Merges the theme into Godot's global default once. (A theme on the
## window wouldn't reach screens inside CanvasLayers, which is most of ours.
## No static cache: static variables kept scripts alive at exit, #100.)
static func install() -> void:
	if Engine.has_meta("depths_ui_theme"):
		return
	Engine.set_meta("depths_ui_theme", true)
	var theme := make()
	ThemeDB.get_default_theme().merge_with(theme)
	ThemeDB.get_default_theme().default_font = theme.default_font
	ThemeDB.get_default_theme().default_font_size = theme.default_font_size


static func make() -> Theme:
	var theme: Theme = FieldKit.make_theme()
	theme.default_font_size = 20
	theme.set_font_size("font_size", "Button", 20)
	theme.set_font_size("font_size", "PageTitle", 30)
	theme.set_font_size("font_size", "ItemTitle", 24)
	# Panels: dark charcoal with a thin worn edge (Field kit).
	var panel := FieldKit.plate(Color(0.08, 0.075, 0.06, 0.94), FieldKit.EDGE, 14)
	theme.set_stylebox("panel", "PanelContainer", panel)
	theme.set_stylebox("panel", "Panel", panel)
	# Menus and drop-downs (Settings) match the buttons.
	theme.set_stylebox("panel", "PopupMenu", FieldKit.plate(FieldKit.SURFACE, FieldKit.EDGE, 6))
	theme.set_color("font_color", "PopupMenu", FieldKit.TEXT)
	theme.set_color("font_hover_color", "PopupMenu", FieldKit.AMBER)
	theme.set_stylebox("hover", "PopupMenu", FieldKit.plate(Color("3d392b"), FieldKit.AMBER, 4))
	for type in ["OptionButton", "CheckButton", "CheckBox"]:
		theme.set_font("font", type, FieldKit.ACTION)
		theme.set_color("font_color", type, FieldKit.TEXT)
		theme.set_color("font_hover_color", type, FieldKit.TEXT)
		theme.set_color("font_focus_color", type, FieldKit.TEXT)
		theme.set_color("font_pressed_color", type, FieldKit.TEXT)
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		theme.set_stylebox(state, "OptionButton", theme.get_stylebox(state, "Button"))
	# Health and progress bars.
	var back := StyleBoxFlat.new()
	back.bg_color = Color(0.12, 0.08, 0.07)
	var fill := StyleBoxFlat.new()
	fill.bg_color = FieldKit.AMBER
	theme.set_stylebox("background", "ProgressBar", back)
	theme.set_stylebox("fill", "ProgressBar", fill)
	# Sliders (volume).
	var groove := StyleBoxFlat.new()
	groove.bg_color = Color("3a372c")
	groove.content_margin_top = 3
	groove.content_margin_bottom = 3
	var groove_fill := groove.duplicate()
	groove_fill.bg_color = FieldKit.AMBER
	theme.set_stylebox("slider", "HSlider", groove)
	theme.set_stylebox("grabber_area", "HSlider", groove_fill)
	theme.set_stylebox("grabber_area_highlight", "HSlider", groove_fill)
	# Tooltips: the words behind the icons (#105).
	var tip := FieldKit.plate(Color(0.06, 0.055, 0.045, 0.97), FieldKit.AMBER, 8)
	theme.set_stylebox("panel", "TooltipPanel", tip)
	theme.set_color("font_color", "TooltipLabel", FieldKit.TEXT)
	theme.set_font("font", "TooltipLabel", FieldKit.BODY)
	theme.set_font_size("font_size", "TooltipLabel", 18)
	return theme

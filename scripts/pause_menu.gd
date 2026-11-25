extends "res://scripts/field_menu.gd"
## A true modal pause, preserving the caller's screen, selection and focus.
signal options_requested
signal save_requested
var _actions: VBoxContainer
var _continue: Button
var _options: Button
var _save: Button
var _was_paused := false
var options_overlay: Control

func _init() -> void:
	super()
	process_mode=Node.PROCESS_MODE_ALWAYS
	_heading.text="Paused"
	_symbol.visible=false
	_actions=VBoxContainer.new()
	_actions.add_theme_constant_override("separation",8)
	_actions.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_body.add_child(_actions)
	_continue=_action("Continue",finish)
	_options=_action("Options",func():options_requested.emit())
	_save=_action("Save & exit",func():save_requested.emit())

func _action(title: String, callback: Callable) -> Button:
	var button:=Button.new()
	button.text=title
	button.add_theme_font_size_override("font_size",18)
	button.size_flags_vertical=Control.SIZE_EXPAND_FILL
	button.pressed.connect(callback)
	_actions.add_child(button)
	return button

func open() -> void:
	if visible:return
	_was_paused=get_tree().paused
	begin_open()
	get_tree().paused=true
	_continue.grab_focus.call_deferred()

func _input(event: InputEvent) -> void:
	# Input order follows nodes, not CanvasLayer order. Let Options consume
	# Escape first while it covers this menu.
	if is_instance_valid(options_overlay) and options_overlay.visible:return
	super._input(event)

func finish() -> void:
	if not visible:return
	get_tree().paused=_was_paused
	super()

func _fit() -> void:
	if not is_inside_tree() or _actions==null:return
	var available: Vector2=_panel.get_parent().size
	var scale:=get_viewport().get_screen_transform().get_scale()
	var pixels:=maxf(.1,minf(scale.x,scale.y))
	var touch:=maxf(34,44/pixels)
	for button in [_continue,_options,_save]:
		button.custom_minimum_size=Vector2(180,touch)
		button.add_theme_font_size_override("font_size",roundi(maxf(18,16/pixels)))
	_heading.add_theme_font_size_override("font_size",roundi(maxf(28,22/pixels)))
	_close.custom_minimum_size=Vector2(touch,touch)
	_close.add_theme_constant_override("icon_max_width",roundi(maxf(20,22/pixels)))
	_body.custom_minimum_size.y=touch*3+16
	_panel.size=Vector2(minf(360,available.x-24),minf(270,available.y-24))
	_panel.position=(available-_panel.size)/2

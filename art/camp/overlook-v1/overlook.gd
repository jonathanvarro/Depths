extends Control
## #190 standalone presentation. Callers own party, story, storage and travel.
signal target_activated(id: String)

const DIR := "res://art/camp/overlook-v1/"
const HEADING := preload("res://art/fonts/heading-cinzel.tres")
const BODY := preload("res://art/fonts/body-source-sans.tres")
const REQUIRED_SITE := {"mara-warming":"firepit", "corin-equipment":"firepit", "alwen-reading":"survey", "fixer-planning":"survey", "mara-relaxing":"shelter"}

@export_enum("discovered", "provisioned", "connected") var refuge_state := "provisioned":
	set(value):
		if value not in ["discovered", "provisioned", "connected"]:return
		refuge_state=value
		if is_node_ready():_sync()
@export var animate_lights := true:
	set(value):
		animate_lights=value
		if is_node_ready():_sync_motion()
@export var fire_burning := true:
	set(value):
		fire_burning=value
		if is_node_ready():_sync()
@export var show_targets := false:
	set(value):
		show_targets=value
		if is_node_ready():_target_styles()

var _layout: Dictionary
var _canvas: Node2D
var _layers := {}
var _buttons := {}
var _presence := {}
var _occupants: Array[String] = []
var _effects: Array[CanvasItem] = []
var _fire_glow: ColorRect
var _lamp_glow: ColorRect
var _route_glows: Array[ColorRect] = []
var _heading: Label
var _caption: PanelContainer
var _caption_text: Label
var _safe := Vector4.ZERO
var _phase := 0.0
var _ui_scale := 1.0

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	_layout=JSON.parse_string(FileAccess.get_file_as_string(DIR+"layout.json"))
	var back:=ColorRect.new();back.color=Color("10140f");back.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);back.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(back)
	_canvas=Node2D.new();add_child(_canvas)
	var terrain:=Sprite2D.new();terrain.texture=load(_layout.terrain);terrain.centered=false;terrain.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR;_canvas.add_child(terrain)
	for entry in _layout.layers:
		var image:=Sprite2D.new();image.name=entry.id;image.centered=false;image.texture=load(entry.texture)
		image.position=Vector2(entry.rect[0],entry.rect[1]);image.scale=Vector2(0.5,0.5);image.z_index=entry.z;image.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
		_canvas.add_child(image);_layers[entry.id]=image
		if entry.id=="flame":_set_shader(image,"flame")
	# The foreground reuses exactly registered terrain pixels, not a redraw.
	var rim:=Polygon2D.new();var vertices:=PackedVector2Array()
	for point in _layout.foreground_polygon:vertices.append(Vector2(point[0],point[1]))
	rim.polygon=vertices;rim.uv=vertices;rim.texture=terrain.texture;rim.z_index=40;rim.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR;_canvas.add_child(rim)
	_fire_glow=_glow(Rect2(349,381,295,171),0.32);_fire_glow.z_index=31
	_lamp_glow=_glow(Rect2(586,220,128,91),0.14);_lamp_glow.z_index=31
	for rect in [Rect2(1110,473,175,130),Rect2(75,66,158,116)]:_route_glows.append(_glow(rect,0.08))
	var haze:=TextureRect.new();haze.texture=preload("res://art/effects/combat-fog-v1/fog-bank.png");haze.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	haze.position=Vector2(970,304);haze.size=Vector2(630,560);haze.z_index=3;haze.mouse_filter=Control.MOUSE_FILTER_IGNORE;_canvas.add_child(haze);_set_shader(haze,"haze")
	_heading=Label.new();_heading.z_index=101;_heading.text="The Overlook";_heading.add_theme_font_override("font",HEADING);_heading.add_theme_color_override("font_color",Color("e6dac1"));_heading.add_theme_color_override("font_outline_color",Color("10140f"));_heading.add_theme_constant_override("outline_size",5);_heading.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(_heading)
	_caption=PanelContainer.new();_caption.z_index=102;_caption.mouse_filter=Control.MOUSE_FILTER_IGNORE;_caption.visible=false
	var panel:=StyleBoxFlat.new();panel.bg_color=Color("10140fed");panel.border_color=Color("9e855e");panel.set_border_width_all(1);panel.content_margin_left=14;panel.content_margin_right=14;panel.content_margin_top=7;panel.content_margin_bottom=7;_caption.add_theme_stylebox_override("panel",panel)
	_caption_text=Label.new();_caption_text.add_theme_font_override("font",BODY);_caption_text.add_theme_color_override("font_color",Color("e6dac1"));_caption.add_child(_caption_text);add_child(_caption)
	for entry in _layout.targets:
		var button:=Button.new();button.z_index=100;button.name=entry.id;button.accessibility_name=entry.label;button.focus_mode=Control.FOCUS_ALL;button.clip_text=true
		button.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
		button.mouse_entered.connect(_hint.bind(entry.id));button.focus_entered.connect(_hint.bind(entry.id))
		button.mouse_exited.connect(_clear_hint);button.focus_exited.connect(_clear_hint)
		button.pressed.connect(_activate.bind(entry.id));add_child(button);_buttons[entry.id]=button
	_target_styles();resized.connect(_fit);visibility_changed.connect(_sync_motion);_fit();_sync()

func _set_shader(item: CanvasItem, shader_name: String) -> void:
	var material:=ShaderMaterial.new();material.shader=load(DIR+shader_name+".gdshader");item.material=material;_effects.append(item)

func _glow(rect: Rect2, strength: float) -> ColorRect:
	var item:=ColorRect.new();item.position=rect.position;item.size=rect.size;item.mouse_filter=Control.MOUSE_FILTER_IGNORE;_canvas.add_child(item)
	_set_shader(item,"glow");item.material.set_shader_parameter("strength",strength);return item

func set_safe_area(insets: Vector4) -> void:
	_safe=insets
	if is_node_ready():_fit()

func set_text_scale(value: float) -> void:
	_ui_scale=clampf(value,1.0,1.3)
	if is_node_ready():_fit()

## Reject unknown, duplicated or >3 identities atomically. No invented occupants.
func set_occupants(ids: Array) -> bool:
	if not is_node_ready():return false
	if ids.size()>3:return false
	var identities:={}
	for id in ids:
		if not id is String:return false
		var identity:=""
		for entry in _layout.layers:
			if entry.id==id:identity=entry.hero_visual_id
		if identity=="" or identities.has(identity):return false
		identities[identity]=true
	_occupants.assign(ids);_sync();return true

func set_site_present(id: String, present: bool) -> bool:
	if id not in ["shelter","stash","survey","firepit","supplies","lantern"]:return false
	_presence[id]=present
	if is_node_ready():_sync()
	return true

func _sync() -> void:
	for entry in _layout.layers:
		var showing:bool=refuge_state in entry.states and _presence.get(entry.id,true)
		if entry.hero_visual_id!="":showing=showing and entry.id in _occupants and _presence.get(REQUIRED_SITE[entry.id],true)
		if entry.id=="mara-warming":showing=showing and fire_burning
		_layers[entry.id].visible=showing
	_layers.flame.visible=_layers.firepit.visible and fire_burning
	_fire_glow.visible=_layers.flame.visible;_lamp_glow.visible=_layers.lantern.visible and _layers.shelter.visible
	_layers.lantern.visible=_layers.lantern.visible and _layers.shelter.visible
	for entry in _layout.targets:
		var available:=true
		for id in entry.requires:available=available and _layers[id].visible
		var button:Button=_buttons[entry.id]
		if not available and button.has_focus():button.release_focus()
		button.visible=available;button.disabled=not available
	_caption.hide();_sync_motion()

func _sync_motion() -> void:
	set_process(animate_lights and is_visible_in_tree())
	if not animate_lights:
		_phase=0.0;_update_effects()

func _process(delta: float) -> void:
	_phase+=minf(delta,0.1);_update_effects()

func _update_effects() -> void:
	for item in _effects:item.material.set_shader_parameter("phase",_phase)

func _fit() -> void:
	var area:=Rect2(_safe.x,_safe.y,maxf(1,size.x-_safe.x-_safe.z),maxf(1,size.y-_safe.y-_safe.w))
	var factor:=minf(area.size.x/1600.0,area.size.y/900.0)
	_canvas.scale=Vector2.ONE*factor;_canvas.position=area.position+(area.size-Vector2(1600,900)*factor)*0.5
	_heading.position=area.position+Vector2(12,8);_heading.add_theme_font_size_override("font_size",roundi(22*_ui_scale))
	_caption_text.add_theme_font_size_override("font_size",roundi(18*_ui_scale))
	_caption.reset_size();_caption.position=Vector2(area.position.x+12,area.end.y-_caption.size.y-8)
	for entry in _layout.targets:
		var rect: Array=entry.rect;var centre:=_canvas.position+Vector2(rect[0]+rect[2]/2.0,rect[1]+rect[3]/2.0)*factor
		var extent:=Vector2(maxf(44,rect[2]*factor),maxf(44,rect[3]*factor))
		var button:Button=_buttons[entry.id];button.position=centre-extent*0.5;button.size=extent
		button.add_theme_font_override("font",BODY);button.add_theme_font_size_override("font_size",roundi(16*_ui_scale))

func _target_styles() -> void:
	for entry in _layout.targets:
		var button:Button=_buttons[entry.id];button.text={"mine":"Mine","fire":"Fire","survey":"Table","stash":"Stash","onward":"Onward"}[entry.id] if show_targets else ""
		for state in ["normal","hover","pressed","focus"]:
			var style:=StyleBoxFlat.new();style.bg_color=Color(0.9,0.73,0.43,0.10 if state!="normal" else 0.0)
			style.border_color=Color(0.86,0.70,0.43,0.85 if state!="normal" else 0.45 if show_targets else 0.0)
			style.set_border_width_all(2 if state=="focus" else 1);style.set_corner_radius_all(6);button.add_theme_stylebox_override(state,style)
		button.add_theme_color_override("font_color",Color("e6dac1"));button.add_theme_color_override("font_outline_color",Color("10140f"));button.add_theme_constant_override("outline_size",4)

func _hint(id: String) -> void:
	for entry in _layout.targets:
		if entry.id==id:_caption_text.text=entry.label
	_caption.show();_fit()

func _clear_hint() -> void:
	for button in _buttons.values():
		if button.is_visible_in_tree() and (button.is_hovered() or button.has_focus()):return
	_caption.hide()

func _activate(id: String) -> void:
	if not _buttons[id].visible or _buttons[id].disabled:return
	_hint(id);target_activated.emit(id)

func target_rects() -> Dictionary:
	var result:={}
	for id in _buttons:
		if _buttons[id].visible:result[id]=_buttons[id].get_global_rect()
	return result

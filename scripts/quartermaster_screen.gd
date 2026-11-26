extends "res://scripts/field_menu.gd"
## Garran's desk: presentation over existing CampState issue/route authority.
signal departure_requested(depth: int)
const CAMP:=preload("res://scripts/camp_state.gd")
const QUESTS:=preload("res://scripts/quests.gd")
const FACE:=preload("res://art/camp/quartermaster-v1/portrait.png")
const TOPICS:={
	"job":["What do you do here?","I count what goes down, and who comes back. The merchant sells; I keep the camp's issue ready and arrange the scouts. Start with enough light to find your way home."],
	"issue":["Why not take every spare torch?","Because the next party needs light too. Your issue is an allowance, not another full bundle each time you ask. What you've put in your chest counts. Improve the issue once, and every later return benefits."],
	"routes":["How do the scouts' routes work?","Reach a floor on two expeditions and the scouts can mark a way through the upper workings. Their fee is for that trip. Choose where you're going; we settle their pay only when you enter the mine."],
	"advice":["Any advice before we leave?","Count the torches. Check who can stand, and who needs the nurse. Then choose a depth the party can return from. A full pack is no use if nobody brings it home."]
}
var camp
var party
var selected_depth:=1
var tab:="routes"
var _reply:=""
var _notice:=""
var _left: VBoxContainer
var _portrait: TextureRect
var _quote: Label
var _right: VBoxContainer
var _tabs: Dictionary={}
var _scroll: ScrollContainer
var _rows: VBoxContainer
var _notice_label: Label
var _footer: VBoxContainer
var _departure: Button
var _balance: Label
var _fee: Label
var _route_buttons: Dictionary={}
var _upgrade: Button
var _compact:=false

func _init() -> void:
	super._init()
	_heading.text="Quartermaster Garran"
	_balance=text_label("",16,Kit.AMBER);_balance.autowrap_mode=TextServer.AUTOWRAP_OFF;_balance.size_flags_vertical=Control.SIZE_SHRINK_CENTER;_header.add_child(_balance);_header.move_child(_balance,_close.get_index())
	_close.tooltip_text="Back to camp";_close.accessibility_name="Back to camp"
	var head:=AtlasTexture.new();head.atlas=FACE
	var extent:=FACE.get_size();head.region=Rect2(extent*Vector2(.31,0),extent*Vector2(.40,.34))
	_symbol.texture=head;_symbol.modulate=Color.WHITE;_symbol.custom_minimum_size=Vector2(44,44)
	var split:=HBoxContainer.new();split.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);split.add_theme_constant_override("separation",20);_body.add_child(split)
	_left=VBoxContainer.new();_left.custom_minimum_size.x=230;_left.add_theme_constant_override("separation",12);split.add_child(_left)
	_portrait=TextureRect.new();_portrait.texture=FACE;_portrait.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	_portrait.custom_minimum_size=Vector2(230,270);_portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;_portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;_left.add_child(_portrait)
	_left.add_child(text_label("Garran · Quartermaster",20,Kit.AMBER))
	_quote=text_label("",18);_left.add_child(_quote)
	_right=VBoxContainer.new();_right.size_flags_horizontal=Control.SIZE_EXPAND_FILL;_right.add_theme_constant_override("separation",8);split.add_child(_right)
	var tabs:=HBoxContainer.new();tabs.add_theme_constant_override("separation",8);_right.add_child(tabs)
	for id: String in ["supplies","routes","talk"]:
		var button:=action_button({"supplies":"Supplies","routes":"Routes","talk":"Talk"}[id]);button.toggle_mode=true;button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		button.pressed.connect(show_tab.bind(id));tabs.add_child(button);_tabs[id]=button
	_notice_label=text_label("",17,Kit.AMBER);_right.add_child(_notice_label)
	_scroll=ScrollContainer.new();_scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;_scroll.follow_focus=true;_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;_right.add_child(_scroll)
	_rows=VBoxContainer.new();_rows.size_flags_horizontal=Control.SIZE_EXPAND_FILL;_rows.add_theme_constant_override("separation",12);_scroll.add_child(_rows)
	_footer=VBoxContainer.new();_footer.add_theme_constant_override("separation",5);_right.add_child(_footer)
	_fee=text_label("",16,Kit.MUTED);_footer.add_child(_fee)
	_departure=action_button("Head back down");_departure.size_flags_horizontal=Control.SIZE_EXPAND_FILL;_departure.pressed.connect(_prepare);_footer.add_child(_departure)

func open(state,party_state) -> void:
	if camp and camp.changed.is_connected(_on_changed):camp.changed.disconnect(_on_changed)
	if party and party.changed.is_connected(_on_changed):party.changed.disconnect(_on_changed)
	camp=state;party=party_state
	camp.changed.connect(_on_changed);party.changed.connect(_on_changed)
	if selected_depth>1 and not camp.route_open(selected_depth):selected_depth=1
	_notice="";tab="routes";_reply=""
	_refresh();begin_open()

func show_tab(value: String) -> void:
	tab=value;_reply="";_notice="";_scroll.scroll_vertical=0;_refresh()

func _on_changed() -> void:
	if visible:_refresh.call_deferred()

func _greeting() -> String:
	if _reply!="":return _reply
	match tab:
		"supplies":return "Light, food, a clean dressing. Improve the issue here, and it's ready every time you return."
		"talk":return "Ask. Better a question here than a mistake down there."
	return "Pick your way down. We'll check the party before anyone leaves."

func _refresh() -> void:
	if camp==null or party==null:return
	for child in _rows.get_children():_rows.remove_child(child);child.queue_free()
	_route_buttons.clear();_upgrade=null
	for id: String in _tabs:
		var button: Button=_tabs[id];button.button_pressed=id==tab
		Kit.Brass.apply(button,Kit.Brass.Edge.CENTRE,6)
	_balance.text="%d gold"%[party.supplies.gold+camp.stash.gold]
	_quote.text='“'+_greeting()+'”'
	_notice_label.text=_notice;_notice_label.visible=_notice!=""
	_footer.visible=tab=="routes"
	if _compact:_rows.add_child(text_label('Garran: “'+_greeting()+'”',17,Kit.MUTED))
	match tab:
		"supplies":_supplies()
		"routes":_routes()
		"talk":_talk()
	_layout_body.call_deferred()

func _card(title: String) -> VBoxContainer:
	var plate:=PanelContainer.new();plate.size_flags_horizontal=Control.SIZE_EXPAND_FILL;plate.add_theme_stylebox_override("panel",Kit.Brass.panel(10));_rows.add_child(plate)
	var box:=VBoxContainer.new();box.add_theme_constant_override("separation",7);plate.add_child(box);box.add_child(text_label(title,21,Kit.AMBER));return box

func _supplies() -> void:
	var current:=_card("Your standing issue")
	current.add_child(text_label(camp.ISSUE[camp.issue_level]["name"],18))
	_issue_icons(current,camp.issue_level)
	current.add_child(text_label("Free on return, topped up to this allowance. Supplies in your pack and tent chest both count.",17,Kit.MUTED))
	var next: Dictionary=camp.next_issue()
	if next.is_empty():
		_rows.add_child(text_label("The full allowance is arranged. Bring everyone home; I'll keep it ready.",18));return
	var improve:=_card("Improve the issue · permanent")
	_issue_icons(improve,camp.issue_level+1)
	improve.add_child(text_label("One payment: "+camp.next_issue_price()+". Every later return uses the improved allowance.",18))
	_upgrade=action_button(str(next["name"])+" · "+camp.next_issue_price());_upgrade.disabled=not camp.can_raise_issue(party) or party.members.is_empty()
	_upgrade.pressed.connect(_buy_issue);improve.add_child(_upgrade)
	var missing: String=camp.issue_shortfall(party)
	if missing!="":improve.add_child(text_label(missing,17,Kit.AMBER))
	if party.members.is_empty():improve.add_child(text_label("Find companions at the fire before preparing an issue.",17,Kit.AMBER))
	improve.add_child(text_label("Gold and materials may come from your pack or the tent chest.",16,Kit.MUTED))

func _issue_icons(box: VBoxContainer,level: int) -> void:
	var items: Dictionary=camp.issue_items(level)
	for item: SupplyItem in items:
		var row:=HBoxContainer.new();row.add_theme_constant_override("separation",10);box.add_child(row)
		var icon:=TextureRect.new();icon.texture=item.icon;icon.custom_minimum_size=Vector2(30,30);icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;row.add_child(icon)
		var name_label:=text_label("%s ×%d"%[item.display_name,items[item]],18);name_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;name_label.set_meta("issue_name",true);row.add_child(name_label)

func _buy_issue() -> void:
	if party.members.is_empty() or not camp.raise_issue(party):
		_notice=camp.issue_shortfall(party);_refresh();return
	camp.top_up_torches(party)
	_notice="Paid. Your standing issue is now "+camp.issue_text()+"."
	_refresh();_scroll.scroll_vertical=0

func _routes() -> void:
	var ready: Array=camp.available(party)
	_rows.add_child(text_label("Going: "+", ".join(PackedStringArray(ready.map(func(hero):return hero.display_name))) if not ready.is_empty() else "No one is fit to go. Rest or find companions at the fire.",18,Kit.AMBER))
	var recovering: Array=party.living_members().filter(func(hero):return hero not in ready)
	if not recovering.is_empty():_rows.add_child(text_label("Staying with the nurse: "+", ".join(PackedStringArray(recovering.map(func(hero):return hero.display_name))),17,Kit.MUTED))
	var quest: String=QUESTS.current(camp)
	if quest!="":_rows.add_child(text_label(QUESTS.INFO[quest]["title"]+" · "+QUESTS.brief(camp,quest),17,Kit.MUTED))
	var standard:=_route_button(1,"Floor 1 · Mine entrance","Free. Descend through the workings yourself.",true)
	standard.tooltip_text="Start at the mine entrance without a guide fee."
	for depth: int in CAMP.ROUTE_PRICES:
		var earned: bool=camp.route_open(depth)
		var detail: String="Scouts guide you past the upper floors. %d gold for this trip."%camp.route_price(depth) if earned else "Reach this floor on two expeditions. Surveyed %d/%d."%[mini(camp.times_reached(depth),CAMP.ROUTE_AFTER),CAMP.ROUTE_AFTER]
		_route_button(depth,"Floor %d · Scouts' route"%depth,detail,earned)
	var price: int=0 if selected_depth==1 else camp.route_price(selected_depth)
	var can_pay: bool=price==0 or camp.can_afford(party,price)
	_departure.disabled=ready.is_empty() or not can_pay or (selected_depth>1 and not camp.route_open(selected_depth))
	_departure.text="Head back down" if selected_depth==1 else "Prepare for floor %d · %d gold"%[selected_depth,price]
	_fee.text="Next: check the party and equipment. Back to camp costs nothing." if price==0 else "Scouts are paid only when you choose Enter the mine."
	if not can_pay:
		var shortage: int=maxi(0,price-party.supplies.gold-camp.stash.gold)
		_fee.text="Need %d more gold for the scouts."%shortage

func _route_button(depth: int,title: String,detail: String,earned: bool) -> Button:
	var box:=_card(title)
	var select:=action_button("Selected" if selected_depth==depth else ("Choose this route" if earned else "Not yet scouted"))
	select.disabled=not earned;select.toggle_mode=true;select.button_pressed=selected_depth==depth
	select.pressed.connect(func():selected_depth=depth;_notice="";_refresh())
	box.add_child(text_label(detail,17,Kit.MUTED));box.add_child(select);_route_buttons[depth]=select;return select

func _prepare() -> void:
	if camp.available(party).is_empty():_notice="No one is fit to go.";_refresh();return
	if selected_depth>1 and (not camp.route_open(selected_depth) or not camp.can_afford(party,camp.route_price(selected_depth))):
		_notice="That route is not ready. Check the scouts and their fee.";_refresh();return
	departure_requested.emit(selected_depth) # planning never spends gold

func _talk() -> void:
	var intro:=_card("At the quartermaster's table")
	intro.add_child(text_label("Garran sets a finger on the ledger and waits for your question.",18,Kit.MUTED))
	for id: String in TOPICS:
		var topic:=action_button(TOPICS[id][0]);topic.pressed.connect(func():_reply=TOPICS[id][1];_refresh();_scroll.scroll_vertical=0);intro.add_child(topic)

func _layout_body() -> void:
	if _right==null:return
	var scale: Vector2=get_viewport().get_screen_transform().get_scale() if is_inside_tree() else Vector2.ONE
	var pixel:=maxf(.1,minf(scale.x,scale.y));var touch:=maxf(44/pixel,40)
	var compact: bool=_body.size.x*pixel<820 or _body.size.y*pixel<360
	if compact!=_compact:
		_compact=compact
		if camp:_refresh.call_deferred()
	_left.visible=not _compact;_symbol.visible=_compact
	_heading.text="Quartermaster" if _compact else "Quartermaster Garran"
	_heading.add_theme_font_size_override("font_size",roundi(maxf(22 if _compact else 28,18/pixel)))
	_balance.add_theme_font_size_override("font_size",roundi(maxf(16,14/pixel)))
	_close.custom_minimum_size=Vector2.ONE*maxf(48,44/pixel)
	_symbol.custom_minimum_size=Vector2.ONE*maxf(40,40/pixel)
	for button: Button in _body.find_children("*","Button",true,false):
		button.custom_minimum_size.y=touch;button.add_theme_font_size_override("font_size",roundi(maxf(18,14/pixel)))
	for label: Label in _body.find_children("*","Label",true,false):
		if not label.has_meta("qm_font"):label.set_meta("qm_font",label.get_theme_font_size("font_size"))
		label.add_theme_font_size_override("font_size",roundi(maxf(label.get_meta("qm_font"),14/pixel)))

func action_button(value: String) -> Button:
	var button:=super.action_button(value);Kit.Brass.apply(button,Kit.Brass.Edge.CENTRE,6);return button

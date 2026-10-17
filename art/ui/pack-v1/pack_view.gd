extends Control
## Refined design component. Uses supplied PartyState; preview supplies a copy.
signal closed
const Style := preload("res://art/ui/field-kit-v1/style.gd")
const PortraitView := preload("res://scripts/portrait_view.gd")
var party
var phone := false
var selected: SupplyItem
var row_buttons := {}
var row_counts := {}
var row_names := {}
var root_panel: PanelContainer
var back_button: Button
var action_button: Button
var detail_title: Label
var description: Label
var recovery_note: Label
var recipient: Label
var recipient_title: Label
var recipient_portrait: Control
var detail_icon: TextureRect
var lantern_title: Label
var lantern_note: Label
var lantern_bar: ProgressBar
var time_label: Label
var feedback: Label
var body: HBoxContainer
var last_message := "Browsing costs no time."

func setup(state, phone_layout := false) -> void:
	party = state
	phone = phone_layout
	theme = Style.make_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	build()
	party.changed.connect(refresh)
	party.supplies.changed.connect(refresh)
	if not party.supplies.items.is_empty():
		selected = party.supplies.items[0]
	refresh()

func text(parent: Node, value: String, role := "") -> Label:
	var node := Label.new()
	node.text = value
	node.theme_type_variation = role
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	return node

func button(parent: Node, value: String, callback: Callable) -> Button:
	var node := Button.new()
	node.text = value
	node.custom_minimum_size.y = 72 if phone else 56
	node.pressed.connect(callback)
	parent.add_child(node)
	return node

func build() -> void:
	var shade := ColorRect.new()
	shade.color = Color(0.035,0.045,0.035,0.92)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var outer := MarginContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outer.add_theme_constant_override("margin_left",97 if phone else 40)
	outer.add_theme_constant_override("margin_right",97 if phone else 40)
	outer.add_theme_constant_override("margin_top",14 if phone else 28)
	outer.add_theme_constant_override("margin_bottom",35 if phone else 28)
	add_child(outer)
	root_panel = PanelContainer.new()
	root_panel.add_theme_stylebox_override("panel",Style.plate(Style.SURFACE,Style.EDGE,12 if phone else 24))
	outer.add_child(root_panel)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation",8 if phone else 16)
	root_panel.add_child(stack)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation",16)
	stack.add_child(header)
	var heading := text(header,"Pack","PageTitle")
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	time_label = text(header,"","SecondaryText")
	time_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	back_button = button(header,"Back",func(): closed.emit())
	back_button.custom_minimum_size.x = 110
	var lantern := HBoxContainer.new()
	lantern.add_theme_constant_override("separation",24)
	stack.add_child(lantern)
	var oil := VBoxContainer.new()
	oil.custom_minimum_size.x = 285
	lantern.add_child(oil)
	lantern_title = text(oil,"","Emphasis")
	lantern_bar = ProgressBar.new()
	lantern_bar.show_percentage = false
	lantern_bar.max_value = 100
	lantern_bar.custom_minimum_size.y = 7
	lantern_bar.add_theme_stylebox_override("background",Style.plate(Color("121a15"),Color(0,0,0,0),0))
	var fill := Style.plate(Style.AMBER,Color(0,0,0,0),0)
	fill.set_border_width_all(0)
	lantern_bar.add_theme_stylebox_override("fill",fill)
	oil.add_child(lantern_bar)
	lantern_note = text(lantern,"","SecondaryText")
	lantern_note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lantern_note.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	lantern_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body = HBoxContainer.new()
	body.add_theme_constant_override("separation",18 if phone else 28)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.add_child(body)
	var list := VBoxContainer.new()
	list.custom_minimum_size.x = 390 if phone else 430
	list.add_theme_constant_override("separation",6 if phone else 10)
	body.add_child(list)
	for item: SupplyItem in party.supplies.items:
		var row := Button.new()
		row.theme_type_variation = "ItemRow"
		row.custom_minimum_size.y = 72 if phone else 82
		row.toggle_mode = true
		row.pressed.connect(select_item.bind(item))
		list.add_child(row)
		row_buttons[item] = row
		var inset := MarginContainer.new()
		inset.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		for side in ["left","right"]:
			inset.add_theme_constant_override("margin_"+side,14)
		inset.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(inset)
		var line := HBoxContainer.new()
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		line.add_theme_constant_override("separation",14)
		inset.add_child(line)
		var picture := TextureRect.new()
		picture.texture = icon_for(item)
		picture.custom_minimum_size = Vector2(48,48)
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
		line.add_child(picture)
		var name := text(line,item.display_name)
		name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row_names[item] = name
		var count := text(line,"","Emphasis")
		count.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row_counts[item] = count
	var detail := PanelContainer.new()
	detail.add_theme_stylebox_override("panel",Style.plate(Color("1b201a"),Color("454735"),14 if phone else 20))
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(detail)
	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation",8 if phone else 12)
	detail.add_child(info)
	var identity := HBoxContainer.new()
	identity.add_theme_constant_override("separation",16)
	info.add_child(identity)
	detail_icon = TextureRect.new()
	detail_icon.custom_minimum_size = Vector2(64,64)
	detail_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	detail_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	detail_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	identity.add_child(detail_icon)
	detail_title = text(identity,"","ItemTitle")
	detail_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	description = text(info,"")
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	recovery_note = text(info,"","SecondaryText")
	recovery_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var affected := HBoxContainer.new()
	affected.add_theme_constant_override("separation",12)
	info.add_child(affected)
	recipient_portrait = PortraitView.new()
	recipient_portrait.custom_minimum_size = Vector2(56,56)
	affected.add_child(recipient_portrait)
	var person := VBoxContainer.new()
	person.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	affected.add_child(person)
	recipient_title = text(person,"","Emphasis")
	recipient = text(person,"","SecondaryText")
	recipient.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var flexible := Control.new()
	flexible.size_flags_vertical = Control.SIZE_EXPAND_FILL
	info.add_child(flexible)
	action_button = button(info,"",use_selected)
	action_button.theme_type_variation = "PrimaryAction"
	feedback = text(stack,last_message,"SecondaryText")
	feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func icon_for(item: SupplyItem) -> Texture2D:
	if item.icon:
		return item.icon
	if item.effect == SupplyItem.Effect.DRESS_INJURY:
		return preload("res://art/ui/pack-v1/clean-dressing.png")
	return null

func select_item(item: SupplyItem) -> void:
	selected = item
	refresh()

func refresh() -> void:
	if party == null or selected == null:
		return
	var supplies = party.supplies
	lantern_title.text = "Lantern  %d / 100" % roundi(supplies.oil)
	lantern_bar.value = supplies.oil
	lantern_note.text = "%s light · burns %.1f oil / time\nA fuller flame reaches farther and burns faster." % [supplies.LIGHT_NAMES[supplies.light_band()],supplies.burn_rate()]
	time_label.text = "Time spent  %d" % party.time_elapsed
	for item: SupplyItem in supplies.items:
		row_buttons[item].set_pressed_no_signal(item == selected)
		row_counts[item].text = "×%d" % supplies.count(item)
		row_names[item].modulate.a = 0.6 if supplies.count(item) <= 0 else 1.0
	detail_icon.texture = icon_for(selected)
	detail_title.text = selected.display_name
	description.text = selected.description
	if selected.effect == SupplyItem.Effect.FEED_PARTY:
		description.text = "Each living hero regains %d health over %d time." % [selected.amount,selected.duration]
	elif selected.effect == SupplyItem.Effect.HEAL_ONE:
		description.text = "The most hurt hero regains %d health over %d time." % [selected.amount,selected.duration]
	recovery_note.visible = selected.duration > 0
	recovery_note.text = "Recovery finishes at rest or when you change floors."
	var target: Companion = null
	match selected.effect:
		SupplyItem.Effect.HEAL_ONE:
			target = party.most_hurt()
		SupplyItem.Effect.DRESS_INJURY:
			target = party.first_undressed_injured()
		SupplyItem.Effect.FEED_PARTY:
			target = party.living_members()[0] if not party.living_members().is_empty() else null
	if selected.effect == SupplyItem.Effect.REFILL_LANTERN:
		recipient_title.text = "For the lantern"
		recipient.text = "Open flask: %d oil left" % roundi(supplies.open_flask) if supplies.open_flask > 0 else "Unused oil stays in the flask."
	elif selected.effect == SupplyItem.Effect.FEED_PARTY:
		recipient_title.text = "For the whole party"
		recipient.text = ", ".join(PackedStringArray(party.living_members().map(func(m): return "%s %d/%d" % [m.display_name,m.health,m.effective_max_health()])))
	else:
		recipient_title.text = "For " + target.display_name if target else "No recipient needs this"
		recipient.text = "%d/%d health" % [target.health,target.effective_max_health()] if target else ""
		if target and selected.effect == SupplyItem.Effect.DRESS_INJURY:
			recipient.text += " · " + target.hindering_injuries()[0].display_name
	recipient_portrait.visible = target != null
	if target and recipient_portrait.portrait_set != target.portrait_set:
		recipient_portrait.show_portrait(target.portrait_set,target.portrait)
	if target:
		recipient_portrait.set_condition("blood",not target.hindering_injuries().is_empty())
		recipient_portrait.set_condition("bandage",not target.dressed.is_empty())
	var reason: String = party.cannot_use_reason(selected)
	action_button.disabled = reason != ""
	var verb := {0:"Refill lantern",1:"Eat ration",2:"Drink draught",3:"Bind injury"}
	action_button.text = reason if reason != "" else "%s · %d time" % [verb[selected.effect],selected.use_time]
	feedback.text = last_message

func use_selected() -> void:
	var message: String = party.use_item(selected)
	if message != "":
		last_message = message
	refresh()
	if action_button.disabled:
		row_buttons[selected].grab_focus()

func _unhandled_key_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		closed.emit()

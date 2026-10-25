extends SceneTree
## Real loot/economy widgets and input, no Main, settings files or saves.
const PARTY:=preload("res://scripts/party_state.gd")
const CAMP:=preload("res://scripts/camp_state.gd")
const CHEST:=preload("res://scripts/chest_screen.gd")
const MERCHANT:=preload("res://scripts/merchant_screen.gd")
const SAFE:=preload("res://scripts/safe_area.gd")
const OUT:="res://art/concepts/interface/exchange-live-v1/"
var checks:=0
var failures:Array[String]=[]
var captures:Array[String]=[]
var party
var chest
var merchant
var camp

func _initialize() -> void:
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	call_deferred("run")

func check(ok:bool,label:String) -> void:
	checks+=1
	if not ok:failures.append(label);push_error(label)

func settle() -> void:
	for i in 8:await process_frame

func item(id:String) -> SupplyItem:return load("res://data/items/"+id+".tres")
func gear(id:String) -> Equipment:return load("res://data/gear/"+id+".tres")

func snap(name:String) -> void:
	await settle();await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(OUT+name+".png")==OK,"Capture "+name)
	captures.append(name+".png")

func fit(view:Control,phone:bool) -> void:
	var inset:=SAFE.insets(root,phone)
	view.content.offset_left=inset.x;view.content.offset_top=inset.y
	view.content.offset_right=-inset.z;view.content.offset_bottom=-inset.w

func click(button:Button,touch:=false) -> void:
	check(button!=null and not button.disabled,"Enabled input target")
	if button==null or button.disabled:return
	var parent:=button.get_parent()
	while parent and not parent is ScrollContainer:parent=parent.get_parent()
	if parent:parent.ensure_control_visible(button)
	await settle()
	var pos:=button.get_global_rect().get_center()
	if touch:
		for pressed in [true,false]:
			var event:=InputEventScreenTouch.new();event.index=0;event.position=pos;event.pressed=pressed
			Input.parse_input_event(event);await process_frame
	else:
		var motion:=InputEventMouseMotion.new();motion.position=pos;Input.parse_input_event(motion);await process_frame
		for pressed in [true,false]:
			var event:=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.position=pos;event.pressed=pressed
			Input.parse_input_event(event);await process_frame
	await settle()

func tile(view,key,side:="left") -> Button:
	for b:Button in (view._left_grid.get_children() if side=="left" else view._bag.slots):
		if b.has_meta("exchange_key") and typeof(b.get_meta("exchange_key"))==typeof(key) and b.get_meta("exchange_key")==key:return b
	return null

func drag(button:Button,destination:Control) -> void:
	var start:=button.get_global_rect().get_center()
	var motion:=InputEventMouseMotion.new();motion.position=start;Input.parse_input_event(motion);await settle()
	var down:=InputEventMouseButton.new();down.button_index=MOUSE_BUTTON_LEFT;down.position=start;down.pressed=true
	Input.parse_input_event(down);await process_frame
	for target in [start+Vector2(24,0),destination.get_global_rect().get_center()]:
		motion=InputEventMouseMotion.new();motion.position=target;motion.relative=target-start;motion.button_mask=MOUSE_BUTTON_MASK_LEFT
		Input.parse_input_event(motion);await settle()
	check(root.gui_is_dragging(),"Native pointer movement starts loot drag")
	var up:=InputEventMouseButton.new();up.button_index=MOUSE_BUTTON_LEFT;up.position=destination.get_global_rect().get_center();up.pressed=false
	Input.parse_input_event(up);await settle()

func key(code:Key) -> void:
	for pressed in [true,false]:
		var event:=InputEventKey.new();event.keycode=code;event.pressed=pressed
		Input.parse_input_event(event);await process_frame
	await settle()

func layout(view:Control,tag:String) -> void:
	check(view._left_scroll.get_global_rect().end.x<view._bag.get_global_rect().position.x,"Contents left and backpack right "+tag)
	check(view._details.get_global_rect().position.y>=view._bag.get_global_rect().end.y-1,"Inspection stays below both sides "+tag)
	for button:Button in view.find_children("*","Button",true,false):
		if not button.is_visible_in_tree() or button.disabled:continue
		if button.get_parent()==view._left_grid:continue  # independently scrollable stock
		var rect:=button.get_global_rect()
		check(rect.size.x>=43.9 and rect.size.y>=43.9,"44px target "+tag)
		check(root.get_visible_rect().encloses(rect),"Target fits viewport "+tag)
	for button:Button in view._left_grid.get_children():
		view._left_scroll.ensure_control_visible(button);await settle()
		check(view._left_scroll.get_global_rect().grow(1).encloses(button.get_global_rect()),"Each stock/loot target can be revealed %s: %s in %s"%[tag,button.get_global_rect(),view._left_scroll.get_global_rect()])
	view._left_scroll.scroll_vertical=0;await settle()

func run() -> void:
	Engine.set_meta("depths_settings",preload("res://scripts/settings.gd").DEFAULTS.duplicate())
	Engine.set_meta("depths_settings_loaded",true)
	preload("res://scripts/settings.gd").ensure_buses()
	AudioServer.set_bus_mute(0,true)
	preload("res://scripts/ui_theme.gd").install()
	party=PARTY.new();party.add_member(load("res://data/companions/mara.tres"))
	party.supplies.gold=84;party.supplies.add(item("ration"),7);party.supplies.add(item("oil_flask"),2)
	party.supplies.add(item("copper_ore"),2);party.supplies.gear.append(gear("plain_knife"))
	camp=CAMP.new();camp.start(23,party)
	chest=CHEST.new();root.add_child(chest);chest.closed.connect(chest.hide)
	merchant=MERCHANT.new();root.add_child(merchant);merchant.closed.connect(merchant.hide)
	for shape in [Vector2i(1280,720),Vector2i(1278,590),Vector2i(1334,750)]:
		root.size=shape
		for scale_factor in [1.0,1.3]:
			root.content_scale_factor=scale_factor
			var tag:="%d-%s"%[shape.x,"larger" if scale_factor>1 else "normal"]
			merchant.hide();chest.open("A battered chest",{item("restorative_draught"):2,item("dressing"):3,gear("simple_spear"):1},party)
			fit(chest,shape.y!=720);await settle();await layout(chest,"loot "+tag)
			chest.select_item(item("restorative_draught"),"left");await snap("loot-"+tag)
			chest.hide();merchant.open(camp,party);fit(merchant,shape.y!=720)
			await settle();await layout(merchant,"merchant "+tag)
			merchant.select_item(item("dressing"),"left");await snap("merchant-"+tag)
			merchant.hide()
	root.content_scale_factor=1.0;root.size=Vector2i(1278,590)
	chest.open("Room finds",{item("restorative_draught"):2,gear("simple_spear"):1},party);fit(chest,true);await settle()
	var before_time:int=party.time_elapsed
	var before_count:int=party.supplies.count(item("restorative_draught"))
	await click(tile(chest,item("restorative_draught")),true)
	check(party.supplies.count(item("restorative_draught"))==before_count,"Touch inspection does not take loot")
	await click(chest._primary,true)
	check(party.supplies.count(item("restorative_draught"))==before_count+2 and not chest.contents.has(item("restorative_draught")),"Take transfers each available item once")
	check(party.time_elapsed==before_time,"Loot browsing/transfers spend no time")
	chest.select_item(item("ration"),"right");await settle();await click(chest._primary)
	check(party.supplies.count(item("ration"))==5 and chest.contents[item("ration")]==2,"Leave uses existing partial-stack-first rule")
	chest._take_all.pressed.emit();await settle()
	check(chest.is_empty() and chest._empty.visible and chest._take_all.disabled,"Take All clears contents and shows Empty")
	await snap("loot-empty-phone")
	# Full pack does not delete leftovers, and room in a partial stack still works.
	party.supplies.capacity=party.supplies.slots_used()
	chest.open("No room in your pack",{item("fine_cloth"):4},party);await settle()
	chest.select_item(item("fine_cloth"),"left");await settle()
	check(chest._primary.disabled and chest._take_all.disabled,"Full-pack transfer is visibly unavailable")
	chest.take_all();check(chest.contents[item("fine_cloth")]==4,"No-room loot remains in container")
	await snap("loot-full-phone")
	chest.put_back(gear("simple_spear"));chest.take(item("fine_cloth"))
	check(party.supplies.count(item("fine_cloth"))==3 and chest.contents[item("fine_cloth")]==1,"Partial fit leaves exact remainder")
	check(not chest._can_drop_on_pack(Vector2.ZERO,{"chest_item":item("holy_water")}),"Unknown drag data cannot create an item")
	party.supplies.capacity=24
	check(chest._can_drop_on_pack(Vector2.ZERO,{"chest_item":gear("simple_spear")}),"Gear supports the same drag path")
	chest._drop_on_pack(Vector2.ZERO,{"chest_item":gear("simple_spear")})
	check(gear("simple_spear") in party.supplies.gear and not chest.contents.has(gear("simple_spear")),"Gear drop transfers exactly once")
	chest.open("Drag review",{item("ration"):1},party);await settle()
	before_count=party.supplies.count(item("ration"))
	await drag(tile(chest,item("ration")),chest._bag)
	check(chest.is_empty() and party.supplies.count(item("ration"))==before_count+1,"Native mouse drag transfers one available ration")
	chest.open("Keyboard review",{item("dressing"):1},party);await settle()
	chest.select_item(item("dressing"),"left");chest._primary.grab_focus();await settle()
	before_count=party.supplies.count(item("dressing"));await key(KEY_ENTER)
	check(chest.is_empty() and party.supplies.count(item("dressing"))==before_count+1,"Keyboard activates explicit Take once")
	await key(KEY_ESCAPE);check(not chest.visible,"Keyboard Escape closes an empty chest")
	party.supplies.gear.append(gear("plain_knife"))
	chest.open("Repeated gear",{},party)
	chest.put_back(gear("plain_knife"));chest.put_back(gear("plain_knife"))
	check(chest.contents.get(gear("plain_knife"))==2,"Leaving identical spare gear preserves both pieces")
	party.supplies.capacity=party.supplies.slots_used()+1;chest.take_all()
	check(chest.contents.get(gear("plain_knife"))==1 and party.supplies.gear.count(gear("plain_knife"))==1,"Gear partial fit retains the second piece")
	party.supplies.capacity=24;chest.take_all()
	check(chest.is_empty() and party.supplies.gear.count(gear("plain_knife"))==2,"Take All recovers all identical gear")
	party.supplies.gear.erase(gear("plain_knife"))
	chest.hide();party.supplies.gold=84;merchant.open(camp,party);fit(merchant,true);await settle()
	before_count=party.supplies.count(item("dressing"))
	await click(tile(merchant,item("dressing")),true)
	var before_gold:int=party.supplies.gold
	await click(merchant._primary,true)
	check(party.supplies.count(item("dressing"))==before_count+1 and party.supplies.gold==before_gold-item("dressing").price,"Buy uses actual price and adds one")
	merchant.select_item(item("copper_ore"),"right");await settle()
	before_gold=party.supplies.gold;before_count=party.supplies.count(item("copper_ore"))
	await click(merchant._primary)
	check(party.supplies.gold==before_gold+item("copper_ore").price and party.supplies.count(item("copper_ore"))==before_count-1,"Sell one treasure at actual value")
	merchant.select_item(gear("plain_knife"),"right");await settle();before_gold=party.supplies.gold
	await click(merchant._primary,true)
	check(gear("plain_knife") not in party.supplies.gear and party.supplies.gold==before_gold+CAMP.sale_price(gear("plain_knife")),"Spare gear sale preserves resale fraction")
	merchant.select_item(item("ration"),"right");await settle()
	check(merchant._primary.disabled,"Supplies are visible but not newly sellable")
	# A stale purchase cannot fire after trading closes.
	merchant.select_item(item("dressing"),"left");await settle()
	var stale:Button=merchant._primary;before_gold=party.supplies.gold
	camp.set_merchant_unloading(true);merchant.refresh();stale.pressed.emit();await settle()
	check(party.supplies.gold==before_gold and merchant._left_entries.is_empty(),"Unloading blocks stale purchases and hides stock")
	await snap("merchant-unloading-phone")
	camp.set_merchant_unloading(false);party.supplies.has_lantern=false;party.supplies.gold=39;merchant.refresh();await settle()
	check(not merchant._left_entries.any(func(e):return e.key is Resource and e.key==item("oil_flask")),"Oil stock waits for a lantern")
	merchant.select_item("lantern","left");await settle();check(merchant._primary.disabled,"Unaffordable lantern explains missing gold")
	party.supplies.gold=45;merchant.refresh();await settle();await click(merchant._primary,true)
	check(party.supplies.has_lantern and party.supplies.source==1 and party.supplies.oil==100 and party.supplies.gold==5,"Lantern purchase preserves actual upgrade behavior")
	check(merchant._left_entries.any(func(e):return e.key==item("oil_flask")) and not merchant._left_entries.any(func(e):return e.key is String and e.key=="lantern"),"Upgrade updates stock immediately")
	party.supplies.capacity=party.supplies.slots_used();merchant.refresh();merchant.select_item(item("pick"),"left");await settle()
	check(merchant._primary.disabled,"Full-pack purchase remains disabled")
	# Existing emergency torches remain possible even while unloading.
	var poor=PARTY.new();poor.add_member(load("res://data/companions/mara.tres"));poor.supplies.has_lantern=false;poor.supplies.source=0
	var arriving=CAMP.new();arriving.start(54,poor);arriving.begin_arrivals()
	merchant.open(arriving,poor);await settle();check(merchant._extra.visible,"Emergency torches remain visible while unloading")
	await click(merchant._extra,true)
	check(poor.supplies.count(item("torch"))==2 and not merchant._extra.visible,"Charity retains once-per-day rule")
	check(poor.time_elapsed==0,"Trading/charity does not change expedition clock")
	await snap("merchant-arrival-phone")
	# Overflow pages retain every real item.
	for id in ["garnet","emerald","amethyst","military_medal","small_reliquary","silver_ingot","spice_pouch","gold_nuggets","pearl_necklace","silver_locket","gold_signet_ring","fine_cloth","copper_ore"]:party.supplies.add(item(id),1)
	merchant.open(camp,party);await settle();merchant.show_page(1);await settle()
	check(merchant._bag_page==1 and merchant._bag.slots.any(func(b):return b.has_meta("exchange_key")),"Overflow sale page is reachable")
	await snap("merchant-overflow-phone")
	var file:=FileAccess.open(OUT+"validation.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"captures":captures,"physical_iPhone":false,"main_or_saves":false},"\t")+"\n");file.close()
	merchant.free();chest.free();party=null;camp=null;poor=null;arriving=null;await settle()
	print("KIT_EXCHANGE: checks=%d failures=%d"%[checks,failures.size()])
	quit(0 if failures.is_empty() else 1)

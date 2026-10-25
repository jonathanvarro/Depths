extends SceneTree
## Real PartyState/PackScreen/input; isolated from Main, settings files and saves.
const PACK := preload("res://scripts/pack_screen.gd")
const PARTY := preload("res://scripts/party_state.gd")
const SAFE := preload("res://scripts/safe_area.gd")
const OUT := "res://art/concepts/interface/combined-live-v1/"
var checks:=0
var failures:Array[String]=[]
var captures:Array[String]=[]
var pack
var party

func _initialize() -> void:
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	call_deferred("run")

func check(ok:bool,label:String) -> void:
	checks+=1
	if not ok:failures.append(label);push_error(label)

func settle() -> void:
	for i in 8:await process_frame

func snap(name:String) -> void:
	await settle();await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(OUT+name+".png")==OK,"Capture "+name)
	captures.append(name+".png")

func action(kind:String) -> Button:
	for b in pack._detail_actions.get_children():
		if b.get_meta("kit_focus","")=="action:"+kind:return b
	return null

func click(b:Button,touch:=false) -> void:
	check(b!=null and not b.disabled,"Enabled input target")
	if b==null or b.disabled:return
	var pos:=b.get_global_rect().get_center()
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

func item(id:String) -> SupplyItem:return load("res://data/items/"+id+".tres")
func gear(id:String) -> Equipment:return load("res://data/gear/"+id+".tres")

func fit(phone:bool) -> void:
	var insets:=SAFE.insets(root,phone)
	pack.content.offset_left=insets.x;pack.content.offset_top=insets.y
	pack.content.offset_right=-insets.z;pack.content.offset_bottom=-insets.w

func labels() -> String:
	return "\n".join(pack.find_children("*","Label",true,false).filter(func(l):return l.is_visible_in_tree()).map(func(l):return l.text))

func run() -> void:
	# In-memory settings only. Quality borders consult this without reading a slot.
	Engine.set_meta("depths_settings",preload("res://scripts/settings.gd").DEFAULTS.duplicate())
	Engine.set_meta("depths_settings_loaded",true)
	preload("res://scripts/ui_theme.gd").install()
	party=PARTY.new()
	for id in ["mara","corin","alwen"]:party.add_member(load("res://data/companions/"+id+".tres"))
	party.members[1].health=5
	party.supplies.gold=84;party.supplies.oil=42
	for id in ["oil_flask","ration","restorative_draught","dressing"]:party.supplies.add(item(id),3)
	party.supplies.add(item("amber_pendant"),1)
	for id in ["plain_knife","simple_spear","padded_coat","satchel"]:party.supplies.gear.append(gear(id))
	pack=PACK.new();root.add_child(pack);pack.setup(party)
	pack.closed.connect(pack.hide)
	for shape in [Vector2i(1280,720),Vector2i(1278,590),Vector2i(1334,750)]:
		root.size=shape
		for scale_factor in [1.0,1.3]:
			root.content_scale_factor=scale_factor
			fit(shape.y!=720)
			pack.refresh();await settle()
			var tag:="%d-%s"%[shape.x,"larger" if scale_factor>1 else "normal"]
			check(pack._bag.get_global_rect().position.x>pack._equipment.get_global_rect().end.x,"Equipment left, bag right "+tag)
			check(pack._details.get_global_rect().position.y>=pack._bag.get_global_rect().end.y-1,"Inspection never covers bag "+tag)
			for slot:Button in pack._slot_buttons.values():
				check(pack._equipment.get_global_rect().grow(1).encloses(slot.get_global_rect()),"Loadout fits left panel "+tag)
			for b:Button in pack.find_children("*","Button",true,false):
				if not b.is_visible_in_tree() or b.disabled:continue
				var rect:=b.get_global_rect()
				check(rect.size.x>=43.9 and rect.size.y>=43.9,"44px target "+b.accessibility_name+" "+tag)
				check(root.get_visible_rect().encloses(rect),"Target inside viewport "+b.accessibility_name+" "+tag)
			await snap("equipment-"+tag)
			pack.inspect_item(gear("simple_spear"));await settle()
			check(labels().contains("Replaces") and labels().contains("→"),"Visible actual gear comparison "+tag)
			await snap("inspect-"+tag)
			pack.set_status(true);await settle()
			check(pack._bag.is_visible_in_tree() and pack._status_scroll.is_visible_in_tree(),"Bag stays during Status "+tag)
			await snap("status-"+tag)
			pack.set_status(false);pack.clear_inspection()
	root.content_scale_factor=1.0;root.size=Vector2i(1278,590);fit(true);await settle()
	var time_before:int=party.time_elapsed
	# Inspect by real mouse and activate only after a click/tap.
	var spear:Button=pack._bag.slots.filter(func(b):return b.has_meta("item") and b.get_meta("item")==gear("simple_spear"))[0]
	await click(spear,true)
	check(pack._selection==gear("simple_spear") and party.time_elapsed==time_before,"Touch pins inspection without using time")
	var stale:Button=action("equip")
	pack.select_hero(party.members[1])
	stale.pressed.emit()
	check(party.members[1].weapon!=gear("simple_spear") and pack._selection==null,"Switching hero invalidates old action")
	pack.inspect_item(gear("simple_spear"));await settle()
	var previous:Equipment=party.members[1].weapon
	await click(action("equip"))
	check(party.members[1].weapon==gear("simple_spear") and (previous==null or previous in party.supplies.gear),"Equip swaps old gear into shared bag")
	check(party.time_elapsed==time_before,"Gear swap preserves browsing time rule")
	pack.inspect_item(party.members[1].weapon,true,"weapon");await settle()
	check(action("unequip").disabled,"Founder's weapon still needs a replacement")
	party.members[1].founder=false  # exercise the existing recruit permission
	pack.refresh();await settle();await click(action("unequip"),true)
	check(party.members[1].weapon==null and gear("simple_spear") in party.supplies.gear,"Unequip recruit returns item")
	pack.select_hero(party.members[0]);pack.inspect_item(item("restorative_draught"));await settle()
	check(labels().contains("Treats Corin"),"Draught names actual model target, not inspected hero")
	var count:int=party.supplies.count(item("restorative_draught"))
	await click(action("use"),true)
	check(party.supplies.count(item("restorative_draught"))==count-1 and party.time_elapsed==time_before+item("restorative_draught").use_time,"Use consumes one and exact time")
	check(not party.members[1].pending_effects.is_empty(),"Healing follows existing most-hurt targeting")
	pack.inspect_item(item("amber_pendant"));await settle();await click(action("wear"),true)
	check(party.members[0].trinket!=null,"Treasure wears through real model")
	pack.inspect_item(party.members[0].trinket,true,"trinket");await settle();await click(action("unequip"))
	check(party.members[0].trinket==null and party.supplies.count(item("amber_pendant"))==1,"Jewellery returns as original treasure")
	# Backpacks change capacity; an extra empty page is still navigable.
	party.supplies.capacity=14;pack.refresh();pack.show_page(1);await settle()
	check(pack._page==1,"Unused capacity pages remain reachable")
	party.update_capacity();pack.show_page(0)
	var curse:Equipment=load("res://data/trinkets/goblin_torc_cursed.tres")
	party.supplies.gear.append(curse);party.wear(party.members[0],curse)
	pack.refresh();pack.inspect_item(curse,true,"trinket");await settle()
	check(action("unequip").disabled and labels().contains("Cursed"),"Cursed equipment is visibly locked")
	pack.inspect_item(item("ration"));await settle()
	count=party.supplies.count(item("ration"));await click(action("drop"))
	check(party.supplies.count(item("ration"))==count-1,"Drop removes one supply only")
	for id in ["garnet","emerald","amethyst","fine_cloth","spice_pouch","copper_ore","gold_nuggets","military_medal","small_reliquary"]:party.supplies.add(item(id),1)
	pack.refresh();await settle()
	check(pack._entries.size()>12 and pack._pages.get_child_count()==3,"Overflow pages without shrinking targets")
	var last:Resource=pack._entries[-1].item
	pack.show_page(1);await settle()
	check(pack._bag.slots.any(func(b):return b.has_meta("item") and b.get_meta("item")==last),"Last overflow item remains reachable")
	await snap("overflow-phone")
	pack.hide();pack.show();await settle()
	check(not pack._status and pack._selection==null and pack._close.has_focus(),"Reopen defaults Equipment with Close keyboard focus")
	pack.inspect_item(item("ration"))
	var escape:=InputEventKey.new();escape.keycode=KEY_ESCAPE;escape.pressed=true
	Input.parse_input_event(escape);await settle()
	check(pack.visible and pack._selection==null,"Escape dismisses inspection first")
	Input.parse_input_event(escape);await settle()
	check(not pack.visible,"Second Escape closes the kit")
	var file:=FileAccess.open(OUT+"validation.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"captures":captures,"physical_iPhone":false,"uses_main_or_save":false},"\t")+"\n");file.close()
	pack.free();party=null;await process_frame
	print("COMBINED_PACK: checks=%d failures=%d"%[checks,failures.size()])
	quit(0 if failures.is_empty() else 1)

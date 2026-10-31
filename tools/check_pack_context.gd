extends SceneTree
## #191: selected recipients, real hover/tap/drag, bounded item cards and phone layouts.
## No Main or player files. With a renderer, captures go into -- <output directory>.
const PACK:=preload("res://scripts/pack_screen.gd")
const PARTY:=preload("res://scripts/party_state.gd")
var out:="res://build/pack-context-review/"
var checks:=0
var failures:Array[String]=[]
var captures:Array[String]=[]
var pack
var party

func _initialize() -> void:
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	if not OS.get_cmdline_user_args().is_empty():out=OS.get_cmdline_user_args()[0].trim_suffix("/")+"/"
	call_deferred("run")

func check(ok:bool,label:String) -> void:
	checks+=1
	if not ok:failures.append(label);push_error(label)

func settle() -> void:
	for i in 10:await process_frame

func item(id:String) -> SupplyItem:return load("res://data/items/"+id+".tres")
func gear(id:String) -> Equipment:return load("res://data/gear/"+id+".tres")

func new_party():
	var ps=PARTY.new()
	for id in ["mara","corin","alwen"]:ps.add_member(load("res://data/companions/"+id+".tres"))
	return ps

func model_checks() -> void:
	var ps=new_party()
	var a:Companion=ps.members[0]
	var b:Companion=ps.members[1]
	var draught:=item("restorative_draught")
	ps.supplies.add(draught,8)
	a.health=a.effective_max_health()-2;b.health=2
	check(ps.use_item(draught,false,a)!="" and not a.pending_effects.is_empty() and b.pending_effects.is_empty(),"Explicit treatment goes to selected less-hurt hero")
	check(ps.time_elapsed==draught.use_time and ps.supplies.count(draught)==7,"Targeted treatment costs one item and exact time")
	a.pending_effects.clear();a.health=a.effective_max_health()
	var before:int=ps.time_elapsed
	check(ps.cannot_use_reason(draught,false,a).contains(a.display_name) and ps.use_item(draught,false,a)=="","Full selected hero cannot silently heal another")
	var foreign:=a.duplicate()
	check(ps.use_item(draught,false,foreign)=="","Foreign hero rejected")
	check(ps.time_elapsed==before and ps.supplies.count(draught)==7,"Invalid treatment spends nothing")
	ps.use_item(draught)
	check(not b.pending_effects.is_empty(),"Omitted recipient preserves automatic most-hurt targeting")
	a.main_hero=true;a.health=0;a.pending_effects.clear()
	check(ps.use_item(draught,false,a)!="" and not a.pending_effects.is_empty(),"Selected unconscious main hero can be revived")
	b.main_hero=false;b.health=0
	check(ps.use_item(draught,false,b)=="","Fallen recruit cannot receive medicine")
	a.health=5;b.health=5
	var injury:Injury=load("res://data/injuries/deep_wound.tres")
	a.add_injury(injury);b.add_injury(injury)
	ps.supplies.add(item("dressing"),3)
	ps.use_item(item("dressing"),false,b)
	check(injury in b.dressed and a.dressed.is_empty(),"Bandage binds selected hero only")
	before=ps.time_elapsed
	check(ps.use_item(item("dressing"),false,b)=="" and ps.time_elapsed==before,"Already dressed target spends nothing")
	var bane:Boon=load("res://data/boons/shaking_hands.tres")
	a.add_boon(bane);b.add_boon(bane)
	ps.supplies.add(item("holy_water"),3)
	ps.use_item(item("holy_water"),false,b)
	check(a.has_bane() and not b.has_bane(),"Holy water lifts selected hero's bane")
	check(ps.use_item(item("holy_water"),false,b)=="","Uncursed selected hero cannot redirect holy water")
	ps.use_item(item("holy_water"))
	check(not a.has_bane(),"Omitted holy-water recipient preserves default behaviour")
	for h in ps.members:h.pending_effects.clear();h.health=4
	ps.supplies.add(item("ration"))
	ps.use_item(item("ration"),false,a)
	check(ps.members.all(func(h):return not h.pending_effects.is_empty()),"Ration still feeds whole party")
	ps.supplies.oil=10;ps.supplies.has_lantern=true;ps.supplies.add(item("oil_flask"))
	ps.use_item(item("oil_flask"),false,b)
	check(ps.supplies.oil>10,"Oil still refills shared light")
	ps=null

func action(kind:String) -> Button:
	for b in pack._detail_actions.get_children():
		if b.get_meta("kit_focus","")=="action:"+kind:return b
	return null

func tile(resource:Resource) -> Button:
	for b in pack._bag.slots:
		if b.has_meta("item") and b.get_meta("item")==resource:return b
	return null

func move(point:Vector2,held:=false) -> void:
	var event:=InputEventMouseMotion.new();event.position=point;event.global_position=point
	event.relative=point-root.get_mouse_position()
	event.button_mask=MOUSE_BUTTON_MASK_LEFT if held else 0
	Input.parse_input_event(event);await process_frame

func mouse_button(point:Vector2,pressed:bool) -> void:
	var event:=InputEventMouseButton.new();event.position=point;event.global_position=point;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=pressed
	event.button_mask=MOUSE_BUTTON_MASK_LEFT if pressed else 0
	Input.parse_input_event(event);await process_frame

func click(control:Control,touch:=false) -> void:
	var point:=control.get_global_rect().get_center()
	if touch:
		for pressed in [true,false]:
			var event:=InputEventScreenTouch.new();event.index=0;event.position=point;event.pressed=pressed
			Input.parse_input_event(event);await process_frame
	else:
		await move(point);await mouse_button(point,true);await mouse_button(point,false)
	await settle()

func drag(source:Control,destination:Vector2,touch:=false) -> void:
	var start:=source.get_global_rect().get_center()
	if touch:
		var press:=InputEventScreenTouch.new();press.index=0;press.position=start;press.pressed=true;Input.parse_input_event(press);await process_frame
		for point in [start+Vector2(18,0),destination]:
			var motion:=InputEventScreenDrag.new();motion.index=0;motion.position=point;motion.relative=point-start
			Input.parse_input_event(motion);await process_frame
		var release:=InputEventScreenTouch.new();release.index=0;release.position=destination;release.pressed=false;Input.parse_input_event(release)
	else:
		await move(start);await mouse_button(start,true)
		await move(start+Vector2(18,0),true);await move(destination,true)
		if not root.gui_is_dragging():print("Failed drag start: ",source.accessibility_name," hovered=",root.gui_get_hovered_control()," selection=",pack._selection)
		check(root.gui_is_dragging() and pack._selection==null,"Drag stays active without hover cards covering the destination")
		await mouse_button(destination,false)
	await settle()

func snap(name:String) -> void:
	if DisplayServer.get_name()=="headless":return
	await settle();await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(out+name+".png")==OK,"Capture "+name)
	captures.append(name+".png")

func fit(phone:bool) -> void:
	# Scale the preview cutout with its UI height; actual devices use their safe area.
	var inset:=Vector4(97,0,97,35)*(root.get_visible_rect().size.y/648.0) if phone else Vector4.ZERO
	pack.content.offset_left=inset.x;pack.content.offset_right=-inset.z
	pack.content.offset_top=inset.y;pack.content.offset_bottom=-inset.w

func run() -> void:
	DirAccess.make_dir_recursive_absolute(out)
	Engine.set_meta("depths_settings",preload("res://scripts/settings.gd").DEFAULTS.duplicate())
	Engine.set_meta("depths_settings_loaded",true)
	preload("res://scripts/ui_theme.gd").install()
	model_checks()
	party=new_party();party.supplies.gold=84;party.supplies.oil=42
	for h in party.members:h.health=5
	for id in ["oil_flask","ration","restorative_draught","dressing","holy_water"]:party.supplies.add(item(id),3)
	for id in ["plain_knife","simple_spear","padded_coat","satchel"]:party.supplies.gear.append(gear(id))
	pack=PACK.new();root.add_child(pack);pack.setup(party);await settle()
	for shape in [Vector2i(1280,720),Vector2i(1278,590),Vector2i(844,390),Vector2i(1334,750)]:
		root.size=shape
		for scale_factor in [1.0,1.3]:
			root.content_scale_factor=scale_factor;fit(shape.y!=720);pack.clear_inspection();await settle()
			var tag:="%d-%s"%[shape.x,"larger" if scale_factor>1 else "normal"]
			check(not pack._details.visible,"No bottom strip "+tag)
			check(pack._hero_row.get_global_rect().end.x<pack._equipment.global_position.x,"Portrait rail on left "+tag)
			for hero_button in pack._hero_row.get_children():
				check(hero_button.get_global_rect().encloses(hero_button.get_child(0).get_global_rect()),"Portrait stays inside button "+tag)
			for slot_button in pack._slot_buttons.values():
				check(pack._equipment.get_global_rect().grow(1).encloses(slot_button.get_global_rect()),"Slots stay inside equipment roll "+tag)
			for b in pack.find_children("*","Button",true,false):
				if not b.is_visible_in_tree():continue
				check(root.get_visible_rect().encloses(b.get_global_rect()),"Control inside viewport "+tag+" "+b.accessibility_name)
				check(b.size.x>=43.9 and b.size.y>=43.9,"44px target "+tag+" "+b.accessibility_name)
			await snap("equipment-"+tag)
			pack.inspect_item(gear("simple_spear"));await settle()
			check(pack.content.get_global_rect().encloses(pack._details.get_global_rect()),"Safe item card "+tag)
			check(not pack._details.get_global_rect().intersects(pack._anchor_rect),"Card leaves source pocket reachable "+tag)
			check(pack._detail_actions.global_position.y>=pack._detail_scroll.get_global_rect().end.y,"Actions under brief "+tag)
			check(action("equip").size.y>=44,"Reachable Equip "+tag)
			check(pack._detail_scroll.size.y<=pack._detail_text.get_combined_minimum_size().y+20,"Actions follow brief without a large empty gap "+tag)
			await snap("inspect-"+tag)
			pack.clear_inspection()
	root.size=Vector2i(1278,590);root.content_scale_factor=1;fit(true);await settle()
	party.supplies.add(item("ration"),6);await settle()
	var stacks=pack._bag.slots.filter(func(b):return b.has_meta("item") and b.get_meta("item")==item("ration"))
	await move(stacks[-1].get_global_rect().get_center());await settle()
	check(stacks.size()>1 and pack._anchor_rect==stacks[-1].get_global_rect(),"Duplicate stacks anchor to the hovered pocket")
	pack.clear_inspection()
	var before:int=party.time_elapsed
	await move(tile(item("restorative_draught")).get_global_rect().get_center());await settle()
	check(pack._details.visible and not pack._pinned and party.time_elapsed==before,"Mouse hover previews without using")
	await click(tile(item("restorative_draught")),true)
	check(pack._pinned,"Touch pins item card")
	await move(action("use").get_global_rect().get_center());await create_timer(0.2).timeout
	check(pack._details.visible,"Card stays while pointer reaches actions")
	check(action("use").text=="Drink","Contextual Drink verb")
	await click(action("use"),true)
	check(party.time_elapsed==before+1 and not party.members[0].pending_effects.is_empty() and party.members[1].pending_effects.is_empty(),"Touch Drink uses selected hero once")
	pack.clear_inspection();await settle()
	before=party.time_elapsed
	await drag(tile(item("restorative_draught")),pack._hero_row.get_child(1).get_global_rect().get_center())
	check(not party.members[1].pending_effects.is_empty() and party.time_elapsed==before+1 and pack._selected_hero==party.members[1],"Real mouse drag treats destination portrait")
	party.members[2].add_injury(load("res://data/injuries/deep_wound.tres"))
	pack.select_hero(party.members[2]);await settle();before=party.time_elapsed
	await drag(tile(item("dressing")),pack._equipment.get_global_rect().get_center(),true)
	check(not party.members[2].dressed.is_empty() and party.time_elapsed==before+3,"Real touch drag onto selected hero area binds injury")
	pack.clear_inspection();await settle()
	await drag(tile(gear("padded_coat")),pack._slot_buttons.body.get_global_rect().get_center())
	check(party.members[2].body==gear("padded_coat"),"Gear drag onto its slot equips")
	await drag(pack._slot_buttons.body,pack._bag.get_global_rect().get_center())
	check(party.members[2].body==null and gear("padded_coat") in party.supplies.gear,"Gear drag back into bag takes off")
	var payload:={"kit_drag":"bag","party":party,"item":item("dressing")}
	check(not pack._can_drop_on_hero(Vector2.ZERO,payload,party.members[2]),"Invalid already-dressed drop rejected")
	payload.item=gear("plain_knife");payload.party=PARTY.new()
	check(not pack._can_drop_on_selected(Vector2.ZERO,payload),"Foreign-party drag rejected")
	payload.party=party
	check(not pack._can_drop_on_slot(Vector2.ZERO,payload,"body"),"Wrong equipment slot rejected")
	check(not pack._can_drop_on_bag(Vector2.ZERO,{"kit_drag":"slot","party":party,"hero":party.members[2],"slot":"back","item":null}),"Stale empty-slot drag rejected safely")
	# A deliberately long test item verifies scroll access without altering live items.
	var long_item:Equipment=gear("plain_knife").duplicate()
	long_item.description="A weathered knife. ".repeat(100)+"END OF DESCRIPTION"
	party.supplies.gear.append(long_item);pack.refresh();pack.inspect_item(long_item);await settle()
	check(pack._detail_scroll.get_v_scroll_bar().max_value>pack._detail_scroll.size.y,"Long description scrolls")
	pack._detail_scroll.scroll_vertical=10000;await settle()
	check(pack._detail_text.get_child(-1).get_global_rect().end.y<=pack._detail_scroll.get_global_rect().end.y+1,"End of long brief reachable")
	check(pack._details.get_global_rect().encloses(action("drop").get_global_rect()),"Actions remain inside long card")
	await snap("long-description-phone")
	pack.clear_inspection();pack.inspect_item(item("ration"));await settle()
	check(action("use").text=="Eat","Contextual Eat verb")
	var stale:Callable=action("use").pressed.get_connections()[0].callable
	await click(pack._hero_row.get_child(0),true)
	stale.call()
	check(pack._selection==null,"Switching hero dismisses and invalidates old card")
	pack.inspect_item(item("dressing"));await settle()
	check(action("use").disabled,"Unavailable action disabled with reason")
	await snap("unavailable-phone")
	pack.clear_inspection();pack.select_hero(party.members[1]);pack.set_status(true);await settle();await snap("status-phone")
	pack.free();party=null;await process_frame
	var file:=FileAccess.open(out+"validation.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"captures":captures,"physical_iPhone":false,"uses_player_files":false},"\t")+"\n");file.close()
	print("PACK_CONTEXT: checks=%d failures=%d"%[checks,failures.size()])
	quit(0 if failures.is_empty() else 1)

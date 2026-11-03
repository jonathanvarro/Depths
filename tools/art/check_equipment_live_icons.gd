extends SceneTree
## #196: real equipment Pack/loot/merchant views, isolated from Main and player files.
const DIR:="res://art/items/equipment-live-v1/"
const OUT:="res://art/concepts/equipment-live-v1/"
const PARTY:=preload("res://scripts/party_state.gd")
const CAMP:=preload("res://scripts/camp_state.gd")
const PACK:=preload("res://scripts/pack_screen.gd")
const CHEST:=preload("res://scripts/chest_screen.gd")
const MERCHANT:=preload("res://scripts/merchant_screen.gd")
const SETTINGS:=preload("res://scripts/settings.gd")
const SAFE:=preload("res://scripts/safe_area.gd")
const MODEL:=preload("res://scripts/gear_model.gd")
const SAVE:=preload("res://scripts/save_game.gd")
var checks:=0
var failures:Array[String]=[]
var captures:Array[String]=[]

func _initialize() -> void:
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED;call_deferred("run")
func check(ok:bool,label:String) -> void:
	checks+=1
	if not ok:failures.append(label);push_error(label)
func settle() -> void:
	for i in 8:await process_frame
func fit(view:Control,phone:bool) -> void:
	var inset:=SAFE.insets(root,phone)
	view.content.offset_left=inset.x;view.content.offset_top=inset.y
	view.content.offset_right=-inset.z;view.content.offset_bottom=-inset.w
func snap(name:String) -> void:
	if DisplayServer.get_name()=="headless":return
	var move:=InputEventMouseMotion.new();move.position=Vector2(-100,-100);Input.parse_input_event(move)
	await settle();await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(OUT+name+".png")==OK,"Real UI capture "+name);captures.append(name+".png")

func run() -> void:
	Engine.set_meta("depths_settings",SETTINGS.DEFAULTS.duplicate());Engine.set_meta("depths_settings_loaded",true)
	SETTINGS.ensure_buses();AudioServer.set_bus_mute(0,true);preload("res://scripts/ui_theme.gd").install()
	var catalog:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(DIR+"catalog.json"))
	var party=PARTY.new();party.add_member(load("res://data/companions/mara.tres"))
	party.supplies.gold=24
	var items:Array[Equipment]=[];var loot:={}
	var rng:=RandomNumberGenerator.new();rng.seed=196
	for entry in catalog.items:
		var item:Equipment=preload("res://scripts/gear_model.gd").generate(rng,entry.id,"ordinary");items.append(item);loot[item]=1;party.supplies.gear.append(item)
		var base:Dictionary=MODEL.base(entry.id)
		var uri:String=base.icon
		for quality in ["cracked","bent","ordinary","fine","exceptional"]:
			var a:=RandomNumberGenerator.new();a.seed=196
			var b:=RandomNumberGenerator.new();b.seed=196
			base.erase("icon")
			var old:Equipment=MODEL.generate(a,entry.id,quality)
			base.icon=uri
			var fresh:Equipment=MODEL.generate(b,entry.id,quality)
			var old_data:=SAVE.pack_object(old);var new_data:=SAVE.pack_object(fresh)
			for key in ["icon","description"]:old_data.erase(key);new_data.erase(key)
			check(old_data==new_data and a.state==b.state,"Art preserves all rolls and RNG "+entry.id+quality)
			var restored:Equipment=SAVE.unpack_value(SAVE.pack_value(old))
			var same:=MODEL.ensure_instance(restored)
			check(same==restored and restored.icon.resource_path==uri and SAVE.pack_object(restored)==SAVE.pack_object(fresh),"Saved item refreshes without reroll "+entry.id+quality)
		check(item.icon.resource_path==entry.export and item.icon.get_size()==Vector2(128,128),"Live icon "+entry.id)
		check((load(entry.compact) as Texture2D).get_size()==Vector2(64,64),"Compact64 "+entry.id)
		check(not item.description.contains("Placeholder picture"),"Current description "+entry.id)
	var pack=PACK.new();root.add_child(pack);pack.setup(party)
	var chest=CHEST.new();root.add_child(chest)
	var merchant=MERCHANT.new();root.add_child(merchant)
	var camp=CAMP.new();camp.merchant_unloading=false
	pack.refresh();await settle()
	check(pack._entries.size()==7,"All seven equipment appear in the real bag")
	for item in items:
		pack.inspect_item(item,true);await settle()
		check(pack._detail_icon.texture==item.icon,"Pack inspection uses actual icon "+item.display_name)
	pack.hide();merchant.open(camp,party);await settle()
	check(merchant._bag_entries.size()==7,"All seven equipment appear for merchant sale")
	for item in items:
		merchant.select_item(item,"right");await settle()
		check(merchant._detail_icon.texture==item.icon,"Merchant inspection uses actual icon "+item.display_name)
	merchant.hide()
	for profile in [[1280,720,1.0],[1278,590,1.0],[1278,590,1.3],[1334,750,1.3]]:
		root.size=Vector2i(profile[0],profile[1]);root.content_scale_factor=profile[2]
		var tag:="%d-%s"%[profile[0],"larger" if profile[2]>1 else "normal"]
		chest.hide();merchant.hide();pack.show();fit(pack,profile[0]!=1280);pack.refresh();pack.clear_inspection();await settle()
		await snap("pack-"+tag)
		pack.hide();chest.open("Recovered equipment",loot,party);fit(chest,profile[0]!=1280);await settle()
		chest.select_item(items[0],"left");await snap("loot-"+tag)
		chest.hide();merchant.open(camp,party);fit(merchant,profile[0]!=1280);await settle()
		merchant.select_item(items[5],"right");await snap("merchant-"+tag);merchant.hide()
	check(party.time_elapsed==0 and party.supplies.gold==24 and items.all(func(item):return item in party.supplies.gear),"Review leaves inventory, purse and time unchanged")
	var f:=FileAccess.open(OUT+("godot-headless.json" if DisplayServer.get_name()=="headless" else "godot-renderer.json"),FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks":checks,"failures":failures,"captures":captures,"renderer":RenderingServer.get_current_rendering_method(),"uses_player_files":false,"physical_iphone_tested":false},"\t")+"\n");f.close()
	print("EQUIPMENT_GODOT: %d checks, %d failures, %d captures"%[checks,failures.size(),captures.size()])
	pack.free();chest.free();merchant.free();await process_frame;quit(0 if failures.is_empty() else 1)

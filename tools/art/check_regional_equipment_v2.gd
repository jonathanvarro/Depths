extends "res://tools/art/check_regional_equipment_icons.gd"
const V2:="res://art/items/regional-equipment-v2/"
func run() -> void:
	out=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(out)
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	Engine.set_meta(SETTINGS.STATE,SETTINGS.DEFAULTS.duplicate());Engine.set_meta(SETTINGS.STATE+"_loaded",true)
	SETTINGS.ensure_buses();AudioServer.set_bus_mute(0,true)
	preload("res://scripts/ui_theme.gd").install()
	var items: Array[Equipment]=[]
	for id in ["quilted_coat","studded_jerkin","goblin_scale","goblin_shield"]:
		var base:=MODEL.base(id);var uri: String=base.icon
		for quality in ["cracked","bent","ordinary","fine","exceptional"]:
			var old_rng:=RandomNumberGenerator.new();old_rng.seed=194195
			var new_rng:=RandomNumberGenerator.new();new_rng.seed=194195
			base.erase("icon");var legacy:=MODEL.generate(old_rng,id,quality)
			base.icon=uri;var current:=MODEL.generate(new_rng,id,quality)
			check(SAVE.pack_object(legacy,["icon"])==SAVE.pack_object(current,["icon"]) and old_rng.state==new_rng.state,"Icon-only rolls "+id+quality)
			var restored: Equipment=SAVE.unpack_value(SAVE.pack_value(legacy))
			MODEL.ensure_instance(restored)
			check(restored.icon.resource_path==V2+id+".png","Saved gear art "+id+quality)
		var rng:=RandomNumberGenerator.new();rng.seed=194195
		var item:=MODEL.generate(rng,id,"ordinary");items.append(item)
		check(item.icon.get_size()==Vector2(128,128),"Native128 "+id)
		check(load(V2+"compact64/"+id+".png").get_size()==Vector2(64,64),"Compact64 "+id)
	check(load("res://data/gear/padded_coat.tres").icon==items[0].icon,"Authored quilted coat shares art")
	var party=preload("res://scripts/party_state.gd").new();party.add_member(load("res://data/companions/mara.tres"))
	party.supplies.gear.append_array(items)
	var pack=preload("res://scripts/pack_screen.gd").new();root.add_child(pack);pack.setup(party)
	var chest=preload("res://scripts/chest_screen.gd").new();root.add_child(chest)
	var merchant=preload("res://scripts/merchant_screen.gd").new();root.add_child(merchant)
	var camp=preload("res://scripts/camp_state.gd").new();camp.merchant_unloading=false
	for size in [Vector2i(1278,590),Vector2i(852,393)]:
		root.size=size
		for item in items:
			var suffix:=item.icon.resource_path.get_file().get_basename()+"-"+str(size.x)
			pack.show();fit(pack);pack.refresh();pack.inspect_item(item,true)
			await capture("pack-"+suffix);check(pack._detail_icon.texture==item.icon,"Pack art "+suffix);pack.hide()
			chest.open("Regional equipment",{item:1},party);fit(chest);await process_frame;chest.select_item(item,"left")
			await capture("loot-"+suffix);check(chest._detail_icon.texture==item.icon,"Loot art "+suffix);chest.hide()
			merchant.open(camp,party);fit(merchant);await process_frame;merchant.select_item(item,"right")
			await capture("merchant-"+suffix);check(merchant._detail_icon.texture==item.icon,"Merchant art "+suffix);merchant.hide()
	check(party.time_elapsed==0 and party.supplies.gear.size()==4,"Inspection preserves time and equipment")
	FileAccess.open(out.path_join("regional-v2-validation.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"captures":captures},"\t"))
	print("REGIONAL_V2 ",checks," failures=",failures)
	pack.free();chest.free();merchant.free();await process_frame;quit(0 if failures.is_empty() else 1)

extends SceneTree
## Confirm regional art on generated and recovered gear through the actual views.
const ICONS := "res://art/items/regional-equipment-v1/"
const MODEL := preload("res://scripts/gear_model.gd")
const SAVE := preload("res://scripts/save_game.gd")
const SETTINGS := preload("res://scripts/settings.gd")
const SAFE := preload("res://scripts/safe_area.gd")
var out := ""
var checks := 0
var failures: Array[String] = []
var captures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		push_error(label)

func capture(name: String) -> void:
	for frame in 6:
		await process_frame
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	var filename := name + ".png"
	check(root.get_texture().get_image().save_png(out + "/" + filename) == OK, "Capture " + name)
	captures.append(filename)

func fit(view: Control) -> void:
	var inset := SAFE.insets(root,true)
	view.content.offset_left = inset.x
	view.content.offset_top = inset.y
	view.content.offset_right = -inset.z
	view.content.offset_bottom = -inset.w

func run() -> void:
	out = OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(out)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	Engine.set_meta(SETTINGS.STATE,SETTINGS.DEFAULTS.duplicate())
	Engine.set_meta(SETTINGS.STATE+"_loaded",true)
	SETTINGS.ensure_buses()
	AudioServer.set_bus_mute(0,true)
	preload("res://scripts/ui_theme.gd").install()
	var original := load("res://data/gear/companion_mace.tres") as Equipment
	var mace_base := MODEL.base("light_mace")
	var icon_uri: String = mace_base.icon
	var rng := RandomNumberGenerator.new()
	rng.seed = 194195
	var mace := MODEL.generate(rng,"light_mace","ordinary")
	var sledge := load("res://data/gear/miners_sledge.tres") as Equipment
	check(mace.icon.resource_path == ICONS+"light_mace.png","Generated Light mace uses new art")
	check(sledge.icon.resource_path == ICONS+"miners_sledge.png","Tool rack resource uses hammer art")
	check(original.icon.resource_path != mace.icon.resource_path,"Founder mace retains original icon")
	for quality in ["cracked","bent","ordinary","fine","exceptional"]:
		var old_rng := RandomNumberGenerator.new()
		old_rng.seed = 194195
		var new_rng := RandomNumberGenerator.new()
		new_rng.seed = 194195
		mace_base.erase("icon")
		var legacy := MODEL.generate(old_rng,"light_mace",quality)
		mace_base.icon = icon_uri
		var current := MODEL.generate(new_rng,"light_mace",quality)
		check(SAVE.pack_object(legacy,["icon"]) == SAVE.pack_object(current,["icon"])
			and old_rng.state == new_rng.state,"Icon-only generation " + quality)
		var restored: Equipment = SAVE.unpack_value(SAVE.pack_value(legacy))
		check(MODEL.ensure_instance(restored) == restored and
			SAVE.pack_object(restored) == SAVE.pack_object(current),"Old saved icon upgrades " + quality)
	var items: Array[Equipment] = [sledge,mace]
	for item in items:
		check(item.icon.get_size() == Vector2(128,128),"Native128 " + item.display_name)
		var compact := load(ICONS+"compact64/"+item.icon.resource_path.get_file()) as Texture2D
		check(compact.get_size() == Vector2(64,64),"Compact64 " + item.display_name)
	var party = preload("res://scripts/party_state.gd").new()
	party.add_member(load("res://data/companions/mara.tres"))
	party.supplies.gold = 24
	party.supplies.gear.append_array(items)
	var pack = preload("res://scripts/pack_screen.gd").new()
	var chest = preload("res://scripts/chest_screen.gd").new()
	var merchant = preload("res://scripts/merchant_screen.gd").new()
	var camp = preload("res://scripts/camp_state.gd").new()
	camp.merchant_unloading = false
	root.add_child(pack)
	root.add_child(chest)
	root.add_child(merchant)
	pack.setup(party)
	for size: Vector2i in [Vector2i(1278,590),Vector2i(852,393)]:
		root.size = size
		for item in items:
			var suffix := item.icon.resource_path.get_file().get_basename()+"-"+str(size.x)
			pack.show()
			fit(pack)
			pack.refresh()
			pack.inspect_item(item,true)
			await capture("pack-"+suffix)
			check(pack._detail_icon.texture == item.icon,"Pack " + suffix)
			pack.hide()
			chest.open("Recovered equipment",{item:1},party)
			fit(chest)
			await process_frame
			chest.select_item(item,"left")
			await capture("loot-"+suffix)
			check(chest._detail_icon.texture == item.icon,"Loot " + suffix)
			chest.hide()
			merchant.open(camp,party)
			fit(merchant)
			await process_frame
			merchant.select_item(item,"right")
			await capture("merchant-"+suffix)
			check(merchant._detail_icon.texture == item.icon,"Merchant " + suffix)
			merchant.hide()
	check(party.supplies.gold == 24 and party.time_elapsed == 0 and party.supplies.gear.size() == 2,
		"Inspecting preserves purse, time and pack")
	var report := {"checks":checks,"failures":failures,"captures":captures}
	var filename := "headless.json" if DisplayServer.get_name()=="headless" else "renderer.json"
	FileAccess.open(out+"/"+filename,FileAccess.WRITE).store_string(JSON.stringify(report,"  ")+"\n")
	print("REGIONAL ICONS ",checks," failures=",failures)
	pack.free()
	chest.free()
	merchant.free()
	await process_frame
	quit(0 if failures.is_empty() else 1)

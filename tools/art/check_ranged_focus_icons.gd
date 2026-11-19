extends SceneTree
## Native review of the four inventory images and their normal entry points.
const NAMES := ["sling", "short_bow", "wand", "oak_staff"]
var fails := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	print("PASS " if ok else "FAIL ", label)
	if not ok:
		fails += 1

func settle() -> void:
	for frame in 4:
		await process_frame

func run() -> void:
	var party = load("res://scripts/party_state.gd").new()
	party.add_member(load("res://data/companions/mara.tres"))
	party.members[0].display_name = "Mara"
	var camp = load("res://scripts/camp_state.gd").new()
	party.supplies.gold = 500
	var goods: Array[Equipment] = []
	for name in NAMES:
		var item: Equipment = load("res://data/gear/%s.tres" % name)
		goods.append(item)
		check(item.icon.resource_path.contains("ranged-focus-v2") and item.icon.get_size() == Vector2(128,128), name + " new inventory image")
		check(item in camp.SMITH_STOCK, name + " stocked by the apprentice")
		check(camp.buy_gear(party,item), name + " can be bought through existing trade")
	var pack = load("res://scripts/pack_screen.gd").new()
	root.add_child(pack)
	pack.setup(party)
	pack.show()
	pack.refresh()
	await settle()
	check(party.supplies.gear.all(func(item): return item.icon.resource_path.contains("ranged-focus-v2")),
		"purchased instances use the new images on inventory tiles")
	var args := OS.get_cmdline_user_args()
	for item in goods:
		pack.inspect_item(item)
		await settle()
		check(pack._detail_icon.texture == item.icon and pack._detail_title.text == item.display_name, item.display_name + " Pack inspection")
		if not args.is_empty():
			await RenderingServer.frame_post_draw
			var name: String = item.resource_path.get_file().get_basename()
			check(root.get_texture().get_image().save_png(args[0].path_join(name+"-pack.png")) == OK, name + " phone capture")
	pack.hide()
	var smith = load("res://scripts/smith_screen.gd").new()
	root.add_child(smith)
	smith.open(camp,party)
	await settle()
	if not args.is_empty():
		await RenderingServer.frame_post_draw
		check(root.get_texture().get_image().save_png(args[0].path_join("smith.png")) == OK, "smith phone capture")
	print("fails=",fails)
	quit(fails)

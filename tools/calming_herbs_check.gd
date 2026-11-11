extends SceneTree
## #244 real Pack display at desktop and landscape phone sizes.
var checks := 0
var failures: Array[String] = []
var captures: Array[String] = []
const OUT := "E:/GitHub/Depths/build/local-traps-sites-mist-v1/captures/"
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks+=1
	if not ok: failures.append(label); push_error(label)
func run() -> void:
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	var item: SupplyItem=load("res://data/items/calming_herbs.tres")
	check(item.icon.resource_path=="res://art/items/field-kit-v1/calming-herbs.png","Dedicated live herb icon")
	check(item.icon.get_size()==Vector2(128,128),"Native 128px")
	check(item.price==8 and item.amount==20 and item.use_time==2 and not item.usable_in_combat,"Resource rules preserved")
	var party=load("res://scripts/party_state.gd").new()
	party.add_member(load("res://data/companions/mara.tres"))
	party.supplies.add(item,2)
	var pack=load("res://scripts/pack_screen.gd").new()
	root.add_child(pack)
	pack.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pack.setup(party)
	for size in [Vector2i(1278,590),Vector2i(852,393),Vector2i(667,375)]:
		root.size=size
		for i in 6: await process_frame
		check(pack.inspect_item_by_name("Calming herbs"),"Real item inspection")
		for i in 6: await process_frame
		check(pack._detail_icon.texture==item.icon,"Real detail uses herb art")
		check(pack._detail_title.text=="Calming herbs","Real herb title")
		await RenderingServer.frame_post_draw
		var name: String="herbs-pack-%d.png" % size.x
		check(root.get_texture().get_image().save_png(OUT+name)==OK,"Capture "+name)
		captures.append(name)
	var file:=FileAccess.open(OUT+"../herbs-validation.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"captures":captures},"  ")+"\n")
	print("HERBS_CHECKS ",checks," failures=",failures.size())
	quit(0 if failures.is_empty() else 1)

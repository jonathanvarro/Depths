extends SceneTree
## #272: fitted equipment art and a stable, truthful item-stat header.
const PACK:=preload("res://scripts/pack_screen.gd")
const PARTY:=preload("res://scripts/party_state.gd")
const SETTINGS:=preload("res://scripts/settings.gd")
const SAFE:=preload("res://scripts/safe_area.gd")
var checks:=0
var failures:Array[String]=[]
var output:=""

func _initialize() -> void:
	Engine.set_meta("depths_settings",SETTINGS.DEFAULTS.duplicate())
	Engine.set_meta("depths_settings_loaded",true)
	preload("res://scripts/ui_theme.gd").install()
	var args:=OS.get_cmdline_user_args()
	output=args[0] if not args.is_empty() else "res://build/pack-brief-check"
	DirAccess.make_dir_recursive_absolute(output)
	call_deferred("run")

func check(ok:bool,label:String) -> void:
	checks+=1
	if not ok:failures.append(label);push_error(label)

func settle() -> void:
	for i in 10:await process_frame

func snap(label:String) -> void:
	if DisplayServer.get_name()=="headless":return
	await settle()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(label+".png"))

func run() -> void:
	var party=PARTY.new()
	for id in ["mara","corin","alwen"]:party.add_member(load("res://data/companions/"+id+".tres"))
	var hero:Companion=party.members[0]
	hero.weapon=load("res://data/gear/companion_short_sword.tres").duplicate()
	hero.body=load("res://data/gear/padded_coat.tres").duplicate()
	hero.back=load("res://data/gear/frame_pack.tres").duplicate()
	hero.body.tier="rare" # stress the frame's extra padding, on a private copy
	var spare:Equipment=load("res://data/gear/simple_spear.tres").duplicate()
	party.supplies.gear.append(spare)
	party.supplies.add(load("res://data/items/restorative_draught.tres"),2)
	var pack=PACK.new();root.add_child(pack);pack.setup(party)
	await settle()
	for shape in [Vector2i(1280,720),Vector2i(1278,590),Vector2i(844,390),Vector2i(667,375)]:
		for scale_factor in [1.0,1.3]:
			root.size=shape;root.content_scale_factor=scale_factor
			var safe:=SAFE.insets(root,shape.y<720)
			for side in ["left","top","right","bottom"]:
				pack.content.add_theme_constant_override("margin_"+side,12)
			pack.content.offset_left=safe.x;pack.content.offset_top=safe.y
			pack.content.offset_right=-safe.z;pack.content.offset_bottom=-safe.w
			pack.clear_inspection();await settle()
			var cloth:Rect2=pack._roll_contents.get_global_rect()
			for button:Button in pack._slot_buttons.values():
				check(cloth.grow(1).encloses(button.get_global_rect()),"slot is inside physical cloth")
				var picture:Control=button.get_child(0)
				check(cloth.grow(1).encloses(picture.get_global_rect()),"icon fits physical cloth, including rare frame")
				check(button.clip_contents and pack._roll_contents.clip_contents,"no decorative spill beyond the roll")
			var saved:Equipment=hero.weapon
			pack.inspect_item(hero.weapon,true,"weapon");await settle()
			check(pack._detail_stats.visible and pack._detail_stats.text==pack._as_known(hero,func():return pack._numbers(hero,hero.weapon)).replace(" dmg, "," damage · "),"equipped damage/accuracy is correct and always visible")
			check(pack._detail_stats.global_position.y>=pack._detail_title.global_position.y,"numbers follow the title")
			check(pack._detail_stats.get_global_rect().end.y<=pack._detail_scroll.global_position.y,"numbers precede scrollable prose")
			var pictures=pack._details.find_children("*","TextureRect",true,false)
			check(pictures.all(func(p):return p.texture!=hero.weapon.icon),"no duplicate item picture in brief")
			var text:=" ".join(pack._detail_text.find_children("*","Label",true,false).map(func(label):return label.text))
			check(not text.contains("Replace this weapon from the pack"),"no redundant replacement instruction")
			check(hero.weapon==saved,"inspection preserves the worn resource")
			check(pack.content.get_global_rect().encloses(pack._details.get_global_rect()),"new header stays in the safe area")
			await snap("worn-%d-%s" % [shape.x,"larger" if scale_factor>1 else "normal"])
			pack.inspect_item(spare,true);await settle()
			check(pack._detail_stats.visible and pack._detail_comparison.visible,"carried weapon has the same stat header and a secondary comparison")
			check(pack._detail_stats.text==pack._as_known(hero,func():return pack._numbers(hero,spare)).replace(" dmg, "," damage · "),"carried stats use the selected hero")
			check(hero.weapon==saved,"comparison preserves the worn resource")
			await snap("carried-%d-%s" % [shape.x,"larger" if scale_factor>1 else "normal"])
	FileAccess.open(output.path_join("validation.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"physical_iPhone":false},"\t"))
	pack.queue_free();await create_timer(.2).timeout
	print("PACK_BRIEF checks=%d failures=%d" % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)

extends SceneTree
## Real Pack and PartyCard components in isolation. No Main or saves.
const OUT := "res://art/concepts/field-kit-v1/"
const PARTY := preload("res://scripts/party_state.gd")
const PACK := preload("res://scripts/pack_screen.gd")
const CARD := preload("res://scripts/party_card.gd")
var checks := 0
var failures: Array[String] = []
var captures: Array[String] = []

func _initialize() -> void:
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	call_deferred("_run")

func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:
		failures.append(label)
		push_error(label)

func settle() -> void:
	for tick in 6: await process_frame

func snap(name: String) -> void:
	await settle()
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(OUT+name+".png")==OK,"Saved "+name)
	captures.append(name)

func _run() -> void:
	var catalogue: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://art/items/field-kit-v1/catalog.json"))
	for entry: Dictionary in catalogue.items+catalogue.symbols:
		var definition=load(entry.resource)
		check(definition.icon!=null and definition.icon.resource_path==entry.icon,"Real resource binding "+entry.id)
		check(definition.icon.get_size()==Vector2(128,128) if entry in catalogue.items else definition.icon.get_size()==Vector2(32,32),"Imported canvas "+entry.id)
	var party=PARTY.new()
	party.add_member(load("res://data/companions/mara.tres"))
	for entry: Dictionary in catalogue.items:
		var definition=load(entry.resource)
		if definition is Equipment:party.supplies.gear.append(definition)
		else:party.supplies.add(definition)
	var pack=PACK.new()
	root.add_child(pack)
	pack.setup(party)
	await settle()
	var textures: Array=pack.find_children("*","TextureRect",true,false)
	for entry: Dictionary in catalogue.items:
		check(textures.any(func(t):return t.texture!=null and t.texture.resource_path==entry.icon),"Actual Pack draws "+entry.id)
	for phone in [false,true]:
		root.size=Vector2i(1278,590) if phone else Vector2i(1280,720)
		await settle()
		for id in ["leather-satchel","oilcloth-cloak","miners-pick","antidote"]:
			var target: TextureRect=textures.filter(func(t):return t.texture!=null and t.texture.resource_path.ends_with("/"+id+".png"))[0]
			var row: Control=target
			while row.get_parent()!=pack._list:row=row.get_parent()
			pack._inventory_scroll.ensure_control_visible(row)
			await snap("pack-"+id+("-phone" if phone else "-desktop"))
	pack.queue_free()
	await settle()
	var background:=ColorRect.new()
	background.color=Color("171e1a")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(background)
	var margin:=MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["top","left","bottom","right"]:margin.add_theme_constant_override("margin_"+side,24)
	root.add_child(margin)
	var grid:=GridContainer.new()
	grid.columns=6
	grid.add_theme_constant_override("h_separation",16)
	grid.add_theme_constant_override("v_separation",28)
	margin.add_child(grid)
	var cards: Array=[]
	for entry: Dictionary in catalogue.symbols:
		var column:=VBoxContainer.new()
		column.custom_minimum_size=Vector2(180,190)
		grid.add_child(column)
		var label:=Label.new()
		label.text=entry.name
		label.add_theme_font_size_override("font_size",17)
		label.add_theme_color_override("font_color",Color("e6dac1"))
		column.add_child(label)
		var card=CARD.new()
		column.add_child(card)
		var hero: Companion=load("res://data/companions/mara.tres").duplicate(true)
		hero.pending_effects=[]
		hero.boons=[]
		hero.add_boon(load(entry.resource))
		card.show_companion(hero)
		cards.append(card)
	await settle()
	for i in cards.size():
		var card=cards[i]
		var entry: Dictionary=catalogue.symbols[i]
		var icons=card._icons.get_children().filter(func(n):return n is TextureRect and n.texture!=null and n.texture.resource_path==entry.icon)
		check(icons.size()==1,"Actual PartyCard uses specific symbol "+entry.id)
		if icons.size()==1:
			check(icons[0].custom_minimum_size==Vector2(14,14) and icons[0].texture_filter==CanvasItem.TEXTURE_FILTER_NEAREST,"Actual 14px nearest glyph "+entry.id)
			check(icons[0].tooltip_text.contains(load(entry.resource).display_name),"Named effect tooltip retained "+entry.id)
	for phone in [false,true]:
		root.size=Vector2i(1278,590) if phone else Vector2i(1280,720)
		await snap("party-symbols-"+("phone" if phone else "desktop"))
	var file:=FileAccess.open(OUT+"godot-validation.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"captures":captures,"limits":"Existing Pack/PartyCard components, isolated from Main and saves. Phone dimensions on Windows, not physical iPhone."},"\t")+"\n")
	file.close()
	print("FIELD_KIT_ART checks=%d failures=%d"%[checks,failures.size()])
	quit(0 if failures.is_empty() else 1)

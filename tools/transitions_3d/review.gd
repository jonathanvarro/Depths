extends Control
const ART := "res://art/features/transitions-3d-v1/"
const REGIONS := ["cave","fungal","scorched","waterlogged"]
const SKINS := preload("res://art/materials/regional-props-v1/skins.gd")
var catalog: Dictionary
var selected := 0
var angle := 0
var neutral := false
var controls: Array[Control] = []
var prop: Node3D
var stage: Node3D
var viewport: SubViewport
var camera: Camera3D
var key: DirectionalLight3D
var environment: Environment
var floor_root: Node3D
var wall: MeshInstance3D
var ceiling: MeshInstance3D

func _ready() -> void:
	catalog=JSON.parse_string(FileAccess.get_file_as_string(ART+"catalog.json"))
	var back:=ColorRect.new()
	back.color=Color("#141b1d")
	back.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(back)
	var margin:=MarginContainer.new()
	margin.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	for side in ["left","right"]: margin.add_theme_constant_override("margin_"+side,44)
	for side in ["top","bottom"]: margin.add_theme_constant_override("margin_"+side,12)
	add_child(margin)
	var column:=VBoxContainer.new()
	margin.add_child(column)
	var title:=Label.new()
	title.text="DEPTHS / TRANSITIONS, BLOCKERS AND REGIONAL PROPS"
	title.add_theme_font_size_override("font_size",16)
	column.add_child(title)
	var bar:=HFlowContainer.new()
	column.add_child(bar)
	var items:=OptionButton.new()
	for entry in catalog.assets: items.add_item(str(entry.id).replace("-"," ").capitalize())
	for region in REGIONS: items.add_item("Props / "+region.capitalize())
	bar.add_child(items)
	controls.append(items)
	items.item_selected.connect(func(value): selected=value; load_prop())
	var angles:=OptionButton.new()
	for label in ["Three-quarter","Eye height","Overhead"]: angles.add_item(label)
	bar.add_child(angles)
	controls.append(angles)
	angles.item_selected.connect(func(value): angle=value; frame_prop())
	var light:=CheckButton.new()
	light.text="Neutral"
	bar.add_child(light)
	controls.append(light)
	light.toggled.connect(func(value): neutral=value; frame_prop())
	for item in controls: item.custom_minimum_size.y=44
	var holder:=SubViewportContainer.new()
	holder.stretch=true
	holder.size_flags_vertical=SIZE_EXPAND_FILL
	column.add_child(holder)
	viewport=SubViewport.new()
	viewport.own_world_3d=true
	viewport.msaa_3d=Viewport.MSAA_4X
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	holder.add_child(viewport)
	stage=Node3D.new()
	viewport.add_child(stage)
	var world:=WorldEnvironment.new()
	environment=Environment.new()
	environment.background_mode=Environment.BG_COLOR
	environment.background_color=Color("#202a2b")
	environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	world.environment=environment
	stage.add_child(world)
	key=DirectionalLight3D.new()
	key.rotation_degrees=Vector3(-45,-30,0)
	stage.add_child(key)
	floor_root=Node3D.new()
	stage.add_child(floor_root)
	wall=plane(Vector2(4,2.4),Vector3(0,1.2,-1.04),Vector3(90,0,0),"wall")
	ceiling=plane(Vector2(4,4),Vector3(0,2.4,0),Vector3(180,0,0),"ceiling")
	ceiling.visible=false
	camera=Camera3D.new()
	camera.current=true
	stage.add_child(camera)
	var note:=Label.new()
	note.text="Floor origins / -Z forward • real recessed descents • unchanged regional meshes"
	note.add_theme_font_size_override("font_size",14)
	column.add_child(note)
	resized.connect(frame_prop)
	load_prop()

func region() -> String:
	return REGIONS[selected-catalog.assets.size()] if selected>=catalog.assets.size() else ("scorched" if str(catalog.assets[selected].id).begins_with("fortress") else "cave")

func surface(id: String) -> StandardMaterial3D:
	var base: String="res://art/textures/"+ ("stone-v1/" if selected<2 else "cave-v1/") +id+".png"
	if selected<2 and id=="wall": base="res://art/textures/stone-v1/wall_plain.png"
	match region():
		"fungal": base="res://art/textures/descent-walls-v1/fungal-stone.png" if id=="wall" else "res://art/textures/descent-surfaces-v1/fungal-stone-"+id+".png"
		"scorched": base="res://art/textures/fortress-v1/"+id+".png"
		"waterlogged": base="res://art/textures/waterworks-v1/wet-plain.png" if id=="wall" else "res://art/textures/descent-surfaces-v1/drowned-masonry-"+id+".png"
	var material:=StandardMaterial3D.new()
	material.albedo_texture=load(base)
	material.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	material.roughness=1.0
	material.uv1_triplanar=true
	material.uv1_world_triplanar=true
	material.uv1_scale=Vector3(.5,.5,.5)
	return material

func plane(size: Vector2,at: Vector3,rotation: Vector3,id: String) -> MeshInstance3D:
	var item:=MeshInstance3D.new()
	var mesh:=PlaneMesh.new()
	mesh.size=size
	item.mesh=mesh
	item.position=at
	item.rotation_degrees=rotation
	item.material_override=surface(id)
	stage.add_child(item)
	return item

func load_prop() -> void:
	if prop!=null:
		stage.remove_child(prop)
		prop.queue_free()
	for child in floor_root.get_children(): child.free()
	var recessed: bool=selected<catalog.assets.size() and catalog.assets[selected].floor_aperture
	var patches: Array=[[Vector2(6,6),Vector3(0,-.002,0)]]
	if recessed:
		patches=[[Vector2(2,6),Vector3(-2,-.002,0)],[Vector2(2,6),Vector3(2,-.002,0)],
			[Vector2(2,2),Vector3(0,-.002,-2)],[Vector2(2,2),Vector3(0,-.002,2)]]
	for patch in patches:
		var item:=plane(patch[0],patch[1],Vector3.ZERO,"floor")
		stage.remove_child(item)
		floor_root.add_child(item)
	wall.visible=selected<catalog.assets.size() and str(catalog.assets[selected].id).ends_with("up")
	wall.material_override=surface("wall")
	ceiling.material_override=surface("ceiling")
	if selected<catalog.assets.size():
		prop=load(ART+catalog.assets[selected].id+".tscn").instantiate()
		prop.ground_material=surface("floor")
		stage.add_child(prop)
	else:
		prop=Node3D.new()
		stage.add_child(prop)
		var shared: Material=SKINS.material(region()) if region()!="cave" else dry_material()
		for entry in [["barrel_large",Vector3(-.62,0,0),.45],["box_large",Vector3(.35,0,.02),.45],["bottle_B_green",Vector3(.88,0,-.05),.45]]:
			var piece: Node3D=load("res://art/third-party/kaykit-dungeon-remastered/models/"+entry[0]+".glb").instantiate()
			piece.position=entry[1]
			piece.scale=Vector3.ONE*entry[2]
			prop.add_child(piece)
			SKINS.apply(piece,shared)
	call_deferred("frame_prop")

func dry_material() -> StandardMaterial3D:
	var material:=StandardMaterial3D.new()
	material.albedo_texture=load("res://art/third-party/kaykit-dungeon-remastered/texture-floor1.png")
	material.roughness=1
	material.metallic_specular=.1
	material.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	material.detail_enabled=true
	material.detail_albedo=load("res://art/third-party/kaykit-dungeon-remastered/grain-floor1.png")
	material.detail_blend_mode=BaseMaterial3D.BLEND_MODE_MUL
	material.detail_uv_layer=BaseMaterial3D.DETAIL_UV_2
	material.uv2_triplanar=true
	material.uv2_world_triplanar=true
	material.uv2_scale=Vector3(.5,.5,.5)
	return material

func frame_prop() -> void:
	if prop==null: return
	(controls[0] as OptionButton).select(selected)
	(controls[1] as OptionButton).select(angle)
	(controls[2] as CheckButton).set_pressed_no_signal(neutral)
	ceiling.visible=selected==5 and angle!=2
	key.light_color=Color("#fff7ec") if neutral else Color("#d1e1dd" if region()=="waterlogged" else "#efbd87")
	key.light_energy=1.8 if neutral else 1.5
	environment.ambient_light_color=Color("#b8c4c8") if neutral else Color("#707b80")
	environment.ambient_light_energy=.7 if neutral else .30
	for item: MeshInstance3D in prop.find_children("*","MeshInstance3D",true,false):
		if item.is_in_group("ceiling"): item.visible=angle!=2
	var bounds:=AABB()
	var first:=true
	for item: MeshInstance3D in prop.find_children("*","MeshInstance3D",true,false):
		var piece: AABB=item.global_transform*item.get_aabb()
		bounds=piece if first else bounds.merge(piece)
		first=false
	var focus:=bounds.get_center()
	if angle==1:
		camera.projection=Camera3D.PROJECTION_PERSPECTIVE
		camera.fov=65
		camera.position=Vector3(0,1.55,2.6)
		var eye_focus:=.50 if selected>=catalog.assets.size() else (.2 if catalog.assets[selected].floor_aperture else 1.05)
		camera.look_at(Vector3(0,eye_focus,-.15))
		return
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.position=focus+(Vector3(1.4,1.4,2.2) if angle==0 else Vector3(.1,5,2.2))
	camera.look_at(focus)
	var inverse:=camera.global_transform.affine_inverse()
	var projected:=AABB(inverse*bounds.position,Vector3.ZERO)
	for x in [bounds.position.x,bounds.end.x]:
		for y in [bounds.position.y,bounds.end.y]:
			for z in [bounds.position.z,bounds.end.z]: projected=projected.expand(inverse*Vector3(x,y,z))
	var aspect:=float(maxi(1,viewport.size.x))/maxi(1,viewport.size.y)
	camera.size=maxf(.4,maxf(projected.size.y+.1,(projected.size.x+.1)/aspect))*1.12

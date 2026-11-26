extends SceneTree
## #302: standalone surface review using real LevelBuilder geometry.
const BUILDER=preload("res://scripts/level_builder.gd")
const MAP=preload("res://scripts/dungeon_map.gd")
const DIR="res://art/textures/damp-caves-v1/"
var out: String
var checks:=0
var failures: Array[String]=[]
var captures: Array[String]=[]
var edge_measurements: Dictionary={}
var world: Node3D
var camera: Camera3D
var lamp: OmniLight3D
var environment: Environment
var caption: Label

func _initialize() -> void:
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	out=OS.get_cmdline_user_args()[0] if not OS.get_cmdline_user_args().is_empty() else "res://build/damp-surfaces-review"
	DirAccess.make_dir_recursive_absolute(out)
	call_deferred("run")

func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures.append(label);push_error(label)

func settle() -> void:
	for i in 7:await process_frame

func snap(id: String) -> void:
	if DisplayServer.get_name()=="headless":return
	await settle();await RenderingServer.frame_post_draw
	var picture:=root.get_texture().get_image()
	check(picture!=null and not picture.is_empty(),id+" rendered framebuffer")
	check(picture.save_png(out.path_join(id+".png"))==OK,id+" saved native capture")
	var probe:=picture.duplicate() as Image;probe.resize(64,36,Image.INTERPOLATE_BILINEAR)
	var low:=1.0;var high:=0.0
	for y in range(5,34):
		for x in range(2,62):
			var c:=probe.get_pixel(x,y);var value: float=(c.r+c.g+c.b)/3.0
			low=minf(low,value);high=maxf(high,value)
	check(high-low>.08,id+" readable surface separation")
	captures.append(id+".png")

func edges(texture: Texture2D) -> Vector2:
	var image:=texture.get_image()
	if image.is_compressed():image.decompress()
	var horizontal:=0.0;var vertical:=0.0
	for i in image.get_width():
		var a:=image.get_pixel(0,i);var b:=image.get_pixel(image.get_width()-1,i)
		horizontal+=(absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b))/3.0
		a=image.get_pixel(i,0);b=image.get_pixel(i,image.get_height()-1)
		vertical+=(absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b))/3.0
	return Vector2(horizontal,vertical)/image.get_width()

func run() -> void:
	var catalogue: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(DIR+"catalog.json"))
	var provenance: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(DIR+"generation.json"))
	var materials: Dictionary={}
	for row: Dictionary in catalogue.assets:
		var material: Material=load(row.material)
		materials[row.id]=material
		var texture: Texture2D=material.get_shader_parameter("variant_albedo") if material is ShaderMaterial else material.albedo_texture
		check(texture!=null,row.id+" texture exists")
		check(texture.get_size()==Vector2(512,512),row.id+" bounded 512px runtime texture")
		var pixels:=texture.get_image()
		if pixels.is_compressed():pixels.decompress()
		check(pixels.has_mipmaps(),row.id+" mipmaps for distance stability")
		check(not pixels.is_invisible(),row.id+" texture contains visible pixels")
		check(pixels.detect_alpha()==Image.ALPHA_NONE,row.id+" source has no translucent pixels")
		if material is ShaderMaterial:
			check(not material.shader.code.contains("ALPHA =") and not material.shader.code.contains("ALPHA="),row.id+" opaque shader without alpha writes")
			check(material.get_shader_parameter("base_albedo")==materials["limestone-wall"].albedo_texture,row.id+" common edge texture")
			check(is_equal_approx(material.get_shader_parameter("wet_roughness"),row.roughness),row.id+" wet roughness retained")
			check(is_equal_approx(material.get_shader_parameter("wet_specular"),row.specular),row.id+" wet specular retained")
			check(material.get_shader_parameter("variant_strength")==.55,row.id+" restrained centre blend")
			check(not material.shader.code.contains("TIME") and not material.shader.code.contains("EMISSION"),row.id+" no motion or glow")
		else:
			check(material.transparency==BaseMaterial3D.TRANSPARENCY_DISABLED,row.id+" solid depth-writing surface")
			check(material.texture_filter==BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS and material.texture_repeat,row.id+" filtered repeated texture")
			check(is_equal_approx(material.roughness,row.roughness) and material.roughness>=.6,row.id+" restrained wet roughness")
			check(is_equal_approx(material.metallic_specular,row.specular) and material.metallic==0,row.id+" dielectric low specular")
			check(not material.emission_enabled and not material.normal_enabled and not material.clearcoat_enabled,row.id+" no extra surface or light effects")
		var source: Dictionary=provenance.assets.filter(func(item):return item.id==row.id)[0]
		check(FileAccess.get_sha256(row.texture)==source.sha256,row.id+" unchanged generated original")
		var delta:=edges(texture);edge_measurements[row.id]=[delta.x,delta.y]
		check(maxf(delta.x,delta.y)<.10,row.id+" no large wrap value discontinuity")
	world=Node3D.new();root.add_child(world)
	environment=Environment.new();environment.background_mode=Environment.BG_COLOR;environment.background_color=Color("0b1013")
	environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;environment.ambient_light_color=Color("a9bac1");environment.ambient_light_energy=.25
	var env:=WorldEnvironment.new();env.environment=environment;world.add_child(env)
	camera=Camera3D.new();world.add_child(camera);camera.current=true;camera.fov=72;camera.near=.06
	lamp=OmniLight3D.new();world.add_child(lamp);lamp.omni_range=7;lamp.light_color=Color(1,.77,.49);lamp.light_energy=2;lamp.shadow_enabled=false
	var ui:=CanvasLayer.new();root.add_child(ui);caption=Label.new();ui.add_child(caption);caption.position=Vector2(16,12)
	caption.add_theme_font_size_override("font_size",20);caption.add_theme_color_override("font_shadow_color",Color.BLACK);caption.add_theme_constant_override("shadow_offset_x",2);caption.add_theme_constant_override("shadow_offset_y",2)
	var live_cave: EnvironmentTheme=load("res://themes/cave.tres")
	var live_fungal: EnvironmentTheme=load("res://themes/fungal-caverns.tres")
	var original_wall:=live_fungal.wall_material;var original_dresser:=live_fungal.dressing_script
	var theme:=EnvironmentTheme.new();theme.display_name="Damp Caves surface review only";theme.wall_face_uv=true
	theme.wall_material=materials["limestone-wall"];theme.wall_variant_material=materials["limestone-wall-variant"]
	theme.floor_material=materials["silt-floor"];theme.ceiling_material=materials["seeping-ceiling"]
	var map=MAP.new(PackedStringArray(["#########","#,,,,,,,#","#,,,,,,,#","#,,###,,#","#,,###,,#","#,,,,,,,#","#,,,S,,,#","#,,,,,,,#","#########"]))
	var level=BUILDER.new();world.add_child(level);level.build(map,theme,2.0,2.2)
	check(level.cell_size==2 and is_equal_approx(level.wall_height,2.2),"real 2m cells / 2.2m ceiling")
	var wall:=level._wall_mesh(theme.wall_material) as ArrayMesh
	var arrays:=wall.surface_get_arrays(0);var uv: PackedVector2Array=arrays[Mesh.ARRAY_TEX_UV]
	check(uv.size()==24,"full-face box mesh has 24 vertices")
	check(Array(uv).all(func(p):return p.x>=0 and p.x<=1 and p.y>=0 and p.y<=1),"wall UVs remain full-face 0..1")
	check(wall.surface_get_material(0)==theme.wall_material,"wall shares the delivered material")
	check(level.find_children("*","Light3D",true,false).is_empty(),"surface-only room adds no lights")
	camera.position=Vector3(8,1.2,12);camera.look_at(Vector3(8,1.2,7.8));lamp.position=camera.position+Vector3(.35,.2,-.5)
	root.size=Vector2i(1280,720);lamp.light_energy=0;environment.ambient_light_energy=.85;caption.text="Damp Caves · neutral surface review"
	await snap("room-neutral")
	lamp.light_energy=2;environment.ambient_light_energy=.15;caption.text="Damp Caves · warm torch · no dressing or new gameplay"
	for shape in [Vector2i(1280,720),Vector2i(1278,590),Vector2i(844,390)]:
		root.size=shape;await snap("room-torch-%d"%shape.x)
	# Compare against actual existing cave surfaces on the same geometry/light.
	level.queue_free();await settle()
	level=BUILDER.new();world.add_child(level);level.build(map,live_cave,2.0,2.2);root.size=Vector2i(1280,720);caption.text="Existing mine surfaces · same camera and torch"
	await snap("mine-comparison");level.queue_free();await settle()
	# Grazing view exposes floor joins and over-bright specular response.
	level=BUILDER.new();world.add_child(level);level.build(map,theme,2.0,2.2)
	camera.position=Vector3(3,1.2,12);camera.look_at(Vector3(11,1.0,3));lamp.position=Vector3(3.4,1.3,10.8);caption.text="Damp Caves · grazing floor and wall joins"
	await snap("room-grazing");level.queue_free();await settle()
	# Single plane at four repeats makes tiling review explicit for all albedos.
	lamp.light_energy=0;environment.ambient_light_energy=1;camera.position=Vector3(0,0,5);camera.rotation=Vector3.ZERO;camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=4.8
	root.size=Vector2i(900,900)
	for id: String in materials:
		var quad:=MeshInstance3D.new();var mesh:=QuadMesh.new();mesh.size=Vector2(4,4);quad.mesh=mesh
		var tile_arrays:=mesh.get_mesh_arrays();var tile_uv: PackedVector2Array=tile_arrays[Mesh.ARRAY_TEX_UV]
		for i in tile_uv.size():tile_uv[i]*=4
		tile_arrays[Mesh.ARRAY_TEX_UV]=tile_uv
		var tiled:=ArrayMesh.new();tiled.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,tile_arrays);quad.mesh=tiled
		quad.material_override=materials[id];world.add_child(quad)
		caption.text=id+" · 4×4 repeat / native Mobile"
		await snap(id+"-repeat");quad.queue_free();await settle()
	if DisplayServer.get_name()!="headless":
		var base_image:=Image.load_from_file(out.path_join("limestone-wall-repeat.png"))
		var variant_image:=Image.load_from_file(out.path_join("limestone-wall-variant-repeat.png"))
		var border_delta:=0.0;var centre_delta:=0.0;var count:=0
		# In this square 900px orthographic view the 4m plane spans 75..825.
		for y in range(120,780,3):
			for x in [76,263,450,638,823]:
				var a:=base_image.get_pixel(x,y);var b:=variant_image.get_pixel(x,y)
				border_delta+=(absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b))/3.0;count+=1
			for x in [169,356,544,731]:
				var a:=base_image.get_pixel(x,y);var b:=variant_image.get_pixel(x,y)
				centre_delta+=(absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b))/3.0
		check(border_delta/count<.006,"rendered variant joins match base borders")
		check(centre_delta/(count*.8)>.0005,"rendered variant retains interior variation")
	check(live_fungal.wall_material==original_wall and live_fungal.dressing_script==original_dresser,"live fungal theme and dresser retained")
	var report:={"checks":checks,"failures":failures,"captures":captures,"edge_mean_rgb_delta":edge_measurements,"rendering_method":ProjectSettings.get_setting("rendering/renderer/rendering_method"),"physical_iPhone":false,"live_theme_assignment":false,"geometry":"Existing LevelBuilder at 2m / 2.2m; no gameplay or world placement bindings.","tiling_limit":"Edge-value measurements and 4x4 renders do not prove geological continuity. Keep review of repeated motifs."}
	FileAccess.open(out.path_join("validation.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  ")+"\n")
	world.queue_free();ui.queue_free();await settle()
	print("DAMP_SURFACES checks=",checks," failures=",failures.size());quit(0 if failures.is_empty() else 1)


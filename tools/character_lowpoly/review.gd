extends Control
const Character=preload("res://character.gd")
var person:Node3D
var viewport:SubViewport
var camera:Camera3D
var stage:Node3D
var bench:MeshInstance3D
var selectors:Dictionary={}
var stats_label:Label
var outfit:=0
var utility:=1
var pose:=0
var view:=0
var angle:=1
var motion:=false

func _ready() -> void:
 var bg=ColorRect.new();bg.color=Color("11191e");bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT);add_child(bg)
 var margins=MarginContainer.new();margins.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
 for side in ["left","right","top","bottom"]:margins.add_theme_constant_override("margin_"+side,16)
 add_child(margins)
 var column=VBoxContainer.new();column.add_theme_constant_override("separation",7);margins.add_child(column)
 var title=Label.new();title.text="DEPTHS / LOW-POLY CHARACTER STUDY";title.add_theme_font_size_override("font_size",23);column.add_child(title)
 var sub=Label.new();sub.text="Rook-inspired traveller · angular planes / silver streak / burgundy & slate · likeness pending review";sub.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;column.add_child(sub)
 var row=HFlowContainer.new();row.add_theme_constant_override("h_separation",10);column.add_child(row)
 choice(row,"Outfit",Character.OUTFITS,func(i):outfit=i;apply())
 choice(row,"Utility",Character.BACKS,func(i):utility=i;apply())
 choice(row,"Pose",Character.POSES,func(i):pose=i;apply())
 choice(row,"View",["Full figure","Face & shoulders"],func(i):view=i;apply())
 choice(row,"Angle",["Front","Three-quarter","Profile","Back"],func(i):angle=i;apply())
 var button=CheckButton.new();button.text="Idle / blink";button.custom_minimum_size.y=44;button.toggled.connect(func(on):motion=on;apply());row.add_child(button)
 var container=SubViewportContainer.new();container.stretch=true;container.size_flags_vertical=SIZE_EXPAND_FILL;container.size_flags_horizontal=SIZE_EXPAND_FILL;column.add_child(container)
 viewport=SubViewport.new();viewport.own_world_3d=true;viewport.size=Vector2i(1200,680);viewport.msaa_3d=Viewport.MSAA_4X;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;container.add_child(viewport)
 stage=Node3D.new();viewport.add_child(stage)
 var world=WorldEnvironment.new();var env=Environment.new();world.environment=env
 env.background_mode=Environment.BG_COLOR;env.background_color=Color("242f35")
 env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color("9dafb8");env.ambient_light_energy=.42
 env.tonemap_mode=Environment.TONE_MAPPER_FILMIC;stage.add_child(world)
 var key=DirectionalLight3D.new();key.rotation_degrees=Vector3(-32,-36,0);key.light_color=Color("ffe2bc");key.light_energy=1.5;key.shadow_enabled=true;stage.add_child(key)
 var fill=DirectionalLight3D.new();fill.rotation_degrees=Vector3(-25,125,0);fill.light_color=Color("81b4ce");fill.light_energy=.8;stage.add_child(fill)
 person=Character.new();person.name="TravellerStudy";stage.add_child(person);person.setup()
 camera=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;viewport.add_child(camera);camera.current=true
 var ground=MeshInstance3D.new();var plane=CylinderMesh.new();plane.top_radius=.7;plane.bottom_radius=.72;plane.height=.055;plane.radial_segments=12
 ground.mesh=plane;ground.position.y=-.02;var mat=StandardMaterial3D.new();mat.albedo_color=Color("354047");mat.roughness=1;ground.material_override=mat;stage.add_child(ground)
 bench=MeshInstance3D.new();var seat=BoxMesh.new();seat.size=Vector3(.48,.06,.33);bench.mesh=seat;bench.position=Vector3(0,.425,-.07);var wood=StandardMaterial3D.new();wood.albedo_color=Color("463a32");bench.material_override=wood;stage.add_child(bench)
 stats_label=Label.new();stats_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;column.add_child(stats_label)
 var footer=Label.new();footer.text="Original geometry · blended cloth joints / rigid armour · isolated study, no live art or saves changed";footer.add_theme_font_size_override("font_size",13);footer.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;column.add_child(footer)
 select_state(0,1,0,0,1)

func choice(parent:Control,label:String,options:Array,callback:Callable) -> void:
 var group=VBoxContainer.new();parent.add_child(group);var title=Label.new();title.text=label;group.add_child(title)
 var option=OptionButton.new();option.custom_minimum_size=Vector2(165,44)
 for text in options:option.add_item(text)
 option.item_selected.connect(callback);group.add_child(option);selectors[label]=option

func apply() -> void:
 person.select(outfit,utility,pose);person.animated=motion
 person.rotation.y=[0.0,.48,PI/2,PI][angle]
 bench.visible=pose>0 and view==0;bench.rotation.y=person.rotation.y
 var focus=Vector3(0,1.62 if view==1 else .94,0)
 if pose>0:focus.y-=.43
 camera.position=focus+Vector3(0,.025 if view==1 else .34,5);camera.look_at(focus)
 camera.size=.62 if view==1 else 2.08
 var count=person.stats()
 stats_label.text="%s · %s · %s | %d visible triangles / %d mesh surfaces"%[Character.OUTFITS[outfit],Character.BACKS[utility],Character.POSES[pose],count.triangles_visible,count.meshes_visible]

func select_state(o:int,u:int,p:int,v:int,a:int) -> void:
 outfit=o;utility=u;pose=p;view=v;angle=a
 for pair in [["Outfit",o],["Utility",u],["Pose",p],["View",v],["Angle",a]]:selectors[pair[0]].select(pair[1])
 apply()

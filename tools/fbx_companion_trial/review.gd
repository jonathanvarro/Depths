extends Control
const Character=preload("res://character.gd")
var characters:Array=[]
var viewport:SubViewport
var stage:Node3D
var camera:Camera3D
var benches:Array=[]
var action:OptionButton
var view_choice:OptionButton
var angle_choice:OptionButton
var paused_button:CheckButton
var timeline:HSlider
var info:Label
var current_action:="standing"
var view_index:=0
var angle_index:=1
var stopped:=false
const ACTIONS=["standing","source_idle","sit_down","seated_idle","stand_up"]

func _ready() -> void:
 if not FileAccess.file_exists("res://../../build/local-fbx-trial/imported.tscn"):
  var missing=Label.new();missing.text="Prepare the local FBX sample first. See tools/fbx_companion_trial/README.md.\nSource assets and derived models are intentionally not stored in Git.";missing.position=Vector2(24,24);add_child(missing);return
 var bg=ColorRect.new();bg.color=Color("111b21");bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT);add_child(bg)
 var margin=MarginContainer.new();margin.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
 for side in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+side,16)
 add_child(margin);var column=VBoxContainer.new();column.add_theme_constant_override("separation",8);margin.add_child(column)
 var heading=Label.new();heading.text="DEPTHS / LOCAL FBX EXPEDITION TRIAL";heading.add_theme_font_size_override("font_size",24);column.add_child(heading)
 var note=Label.new();note.text="Same supplied body and outfit · copper hair / silver crop & slate wrap · no named likeness assignment";note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;column.add_child(note)
 var row=HFlowContainer.new();row.add_theme_constant_override("h_separation",12);column.add_child(row)
 action=choice(row,"Animation",["Standing","Supplied idle","Sit down","Seated idle","Stand up"]);action.item_selected.connect(func(i):set_action(ACTIONS[i]))
 view_choice=choice(row,"View",["Full figures","Portraits"]);view_choice.item_selected.connect(func(i):view_index=i;frame_camera())
 angle_choice=choice(row,"Angle",["Front","Three-quarter","Back","Profile"]);angle_choice.select(1);angle_choice.item_selected.connect(func(i):angle_index=i;frame_camera())
 paused_button=CheckButton.new();paused_button.text="Pause";paused_button.custom_minimum_size.y=44;row.add_child(paused_button);paused_button.toggled.connect(func(on):stopped=on;set_pause())
 timeline=HSlider.new();timeline.custom_minimum_size=Vector2(250,44);timeline.min_value=0;timeline.max_value=1.6;timeline.step=.01;row.add_child(timeline)
 timeline.drag_started.connect(func():paused_button.button_pressed=true)
 timeline.value_changed.connect(func(value):
  if stopped:
   for person in characters:person.play(current_action,value)
 )
 var container=SubViewportContainer.new();container.stretch=true;container.size_flags_vertical=SIZE_EXPAND_FILL;container.size_flags_horizontal=SIZE_EXPAND_FILL;column.add_child(container)
 viewport=SubViewport.new();viewport.size=Vector2i(1200,700);viewport.own_world_3d=true;viewport.msaa_3d=Viewport.MSAA_4X;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;container.add_child(viewport)
 stage=Node3D.new();viewport.add_child(stage)
 var world=WorldEnvironment.new();var env=Environment.new();world.environment=env;env.background_mode=Environment.BG_COLOR;env.background_color=Color("2a363c");env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color("a4b5be");env.ambient_light_energy=.5;env.tonemap_mode=Environment.TONE_MAPPER_FILMIC;stage.add_child(world)
 var key=DirectionalLight3D.new();key.rotation_degrees=Vector3(-32,-30,0);key.light_energy=1.6;key.light_color=Color("ffe5c5");key.shadow_enabled=true;stage.add_child(key)
 var fill=DirectionalLight3D.new();fill.rotation_degrees=Vector3(-22,140,0);fill.light_energy=.75;fill.light_color=Color("8fb7cd");stage.add_child(fill)
 camera=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.current=true;viewport.add_child(camera)
 for i in 2:
  var person=Character.new();person.name="CopperAppearance" if i==0 else "SilverAppearance";stage.add_child(person);person.setup(i);characters.append(person)
  person.player.animation_finished.connect(func(name):
   if stopped:return
   if name=="expedition/sit_down":set_action("seated_idle")
   elif name=="expedition/stand_up":set_action("standing")
  )
  var bench=MeshInstance3D.new();var mesh=BoxMesh.new();mesh.size=Vector3(.62,.065,.42);bench.mesh=mesh;bench.position=Vector3(-.55 if i==0 else .55,.46,-.43);var wood=StandardMaterial3D.new();wood.albedo_color=Color("574536");bench.material_override=wood;stage.add_child(bench);benches.append(bench)
  for side in [-1.0,1.0]:
   var leg=MeshInstance3D.new();var timber=BoxMesh.new();timber.size=Vector3(.055,.44,.20);leg.mesh=timber;leg.material_override=wood;leg.position=Vector3(side*.23,-.25,0);bench.add_child(leg)
 var ground=MeshInstance3D.new();var plane=PlaneMesh.new();plane.size=Vector2(5,4);ground.mesh=plane;ground.position.y=-.01;var stone=StandardMaterial3D.new();stone.albedo_color=Color("344147");stone.roughness=1;ground.material_override=stone;stage.add_child(ground)
 info=Label.new();info.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;column.add_child(info)
 var footer=Label.new();footer.text="Local sample and derived art remain in ignored build output. Outfit, face additions and seated motion are exploratory.";footer.add_theme_font_size_override("font_size",13);footer.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;column.add_child(footer)
 set_action("standing");frame_camera()

func choice(parent:Control,label:String,options:Array) -> OptionButton:
 var group=VBoxContainer.new();parent.add_child(group);var title=Label.new();title.text=label;group.add_child(title)
 var select=OptionButton.new();select.custom_minimum_size=Vector2(170,44)
 for text in options:select.add_item(text)
 group.add_child(select);return select

func set_action(key:String,time:float=-1) -> void:
 current_action=key;action.select(ACTIONS.find(key))
 for person in characters:person.play(key,time)
 timeline.set_block_signals(true)
 timeline.max_value=characters[0].player.get_animation("mixamo_com" if key=="source_idle" else "expedition/"+key).length
 timeline.value=time if time>=0 else 0
 timeline.set_block_signals(false)
 if time>=0:stopped=true;paused_button.set_pressed_no_signal(true);timeline.set_value_no_signal(time)
 elif stopped:
  for person in characters:person.play(key,0)
  timeline.set_value_no_signal(0)
 for bench in benches:bench.visible=key in ["sit_down","seated_idle","stand_up"] and view_index==0
 var counts=characters[0].stats();info.text="%s · shared %d-bone source rig · %d visible triangles / %d surfaces (copper appearance)"%[key,counts.bones,counts.triangles,counts.surfaces]
 frame_camera()

func set_pause() -> void:
 for person in characters:
  if stopped:person.player.pause()
  else:person.player.play()

func frame_camera() -> void:
 for i in characters.size():
  characters[i].position.x=(-.55 if i==0 else .55) if view_index==0 else (-.24 if i==0 else .24)
  characters[i].rotation.y=[0.0,.35,PI,PI/2][angle_index]
  var seat_offset=Basis(Vector3.UP,characters[i].rotation.y)*Vector3(0,0,-.43)
  benches[i].position=Vector3(characters[i].position.x,.46,0)+seat_offset;benches[i].rotation.y=characters[i].rotation.y
  benches[i].visible=current_action in ["sit_down","seated_idle","stand_up"] and view_index==0
 var seated=current_action=="seated_idle" or (current_action=="sit_down" and timeline.value>1)
 var focus=Vector3(0,(1.55 if view_index==1 else .88)-(.48 if seated and view_index==1 else 0),0)
 if view_index==1:
  var average_height=0.0
  for person in characters:average_height+=person.rig.to_global(person.rig.get_bone_global_pose(person.bone("Head")).origin).y/characters.size()
  focus.y=average_height+.10
 camera.position=focus+Vector3(0,.02 if view_index==1 else .30,5);camera.look_at(focus);camera.size=.65 if view_index==1 else 2.02

func _process(_delta:float) -> void:
 if characters.is_empty():return
 if not stopped:timeline.set_value_no_signal(characters[0].player.current_animation_position)
 if view_index==1:frame_camera()

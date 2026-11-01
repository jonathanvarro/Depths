extends SceneTree
var app:Control
var out:String
func _initialize() -> void:call_deferred("run")
func settle(n:=6) -> void:
 for i in n:await process_frame
func capture(name:String) -> void:
 await settle();await RenderingServer.frame_post_draw
 app.viewport.get_texture().get_image().save_png(out+"/"+name+".png")
func run() -> void:
 out=ProjectSettings.globalize_path("res://").path_join("../../build/local-fbx-trial/review").simplify_path();DirAccess.make_dir_recursive_absolute(out)
 root.size=Vector2i(1440,960);app=load("res://review.tscn").instantiate();root.add_child(app);await settle()
 app.set_action("standing",0);await capture("standing")
 app.view_index=1;app.frame_camera();await capture("portrait")
 app.view_index=0;app.set_action("seated_idle",0);app.frame_camera();await capture("seated")
 app.view_index=1;app.frame_camera();await capture("seated-portrait")
 app.view_index=0;app.angle_index=2;app.set_action("standing",0);app.frame_camera();await capture("back")
 app.angle_index=3;app.frame_camera();await capture("profile")
 app.angle_index=1;app.set_action("source_idle",4.0);app.frame_camera();await capture("supplied-idle")
 app.set_action("sit_down",.8);app.frame_camera();await capture("mid-sit")
 # Direct renderer samples form a motion preview; no interpolated/generated image frames.
 DirAccess.make_dir_recursive_absolute(out+"/frames")
 var frame_index=0
 for phase in ["sit_down","stand_up"]:
  for frame in 33:
   app.set_action(phase,frame/32.0*1.6);app.frame_camera();await capture("frames/"+str(frame_index).pad_zeros(3));frame_index+=1
 app.set_action("standing",0);app.view_index=0;app.frame_camera()
 var cards=SubViewport.new();cards.world_3d=app.stage.get_world_3d();cards.render_target_update_mode=SubViewport.UPDATE_ALWAYS;cards.msaa_3d=Viewport.MSAA_4X;root.add_child(cards)
 var camera=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=.63;cards.add_child(camera);camera.current=true
 for person in app.characters:
  var focus=Vector3(person.position.x,1.56,0);camera.position=focus+Vector3(0,.025,5);camera.look_at(focus)
  for dimension in [192,96]:
   cards.size=Vector2i(dimension,dimension);await settle();await RenderingServer.frame_post_draw
   cards.get_texture().get_image().save_png(out+"/appearance-"+str(person.look)+"-"+str(dimension)+".png")
 cards.queue_free();await settle()
 root.size=Vector2i(1278,590);await settle();await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(out+"/phone.png")
 print("LOCAL FBX CAPTURES READY")
 app.queue_free();await settle();quit()

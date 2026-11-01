extends SceneTree
const Review=preload("res://review.tscn")
var app:Control
var failures:Array[String]=[]
var count:=0
var output:=""
func _initialize() -> void:call_deferred("run")
func check(ok:bool,label:String) -> void:
 count+=1
 if not ok:failures.append(label);push_error(label)
func settle(frames:=5) -> void:
 for i in frames:await process_frame
func capture(label:String) -> void:
 if output=="" or DisplayServer.get_name()=="headless":return
 await settle();await RenderingServer.frame_post_draw
 check(app.viewport.get_texture().get_image().save_png(output+"/"+label+".png")==OK,"Capture "+label)
func prepare(node:Node,scene:Node) -> void:
 node.set_script(null)
 if node!=scene:node.owner=scene
 for child in node.get_children():prepare(child,scene)
func portable_palette(node:MeshInstance3D) -> void:
 # Runtime GLTF import in 4.7.2 loses vertex-colour material enablement.
 # Portable siblings use real palette materials instead, preserving visible colour.
 var source=node.mesh.surface_get_arrays(0);var groups={}
 for start in range(0,source[Mesh.ARRAY_VERTEX].size(),3):
  var color=source[Mesh.ARRAY_COLOR][start];var key=color.to_html()
  if not groups.has(key):groups[key]=[]
  groups[key].append(start)
 var mesh=ArrayMesh.new()
 for key in groups:
  var v=PackedVector3Array();var n=PackedVector3Array();var b=PackedInt32Array();var w=PackedFloat32Array()
  for start in groups[key]:
   for i in range(start,start+3):
    v.append(source[Mesh.ARRAY_VERTEX][i]);n.append(source[Mesh.ARRAY_NORMAL][i])
    for j in 4:b.append(source[Mesh.ARRAY_BONES][i*4+j]);w.append(source[Mesh.ARRAY_WEIGHTS][i*4+j])
  var arrays=[];arrays.resize(Mesh.ARRAY_MAX);arrays[Mesh.ARRAY_VERTEX]=v;arrays[Mesh.ARRAY_NORMAL]=n;arrays[Mesh.ARRAY_BONES]=b;arrays[Mesh.ARRAY_WEIGHTS]=w
  mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
  var material=StandardMaterial3D.new();material.albedo_color=Color(key);material.roughness=.86;material.cull_mode=BaseMaterial3D.CULL_DISABLED
  mesh.surface_set_material(mesh.get_surface_count()-1,material)
 node.mesh=mesh
func run() -> void:
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("out="):output=arg.substr(4)
 if output!="":DirAccess.make_dir_recursive_absolute(output)
 root.size=Vector2i(1440,960);app=Review.instantiate();root.add_child(app);await settle()
 var person=app.person
 check(person.skeleton.get_bone_count()==16,"Shared rest bone count")
 var mixed:=0
 for node in person.meshes:
  check(node.skin.get_bind_count()==16,"Every mesh has inverse-rest skin")
  check(node.get_node(node.skeleton)==person.skeleton,"Explicit skeleton path")
  var a=node.mesh.surface_get_arrays(0)
  for i in a[Mesh.ARRAY_VERTEX].size():
   var total=0.0
   for k in 4:total+=a[Mesh.ARRAY_WEIGHTS][i*4+k]
   if absf(total-1)>.0001:check(false,"Normalized weights")
   if a[Mesh.ARRAY_WEIGHTS][i*4+1]>.001 and a[Mesh.ARRAY_WEIGHTS][i*4]>.001:mixed+=1
   if not a[Mesh.ARRAY_VERTEX][i].is_finite():check(false,"Finite rest vertex")
 check(mixed>500,"Real blended weights, not rigid attachment claims")
 for outfit in 3:
  for utility in 3:
   for pose in 3:
    app.select_state(outfit,utility,pose,0,1);await settle(2)
    for i in 3:
     check(person.garments[i].visible==(i==outfit),"Exclusive outfit")
     check(person.utilities[i].visible==(i==utility),"Exclusive utility")
    check(person.book.visible==(pose==2),"Prop state")
    for i in 16:check(person.skeleton.get_bone_global_pose(i).origin.is_finite(),"Finite pose")
 for outfit in 3:
  app.select_state(outfit,1,0,0,1);await capture("figure-"+str(outfit))
  app.select_state(outfit,1,0,1,1);await capture("portrait-"+str(outfit))
  app.select_state(outfit,1,1,0,1);await capture("seated-"+str(outfit))
  app.select_state(outfit,1,2,0,1);await capture("reading-"+str(outfit))
 for angle in [0,2,3]:
  app.select_state(0,1,0,0,angle);await capture("angle-"+str(angle))
 for utility in [0,2]:
  app.select_state(0,utility,0,0,1);await capture("utility-"+str(utility))
  app.select_state(0,utility,0,0,3);await capture("utility-back-"+str(utility))
 app.select_state(0,1,0,1,0);await capture("face-front")
 person.blink(true);check(person.shut_eyes.visible and not person.open_eyes.visible,"Blink substitution");await capture("blink")
 person.blink(false)
 # Verify actual renderer skinning snapshot changes when posed, not merely the skeleton.
 app.select_state(0,1,0,0,0);await settle()
 var standing=person.common.bake_mesh_from_current_skeleton_pose() if DisplayServer.get_name()!="headless" else null
 app.select_state(0,1,1,0,0);await settle()
 var seated=person.common.bake_mesh_from_current_skeleton_pose() if DisplayServer.get_name()!="headless" else null
 if standing and seated:
  var a=standing.surface_get_arrays(0)[Mesh.ARRAY_VERTEX];var b=seated.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
  var displacement=0.0
  for i in a.size():displacement=maxf(displacement,a[i].distance_to(b[i]))
  check(displacement>.35,"Rendered skinned body deforms when seated")
  check(a.size()==b.size(),"Pose preserves topology")
 elif DisplayServer.get_name()!="headless":check(false,"Renderer pose baking available")
 if output!="" and DisplayServer.get_name()!="headless":
  var cards=SubViewport.new();cards.world_3d=app.stage.get_world_3d();cards.render_target_update_mode=SubViewport.UPDATE_ALWAYS;cards.msaa_3d=Viewport.MSAA_4X;root.add_child(cards)
  var camera=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=.47;cards.add_child(camera);camera.current=true
  camera.position=Vector3(.10,1.66,5);camera.look_at(Vector3(0,1.66,0))
  for outfit in 3:
   app.select_state(outfit,1,0,0,1)
   for dim in [192,96]:
    cards.size=Vector2i(dim,dim);await settle();await RenderingServer.frame_post_draw
    check(cards.get_texture().get_image().save_png(output+"/card-"+str(outfit)+"-"+str(dim)+".png")==OK,"Native card")
  cards.queue_free();await settle()
 root.size=Vector2i(1278,590);app.select_state(0,2,0,0,1);await settle()
 for option in app.selectors.values():check(option.size.y>=44,"Touch height")
 check(app.viewport.size.y>150,"Phone view area")
 if output!="" and DisplayServer.get_name()!="headless":
  await RenderingServer.frame_post_draw
  check(root.get_texture().get_image().get_size()==root.size,"True phone window")
  root.get_texture().get_image().save_png(output+"/phone.png")
 if output!="":
  app.select_state(0,1,0,0,0);await settle()
  var clone=person.duplicate(0);prepare(clone,clone)
  var packed=PackedScene.new();check(packed.pack(clone)==OK,"Pack script-free native model")
  check(ResourceSaver.save(packed,output+"/traveller.tscn")==OK,"Save native model");clone.free()
  for variant in 3:
   app.select_state(variant,1,0,0,0);await settle()
   var exported=person.duplicate(0);prepare(exported,exported)
   for child in exported.get_children():
    if child is MeshInstance3D and not child.visible:child.free()
    elif child is MeshInstance3D:portable_palette(child)
   root.add_child(exported);await settle()
   var document=GLTFDocument.new();var state=GLTFState.new()
   check(document.append_from_scene(exported,state)==OK,"Serialize GLB "+str(variant))
   check(document.write_to_filesystem(state,output+"/traveller-"+str(variant)+".glb")==OK,"Write portable skinned GLB")
   var imported_state=GLTFState.new()
   check(document.append_from_file(output+"/traveller-"+str(variant)+".glb",imported_state)==OK,"Reimport GLB")
   var imported=document.generate_scene(imported_state)
   check(imported!=null,"Generate independent imported scene")
   if imported:
    app.stage.add_child(imported);await settle()
    var rigs=imported.find_children("*","Skeleton3D",true,false)
    check(rigs.size()==1 and rigs[0].get_bone_count()==16,"Portable sixteen-bone rig")
    var players=imported.find_children("*","AnimationPlayer",true,false)
    check(players.size()==1 and players[0].has_animation("reading"),"Portable pose library")
    for imported_mesh in imported.find_children("*","MeshInstance3D",true,false):
     check(imported_mesh.mesh.surface_get_material(0).albedo_color!=Color.WHITE,"Portable palette survives import")
    if variant==0:
     person.visible=false;app.bench.visible=false;await capture("portable-roundtrip")
     if players.size()==1:
      players[0].play("reading");players[0].seek(.3,true);players[0].pause();await settle()
      check(rigs[0].get_bone_global_pose(rigs[0].find_bone("hips")).origin.y<.6,"Reimported animation moves pelvis")
     person.visible=true
    imported.queue_free()
   exported.queue_free();await settle()
  app.select_state(0,1,0,0,0)
  var report={"checks":count,"failures":failures,"stats":person.stats(),"mixed_weight_vertices":mixed,"renderer":RenderingServer.get_current_rendering_method(),"display":DisplayServer.get_name(),"combinations":27}
  var file=FileAccess.open(output+"/report.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"\t"));file.close()
 print("LOWPOLY: %d checks / %d failures"%[count,failures.size()])
 app.queue_free();await settle();quit(0 if failures.is_empty() else 1)

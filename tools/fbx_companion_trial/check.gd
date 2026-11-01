extends SceneTree
var app:Control
var failures:Array[String]=[]
var checks:=0
var folder:String
func _initialize() -> void:call_deferred("run")
func check(ok:bool,label:String) -> void:
 checks+=1
 if not ok:failures.append(label);push_error(label)
func settle(n:=4) -> void:
 for i in n:await process_frame
func prepare_export(node:Node,scene:Node) -> void:
 node.set_script(null)
 if node!=scene:node.owner=scene
 for child in node.get_children():prepare_export(child,scene)
func cpu_bounds(node:MeshInstance3D,rig:Skeleton3D) -> AABB:
 var a=node.mesh.surface_get_arrays(0);var v=a[Mesh.ARRAY_VERTEX];var slots=a[Mesh.ARRAY_WEIGHTS].size()/v.size()
 var transforms=[]
 for i in rig.get_bone_count():transforms.append(rig.get_bone_global_pose(i)*node.skin.get_bind_pose(i))
 var minimum=Vector3.INF;var maximum=-Vector3.INF
 for i in v.size():
  var p=Vector3.ZERO
  for k in slots:p+=transforms[a[Mesh.ARRAY_BONES][i*slots+k]]*v[i]*a[Mesh.ARRAY_WEIGHTS][i*slots+k]
  minimum=minimum.min(p);maximum=maximum.max(p)
 return AABB(minimum,maximum-minimum)
func run() -> void:
 folder=ProjectSettings.globalize_path("res://").path_join("../../build/local-fbx-trial").simplify_path()
 root.size=Vector2i(1440,960);app=load("res://review.tscn").instantiate();root.add_child(app);await settle()
 var first=app.characters[0];var second=app.characters[1]
 check(first.rig.get_bone_count()==65,"Source sixty-five-bone hierarchy preserved")
 check(first.look!=second.look,"Two separate appearance IDs")
 check(first.hair.material_override.albedo_color!=second.hair.material_override.albedo_color,"Distinct hair colours")
 check(not first.hat.visible and second.hat.visible,"Distinct head silhouettes")
 for i in 65:check(first.rig.get_bone_rest(i)==second.rig.get_bone_rest(i),"Identical rest contract")
 var outfit_a=first.outfit.mesh.surface_get_arrays(0);var outfit_b=second.outfit.mesh.surface_get_arrays(0)
 check(outfit_a[Mesh.ARRAY_VERTEX]==outfit_b[Mesh.ARRAY_VERTEX],"One identical fitted outfit reused")
 check(outfit_a[Mesh.ARRAY_WEIGHTS].size()==outfit_a[Mesh.ARRAY_VERTEX].size()*8,"Source eight-influence garment layout preserved")
 var original=load("res://../../build/local-fbx-trial/FemaleMesh-rest.res").surface_get_arrays(0)
 check(first.body.mesh.surface_get_arrays(0)[Mesh.ARRAY_INDEX].size()+outfit_a[Mesh.ARRAY_VERTEX].size()==original[Mesh.ARRAY_INDEX].size(),"Covered skin hidden; source triangles partitioned without loss")
 for person in app.characters:
  check(person.player.has_animation("mixamo_com") and is_equal_approx(person.player.get_animation("mixamo_com").length,16.6166666667),"Supplied idle retained")
  for key in ["standing","sit_down","seated_idle","stand_up"]:check(person.player.has_animation("expedition/"+key),"Authored clip available")
  for node in person.mesh_nodes:
   var a=node.mesh.surface_get_arrays(0);var slots=a[Mesh.ARRAY_WEIGHTS].size()/a[Mesh.ARRAY_VERTEX].size();var normalized=true;var valid_ids=true
   for i in a[Mesh.ARRAY_VERTEX].size():
    var total=0.0
    for k in slots:
     total+=a[Mesh.ARRAY_WEIGHTS][i*slots+k]
     if a[Mesh.ARRAY_BONES][i*slots+k]>=65:valid_ids=false
    if absf(total-1.0)>.001:normalized=false
   check(normalized,"Normalized source/addition weights")
   check(valid_ids,"Actual bone IDs within rig")
   check(node.skin.get_bind_count()==65 and node.get_node(node.skeleton)==person.rig,"Explicit unified skin and skeleton path")
 var bounds_samples=[]
 for key in ["sit_down","stand_up","seated_idle","source_idle"]:
  var sample_times=[0.0,4.0,8.0,12.0,16.0] if key=="source_idle" else [0.0,.2,.4,.6,.8,1.0,1.2,1.4,1.6]
  for time in sample_times:
   app.set_action(key,time);await settle(2)
   for person in app.characters:
    person.rig.force_update_all_bone_transforms()
    var bounds=cpu_bounds(person.outfit,person.rig)
    check(bounds.position.is_finite() and bounds.size.is_finite(),"Finite deformed clothes")
    check(bounds.size.x<4 and bounds.size.y<4.5 and bounds.size.z<4,"No exploded weight/normal geometry")
    if key!="source_idle":check(bounds.position.y>-.075,"Authored sampled soles remain clear of the floor tolerance")
    bounds_samples.append({"clip":key,"time":time,"look":person.look,"aabb":str(bounds)})
 app.set_action("standing",0);await settle();var standing=cpu_bounds(first.outfit,first.rig)
 app.set_action("seated_idle",0);await settle();var seated=cpu_bounds(first.outfit,first.rig)
 check(standing.end.y-seated.end.y>.8,"Authored seated pose lowers body")
 check(first.rig.get_bone_global_pose(first.bone("Hips")).origin.z<-.8,"Pelvis moves back toward bench")
 if DisplayServer.get_name()!="headless":
  var baked=first.outfit.bake_mesh_from_current_skeleton_pose()
  check(baked!=null,"Actual renderer skin bake available")
  if baked:check(baked.get_aabb().size.distance_to(seated.size)<.02,"Renderer deformation matches independent CPU skin calculation")
 app.set_action("source_idle",4.0);app.set_action("sit_down",.8);await settle()
 check(is_equal_approx(first.player.current_animation_position,.8),"Changing timeline range does not overwrite the requested animation time")
 # Build a clean, script-free local native model for each appearance.
 app.set_action("standing",0);await settle()
 for person in app.characters:
  var clone=person.duplicate(0);clone.position=Vector3.ZERO;clone.rotation=Vector3.ZERO;prepare_export(clone,clone)
  var packed=PackedScene.new();check(packed.pack(clone)==OK,"Pack local native companion")
  var path=folder.path_join("appearance-"+str(person.look)+".tscn")
  check(ResourceSaver.save(packed,path)==OK,"Write local native companion")
  var text=FileAccess.get_file_as_string(path)
  check(not "[ext_resource" in text and not "script = " in text,"Native export has no authoring/intermediate dependencies")
  clone.free()
  var native=load(path).instantiate();root.add_child(native);await settle()
  check(native.get_script()==null,"Native model needs no authoring script")
  var player=native.get_node("SourceRig/AnimationPlayer");var rig=native.get_node("SourceRig/Skeleton3D")
  player.play("expedition/sit_down");player.seek(1.6,true);player.pause();await settle()
  var hip_height=rig.get_bone_global_pose(rig.find_bone("mixamorig_Hips")).origin.y
  check(hip_height<1.5 and hip_height>.8,"Exported seated animation lowers pelvis while preserving sole clearance")
  native.queue_free();await settle()
 root.size=Vector2i(1278,590);await settle()
 check(app.viewport.size.y>150,"Phone-shaped viewport remains usable")
 for option in [app.action,app.view_choice,app.angle_choice]:check(option.size.y>=44,"Touch control height")
 var report={"checks":checks,"failures":failures,"renderer":RenderingServer.get_current_rendering_method(),"display":DisplayServer.get_name(),"stats_copper":first.stats(),"stats_silver":second.stats(),"deformation_samples":bounds_samples,"privacy":"Supplied files, derived models and captures remain in git-ignored build output."}
 var report_name="check-report-headless.json" if DisplayServer.get_name()=="headless" else "check-report.json"
 var file=FileAccess.open(folder.path_join(report_name),FileAccess.WRITE);file.store_string(JSON.stringify(report,"\t"));file.close()
 print("FBX TRIAL: %d checks / %d failures"%[checks,failures.size()])
 app.queue_free();await settle();quit(0 if failures.is_empty() else 1)

extends SceneTree
## Run with the real renderer: pose baking needs registered GPU skinning.
func _initialize() -> void:call_deferred("run")
func prepare_ownership(node:Node,scene:Node) -> void:
 if node!=scene:node.owner=scene
 for child in node.get_children():prepare_ownership(child,scene)
func run() -> void:
 if DisplayServer.get_name()=="headless":push_error("Preparation needs a renderer for rest baking.");quit(1);return
 var folder=ProjectSettings.globalize_path("res://").path_join("../../build/local-fbx-trial").simplify_path()
 var source=folder.path_join("source/character.fbx")
 var doc=FBXDocument.new();var state=FBXState.new()
 if doc.append_from_file(source,state)!=OK:quit(1);return
 var model=doc.generate_scene(state);root.add_child(model)
 var rig=model.find_children("*","Skeleton3D",true,false)[0]
 rig.reset_bone_poses();rig.force_update_all_bone_transforms()
 for i in 6:await process_frame
 var report={"bones":rig.get_bone_count(),"meshes":[],"animations":[]}
 for node in model.find_children("*","MeshInstance3D",true,false):
  var baked=node.bake_mesh_from_current_skeleton_pose()
  if baked==null:push_error("Skin bake unavailable");quit(1);return
  var a=node.mesh.surface_get_arrays(0)
  report.meshes.append({"name":str(node.name),"triangles":a[Mesh.ARRAY_INDEX].size()/3,"influences_per_vertex":a[Mesh.ARRAY_WEIGHTS].size()/a[Mesh.ARRAY_VERTEX].size(),"source_binds":node.skin.get_bind_count(),"baked_aabb":str(baked.get_aabb())})
  if ResourceSaver.save(baked,folder.path_join(str(node.name)+"-rest.res"))!=OK:quit(1);return
 for player in model.find_children("*","AnimationPlayer",true,false):
  for key in player.get_animation_list():report.animations.append({"name":str(key),"length":player.get_animation(key).length})
 prepare_ownership(model,model);var packed=PackedScene.new();packed.pack(model)
 if ResourceSaver.save(packed,folder.path_join("imported.tscn"))!=OK:quit(1);return
 var file=FileAccess.open(folder.path_join("source-report.json"),FileAccess.WRITE);file.store_string(JSON.stringify(report,"\t"));file.close()
 print("FBX PREPARED: original skin/idle preserved; rest geometry baked locally")
 model.queue_free();await process_frame;quit()

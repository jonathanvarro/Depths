extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var packed=load("res://../../art/concepts/character-lowpoly-v1/traveller.tscn")
 var model=packed.instantiate();root.add_child(model)
 await process_frame
 assert(model.get_script()==null)
 var rig=model.get_node("SharedHumanoid")
 assert(rig.get_bone_count()==16)
 var player=model.get_node("PoseLibrary")
 player.play("seated");player.seek(.3,true);player.pause()
 await process_frame
 assert(rig.get_bone_pose_position(0).y<.6)
 for child in model.get_children():
  if child is MeshInstance3D:assert(child.get_node(child.skeleton)==rig and child.skin.get_bind_count()==16)
 print("LOWPOLY EXPORT: native scene loads independently; skin paths and seated animation pass")
 model.queue_free();await process_frame;quit()

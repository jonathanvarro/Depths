extends SceneTree
## #121: family identity and face-specific resources, separate from visual approval.
func _initialize() -> void:
	var catalogue:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/portraits/catalog.json"))
	var checks:=0
	var failures:Array[String]=[]
	var shared_body:Texture2D
	var shared_outfit:Texture2D
	for entry:Dictionary in catalogue.portraits+catalogue.supporting_resources:
		var set:PortraitSet=load(entry.resource)
		checks+=1
		if set.rig_kind!=entry.kind or str(set.rig_family)!=entry.family or str(set.face_id)!=entry.face_id:failures.append(entry.id+" identity mismatch")
		if entry.kind=="Reusable":
			if shared_body==null:shared_body=set.body;shared_outfit=set.clothing[0]
			checks+=1
			if set.body!=shared_body or set.clothing[0]!=shared_outfit:failures.append(entry.id+" wrong body/socket")
		else:
			checks+=1
			if not str(set.rig_family).begins_with("unique-"+entry.face_id):failures.append(entry.id+" unique family")
		for frame:Texture2D in Array(set.blink_frames)+Array(set.talk_frames):
			checks+=1
			if frame.get_size()!=Vector2(192,192) or not frame.resource_path.contains("/"+entry.face_id+"/") and not (entry.face_id=="mara" and frame.resource_path.contains("/mara-neutral-v1/")):failures.append(entry.id+" borrowed/invalid frame")
	var file=FileAccess.open("res://art/concepts/portrait-rigs-v1/godot-validation.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"note":"Family/ownership checks do not certify visual fit; use paused inspector."},"\t")+"\n");file.close()
	print("PORTRAIT_REGISTRY checks=%d failures=%d"%[checks,failures.size()])
	for failure in failures:push_error(failure)
	quit(0 if failures.is_empty() else 1)

extends SceneTree
## #249: Main comes and goes without leaving nodes behind. Visits floor 2,
## frees Main, then lists any node that was never put in (or was taken out
## of) the scene and so would leak at exit.

var fails := 0


func check(label: String, ok: bool, detail = "") -> void:
	if not ok: fails += 1
	print("PASS " if ok else "FAIL ", label, "  ", detail)


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	var before: Array = Node.get_orphan_node_ids()
	var main = load("res://scenes/main.tscn").instantiate()
	main.play_opening = false
	main.use_debug_layout = true
	root.add_child(main)
	await create_timer(0.6).timeout
	main._go_to_floor(2, main.Arrival.FROM_ABOVE)
	await create_timer(0.5).timeout
	main.queue_free()
	for i in 8:
		await process_frame
	var left := []
	for id in Node.get_orphan_node_ids():
		if id not in before:
			var node = instance_from_id(id)
			left.append("%s %s" % [node.get_class(), node.name])
	check("freeing Main leaves no stray nodes (#249)", left.is_empty(), str(left))
	print("fails=", fails)
	quit()

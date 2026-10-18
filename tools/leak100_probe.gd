extends SceneTree
## #100: nothing should outlive Main at exit after a save (run with --verbose
## and look for "still in use" or "Leaked instance").

func _initialize() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	main.play_opening = false
	root.add_child(main)
	await create_timer(0.5).timeout
	main._save_now()
	main.queue_free()
	await create_timer(0.3).timeout
	load("res://scripts/save_game.gd").delete()
	quit()

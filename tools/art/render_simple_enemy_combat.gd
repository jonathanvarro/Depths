extends SceneTree
## Capture each connected enemy in the real combat UI, without changing saves/data.
const CombatState := preload("res://scripts/combat_state.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	for phone in [false, true]:
		root.size = Vector2i(1278,590) if phone else Vector2i(1280,720)
		for enemy in ["rat", "spider", "goblin"]:
			var main = load("res://scenes/main.tscn").instantiate()
			main.use_debug_layout = true
			main.floor_seed = 33
			main.simulate_phone_safe_area = phone
			root.add_child(main)
			await process_frame
			main._party.place(main._map, Vector2i(7,1))
			main._party_state.members[0].initiative = 100
			var types: Array[EnemyType] = [load("res://data/enemies/" + enemy + ".tres")]
			var state = CombatState.new(main._party_state, types)
			main._place_foes(state.foes)
			main._in_combat = true
			main._party.locked = true
			main._touch_pad.visible = false
			main._pack_button.disabled = true
			main._message_label.visible = false
			main._combat.run(state, main._cards)
			await create_timer(0.25).timeout
			await RenderingServer.frame_post_draw
			var suffix := "phone" if phone else "desktop"
			root.get_texture().get_image().save_png("res://art/enemies/cave-simple-v1/" + enemy + "-combat-" + suffix + ".png")
			main.queue_free()
			await process_frame
	print("SIMPLE_ENEMY_REAL_COMBAT_RENDERS_SAVED: 6")
	quit()

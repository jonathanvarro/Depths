extends SceneTree
## #33: check the EnemyType -> scene -> combat animation contract.
const CombatState := preload("res://scripts/combat_state.gd")
var checks := 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if not ok:
		push_error(message)
		quit(1)
		assert(ok, message)
	checks += 1

func _run() -> void:
	var screen = load("res://scripts/combat_screen.gd").new()
	root.add_child(screen)
	for enemy in ["rat", "spider", "goblin"]:
		var type: EnemyType = load("res://data/enemies/" + enemy + ".tres")
		check("cave-simple-v1" in type.scene.resource_path, enemy + " definition uses simpler scene")
		var node: Node3D = type.scene.instantiate()
		root.add_child(node)
		var sprite: AnimatedSprite3D = node.get_node("Sprite")
		check(sprite != null, "Combat Sprite node")
		check(sprite.texture_filter == BaseMaterial3D.TEXTURE_FILTER_NEAREST, "Nearest filter")
		check(absf(sprite.position.y - 56 * sprite.pixel_size) < 0.00001, "Ground pivot")
		for pose in ["idle", "attack", "hurt"]:
			check(sprite.sprite_frames.has_animation(pose), "Named pose")
			check(sprite.sprite_frames.get_frame_count(pose) == 1, "One drawing per pose")
			var texture := sprite.sprite_frames.get_frame_texture(pose, 0)
			check(texture.get_size() == Vector2(128,128), "Exact canvas")
			check(texture.get_image().detect_alpha() != Image.ALPHA_NONE, "Transparent import")
		var foe = CombatState.Foe.new(type, enemy)
		foe.node = node
		for pose in ["attack", "hurt"]:
			screen._play(foe, pose, 0.06)
			check(sprite.animation == pose, "Real combat switches to " + pose)
			await create_timer(0.09).timeout
			check(sprite.animation == "idle", "Real combat restores idle")
		await screen._fade_out(foe)
		check(not node.visible and is_zero_approx(sprite.modulate.a), "Combat death fade works")
		node.queue_free()
	screen.queue_free()
	await process_frame
	print("SIMPLE_ENEMY_COMBAT_CHECKS_PASSED: ", checks)
	quit()

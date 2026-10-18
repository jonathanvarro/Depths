extends SceneTree
## Disposable model/UI checks; --capture adds real opening/Pack review images.
const Supplies := preload("res://scripts/supplies.gd")
const PackScreen := preload("res://scripts/pack_screen.gd")
const TORCH := preload("res://data/items/torch.tres")
const HELD := preload("res://art/props/torch-v1/held.tscn")
const OUT := "res://art/concepts/torch-v1/"
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func _run() -> void:
	check(TORCH.icon != null and TORCH.icon.get_size() == Vector2(64, 64), "Torch icon connected at 64px")
	check(TORCH.effect == SupplyItem.Effect.LIGHT_TORCH and TORCH.use_time == 2, "Existing item effect/time retained")
	var held = HELD.instantiate()
	root.add_child(held)
	var flame: AnimatedSprite2D = held.get_node("FlameAnchor/Flames")
	var anchor: Node2D = held.get_node("FlameAnchor")
	check(flame.sprite_frames == load("res://art/features/campfire-v1/frames.tres"), "Reuses unchanged campfire animation")
	check(flame.sprite_frames.get_frame_count("burn") == 6 and flame.sprite_frames.get_animation_loop("burn"), "Six looping frames")
	var supplies = Supplies.new()
	supplies.has_lantern = false
	supplies.source = Supplies.Source.NONE
	supplies.add(TORCH, 2)
	check(supplies.light_torch(TORCH), "Existing torch use succeeds")
	held.apply_supplies(supplies)
	check(held.visible and flame.visible and flame.is_playing() and anchor.scale == Vector2.ONE, "Steady art follows held torch")
	var first_frame := flame.frame
	await create_timer(0.16).timeout
	check(flame.frame != first_frame, "Animation advances")
	check(supplies.torch_left == 50 and supplies.count(TORCH) == 1, "Presentation consumes no time/items")
	supplies.burn(41)
	held.apply_supplies(supplies)
	check(held.visible and held.dim and anchor.scale.is_equal_approx(Vector2(0.6, 0.6)), "Dim state follows real nine-time threshold")
	check(anchor.position == Vector2(64, 92), "Smaller flame retains attachment")
	supplies.burn(9)
	held.apply_supplies(supplies)
	check(not held.visible and not flame.is_playing(), "No held art after burnout to darkness")
	supplies.has_lantern = true
	supplies.light_torch(TORCH)
	supplies.lose_torch()
	held.apply_supplies(supplies)
	check(supplies.source == Supplies.Source.LANTERN and not held.visible, "Throw/fallback removes held torch art")
	held.visible = true
	held.set_burning(false)
	check(not flame.visible and held.get_node("Body").visible, "Unlit review keeps the same body")
	held.queue_free()
	var pack := PackScreen.new()
	var party = load("res://scripts/party_state.gd").new()
	party.add_member(load("res://data/companions/mara.tres"))
	party.supplies.add(TORCH, 2)
	root.add_child(pack)
	pack.setup(party)
	for definition in [TORCH, load("res://data/items/oil_flask.tres"), SupplyItem.new()]:
		var row := pack._item_row(definition)
		var icons := row.find_children("*", "TextureRect", false, false)
		check(icons.size() == (1 if definition.icon else 0), "Supply row draws optional icon")
		if definition.icon:
			check(icons[0].texture == definition.icon and icons[0].custom_minimum_size == Vector2(40, 40), "Supply icon texture/size retained")
		row.free()
	pack.queue_free()
	await process_frame
	if "--capture" in OS.get_cmdline_user_args():
		await _capture_live()
	var report := {"checks": checks, "failures": failures, "godot": "4.7.2",
		"physical_phone_test": false, "viewports": [[1280, 720], [1278, 590]],
		"held_integration": "Reusable presentation only; captures add an illustrative overlay. Pack icon is live."}
	FileAccess.open(OUT + "godot-validation.json", FileAccess.WRITE).store_string(JSON.stringify(report, "  ") + "\n")
	print("TORCH_CHECKS: ", checks, " failures: ", failures.size())
	quit(0 if failures.is_empty() else 1)

func _capture_live() -> void:
	for phone in [false, true]:
		root.size = Vector2i(1278, 590) if phone else Vector2i(1280, 720)
		await process_frame
		await process_frame
		var suffix := "phone" if phone else "desktop"
		var main = load("res://scenes/main.tscn").instantiate()
		main.floor_seed = 33
		main.simulate_phone_safe_area = phone
		root.add_child(main)
		# The wake-up eyelid/head animation ends at 4.2 seconds.
		await create_timer(4.4).timeout
		var canvas := CanvasLayer.new()
		root.add_child(canvas)
		var torch_view = HELD.instantiate()
		canvas.add_child(torch_view)
		# Illustrative foreground placement: the grip continues below the view.
		# This is not a decision about the final shared HUD (#51).
		torch_view.scale = Vector2(2, 2)
		var pad_rect: Rect2 = main._touch_pad.get_global_rect()
		torch_view.position = Vector2(pad_rect.position.x - 178, root.size.y - 420)
		var body_rect := Rect2(torch_view.position + Vector2(94, 160), Vector2(68, 336))
		check(not body_rect.intersects(main._touch_pad.get_global_rect()), "Illustrative torch clears movement controls")
		var supplies = main._party_state.supplies
		supplies.add(TORCH, 2)
		supplies.source = Supplies.Source.TORCH
		for left in [50.0, 9.0]:
			supplies.torch_left = left
			main._party.set_light(supplies.light_fraction())
			torch_view.apply_supplies(supplies)
			check(torch_view.visible and torch_view.dim == (left < 10), "Real opening sample source state")
			await _capture(("dim-" if left < 10 else "steady-") + suffix)
		torch_view.hide()
		main._set_pack(true)
		await process_frame
		await process_frame
		var textures: Array[Node] = main._pack.find_children("*", "TextureRect", true, false)
		var found := false
		for texture in textures:
			if texture.texture == TORCH.icon:
				found = true
				check(texture.get_global_rect().size == Vector2(40, 40), "Live torch icon fits its slot")
				var scrolls: Array[Node] = main._pack.find_children("*", "ScrollContainer", true, false)
				if not scrolls.is_empty():
					scrolls[0].ensure_control_visible(texture.get_parent())
				await process_frame
				check(Rect2(Vector2.ZERO, Vector2(root.size)).encloses(texture.get_global_rect()), "Torch icon is visible inside viewport")
		check(found, "Live Pack shows torch icon")
		await _capture("pack-" + suffix)
		canvas.queue_free()
		main.queue_free()
		await process_frame

func _capture(label: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(OUT + label + ".png") == OK, "Capture " + label)

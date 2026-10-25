extends SceneTree
## The 3D held torch and lantern (owner, 2026-10-20): they show while
## exploring, follow the supplies (lit, low, out), hide during fights, and
## stay inside the screen. Args: tag ("desk" or "phone"), screenshot dir.

const Supplies := preload("res://scripts/supplies.gd")
const TORCH := preload("res://data/items/torch.tres")

var fails := 0
var dir := ""
var tag := "desk"


func check(label: String, ok: bool, detail = "") -> void:
	if not ok: fails += 1
	print("PASS " if ok else "FAIL ", label, "  ", detail)


func _snap(name: String) -> void:
	for i in 6:
		await process_frame
	if dir != "":
		root.get_texture().get_image().save_png("%s/held_%s_%s.png" % [dir, tag, name])


## The model's own render, enlarged 4x, for review.
func _closeup(view, which: String) -> void:
	await create_timer(0.3).timeout
	if dir == "":
		return
	var image: Image = view._viewport.get_texture().get_image()
	image.resize(image.get_width() * 4, image.get_height() * 4, Image.INTERPOLATE_NEAREST)
	image.save_png("%s/held_%s_closeup_%s.png" % [dir, tag, which])


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	tag = args[0] if args.size() > 0 else "desk"
	dir = args[1] if args.size() > 1 else ""
	var main = load("res://scenes/main.tscn").instantiate()
	main.play_opening = false
	main.floor_seed = 11
	main.simulate_phone_safe_area = tag == "phone"
	root.add_child(main)
	await create_timer(0.6).timeout
	var view = main.get_node("CanvasLayer").find_child("HeldLight", true, false) if main.has_node("CanvasLayer") else null
	if view == null:
		for node in main.find_children("*", "Node2D", true, false):
			if node.get_script() == preload("res://scripts/held_light_view.gd"):
				view = node
	check("the held light is in the game", view != null)
	if view == null:
		print("fails=", fails)
		quit()
		return
	var supplies = main._party_state.supplies
	# A burning torch.
	supplies.has_lantern = false
	supplies.add(TORCH, 2)
	supplies.light_torch(TORCH)
	await create_timer(0.3).timeout
	check("a lit torch shows the torch", view.visible and view._torch.visible and not view._lantern.visible)
	var rect := Rect2(view._sprite.global_position, view._sprite.get_rect().size * view._sprite.global_scale)
	var screen := Rect2(Vector2.ZERO, root.get_visible_rect().size)
	# Held low (owner, 2026-10-25): the top and sides on screen, the
	# handle's end below the bottom edge.
	check("it sits on screen, its handle running off the bottom", rect.position.x >= 0 and rect.end.x <= screen.end.x and rect.position.y >= 0 and rect.end.y > screen.end.y and rect.end.y - screen.end.y < rect.size.y * 0.3, str(rect))
	await _snap("torch")
	# Walking and turning: it bobs and sways.
	var before: Vector3 = view._pivot.position
	main._party._turn(1)
	await create_timer(0.12).timeout
	check("turning swings it", absf(view._sway) > 0.01, "%.3f" % view._sway)
	await _snap("torch_turning")
	await create_timer(0.5).timeout
	# Burning low.
	supplies.torch_left = 6.0
	await create_timer(0.2).timeout
	check("a low torch burns smaller", view._torch._flame_root.scale.x < 0.9)
	await _snap("torch_low")
	# The lantern instead.
	supplies.lose_torch()
	supplies.has_lantern = true
	supplies.oil = Supplies.LANTERN_CAPACITY
	supplies.source = Supplies.Source.LANTERN
	await create_timer(0.3).timeout
	check("a lantern shows the lantern", view._lantern.visible and not view._torch.visible)
	await _snap("lantern")
	supplies.oil = 0.0
	await create_timer(0.2).timeout
	check("an empty lantern is dark", not view._lantern._flame_root.visible)
	await _snap("lantern_out")
	supplies.oil = Supplies.LANTERN_CAPACITY
	await _closeup(view, "lantern")
	supplies.has_lantern = false
	supplies.light_torch(TORCH)
	await _closeup(view, "torch")
	# Hidden in a fight.
	var rat: Array[EnemyType] = [load("res://data/enemies/rat.tres")]
	main._start_combat(main._party.cell, rat)
	await create_timer(0.3).timeout
	check("hidden during a fight", not view.visible)
	print("fails=", fails)
	quit()

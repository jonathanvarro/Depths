extends SceneTree
## #39: real-model checks on disposable sample parties plus layout captures.
var checks := 0
var failures: Array[String] = []
var layouts: Array[Dictionary] = []
const OUT := "res://art/ui/pack-v1/"

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func check_layout(node: Node, viewport_size: Vector2i, phone: bool) -> void:
	for child in node.get_children():
		if child is Control and child.is_visible_in_tree():
			var rect: Rect2 = child.get_global_rect()
			check(rect.position.x >= -1 and rect.position.y >= -1 and rect.end.x <= viewport_size.x+1 and rect.end.y <= viewport_size.y+1,"Visible control fits: %s %s in %s" % [child.name,rect,viewport_size])
			if child is Button:
				check(rect.size.y >= (72 if phone else 56),"Button target height")
		check_layout(child,viewport_size,phone)

func capture(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+name+".png")

func point_at(button: Button, touch: bool) -> void:
	var center := button.get_global_rect().get_center()
	for pressed in [true,false]:
		if touch:
			var event := InputEventScreenTouch.new()
			event.position = center
			event.pressed = pressed
			Input.parse_input_event(event)
		else:
			var event := InputEventMouseButton.new()
			event.position = center
			event.button_index = MOUSE_BUTTON_LEFT
			event.pressed = pressed
			Input.parse_input_event(event)
		await process_frame
	await process_frame

func _run() -> void:
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	var definition: Companion = load("res://data/companions/mara.tres")
	var original_health := definition.health
	var original_injuries := definition.injuries.size()
	for entry in [["desktop",Vector2i(1280,720),false],["phone",Vector2i(1278,590),true],["phone-se",Vector2i(1334,750),true]]:
		var name: String = entry[0]
		root.size = entry[1]
		var node = load(OUT+"preview.tscn").instantiate()
		node.phone = entry[2]
		root.add_child(node)
		await create_timer(0.15).timeout
		var view = node.pack
		var party = node.party
		var clock: int = party.time_elapsed
		var starting_oil: float = party.supplies.oil
		for item: SupplyItem in party.supplies.items:
			view.row_buttons[item].pressed.emit()
			await process_frame
			await process_frame
			check(view.selected == item,"Row selects its item")
			check(view.detail_title.text == item.display_name,"Selection updates detail")
			check(party.time_elapsed == clock and party.supplies.oil == starting_oil,"Inspection is free")
			check_layout(node,root.size,node.phone)
			check(view.root_panel.get_global_rect().end.y <= root.size.y-(35 if node.phone else 28)+1,"Panel respects bottom review inset")
			if name != "phone-se":
				await capture(name+"-"+item.resource_path.get_file().get_basename())
			layouts.append({"layout":name,"item":item.display_name,"viewport":[root.size.x,root.size.y]})
		var oil: SupplyItem = load("res://data/items/oil_flask.tres")
		var ration: SupplyItem = load("res://data/items/ration.tres")
		var draught: SupplyItem = load("res://data/items/restorative_draught.tres")
		var dressing: SupplyItem = load("res://data/items/dressing.tres")
		await point_at(view.row_buttons[ration],false)
		check(view.selected == ration and party.time_elapsed == clock,"Mouse inspection routes to row without spending time")
		await point_at(view.row_buttons[oil],true)
		check(view.selected == oil and party.time_elapsed == clock,"Touch inspection routes to row without spending time")
		view.select_item(ration)
		view.action_button.pressed.emit()
		check(party.supplies.count(ration) == 1 and party.time_elapsed == clock+ration.use_time,"Action uses existing item/time rules")
		check(not party.members[0].pending_effects.is_empty(),"Healing remains over time")
		party.supplies.oil = 100.0
		view.select_item(oil)
		check(view.action_button.disabled and view.action_button.text == "Lantern is full","Full-lantern unavailable state")
		var before: int = party.time_elapsed
		view.use_selected()
		check(party.time_elapsed == before,"Unavailable use cannot spend time")
		party.supplies.oil = 50.0
		view.refresh()
		view.action_button.pressed.emit()
		check(party.supplies.count(oil) == 2 and party.supplies.open_flask > 0 and party.supplies.oil > 50,"Partial flask retained and displayed")
		view.select_item(draught)
		view.action_button.pressed.emit()
		check(view.action_button.disabled and view.row_counts[draught].text == "×0","Depleted item stays visible and unavailable")
		check(view.row_buttons[draught].has_focus(),"Focus returns to selected row after depletion")
		view.select_item(dressing)
		view.action_button.pressed.emit()
		check(party.members[0].dressed.size() == 1,"Dressing binds existing injury")
		check(view.action_button.disabled and view.action_button.text == "No injury to bind","Unavailable treatment reason")
		await process_frame
		await process_frame
		check_layout(node,root.size,node.phone)
		if name != "phone-se":
			await capture(name+"-after-use")
		view.back_button.pressed.emit()
		check(not view.visible and node.reopen.visible and node.reopen.has_focus(),"Back returns and restores opener focus")
		node.reopen.pressed.emit()
		check(view.visible and view.back_button.has_focus(),"Reopen restores navigation focus")
		var escape := InputEventKey.new()
		escape.keycode = KEY_ESCAPE
		escape.pressed = true
		Input.parse_input_event(escape)
		await process_frame
		await process_frame
		check(not view.visible,"Escape returns from Pack")
		node.queue_free()
		await process_frame
	check(definition.health == original_health and definition.injuries.size() == original_injuries,"Sample party never mutates hero resource")
	var report := {"godot":"4.7.2", "checks":checks, "failures":failures,"layouts":layouts,"live_pack_changed":false,"physical_phone_test":false}
	var file := FileAccess.open(OUT+"validation.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"  ")+"\n")
	print("PACK_DESIGN_CHECKS: ",checks," failures: ",failures.size())
	quit(0 if failures.is_empty() else 1)

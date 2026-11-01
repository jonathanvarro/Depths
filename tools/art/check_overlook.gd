extends SceneTree
## Isolated #190 asset/interaction fixture. Never loads Main, Settings or saves.
const SCENE:=preload("res://art/camp/overlook-v1/scene.tscn")
const OUT:="res://art/concepts/overlook-v1/"
var checks:=0
var failures:Array[String]=[]
var captures:Array[String]=[]
var chosen:Array[String]=[]
var camp:Control

func _initialize() -> void:call_deferred("run")
func check(ok:bool,what:String) -> void:
	checks+=1
	if not ok:failures.append(what);push_error(what)
func settle(frames:=8) -> void:
	for i in frames:await process_frame
func choose(id:String) -> void:chosen.append(id)

func photograph(name:String) -> Image:
	var move:=InputEventMouseMotion.new();move.position=Vector2(-100,-100);move.global_position=move.position;Input.parse_input_event(move)
	await settle();await RenderingServer.frame_post_draw
	var image:=root.get_texture().get_image();var path:=OUT+name+".png"
	check(image.save_png(path)==OK,"Capture "+name);captures.append(name+".png");return image

func click_at(point:Vector2,touch:=false) -> void:
	for pressed in [true,false]:
		if touch:
			var event:=InputEventScreenTouch.new();event.index=0;event.position=point;event.pressed=pressed;Input.parse_input_event(event)
		else:
			var event:=InputEventMouseButton.new();event.position=point;event.global_position=point;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=pressed;Input.parse_input_event(event)
		await settle(2)

func fit_checks(label:String) -> void:
	var rects:Dictionary=camp.target_rects();var ids:=rects.keys()
	var safe:Vector4=camp._safe
	var available:=Rect2(safe.x,safe.y,camp.size.x-safe.x-safe.z,camp.size.y-safe.y-safe.w)
	for id in ids:
		var rect:Rect2=rects[id]
		check(rect.size.x>=43.9 and rect.size.y>=43.9,label+" target44 "+id)
		check(available.encloses(rect),label+" safe area "+id)
	for i in ids.size():
		for j in range(i+1,ids.size()):check(not rects[ids[i]].intersects(rects[ids[j]]),label+" separate "+ids[i]+"/"+ids[j])

func run() -> void:
	root.size=Vector2i(1280,720);camp=SCENE.instantiate();root.add_child(camp);await settle()
	camp.animate_lights=false;camp.target_activated.connect(choose)
	check(camp._layers.size()==12,"Independent layer count")
	for id in ["shelter","stash","survey","firepit","supplies","lantern"]:
		var site=load("res://art/camp/overlook-v1/sites/"+id+".tscn").instantiate()
		var sprite:Sprite2D=site.get_node("Art")
		check(sprite.texture!=null and sprite.scale==Vector2(0.5,0.5) and not sprite.centered,"Standalone registered site "+id);site.free()
	check(camp._occupants.is_empty(),"No assumed occupants")
	check(camp._buttons.stash.z_index>40 and camp._caption.z_index>100,"Interaction highlight and caption above foreground")
	check(camp.set_occupants(["mara-warming","corin-equipment","alwen-reading"]),"Existing-party art accepted")
	check(not camp.set_occupants(["mara-warming","mara-relaxing"]),"Duplicate identity rejected")
	check(camp._occupants.size()==3,"Invalid update stays atomic")
	check(not camp.set_occupants(["mara-warming","corin-equipment","alwen-reading","fixer-planning"]),"Fourth person rejected")
	check(not camp.set_occupants(["invented-person"]),"Unknown identity rejected")
	camp.refuge_state="discovered";await settle()
	check(camp.target_rects().size()==2,"Bare refuge retains only both route targets")
	check(not camp._layers.stash.visible and not camp._layers["mara-warming"].visible,"Bare refuge empty")
	if DisplayServer.get_name()!="headless":await photograph("discovered-1280")
	camp.refuge_state="provisioned";await settle()
	check(camp.target_rects().size()==5,"Provisioned service targets")
	check(not camp._layers.lantern.visible and not camp._layers.supplies.visible,"Connection extras independent")
	if DisplayServer.get_name()!="headless":await photograph("provisioned-1280")
	camp.refuge_state="connected";await settle()
	check(camp._layers.lantern.visible and camp._layers.supplies.visible,"Connected extras present")
	for id in ["shelter","stash","survey","firepit"]:
		camp.set_site_present(id,false)
		check(not camp._layers[id].visible,"Absent site hidden "+id)
		if id=="firepit":check(not camp._layers.flame.visible and not camp._fire_glow.visible and not camp._layers["mara-warming"].visible,"Fire/occupant follows pit presence")
		if id=="survey":check(not camp._layers["alwen-reading"].visible,"Reader follows stool/table")
		if id=="shelter":check(not camp._layers.lantern.visible and not camp._lamp_glow.visible,"Lantern follows shelter")
		camp.set_site_present(id,true)
	camp.fire_burning=false;check(not camp._layers.flame.visible and not camp._fire_glow.visible,"Cold fire has no flame or glow")
	check(not camp._layers["mara-warming"].visible and camp._layers["corin-equipment"].visible,"Warming requires a lit fire; equipment checking does not")
	if DisplayServer.get_name()!="headless":await photograph("cold-camp-1280")
	camp.fire_burning=true
	# The same target must activate exactly once via native mouse or touch input.
	for touch in [false,true]:
		for id in camp.target_rects():
			chosen.clear();await click_at(camp.target_rects()[id].get_center(),touch)
			check(chosen.size()==1 and chosen[0]==id,("Touch " if touch else "Mouse ")+id)
	chosen.clear();camp._buttons.stash.grab_focus()
	for pressed in [true,false]:
		var event:=InputEventKey.new();event.keycode=KEY_ENTER;event.pressed=pressed;Input.parse_input_event(event);await settle(2)
	check(chosen==["stash"],"Keyboard activation")
	camp._buttons.stash.release_focus();camp._caption.hide()
	# Real render/layout at desktop and phone sizes, including Larger root scaling.
	for profile in [[1280,720,1.0],[1278,590,1.0],[1278,590,1.3],[1334,750,1.3],[844,390,1.3],[667,375,1.0]]:
		root.size=Vector2i(profile[0],profile[1]);root.content_scale_factor=profile[2]
		camp.set_safe_area(Vector4.ZERO if profile[0]==1280 else Vector4(59/profile[2],0,59/profile[2],21/profile[2]));camp.set_text_scale(profile[2]);await settle()
		var label:="%d-%s"%[profile[0],"larger" if profile[2]>1 else "normal"]
		fit_checks(label)
		if DisplayServer.get_name()!="headless":
			camp.show_targets=false;camp._caption.hide();await photograph("connected-"+label)
			camp.show_targets=true;await photograph("targets-"+label);camp.show_targets=false
	root.size=Vector2i(1278,590);root.content_scale_factor=1.0;camp.set_safe_area(Vector4(59,0,59,21));camp.set_text_scale(1.0)
	if DisplayServer.get_name()!="headless":
		camp._buttons.stash.grab_focus();await photograph("focused-stash-1278")
		camp._buttons.stash.release_focus();camp._caption.hide()
	camp.set_occupants([]);check(camp._layers.values().filter(func(n):return n.name in ["corin-equipment","mara-warming","alwen-reading","fixer-planning","mara-relaxing"] and n.visible).is_empty(),"Empty party remains empty")
	if DisplayServer.get_name()!="headless":await photograph("empty-party-1278")
	camp.set_occupants(["mara-relaxing","fixer-planning","corin-equipment"])
	if DisplayServer.get_name()!="headless":
		await photograph("planning-resting-1278")
		camp._caption.hide();camp.animate_lights=false;await settle()
		var still_a:=root.get_texture().get_image().get_data().hex_encode().sha256_text();await settle(20)
		var still_b:=root.get_texture().get_image().get_data().hex_encode().sha256_text();check(still_a==still_b,"Still pixels exactly stable")
		camp.animate_lights=true;await settle(35)
		check(root.get_texture().get_image().get_data().hex_encode().sha256_text()!=still_b,"Animated effects change pixels")
		await photograph("effects-moving-1278")
		camp.hide();var phase:float=camp._phase;await settle(12);check(camp._phase==phase,"Hidden camp stops effects processing")
		camp.show();camp.animate_lights=false;check(camp._phase==0.0,"Still mode resets phase")
	var report:={"checks":checks,"failures":failures,"captures":captures,"renderer":RenderingServer.get_current_rendering_method(),"uses_player_files":false,"native_mouse_touch_keyboard":true,"physical_iphone_tested":false}
	var f:=FileAccess.open(OUT+("godot-headless.json" if DisplayServer.get_name()=="headless" else "godot-renderer.json"),FileAccess.WRITE);f.store_string(JSON.stringify(report,"\t")+"\n");f.close()
	print("OVERLOOK_GODOT: %d checks, %d failures, %d captures"%[checks,failures.size(),captures.size()]);camp.free();quit(0 if failures.is_empty() else 1)

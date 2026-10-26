extends Node3D
## Floor-two growth: cosmetic, seeded, outside encounters and usable places.
const BaseDressing:=preload("res://scripts/dressing.gd")
const Settings:=preload("res://scripts/settings.gd")
const ART:="res://art/dressing/"
const WALL:=["cave-v1/wall-fungus","landmarks-v1/wall-roots","cave-v1/flowstone","cave-v1/cracks-rubble"]
const ROOF:=["cave-v2/moss-curtain","landmarks-v1/root-curtain-b","cave-v1/stalactite-single"]
const EDGE:=["cave-v2/floor-fungus","cave-v1/stalagmite-stub","cave-v1/stalagmite-broken"]
const FLOOR:=["cave-v1/puddle-small","cave-v1/floor-gravel"]
const HEIGHTS:={"wall-fungus":0.85,"wall-roots":1.15,"flowstone":1.25,"cracks-rubble":0.45}
const PULSE:=preload("res://art/effects/ambient-v1/fungus-pulse.tres")
const DRIP:=preload("res://art/effects/ambient-v1/drip.tres")
var _motion:=true
var _animations:Array[AnimatedSprite3D]=[]

static func clear_cell(map,cell:Vector2i,avoid:Dictionary) -> bool:
	return BaseDressing._clear(map,cell) and not avoid.has(cell) and not map.encounter_zones.has(cell)

static func dress(level:Node3D,map,depth:int,seed:int,cell_size:float,wall_height:float,avoid:Dictionary={}) -> int:
	var root=load("res://scripts/fungal_dressing.gd").new()
	root.name="Dressing"
	level.add_child(root)
	var rng:=RandomNumberGenerator.new();rng.seed=hash([seed,depth,"fungal-caverns"])
	for y in map.height:
		for x in map.width:
			var cell:=Vector2i(x,y)
			if not clear_cell(map,cell,avoid) or rng.randi()%3!=0:continue
			var sides:=BaseDressing._wall_sides(map,cell)
			if sides.is_empty():continue
			var side:Vector2i=sides[rng.randi()%sides.size()]
			var centre:=Vector3(x*cell_size,0,y*cell_size)
			var roll:=rng.randi()%10
			var id:String
			var at:Vector3
			var yaw:=0.0
			if roll<5:
				id=WALL[rng.randi()%WALL.size()]
				at=centre+Vector3(side.x,0,side.y)*(cell_size/2.0-0.025)
				at.y=HEIGHTS[id.get_file()]
				yaw=BaseDressing._yaw_facing(-side)
			elif roll<7:
				id=ROOF[rng.randi()%ROOF.size()]
				at=centre+Vector3(side.x,0,side.y)*cell_size*0.34
				at.y=wall_height-0.02
				if id.ends_with("moss-curtain") and rng.randi()%3==0:id+="-lit"
			elif roll<9:
				id=EDGE[rng.randi()%EDGE.size()]
				at=centre+Vector3(side.x,0,side.y)*cell_size*0.38
				if id.ends_with("floor-fungus") and rng.randi()%3==0:id+="-lit"
			else:
				id=FLOOR[rng.randi()%FLOOR.size()]
				at=centre+Vector3(side.x,0,side.y)*cell_size*0.24
				yaw=rng.randi_range(0,3)*PI/2.0
			var piece:Node3D=load(ART+id+".tscn").instantiate()
			piece.position=at;piece.rotation.y=yaw
			piece.set_meta("dressing_id",id.get_file());piece.set_meta("cell",cell)
			piece.set_meta("mount","wall" if roll<5 else ("ceiling" if roll<7 else ("edge" if roll<9 else "floor")))
			root.add_child(piece)
			if id.ends_with("puddle-small"):piece.get_node("Sprite").modulate*=Color(0.7,0.76,0.6,1)
			if id.ends_with("wall-fungus"):
				root._effect(piece,PULSE,Vector3(0,0,0.03),0.0045,0.5)
			elif id.ends_with("flowstone") and rng.randi()%2==0:
				root._effect(piece,DRIP,Vector3(0,-0.7,0.035),0.006,0.6)
			for sprite:AnimatedSprite3D in piece.find_children("*","AnimatedSprite3D",true,false):
				sprite.frame=rng.randi()%sprite.sprite_frames.get_frame_count(&"loop")
				root._animations.append(sprite)
	root._motion=not Settings.get_value("flashes");root._sync_motion()
	return root.get_child_count()

func _effect(parent:Node3D,frames:SpriteFrames,at:Vector3,pixel:float,alpha:float) -> void:
	var sprite:=AnimatedSprite3D.new()
	sprite.sprite_frames=frames;sprite.animation=&"loop";sprite.position=at;sprite.pixel_size=pixel
	sprite.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sprite.shaded=frames==DRIP;sprite.modulate.a=alpha
	parent.add_child(sprite)

func _process(_delta:float) -> void:
	_sync_motion()

func _sync_motion() -> void:
	var motion:bool=Settings.get_value("flashes")
	if motion==_motion:return
	_motion=motion
	for sprite:AnimatedSprite3D in _animations:
		if motion:sprite.visible=true;sprite.play(&"loop")
		else:
			sprite.pause()
			sprite.visible=sprite.sprite_frames!=DRIP

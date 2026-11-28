extends RefCounted
## Sparse Cavern geology and occupation cues. All gameplay placement remains
## in the map. No object in a quest/fight room or on a sloping connector.
const ART := "res://art/props/cavern-rest-v1/"
const SIDES := [Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]

static func dress(level: Node3D,map,_depth: int,seed: int,size: float,_height: float,used: Dictionary) -> int:
	var root := Node3D.new(); root.name="Dressing"; level.add_child(root)
	var occupied := {}; var columns := 0
	for y in range(2,map.height-2):
		for x in range(2,map.width-2):
			var c := Vector2i(x,y)
			if map.is_wall(c):
				if columns>=14 or posmod(hash([seed,c,"column"]),19)!=0 or map.in_story_site(c,1): continue
				var safe := true
				for dy in range(-1,2):
					for dx in range(-1,2):
						if not map.is_wall(c+Vector2i(dx,dy)): safe=false
				if safe:
					var node: Node3D=load(ART+"column-tall.tscn").instantiate()
					node.position=Vector3(x*size,-17,y*size); node.scale=Vector3(1.25,5,1.25); root.add_child(node); columns+=1
					occupied[c]=true
				continue
			if not map.flat_landings.has(c) or used.has(c) or map.in_story_site(c,1) or map.encounter_zones.has(c) or map.events.has(c) or map.marks.get("wall_lights",{}).has(c): continue
			if posmod(hash([seed,c,"daub"]),13)!=0: continue
			for side in SIDES:
				if not map.is_wall(c+side): continue
				var node: Node3D=load(ART+"goblin-daub.tscn").instantiate()
				node.position=Vector3(x*size,1.15,y*size)+Vector3(side.x,0,side.y)*(size*.5-.02)
				node.rotation.y=atan2(-float(side.x),-float(side.y)); root.add_child(node); break
	return root.get_child_count()

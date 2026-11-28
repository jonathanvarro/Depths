extends SceneTree
const Map := preload("res://scripts/dungeon_map.gd")
const Generator := preload("res://scripts/floor_generator.gd")
const Terrain := preload("res://scripts/cavern_terrain.gd")
const Save := preload("res://scripts/save_game.gd")
var checks := 0
var failures: Array[String] = []

func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok: failures.append(label); push_error(label)

func _initialize() -> void:
	for seed_value in range(30):
		var map=Map.new(Generator.generate(seed_value*7919+11,true,3,"cavern"),3)
		var reachable: Dictionary=map.reachable_from(map.start_cell)
		var rows: PackedStringArray=map._rows.duplicate()
		Terrain.ensure(map)
		check(map._rows==rows,"elevation preserves generated topology")
		check(map.reachable_from(map.start_cell)==reachable,"all old walks still connect")
		for c: Vector2i in map.elevations:
			for d in Terrain.SIDES:
				var n: Vector2i=c+d
				if map.is_wall(n): continue
				var rise: float=absf(map.floor_y(c)-map.floor_y(n))
				var run: float=2.0-map.landing_radius(c,2)-map.landing_radius(n,2)
				check(rise<.001 if run<.001 else rise/run<=.50001,"physical grade at most 26.6 degrees")
		var other=Map.new(rows,3); Save.unpack_into(other,Save.pack_object(map))
		check(other.elevations==map.elevations and other.flat_landings==map.flat_landings,"all terrain fields round-trip")
		var before: Dictionary=map.elevations.duplicate(); Terrain.ensure(map)
		check(map.elevations==before,"idempotent restored terrain")
	print(JSON.stringify({"checks":checks,"failures":failures,"seeds":30}))
	quit(0 if failures.is_empty() else 1)

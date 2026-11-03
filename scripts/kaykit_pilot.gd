extends RefCounted
## #224 pilot (owner, 2026-11-03): floor 1 dressing from a CC0 3D pack,
## KayKit Dungeon Remastered, instead of generated art. Miners' stores
## (barrels, kegs, boxes, crates, rubble, bottles) stand against room
## walls, on top of the existing dressing.
##
## Adopted by the owner on 2026-11-03: on by default (Main.kaykit_pilot;
## `-- --no-kaykit` leaves it out). Every piece shares one recoloured texture
## (tools/art/build_kaykit_pilot.py) and one material. Purely cosmetic and
## seeded like dressing.gd: nothing blocks, hides or lights anything.

const Dressing := preload("res://scripts/dressing.gd")
const DIR := "res://art/third-party/kaykit-dungeon-remastered/"
const SCALE := 0.45  # KayKit units to metres: a large barrel stands 0.9 m
## id -> [weight, scale] (rubble is huge in the pack).
const PIECES := {
	"barrel_large": [3, SCALE], "barrel_small": [3, SCALE], "barrel_small_stack": [2, SCALE],
	"keg": [1, SCALE], "box_large": [3, SCALE], "box_small": [3, SCALE],
	"crates_stacked": [2, SCALE], "rubble_half": [2, 0.3],
}
const SMALL := ["bottle_A_brown", "bottle_B_green"]  # beside a bigger piece
## One in this many room cells against a wall gets a little stack of stores.
const ODDS := 5
## The grain repeats once per this many metres: the walls' 64 pixels to a
## 2 m cell, so props and walls share a pixel size.
const GRAIN_METRES := 2.0


## Dresses floor 1's rooms. Returns how many pieces it placed.
static func dress(level: Node3D, map, depth: int, seed: int, cell_size: float, avoid := {}) -> int:
	if depth != 1:
		return 0
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([seed, depth, "kaykit pilot"])
	var root := Node3D.new()
	root.name = "KayKitPilot"
	level.add_child(root)
	var shared := material()  # one per floor, freed with it (never static: #204)
	for y in map.height:
		for x in map.width:
			var cell := Vector2i(x, y)
			if not map._is_room_cell(cell) or not Dressing._clear(map, cell) or avoid.has(cell):
				continue
			var sides: Array[Vector2i] = Dressing._wall_sides(map, cell)
			if sides.is_empty() or rng.randi() % ODDS != 0:
				continue
			var side: Vector2i = sides[rng.randi() % sides.size()]
			var along := Vector3(side.y, 0, side.x).abs()
			var at := Vector3(x * cell_size, 0.0, y * cell_size) + Vector3(side.x, 0, side.y) * cell_size * 0.3
			at += along * rng.randf_range(-0.35, 0.35) * cell_size
			var id: String = _pick(rng)
			_put(root, id, at, rng.randf_range(-0.4, 0.4) + atan2(float(-side.x), float(-side.y)), shared)
			if rng.randi() % 3 == 0:  # a bottle or a small box beside it
				var extra: String = SMALL[rng.randi() % SMALL.size()] if rng.randi() % 2 == 0 else "box_small"
				_put(root, extra, at + along * cell_size * [-0.22, 0.22][rng.randi() % 2], rng.randf() * TAU, shared)
	return root.get_child_count()


static func _pick(rng: RandomNumberGenerator) -> String:
	var total := 0
	for id in PIECES:
		total += PIECES[id][0]
	var roll := rng.randi() % total
	for id in PIECES:
		roll -= PIECES[id][0]
		if roll < 0:
			return id
	return PIECES.keys()[0]


static func _put(root: Node3D, id: String, at: Vector3, yaw: float, shared: Material) -> Node3D:
	var node: Node3D = load(DIR + "models/" + id + ".glb").instantiate()
	node.name = id  # (named for the checks)
	node.position = at
	node.rotation.y = yaw
	node.scale = Vector3.ONE * float(PIECES.get(id, [0, SCALE])[1])
	for mesh: MeshInstance3D in node.find_children("*", "MeshInstance3D", true, false):
		mesh.material_override = shared
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(node)
	return node


## The material a floor's pieces share: the recoloured texture, matte,
## sampled crisply like the painted dressing, with the walls' grain
## multiplied over it in world space (owner, 2026-11-03). World space keeps
## the grain the same size on a bottle and a crate, and needs no new UVs.
static func material() -> StandardMaterial3D:
	var shared := StandardMaterial3D.new()
	shared.albedo_texture = load(DIR + "texture-floor1.png")
	shared.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	shared.roughness = 1.0
	shared.metallic_specular = 0.1
	shared.detail_enabled = true
	shared.detail_albedo = load(DIR + "grain-floor1.png")
	shared.detail_blend_mode = BaseMaterial3D.BLEND_MODE_MUL
	shared.detail_uv_layer = BaseMaterial3D.DETAIL_UV_2
	shared.uv2_triplanar = true
	shared.uv2_world_triplanar = true
	shared.uv2_scale = Vector3.ONE / GRAIN_METRES
	return shared

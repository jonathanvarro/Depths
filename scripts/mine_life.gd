extends Node3D
## Small wildlife and ceiling dust in the upper mines, using cosmetic time.
const Settings := preload("res://scripts/settings.gd")
const Supplies := preload("res://scripts/supplies.gd")
const DungeonMap := preload("res://scripts/dungeon_map.gd")
const BAT := preload("res://art/enemies/creatures-refined-v2/cave-bat.tscn")
const MOUSE := preload("res://art/enemies/creatures-refined-v2/rat.tscn")
const GAP := Vector2(12.0, 25.0)
const KINDS := ["dust", "mouse", "dust", "bat"]

var main: Node
var _rng := RandomNumberGenerator.new()
var _until_next := 5.0
var _map
var _effect: Node3D
var _actor: Node3D
var _dust: MultiMeshInstance3D
var _kind := ""
var _elapsed := 0.0
var _duration := 0.0
var _from := Vector3.ZERO
var _to := Vector3.ZERO
var _particles: Array[Vector4] = []
var _materials: Array[StandardMaterial3D] = []


func _init() -> void:
	_rng.randomize()
	_until_next = _rng.randf_range(4.0, 8.0)


func _process(delta: float) -> void:
	if main == null or main._party == null:
		return
	if _map != main._map:
		clear()
		_map = main._map
		_until_next = _rng.randf_range(4.0, 8.0)
	if not allowed():
		clear()
		_until_next = maxf(_until_next, 4.0)
		return
	if is_instance_valid(_effect):
		var camera := get_viewport().get_camera_3d()
		if camera and camera.global_position.distance_to(_effect.global_position) > 13.0:
			clear()
			return
		_elapsed += delta
		if _elapsed >= _duration:
			clear()
		else:
			animate()
		return
	_until_next -= delta
	if _until_next <= 0.0:
		_until_next = _rng.randf_range(GAP.x, GAP.y)
		show_effect(KINDS[_rng.randi_range(0, KINDS.size() - 1)])


func allowed() -> bool:
	return main._map != null and is_instance_valid(main._level) and main._depth in [1, 2] \
		and not main._in_opening and not main._in_combat and not main._ending \
		and not main._party.locked and not main._party.paused and not main._camp.visible \
		and not main._pack.visible and not main._full_map.visible and not main._chest.visible \
		and Settings.get_value("flashes") \
		and main._party_state.supplies.light_band() >= Supplies.Light.STEADY


## Choose a neighbouring empty cell reached without crossing a passage.
func target_cells() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	if not allowed():
		return result
	var at: Vector2i = main._party.cell
	var forward: Vector2i = main._party.DIRECTIONS[main._party.facing]
	var candidates: Array[Vector2i] = [at + forward]
	var sideways := Vector2i(-forward.y, forward.x)
	if main._tactical.active:
		candidates.append(at + sideways)
		candidates.append(at - sideways)
	var camera := get_viewport().get_camera_3d()
	for cell in candidates:
		if not main._map.is_passable(cell) or main._map.door_at(cell) != DungeonMap.Door.NONE:
			continue
		if main._map.door_at(at) != DungeonMap.Door.NONE or main._map.solid.has(cell):
			continue
		if main._map.content_at(cell) != DungeonMap.Content.NONE or main._map.encounter_zones.has(cell):
			continue
		if main._tactical.active and not main._tactical.seen.has(cell):
			continue
		var point := Vector3(cell.x * main.CELL_SIZE, .6, cell.y * main.CELL_SIZE)
		if camera and camera.is_position_behind(point):
			continue
		result.append(cell)
	return result


func show_effect(kind: String) -> bool:
	if kind not in ["bat", "mouse", "dust"] or not allowed() or is_instance_valid(_effect):
		return false
	var cells := target_cells()
	if cells.is_empty():
		return false
	var cell: Vector2i = cells[_rng.randi_range(0, cells.size() - 1)]
	_effect = Node3D.new()
	_effect.name = "MineLife"
	add_child(_effect)
	_effect.position = Vector3(cell.x * main.CELL_SIZE, 0, cell.y * main.CELL_SIZE)
	_kind = kind
	_elapsed = 0.0
	_duration = {"bat": 2.1, "mouse": 1.7, "dust": 3.8}[kind]
	if kind == "dust":
		make_dust()
	else:
		make_animal(kind)
	animate()
	return true


func make_animal(kind: String) -> void:
	_actor = (BAT if kind == "bat" else MOUSE).instantiate()
	_effect.add_child(_actor)
	var bat := kind == "bat"
	_actor.scale = Vector3.ONE * (.22 if bat else .26)
	# The bat master includes a one-metre flight offset above its own origin.
	_actor.position.y = -.22 if bat else .007
	if _actor.has_method("set_opacity"):
		_actor.set_opacity(0)
		_actor.contact.visible=false
	for mesh: MeshInstance3D in _actor.find_children("*", "MeshInstance3D", true, false):
		if _actor.has_method("set_opacity"):continue
		var material: StandardMaterial3D = mesh.material_override.duplicate()
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS
		if bat:
			material.cull_mode = BaseMaterial3D.CULL_DISABLED
		material.albedo_color.a = 0.0
		mesh.material_override = material
		_materials.append(material)
	var forward: Vector2i = main._party.DIRECTIONS[main._party.facing]
	var across := Vector3(-forward.y, 0, forward.x)
	var direction := 1.0 if _rng.randf() > .5 else -1.0
	var elevation: float = main.WALL_HEIGHT - .75 if bat else .0
	var centre := Vector3(0, elevation, 0)
	var half_path := .69 if bat else .50
	_from = centre - across * half_path * direction
	_to = centre + across * half_path * direction
	var travel := (_to - _from).normalized()
	_actor.rotation.y = atan2(travel.x, travel.z)


func make_dust() -> void:
	_dust = MultiMeshInstance3D.new()
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	var grain := SphereMesh.new()
	grain.radius = .009
	grain.height = .023
	grain.radial_segments = 4
	grain.rings = 1
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(.43, .39, .31, 1.0)
	material.vertex_color_use_as_albedo = true
	material.roughness = 1.0
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.metallic_specular = 0.0
	grain.material = material
	multimesh.mesh = grain
	multimesh.instance_count = 28
	_dust.multimesh = multimesh
	_dust.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_effect.add_child(_dust)
	for index in multimesh.instance_count:
		_particles.append(Vector4(_rng.randf_range(-.42, .42), _rng.randf_range(-.27, .27),
			_rng.randf_range(0.0, 1.1), _rng.randf_range(.6, 1.12)))


func animate() -> void:
	var t := clampf(_elapsed / _duration, 0, 1)
	if _kind == "dust":
		for index in _particles.size():
			var particle := _particles[index]
			var age := _elapsed - particle.z
			var drop := maxf(0, age)
			var y: float = main.WALL_HEIGHT - .065 - drop * particle.w
			var position := Vector3(particle.x + sin(drop * 1.7 + index) * .025, y, particle.y)
			var fade := clampf(age * 3.0, 0, 1) * clampf((y - .45) / .6, 0, 1) * (1.0 - smoothstep(.7, 1.0, t))
			_dust.multimesh.set_instance_transform(index, Transform3D(Basis.IDENTITY, position))
			_dust.multimesh.set_instance_color(index, Color(1, 1, 1, fade * .42))
		return
	var path := _from.lerp(_to, t)
	if _kind == "bat":
		path.y += sin(t * PI) * .09
		_actor.rotation.z = sin(t * PI) * .30
	_actor.position.x = path.x
	_actor.position.z = path.z
	_actor.position.y = path.y + (-.22 if _kind == "bat" else .007)
	var pose := "idle" if _kind == "bat" else "run"
	var speed := 2.1 if _kind == "bat" else 1.55
	var clip: Animation = _actor.player.get_animation(pose)
	_actor.sample(pose, fmod(_elapsed * speed, clip.length))
	var fade := smoothstep(0.0, .15, t) * (1.0 - smoothstep(.80, 1.0, t))
	if _actor.has_method("set_opacity"):
		_actor.set_opacity(fade*.88)
		_actor.contact.visible=false
	for material in _materials:
		material.albedo_color.a = fade * .88


func clear() -> void:
	if is_instance_valid(_effect):
		remove_child(_effect)
		_effect.queue_free()
	_effect = null
	_actor = null
	_dust = null
	_particles.clear()
	_materials.clear()
	_kind = ""

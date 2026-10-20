extends Node
## The mine's mood while exploring (#129), all from ChatGPT's ambient-v1 art.
## Pure atmosphere (owner, 2026-10-20): nothing here touches supplies, fear,
## fights or what the party can see of real enemies.
##
## - Low fog drifts over the floor, fixed in the world as you walk through it.
## - Swirling darkness creeps in from the screen's edges as the light fails
##   or nerves fray, and draws back when things improve. Under the HUD.
## - Now and then, with the light low or nerves bad, eyes open at the far end
##   of the passage ahead, beyond the lantern - or, rarer, a shadow passes -
##   and are gone again, sooner if you move.
## - Dust hangs in a good lantern's light.
## With screen flashes off (Settings) the darkness holds still and the dust
## is left out. Everything is hidden in fights, the opening and at camp.

const Supplies := preload("res://scripts/supplies.gd")
const StrainRules := preload("res://scripts/strain.gd")
const Settings := preload("res://scripts/settings.gd")
const DIR := "res://art/effects/ambient-v1/"
const DARKNESS := preload("res://art/effects/ambient-v1/darkness.tres")
const FOG := preload("res://art/effects/ambient-v1/fog-strip.png")
const EYES := ["eyes-rat", "eyes-cluster", "eyes-unknown"]
const EYE_HEIGHTS := {"eyes-rat": 0.3, "eyes-cluster": 0.7, "eyes-unknown": 1.45, "shadow": 1.0}
## How strongly the darkness closes in, by light and by the worst nerves.
const LIGHT_DARKNESS := {Supplies.Light.OUT: 1.0, Supplies.Light.DIM: 0.35}
const NERVE_DARKNESS := {StrainRules.State.UNEASY: 0.2, StrainRules.State.SHAKEN: 0.5, StrainRules.State.PANICKING: 1.0}
## The fog is unlit art, so it dims with the light the party carries.
const FOG_LIGHT := {Supplies.Light.OUT: 0.25, Supplies.Light.DIM: 0.55, Supplies.Light.STEADY: 0.85, Supplies.Light.BRIGHT: 1.0}
const EASE := 0.5  # darkness strength per second
const SIGHTING_GAP := Vector2(20.0, 40.0)  # seconds between sightings
const FOG_SHADER := """
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;
uniform sampler2D fog_texture : source_color, filter_nearest, repeat_enable;
uniform float opacity = 1.0;
uniform vec3 centre;
varying vec3 world;
void vertex() { world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	// Fixed in the world, drifting slowly; fades out toward the plane's edge.
	vec4 a = texture(fog_texture, world.xz * vec2(0.18, 0.36) + vec2(TIME * 0.012, 0.0));
	vec4 b = texture(fog_texture, world.zx * vec2(0.13, 0.3) - vec2(TIME * 0.008, 0.0));
	float edge = 1.0 - smoothstep(3.0, 5.5, length(world.xz - centre.xz));
	ALBEDO = mix(a.rgb, b.rgb, 0.5);
	ALPHA = clamp(a.a + b.a, 0.0, 1.0) * opacity * edge;
}
"""

var main: Node  # main.gd: the party, its supplies and nerves, the floor
## Under the HUD; main.gd puts it on its canvas.
var overlay: TextureRect
var sighting: MeshInstance3D  # the eyes or shadow on show, if any

## The sighting's flipbook: its frames as [uv offset, uv scale] on one atlas.
var _sighting_frames: Array = []
var _sighting_fps := 8.0
var _sighting_time := 0.0

var _strength := 0.0
var _frame_time := 0.0
var _frame := 0
var _until_sighting := 0.0
var _fog: MeshInstance3D
var _fog_material: ShaderMaterial
var _dust: Array[AnimatedSprite3D] = []
var _rng := RandomNumberGenerator.new()


func _init() -> void:
	overlay = TextureRect.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	overlay.stretch_mode = TextureRect.STRETCH_SCALE
	overlay.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.texture = DARKNESS.get_frame_texture(&"loop", 0)
	overlay.modulate.a = 0.0
	overlay.visible = false
	_rng.randomize()
	_until_sighting = _rng.randf_range(SIGHTING_GAP.x, SIGHTING_GAP.y)


## Called once the party exists: the fog and dust travel with it.
func attach(party: Node3D, camera: Camera3D) -> void:
	_fog_material = ShaderMaterial.new()
	_fog_material.shader = Shader.new()
	_fog_material.shader.code = FOG_SHADER
	_fog_material.set_shader_parameter("fog_texture", FOG)
	var plane := PlaneMesh.new()
	plane.size = Vector2(11, 11)
	_fog = MeshInstance3D.new()
	_fog.mesh = plane
	_fog.material_override = _fog_material
	_fog.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_fog.top_level = true  # level with the floor, whatever the camera does
	party.add_child(_fog)
	for at in [Vector3(-0.55, 0.15, -1.5), Vector3(0.6, -0.1, -1.9)]:
		var dust := _sprite("dust", 0.011, true)
		dust.position = at
		dust.modulate.a = 0.35
		camera.add_child(dust)
		_dust.append(dust)
	party.moved.connect(func(_cell, _facing): _startle())


func _process(delta: float) -> void:
	if main == null or main._party == null:
		return
	var quiet := _quiet()
	var light: int = main._party_state.supplies.light_band()
	var flashes: bool = Settings.get_value("flashes")
	# The darkness at the edges.
	var target := 0.0 if quiet else maxf(LIGHT_DARKNESS.get(light, 0.0), _nerve_darkness())
	_strength = move_toward(_strength, target, EASE * delta)
	overlay.visible = _strength > 0.01
	overlay.modulate.a = _strength
	if overlay.visible and flashes:
		_frame_time += delta
		if _frame_time >= 1.0 / DARKNESS.get_animation_speed(&"loop"):
			_frame_time = 0.0
			_frame = (_frame + 1) % DARKNESS.get_frame_count(&"loop")
			overlay.texture = DARKNESS.get_frame_texture(&"loop", _frame)
	# Fog and dust.
	if _fog:
		_fog.visible = not quiet
		var at: Vector3 = main._party.global_position
		_fog.global_position = Vector3(at.x, 0.14, at.z)
		_fog_material.set_shader_parameter("centre", at)
		_fog_material.set_shader_parameter("opacity", FOG_LIGHT.get(light, 1.0) * (0.7 if main._depth <= 1 else 1.0))
	for dust in _dust:
		dust.visible = not quiet and flashes and light >= Supplies.Light.STEADY
	# Something watching, now and then.
	if quiet:
		if sighting:
			_end_sighting(0.0)
		return
	if sighting:
		_sighting_time += delta
		var frame: int = int(_sighting_time * _sighting_fps) % _sighting_frames.size()
		var material := sighting.material_override as StandardMaterial3D
		material.uv1_offset = Vector3(_sighting_frames[frame][0].x, _sighting_frames[frame][0].y, 0)
	if sighting == null and (light <= Supplies.Light.DIM or _nerve_darkness() >= 0.5):
		_until_sighting -= delta
		if _until_sighting <= 0.0:
			_until_sighting = _rng.randf_range(SIGHTING_GAP.x, SIGHTING_GAP.y)
			var shadow: bool = light <= Supplies.Light.DIM and _rng.randi() % 4 == 0
			show_sighting("shadow" if shadow else EYES[_rng.randi() % EYES.size()])


## How hard the darkness presses: 0 none, 1 full (for tests).
func strength() -> float:
	return _strength


func _quiet() -> bool:
	return main._in_combat or main._in_opening or main._depth < 1 or main._map == null \
			or not main._level or main._ending


func _nerve_darkness() -> float:
	var worst := 0.0
	for member in main._party_state.living_members():
		worst = maxf(worst, NERVE_DARKNESS.get(member.strain_state(), 0.0))
	return worst


## Eyes (or a shadow) at the far end of the way ahead, beyond the light.
## Returns it, or null if there's nowhere far enough away to put it.
func show_sighting(id: String) -> MeshInstance3D:
	var party = main._party
	var map = main._map
	var step: Vector2i = party.DIRECTIONS[party.facing]
	var cell: Vector2i = party.cell
	var far := 0
	for i in 7:
		var next: Vector2i = cell + step
		if not map.is_passable(next) or map.door_at(next) != main.DungeonMap.Door.NONE:
			break
		cell = next
		far += 1
	if far < 3:
		return null  # too close: it would stand in the light
	var size: float = main.CELL_SIZE
	if sighting:
		sighting.queue_free()
	var eyes := id != "shadow"
	sighting = _flipbook(id, 0.028 if eyes else 0.02, eyes)
	sighting.position = Vector3(cell.x * size, EYE_HEIGHTS[id], cell.y * size) - Vector3(step.x, 0, step.y) * size * 0.3
	main._level.add_child(sighting)
	var material := sighting.material_override as StandardMaterial3D
	var hold: float = _sighting_frames.size() / _sighting_fps
	var tween := sighting.create_tween()
	tween.tween_property(material, "albedo_color:a", 1.0 if eyes else 0.8, 0.4)
	tween.tween_interval(hold)
	tween.tween_callback(_end_sighting.bind(0.6))
	return sighting


## A billboard quad that plays an ambient-v1 sheet. Eyes glow (added
## light, untouched by the mine's murk); a shadow is just a dark shape.
func _flipbook(id: String, pixel: float, glow: bool) -> MeshInstance3D:
	var frames: SpriteFrames = load(DIR + id + ".tres")
	_sighting_frames.clear()
	_sighting_fps = frames.get_animation_speed(&"loop")
	_sighting_time = 0.0
	var first := frames.get_frame_texture(&"loop", 0) as AtlasTexture
	var atlas_size := first.atlas.get_size()
	for i in frames.get_frame_count(&"loop"):
		var region: Rect2 = (frames.get_frame_texture(&"loop", i) as AtlasTexture).region
		_sighting_frames.append([region.position / atlas_size, region.size / atlas_size])
	var material := StandardMaterial3D.new()
	material.albedo_texture = first.atlas
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD if glow else BaseMaterial3D.BLEND_MODE_MIX
	material.disable_fog = glow
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	material.albedo_color = Color(1.8, 1.7, 1.5, 0.0) if glow else Color(1, 1, 1, 0.0)
	var scale: Vector2 = _sighting_frames[0][1]
	material.uv1_scale = Vector3(scale.x, scale.y, 1)
	var quad := QuadMesh.new()
	quad.size = first.region.size * pixel
	var mesh := MeshInstance3D.new()
	mesh.mesh = quad
	mesh.material_override = material
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mesh


## Moving or turning chases it off quickly.
func _startle() -> void:
	if sighting:
		_end_sighting(0.15)


func _end_sighting(fade: float) -> void:
	var gone := sighting
	sighting = null
	if gone == null or not is_instance_valid(gone):
		return
	if fade <= 0.0:
		gone.queue_free()
		return
	var tween := gone.create_tween()
	tween.tween_property(gone.material_override, "albedo_color:a", 0.0, fade)
	tween.tween_callback(gone.queue_free)


func _sprite(id: String, pixel: float, billboard: bool) -> AnimatedSprite3D:
	var sprite := AnimatedSprite3D.new()
	sprite.sprite_frames = load(DIR + id + ".tres")
	sprite.animation = &"loop"
	sprite.pixel_size = pixel
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED if billboard else BaseMaterial3D.BILLBOARD_DISABLED
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.shaded = false
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sprite.play(&"loop")
	return sprite

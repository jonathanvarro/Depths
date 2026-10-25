extends Node3D
## The battle stage (owner, 2026-10-20): when a fight starts, fog surges up
## from the floor and the cave behind fades to near-black; when it ends,
## the fog sinks back. Enemies are drawn above the darkness, so they never
## clip into walls whatever the corridor looks like. With screen flashes
## off (Settings), it's a plain fade instead of a surge.
##
## One camera quad, with an authored low fog bank and ten rising matte
## states (#129). Motion stops when hidden or screen effects are disabled.

const DISTANCE := 0.3  # metres in front of the camera
const ENTER_TIME := 0.6
const EXIT_TIME := 0.5
## Enemies draw after the stage (transparent objects sort by this).
const FOE_PRIORITY := 10
const FOG := preload("res://art/effects/combat-fog-v1/fog-bank.png")
const SURGE := preload("res://art/effects/combat-fog-v1/surge-matte.png")

const SHADER := """
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, depth_test_disabled, cull_disabled, shadows_disabled;

uniform float progress = 0.0;  // 0 clear, 1 the full stage
uniform float surge = 1.0;     // 1 fog rises from the floor; 0 a plain fade
uniform float darkness = 0.97;
uniform float phase = 0.0;
uniform sampler2D fog_bank : source_color, filter_nearest, repeat_enable;
uniform sampler2D surge_matte : filter_nearest, repeat_disable;

vec4 fog_sample(vec2 uv) {
	float a = fract(uv.x);
	float b = fract(uv.x + 0.5);
	float wa = smoothstep(0.0, 0.20, min(a, 1.0-a));
	float wb = smoothstep(0.0, 0.20, min(b, 1.0-b));
	return (texture(fog_bank, vec2(a, clamp(uv.y,0.0,1.0))) * wa
		+ texture(fog_bank, vec2(b, clamp(uv.y,0.0,1.0))) * wb) / (wa+wb);
}

void fragment() {
	vec2 pixel = min(floor(UV * vec2(320.0,180.0)),vec2(319.0,179.0));
	vec2 uv = (pixel + 0.5) / vec2(320.0,180.0);
	float frame = floor(clamp(progress,0.0,1.0)*9.0+0.5);
	vec2 cell = vec2(mod(frame,4.0),floor(frame/4.0));
	float edge = texture(surge_matte,(cell*vec2(320.0,180.0)+pixel+0.5)/vec2(1280.0,540.0)).a;
	float alpha = mix(progress,edge,surge)*darkness;
	vec4 bank = fog_sample(vec2(uv.x+phase*0.012,(uv.y-0.30)/0.70));
	float band = smoothstep(0.50,0.78,uv.y) * bank.a;
	vec3 colour = mix(vec3(0.006,0.006,0.008),bank.rgb*0.42,band);
	float local_y = (uv.y-(1.0-progress*1.45))/0.50;
	vec4 rolling = fog_sample(vec2(uv.x,local_y));
	float rim = step(0.0,local_y)*(1.0-smoothstep(0.45,0.95,local_y))*(1.0-progress)*surge;
	ALBEDO = mix(colour,rolling.rgb*0.50,rim);
	ALPHA = clamp(alpha, 0.0, 1.0);
}
"""

var _quad: MeshInstance3D
var _material: ShaderMaterial
var _tween: Tween
var _clock := 0.0
var _motion := true
var _camera: Camera3D


func _init() -> void:
	_material = ShaderMaterial.new()
	_material.shader = Shader.new()
	_material.shader.code = SHADER
	_material.set_shader_parameter("fog_bank", FOG)
	_material.set_shader_parameter("surge_matte", SURGE)
	_material.render_priority = 0
	_material.set_shader_parameter("progress", 0.0)
	_quad = MeshInstance3D.new()
	var mesh := QuadMesh.new()
	mesh.material = _material
	_quad.mesh = mesh
	_quad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_quad.position = Vector3(0, 0, -DISTANCE)
	add_child(_quad)
	visible = false
	set_process(false)
	visibility_changed.connect(func(): set_process(visible and _motion))


func _process(delta: float) -> void:
	_clock += delta
	_material.set_shader_parameter("phase", floorf(_clock * 8.0) / 8.0)


## Sizes the quad to cover the camera's view (call once it's attached).
func fit(camera: Camera3D) -> void:
	_camera = camera
	if not camera.get_viewport().size_changed.is_connected(_fit_quad):
		camera.get_viewport().size_changed.connect(_fit_quad)
	_fit_quad()


func _fit_quad() -> void:
	if not is_instance_valid(_camera):
		return
	var projection := _camera.get_camera_projection()
	var extent := projection.get_viewport_half_extents()
	# The authored bank is aligned to the viewport's floor, so keep the full
	# texture in view instead of cropping it on an oversized camera quad.
	(_quad.mesh as QuadMesh).size = extent * (2.0 * DISTANCE / projection.get_z_near()) * 1.002


## Fog surges in; the cave fades out. `surge` false gives a plain fade.
func enter(surge := true) -> void:
	_motion = surge
	_clock = 0.0
	_material.set_shader_parameter("phase", 0.0)
	_material.set_shader_parameter("surge", 1.0 if surge else 0.0)
	visible = true
	set_process(surge)
	await _go(1.0, ENTER_TIME)


## The fog sinks back; the cave fades in.
func exit() -> void:
	await _go(0.0, EXIT_TIME)
	visible = false


func is_up() -> bool:
	return visible and _material.get_shader_parameter("progress") > 0.5


func _go(to: float, seconds: float) -> void:
	if _tween:
		_tween.kill()
	var from: float = _material.get_shader_parameter("progress")
	_tween = create_tween()
	_tween.tween_method(func(v: float): _material.set_shader_parameter("progress", v), from, to, seconds) 			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT if to > 0.5 else Tween.EASE_IN)
	await _tween.finished


## Draws an enemy above the stage: see-through pass, drawn last, never
## hidden by walls.
static func raise(node: Node) -> void:
	for sprite in node.find_children("*", "SpriteBase3D", true, false):
		sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED
		sprite.no_depth_test = true
		sprite.render_priority = FOE_PRIORITY
	if node is SpriteBase3D:
		node.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED
		node.no_depth_test = true
		node.render_priority = FOE_PRIORITY

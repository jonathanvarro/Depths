extends Node3D
## The battle stage (owner, 2026-10-20): when a fight starts, fog surges up
## from the floor and the cave behind fades to near-black; when it ends,
## the fog sinks back. Enemies are drawn above the darkness, so they never
## clip into walls whatever the corridor looks like. With screen flashes
## off (Settings), it's a plain fade instead of a surge.
##
## A quad just in front of the camera, with a generated pixel fog until
## ChatGPT's fog surge art lands (#129).

const DISTANCE := 0.3  # metres in front of the camera
const ENTER_TIME := 0.6
const EXIT_TIME := 0.5
## Enemies draw after the stage (transparent objects sort by this).
const FOE_PRIORITY := 10

const SHADER := """
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, depth_test_disabled, cull_disabled, shadows_disabled;

uniform float progress = 0.0;  // 0 clear, 1 the full stage
uniform float surge = 1.0;     // 1 fog rises from the floor; 0 a plain fade
uniform float darkness = 0.97;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}
float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) { v += a * noise(p); p *= 2.0; a *= 0.5; }
	return v;
}

void fragment() {
	vec2 uv = floor(UV * vec2(192.0, 108.0)) / vec2(192.0, 108.0);  // pixel steps, like the art
	float t = TIME * 0.12;
	float n = fbm(vec2(uv.x * 5.0 + t, uv.y * 4.0 - t * 0.6));
	// The fog's front rises from the floor (uv.y = 1) to the top.
	float front = 1.0 - progress * 1.3;
	float edge = smoothstep(front - 0.1, front + 0.1, uv.y + (n - 0.5) * 0.3);
	float alpha = mix(progress, edge, surge) * darkness;
	// Grey drifting fog low down (where the enemies stand), black above.
	float band = smoothstep(0.72, 1.0, uv.y) * (0.35 + 0.65 * n);
	vec3 colour = mix(vec3(0.006, 0.006, 0.008), vec3(0.16, 0.155, 0.17), band * 0.6);
	ALBEDO = colour;
	ALPHA = clamp(alpha, 0.0, 1.0);
}
"""

var _quad: MeshInstance3D
var _material: ShaderMaterial
var _tween: Tween


func _init() -> void:
	_material = ShaderMaterial.new()
	_material.shader = Shader.new()
	_material.shader.code = SHADER
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


## Sizes the quad to cover the camera's view (call once it's attached).
func fit(camera: Camera3D) -> void:
	var height := 2.0 * DISTANCE * tan(deg_to_rad(camera.fov) / 2.0)
	(_quad.mesh as QuadMesh).size = Vector2(height * 3.0, height) * 1.6  # wide and tall enough for any screen


## Fog surges in; the cave fades out. `surge` false gives a plain fade.
func enter(surge := true) -> void:
	_material.set_shader_parameter("surge", 1.0 if surge else 0.0)
	visible = true
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

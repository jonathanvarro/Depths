extends CanvasLayer
## Visions of the past and dreams (owner, 2026-10-20): the whole screen,
## portraits included, drains to a cold blue - deep blue shadows, pale
## light, a soft vignette and a faint slow shimmer - so the player knows
## at once that this is then, not now. Fades in and out. With screen
## flashes off (Settings) the shimmer is left out and only the tint stays.
##
## main.gd's set_vision(true/false) drives it; a Conversation with
## `vision` ticked plays inside it.

const FADE := 0.6
const SHADER := """
shader_type canvas_item;
uniform sampler2D screen : hint_screen_texture, filter_nearest;
uniform float strength = 0.0;   // 0 off, 1 the full vision
uniform float shimmer = 1.0;    // 0 with screen flashes off

void fragment() {
	vec2 uv = SCREEN_UV;
	// A faint, slow wave, as if seen through water or memory.
	uv.x += sin(uv.y * 40.0 + TIME * 1.3) * 0.0012 * shimmer * strength;
	vec3 colour = texture(screen, uv).rgb;
	float grey = dot(colour, vec3(0.299, 0.587, 0.114));
	// Shadows go deep blue, light goes pale, the colour drains away.
	vec3 vision = mix(vec3(0.03, 0.06, 0.16), vec3(0.72, 0.84, 1.0), grey);
	vision += (fract(sin(dot(uv * TIME, vec2(12.9898, 78.233))) * 43758.5453) - 0.5) * 0.025 * shimmer;
	float edge = smoothstep(0.35, 0.95, length(SCREEN_UV - 0.5) * 1.35);
	vision *= 1.0 - edge * 0.55;
	COLOR = vec4(mix(colour, vision, strength), 1.0);
}
"""

var _rect: ColorRect
var _material: ShaderMaterial
var _tween: Tween


func _init() -> void:
	layer = 5  # above the conversations (layer 4), so their portraits tint too
	_material = ShaderMaterial.new()
	_material.shader = Shader.new()
	_material.shader.code = SHADER
	_material.set_shader_parameter("strength", 0.0)
	_rect = ColorRect.new()
	_rect.material = _material
	_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.visible = false
	add_child(_rect)


func is_on() -> bool:
	return _rect.visible and float(_material.get_shader_parameter("strength")) > 0.5


## Slips into the vision; `shimmer` false keeps it to a still tint.
func enter(shimmer := true) -> void:
	_material.set_shader_parameter("shimmer", 1.0 if shimmer else 0.0)
	_rect.visible = true
	await _go(1.0)


## Back to the present.
func exit() -> void:
	await _go(0.0)
	_rect.visible = false


func _go(to: float) -> void:
	if _tween:
		_tween.kill()
	var from: float = _material.get_shader_parameter("strength")
	_tween = create_tween()
	_tween.tween_method(func(v: float): _material.set_shader_parameter("strength", v), from, to, FADE) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await _tween.finished

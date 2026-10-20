shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;
uniform sampler2D fog_texture : source_color, filter_nearest, repeat_enable;
uniform float scroll_speed = 0.01;
uniform float opacity : hint_range(0.0, 1.0) = 0.7;
void fragment() {
	vec4 fog = texture(fog_texture, UV + vec2(TIME * scroll_speed, 0.0));
	ALBEDO = fog.rgb;
	ALPHA = fog.a * opacity;
}

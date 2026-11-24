shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_back, shadows_disabled;
uniform float phase = 0.0;
varying float height;
void vertex() {
	height = VERTEX.y;
	float tip = clamp((VERTEX.y - 0.15) / 0.32, 0.0, 1.0);
	VERTEX.x += sin(phase * 2.4 + VERTEX.z * 22.0) * tip * 0.015;
	VERTEX.z += sin(phase * 1.7 + VERTEX.x * 18.0) * tip * 0.010;
}
void fragment() {
	float tip = clamp((height - 0.15) / 0.32, 0.0, 1.0);
	vec3 base = mix(vec3(1.0, 0.48, 0.12), COLOR.rgb, tip);
	ALBEDO = base;
	EMISSION = base * (0.75 + 0.07 * sin(phase * 2.5));
	ALPHA = mix(0.70, 0.04, tip);
}

shader_type spatial;
render_mode cull_disabled, specular_disabled;

// The original fine silk painting, on a shallow fixed mesh rather than a billboard.
uniform sampler2D silk : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform bool torn = false;

void fragment() {
	vec4 strand = texture(silk, UV);
	float alpha = strand.a;
	if (torn) {
		// Frayed sides and a ragged upper fringe, open all the way to the floor.
		float left = 0.19 + 0.025*sin(UV.y*49.0) + 0.012*sin(UV.y*119.0);
		float right = 0.81 + 0.024*sin(UV.y*57.0+1.3) + 0.013*sin(UV.y*131.0);
		float top = 0.16 + 0.035*sin(UV.x*43.0) + 0.018*sin(UV.x*107.0);
		if (UV.x > left && UV.x < right && UV.y > top) alpha = 0.0;
	}
	ALBEDO = strand.rgb * vec3(0.88, 0.90, 0.86);
	ROUGHNESS = 1.0;
	ALPHA = alpha;
	ALPHA_SCISSOR_THRESHOLD = 0.28;
}

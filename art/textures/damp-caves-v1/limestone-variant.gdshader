shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform sampler2D base_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D variant_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform float wet_roughness : hint_range(0.0,1.0) = 0.63;
uniform float wet_specular : hint_range(0.0,1.0) = 0.28;
uniform float variant_strength : hint_range(0.0,1.0) = 0.55;

void fragment() {
	vec2 cell = fract(UV);
	vec2 interior = smoothstep(vec2(0.0), vec2(0.16), cell)
		* smoothstep(vec2(0.0), vec2(0.16), vec2(1.0)-cell);
	vec3 base = texture(base_albedo, UV).rgb;
	vec3 variant = texture(variant_albedo, UV).rgb;
	ALBEDO = mix(base, variant, interior.x*interior.y*variant_strength);
	ROUGHNESS = wet_roughness;
	SPECULAR = wet_specular;
	METALLIC = 0.0;
	// Normal cave surfaces deliberately write solid depth.
}

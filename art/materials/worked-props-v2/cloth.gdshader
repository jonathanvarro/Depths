shader_type spatial;
render_mode cull_disabled, specular_disabled;
void fragment() {
	vec2 thread=sin(UV*vec2(850.0,720.0));
	float fade=clamp(1.0-length(fwidth(UV)*vec2(850.0,720.0)),0.0,1.0);
	ALBEDO=COLOR.rgb*(0.90+0.07*thread.x*thread.y*fade);
	ROUGHNESS=1.0;
}

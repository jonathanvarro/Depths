shader_type spatial;
render_mode specular_disabled;

float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
	vec2 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);
	return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
void fragment() {
	vec2 p=UV+vec2(UV2.y*3.3);
	float stone=noise(p*29.0)*0.2+noise(p*113.0)*0.16;
	float pores=smoothstep(0.64,0.91,noise(p*173.0));
	ALBEDO=COLOR.rgb*(0.72+stone+noise(p*5.0)*0.10)*(1.0-pores*0.16);
	ROUGHNESS=1.0;
}

shader_type spatial;

uniform vec4 tarnish : source_color = vec4(0.22,0.125,0.065,1.0);
uniform float corrosion = 0.28;
uniform float metalness = 0.65;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
	vec2 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);
	return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
void fragment() {
	vec2 p=UV+vec2(UV2.y*1.7,UV2.y*4.3);
	float pits=noise(p*180.0);
	float hammer=noise(p*61.0);
	float patch=smoothstep(0.50,0.83,noise(p*18.0)+noise(p*47.0)*0.18)*corrosion;
	float scores=smoothstep(0.79,0.96,noise(p*vec2(320.0,15.0)));
	ALBEDO=mix(COLOR.rgb*(0.75+hammer*0.27+pits*0.12)+vec3(scores*0.012),tarnish.rgb,patch);
	METALLIC=metalness*(1.0-patch);
	ROUGHNESS=clamp(0.57+0.26*(1.0-hammer)+patch*0.2,0.0,1.0);
	SPECULAR=0.28;
}

shader_type spatial;
render_mode specular_disabled;

float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
	vec2 i=floor(p), f=fract(p);f=f*f*(3.0-2.0*f);
	return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
void fragment() {
	// UVs are measured in metres and follow each timber's long axis.
	vec2 p=UV+vec2(UV2.y*2.3,UV2.y*3.7);
	float drift=noise(vec2(p.x*9.0,p.y*1.8));
	float grain=noise(vec2(p.x*165.0+drift*4.0,p.y*2.3));
	float fibre=noise(vec2(p.x*430.0+drift*5.0,p.y*13.0));
	float weather=noise(p*vec2(20.0,3.0));
	float knots=pow(abs(sin((p.x+0.015*sin(p.y*9.0))*82.0+drift*5.0)),12.0);
	float endgrain=0.5+0.5*sin(length(p*vec2(1.0,1.3))*290.0+noise(p*37.0)*4.0);
	float tone=0.68+0.34*grain+0.13*fibre-0.11*knots;
	tone=mix(tone,0.70+endgrain*0.25,step(0.5,UV2.x));
	ALBEDO=COLOR.rgb*tone*mix(0.81,1.08,weather);
	ROUGHNESS=0.95;
}

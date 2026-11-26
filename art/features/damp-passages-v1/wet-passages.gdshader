shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform sampler2D limestone_albedo : source_color, filter_linear_mipmap, repeat_enable;

float hash(vec2 p) {return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p) {
	vec2 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);
	return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
void fragment() {
	// UVs are physical metres; UV2 carries material family and piece phase.
	vec2 p=UV+vec2(UV2.y*2.7);
	float stone=.79+noise(p*18.0)*.13+noise(p*62.0)*.07;
	float fibre=.75+noise(p*vec2(148.0,3.0))*.22;
	float kind=UV2.x;
	float wood=step(.5,kind)*(1.0-step(1.5,kind));
	float organic=step(1.5,kind)*(1.0-step(2.5,kind));
	float chalk=step(2.5,kind)*(1.0-step(3.5,kind));
	float dark=step(3.5,kind);
	ALBEDO=COLOR.rgb*mix(stone,fibre,wood);
	if (kind<.5) {
		vec3 limestone=texture(limestone_albedo,UV*.5).rgb;
		ALBEDO=limestone*clamp(COLOR.rgb/vec3(.138,.184,.198),vec3(.25),vec3(2.0));
		// Height derivatives from the same mipmapped albedo give subtle relief,
		// without another texture, a moving effect or a transparency pass.
		float height=dot(limestone,vec3(.3333));
		vec3 dx=dFdx(VERTEX),dy=dFdy(VERTEX);
		vec3 r1=cross(dy,NORMAL),r2=cross(NORMAL,dx);
		float determinant=dot(dx,r1);
		vec3 gradient=sign(determinant)*(dFdx(height)*r1+dFdy(height)*r2);
		NORMAL=normalize(abs(determinant)*NORMAL-.035*gradient);
	}
	ALBEDO*=mix(1.0,.32,dark);
	ROUGHNESS=mix(mix(.65,.83,wood),.75,organic);
	ROUGHNESS=mix(ROUGHNESS,.94,max(chalk,dark));
	SPECULAR=mix(.25,.14,max(wood,organic));
	SPECULAR=mix(SPECULAR,.05,max(chalk,dark));
	METALLIC=0.0;
	// No alpha, emission, animation clock, screen reads or additional lights.
}

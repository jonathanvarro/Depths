shader_type spatial;
render_mode depth_prepass_alpha, diffuse_burley, specular_schlick_ggx;
uniform int surface_kind = 0;
uniform float opacity : hint_range(0.0,1.0) = 1.0;
uniform float ash : hint_range(0.0,1.0) = 0.0;
varying vec3 coat_position;
void vertex(){coat_position=VERTEX;}
void fragment(){
    vec3 p=coat_position;
    // Grouped ragged clumps, aligned with the body; no glossy stone grain.
    vec3 clump=floor(p*vec3(125.0,38.0,150.0));
    float broken=fract(sin(dot(clump,vec3(12.9898,78.233,37.719)))*43758.5453);
    float value=.92+.14*broken;
    vec3 base=COLOR.rgb;
    float grey=dot(base,vec3(.299,.587,.114));
    base=mix(base,vec3(grey*.95,grey,grey*.96)+vec3(.035),ash);
    ALBEDO=base*value;
    ROUGHNESS=1.0;
    SPECULAR=.04;
    ALPHA=opacity;
}

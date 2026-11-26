shader_type spatial;
render_mode depth_prepass_alpha, diffuse_burley, specular_schlick_ggx;
uniform int surface_kind = 0;
uniform float opacity : hint_range(0.0,1.0) = 1.0;
uniform float ash : hint_range(0.0,1.0) = 0.0;
varying vec3 coat_position;
void vertex(){ coat_position=VERTEX; }
void fragment(){
    vec3 p=coat_position;
    float fibre=sin(p.x*227.0+p.y*173.0+sin(p.z*29.0)*1.4);
    float grain=fract(sin(dot(floor(p*vec3(211.0,223.0,71.0)),vec3(12.9898,78.233,37.719)))*43758.5453);
    vec3 base=COLOR.rgb;
    float grey=dot(base,vec3(.299,.587,.114));
    base=mix(base,vec3(grey*.95,grey,grey*.96)+vec3(.035),ash);
    ALBEDO=base*(1.0+(fibre*.015+(grain-.5)*.035)*(surface_kind==0?1.0:.3));
    ROUGHNESS=surface_kind==0?.96:(surface_kind==1?.78:.42);
    SPECULAR=surface_kind==2?.35:.15;
    ALPHA=opacity;
}

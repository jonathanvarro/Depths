shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform int surface_kind=0;
uniform float opacity : hint_range(0.0,1.0)=1.0;
varying vec3 skin_position;
void vertex(){skin_position=VERTEX;}
void fragment(){
 vec3 p=skin_position;
 float grain=fract(sin(dot(floor(p*vec3(127.0,139.0,151.0)),vec3(12.9898,78.233,37.719)))*43758.5453);
 float tissue=sin(p.y*29.0+sin(p.x*18.0+p.z*21.0)*.8);
 float mottling=sin(p.x*47.0+sin(p.y*31.0))*sin(p.z*39.0+p.y*23.0);
 float pigment=surface_kind==0?.075:.035;
 ALBEDO=COLOR.rgb*(.94+(grain-.5)*.055+tissue*.025+mottling*pigment);
 ROUGHNESS=clamp((surface_kind==0?.56:(surface_kind==1?.74:(surface_kind==2?.70:.64)))+mottling*.045,.42,.82);
 SPECULAR=surface_kind==0?.27:(surface_kind==1?.17:.21);
 METALLIC=0.0;
 // Normal solid biology never writes alpha. Thin tissue is colour, not glass.
}

shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform sampler2D limestone_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform float mine_mix : hint_range(0.0,1.0)=0.0;
uniform float glow_strength : hint_range(0.0,0.3)=0.0;
float hash(vec2 p) {return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p) {
 vec2 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);
 return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
void fragment() {
 vec2 p=UV+vec2(UV2.y*2.7);
 float kind=UV2.x;
 float grain=.78+noise(p*18.0)*.14+noise(p*62.0)*.08;
 ALBEDO=COLOR.rgb*grain;
 ROUGHNESS=.73;SPECULAR=.22;METALLIC=0.0;
 if (kind<.5) {
  vec3 limestone=texture(limestone_albedo,UV*.5).rgb;
  vec3 wet=limestone*clamp(COLOR.rgb/vec3(.138,.184,.198),vec3(.25),vec3(2.0));
  ALBEDO=mix(wet,COLOR.rgb*vec3(.88,.75,.58)*grain,mine_mix);
  float height=dot(limestone,vec3(.3333));
  vec3 dx=dFdx(VERTEX),dy=dFdy(VERTEX);vec3 r1=cross(dy,NORMAL),r2=cross(NORMAL,dx);
  float determinant=dot(dx,r1);
  vec3 gradient=sign(determinant)*(dFdx(height)*r1+dFdy(height)*r2);
  NORMAL=normalize(abs(determinant)*NORMAL-.035*gradient);
  ROUGHNESS=mix(.58,.86,mine_mix);
 } else if (kind<1.5) {
  float fibres=noise(p*vec2(149.0,3.0));
  float knots=noise(p*vec2(13.0,4.0));
  ALBEDO=COLOR.rgb*(.66+fibres*.12+knots*.22);
  ROUGHNESS=mix(.78,.90,mine_mix);SPECULAR=.12;
 } else if (kind<2.5) {
  ALBEDO=COLOR.rgb*(.66+noise(p*42.0)*.22+noise(p*150.0)*.12);ROUGHNESS=.88;SPECULAR=.10;
  EMISSION=COLOR.rgb*glow_strength;
 } else if (kind<3.5) {
  ROUGHNESS=.87;SPECULAR=.16;
 } else if (kind<4.5) {
  // Puddles are opaque shallow surfaces. No screen refraction/reflection pass.
  ALBEDO=COLOR.rgb*(.90+noise(p*11.0)*.10);ROUGHNESS=.28;SPECULAR=.36;
 } else if (kind<5.5) {
  ALBEDO=COLOR.rgb*(.70+noise(p*48.0)*.30);ROUGHNESS=.76;SPECULAR=.24;METALLIC=.32;
 } else if (kind<6.5) {ROUGHNESS=.94;SPECULAR=.08;
 } else {
  // Calcite drapery is fine-banded mineral, distinct from boulder's rock albedo.
  float streaks=noise(p*vec2(46.0,2.0));
  vec3 mineral=texture(limestone_albedo,UV*.5).rgb;
  ALBEDO=COLOR.rgb*(.60+.14*streaks+.09*noise(p*120.0))*(.75+mineral*.9);
  ROUGHNESS=.57;SPECULAR=.25;
 }
 // No ALPHA, TIME, screen texture, art-owned light or gameplay visibility.
}

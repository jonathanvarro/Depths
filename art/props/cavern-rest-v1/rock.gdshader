shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap, repeat_enable;
void fragment(){
 vec3 mineral=texture(albedo_texture,UV*.5).rgb;
 float grain=dot(mineral,vec3(.25,.50,.25));
 ALBEDO=COLOR.rgb*(.48+grain*1.80);
 ROUGHNESS=.92;SPECULAR=.17;
}

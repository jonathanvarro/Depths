shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap, repeat_enable;
void fragment(){
 vec2 tile=fract(UV);
 float edge=min(min(tile.x,1.0-tile.x),min(tile.y,1.0-tile.y));
 float blend=smoothstep(0.0,.18,edge)*.32;
 vec3 base=texture(albedo_texture,UV).rgb;
 vec3 variant=texture(albedo_texture,UV+vec2(.37,.19)).rgb;
 ALBEDO=mix(base,variant,blend)*vec3(.85,.90,.92);
 ROUGHNESS=.94;SPECULAR=.16;
}

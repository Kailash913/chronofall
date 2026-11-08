shader_type spatial;
render_mode specular_disabled;
uniform vec4 base_color : source_color = vec4(0.2,0.35,0.4,1.0);
uniform float glow=0.0;
void fragment(){ ALBEDO=base_color.rgb; ROUGHNESS=1.0; EMISSION=base_color.rgb*glow; }
void light(){
 float d=dot(NORMAL,LIGHT);
 float ramp=d>0.65?1.0:(d>0.05?0.65:0.25);
 float rim=pow(1.0-max(dot(NORMAL,VIEW),0.0),4.0);
 DIFFUSE_LIGHT+=ALBEDO*LIGHT_COLOR*ATTENUATION*(ramp+rim*0.22);
}

FSH	o><     common_texColor      �   varying vec2 v_texcoord0;
uniform sampler2D common_texColor;
void main ()
{
  vec4 tmpvar_1;
  tmpvar_1.w = 1.0;
  tmpvar_1.xyz = texture2D (common_texColor, v_texcoord0).xyz;
  gl_FragColor = tmpvar_1;
}

 
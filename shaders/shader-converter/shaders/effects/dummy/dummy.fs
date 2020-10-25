
$input v_texcoord0

#include "../../common/src/bgfx_shader.sh"

SAMPLER2D(common_texColor, 0);

void main()
{
    gl_FragColor = vec4(texture2D(common_texColor, v_texcoord0).rgb, 1.0);
}

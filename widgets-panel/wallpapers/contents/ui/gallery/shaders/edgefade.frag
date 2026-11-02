#version 440
// Fades a layer out towards its edges, so content runs off softly under floating controls.
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4  qt_Matrix;
    float qt_Opacity;
    vec4  fade;       // left, top, right, bottom widths as a fraction of the item
};
layout(binding = 1) uniform sampler2D source;
void main() {
    vec2 uv = qt_TexCoord0;
    float a = 1.0;
    if (fade.x > 0.0) a *= smoothstep(0.0, fade.x, uv.x);
    if (fade.y > 0.0) a *= smoothstep(0.0, fade.y, uv.y);
    if (fade.z > 0.0) a *= smoothstep(0.0, fade.z, 1.0 - uv.x);
    if (fade.w > 0.0) a *= smoothstep(0.0, fade.w, 1.0 - uv.y);
    fragColor = texture(source, uv) * a * qt_Opacity;
}

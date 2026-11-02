#version 440

// Summit Liquid Glass for windows: the desktop cards' material (widgets/glass/liquidglass.frag, after
// Jack Faith's Liquid Glass widgets, GPL-3.0) with one change. It reads one mipmapped copy of what lies
// behind it, and takes the frosted middle from that copy's mip levels. The cards chain blur passes,
// which is right for a still wallpaper; here the glass floats over a gallery that scrolls, and a
// single texture costs one capture however many pieces of glass share it.

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4  qt_Matrix;
    float qt_Opacity;
    vec2  size;              // item size in px
    float radius;            // corner radius in px
    float roundness;         // superellipse exponent; 2 = circle
    float refractThickness;  // bevel width in px
    float refractIOR;
    float refractScale;      // lens strength: px of travel through the slab
    float chromaStrength;    // 0..1 dispersion at the rim
    vec4  tint;
    vec2  uvOffset;          // this item's place in the scene
    vec2  uvScale;
    vec2  mousePos;          // item UV; (-1,-1) = no pointer
    float mouseFade;         // 0..1
    float specStrength;      // 0..1
    float frostLod;          // mip level of the frosted middle; 0 = clear
    vec2  frostSpread;       // scene UV between the frost taps
    float sharpMix;          // 0..1 how clear the rim is next to the frost
    float vibrancy;          // backdrop saturation, 1 = unchanged
    float fresnel;           // 0..1 rim reflection
    float legibility;        // 0..1 extra tint over bright backdrops
    float depth;             // 0..1 edge light and inner shadow
    float magnify;           // 0..1 how much the slab enlarges what is behind it (1 = 20 %)
    float gloss;             // 0..1 the hairline of light on the silhouette
    float shade;             // 0..1 darkens only what is bright behind it, whatever the tint
};

layout(binding = 1) uniform sampler2D scene;

vec3 sceneSDFAndNormal(vec2 p) {
    vec2 b = size * 0.5;
    float n = max(roundness, 2.0);
    float r = clamp(radius, 0.0, min(b.x, b.y));

    vec2 q = abs(p) - b + vec2(r);
    float qx = max(q.x, 0.0);
    float qy = max(q.y, 0.0);

    float d;
    vec2 nrm;
    if (qx <= 0.0 && qy <= 0.0) {
        d = max(q.x, q.y) - r;
        nrm = q.x >= q.y ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
    } else if (qx == 0.0) {
        d = qy - r;
        nrm = vec2(0.0, 1.0);
    } else if (qy == 0.0) {
        d = qx - r;
        nrm = vec2(1.0, 0.0);
    } else {
        float arc = pow(pow(qx, n) + pow(qy, n), 1.0 / n);
        float gx = pow(qx / arc, n - 1.0);
        float gy = pow(qy / arc, n - 1.0);
        float gradLen = sqrt(gx * gx + gy * gy);
        d   = (arc - r) / max(gradLen, 1e-3);
        nrm = vec2(gx, gy) / max(gradLen, 1e-3);
    }
    nrm *= sign(p + vec2(1e-20));
    return vec3(d, nrm);
}

vec2 toScene(vec2 localUV) {
    return clamp(uvOffset + localUV * uvScale, vec2(0.0), vec2(1.0));
}

// Nine taps around a mip level: smooth at any width, with no second pass.
vec3 frosted(vec2 uv) {
    const float k = 0.7071;
    vec3 c = 2.0 * textureLod(scene, uv, frostLod).rgb;
    c += textureLod(scene, clamp(uv + vec2( 1.0,  0.0) * frostSpread, vec2(0.0), vec2(1.0)), frostLod).rgb;
    c += textureLod(scene, clamp(uv + vec2(-1.0,  0.0) * frostSpread, vec2(0.0), vec2(1.0)), frostLod).rgb;
    c += textureLod(scene, clamp(uv + vec2( 0.0,  1.0) * frostSpread, vec2(0.0), vec2(1.0)), frostLod).rgb;
    c += textureLod(scene, clamp(uv + vec2( 0.0, -1.0) * frostSpread, vec2(0.0), vec2(1.0)), frostLod).rgb;
    c += textureLod(scene, clamp(uv + vec2( k,  k) * frostSpread, vec2(0.0), vec2(1.0)), frostLod).rgb;
    c += textureLod(scene, clamp(uv + vec2(-k,  k) * frostSpread, vec2(0.0), vec2(1.0)), frostLod).rgb;
    c += textureLod(scene, clamp(uv + vec2( k, -k) * frostSpread, vec2(0.0), vec2(1.0)), frostLod).rgb;
    c += textureLod(scene, clamp(uv + vec2(-k, -k) * frostSpread, vec2(0.0), vec2(1.0)), frostLod).rgb;
    return c / 10.0;
}

void main() {
    vec2 uv = qt_TexCoord0;
    vec2 p  = (uv - vec2(0.5)) * size;
    vec3 dn = sceneSDFAndNormal(p);
    float d = dn.x;
    vec2 ndir = dn.yz;

    if (d > 1.5) {
        fragColor = vec4(0.0);
        return;
    }

    float depthPx = -d;

    // --- Lens: quarter-circle bevel. x is 1 at the silhouette and 0 where the bevel meets the top.
    float W = max(refractThickness, 1.0);
    float x = refractThickness > 0.0 ? 1.0 - clamp(depthPx / W, 0.0, 1.0) : 0.0;
    float sinI = pow(x, 1.6);
    vec3 N = vec3(ndir * sinI, sqrt(max(1.0 - sinI * sinI, 0.0)));

    float thetaI = asin(clamp(sinI, 0.0, 1.0));
    float thetaT = asin(clamp(sinI / max(refractIOR, 1.0), 0.0, 1.0));
    float bend = tan(thetaI - thetaT);
    vec2 shiftUV = -ndir * bend * refractScale / size;
    vec2 chromaUV = -ndir * bend * refractScale * 0.07 * chromaStrength / size;

    vec2 lensUV = (uv - vec2(0.5)) / (1.0 + 0.2 * clamp(magnify, 0.0, 1.0)) + vec2(0.5);
    vec2 uvR = lensUV + shiftUV + chromaUV;
    vec2 uvG = lensUV + shiftUV;
    vec2 uvB = lensUV + shiftUV - chromaUV;

    vec3 col;
    if (frostLod > 0.0) {
        col = frosted(toScene(uvG));
        float clearW = sharpMix * smoothstep(0.30, 0.92, x);
        if (clearW > 0.001) {
            vec3 rim = vec3(texture(scene, toScene(uvR)).r,
                            texture(scene, toScene(uvG)).g,
                            texture(scene, toScene(uvB)).b);
            col = mix(col, rim, clearW);
        }
    } else {
        col = vec3(texture(scene, toScene(uvR)).r,
                   texture(scene, toScene(uvG)).g,
                   texture(scene, toScene(uvB)).b);
    }

    // --- Vibrancy, then the tint (deeper over bright backdrops when legibility is on).
    float luma = dot(col, vec3(0.2126, 0.7152, 0.0722));
    col = clamp(mix(vec3(luma), col, vibrancy), 0.0, 1.0);
    col *= 1.0 - shade * smoothstep(0.32, 0.9, luma);

    float tintA = tint.a;
    if (legibility > 0.0 && tint.a < 1.0) {
        tintA = min(0.9, tintA + legibility * 0.34 * smoothstep(0.28, 0.82, luma));
    }
    col = mix(col, tint.rgb, tintA);

    // --- Lights. Key light top-left; while hovering it swings towards the pointer.
    vec2 restDir = normalize(vec2(-0.62, -0.78));
    vec2 keyDir = restDir;
    if (mouseFade > 0.0 && mousePos.x >= 0.0 && mousePos.y >= 0.0) {
        vec2 toPointer = (mousePos - vec2(0.5)) * size;
        if (length(toPointer) > 1.0) {
            keyDir = normalize(mix(restDir, normalize(toPointer), mouseFade));
        }
    }

    if (fresnel > 0.0 && x > 0.0) {
        float F = 0.04 + 0.96 * pow(1.0 - N.z, 4.0);
        float sky = 0.5 - 0.5 * ndir.y;
        vec3 env = vec3(0.96, 0.98, 1.0) * mix(0.30, 0.95, sky);
        col = mix(col, env, clamp(F * fresnel * 0.35, 0.0, 1.0));
    }

    float facing = dot(ndir, keyDir);
    if (specStrength > 0.0 && x > 0.0) {
        float arc = pow(max(facing, 0.0), 2.5) + 0.5 * pow(max(-facing, 0.0), 2.5);
        float rim = pow(x, 7.0) * (0.12 + 0.88 * arc);
        col += vec3(1.0, 0.985, 0.96) * rim * specStrength * 0.95;
    }

    if (depth > 0.0) {
        float lip = 1.0 - smoothstep(0.0, 1.6, max(depthPx, 0.0));
        float lit = 0.28 + 0.72 * pow(abs(facing), 3.0) * (facing > 0.0 ? 1.0 : 0.62);
        col += vec3(1.0, 0.99, 0.97) * lip * lit * depth * 0.42;

        float band = smoothstep(0.35, 0.7, x) * (1.0 - smoothstep(0.82, 0.97, x));
        float away = clamp(-facing, 0.0, 1.0);
        col *= 1.0 - depth * band * 0.14 * away;
    }

    if (gloss > 0.0) {
        float line = exp(-max(depthPx - 0.35, 0.0) / 0.8);
        float k = 0.35 + 0.65 * pow(max(facing, 0.0), 4.0) + 0.5 * pow(max(-facing, 0.0), 4.0);
        col = mix(col, vec3(1.0, 0.99, 0.975), clamp(line * k * gloss, 0.0, 1.0));
    }

    float mask = 1.0 - smoothstep(-0.5, 0.5, d);
    fragColor = vec4(clamp(col, 0.0, 1.0) * mask, mask) * qt_Opacity;
}

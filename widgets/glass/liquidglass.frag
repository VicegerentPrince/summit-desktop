#version 440

// Summit Liquid Glass: a thick glass slab with a rounded bevel, after Apple's Liquid Glass material.
// Based on the Liquid Glass widgets' shader by Jack Faith (jaxparrow07, GPL-3.0), itself a port of
// iyinchao/liquid-glass-studio. Same silhouette and uniforms, plus the terms that make it read as
// glass rather than a frosted card:
//
//   lens        Snell's law through a quarter-circle bevel. The rim pulls the scene in and magnifies
//               it, and it is sampled from the unblurred backdrop, so the edge is a clear lens around
//               a frosted middle.
//   vibrancy    the backdrop keeps its colour through the frost, a little richer.
//   legibility  the dark tint deepens only where the backdrop is bright, so white text stays
//               readable without greying the glass over a dark wallpaper.
//   fresnel     glass reflects more at grazing angles: the rim brightens, the top (sky) more than
//               the bottom (ground).
//   rim light   light caught at grazing angles: a thin bright arc on the top-left and a weaker one on
//               the bottom-right, where the bevel turns steep (a highlight spot cannot sit on a steep
//               rim seen from straight ahead, so this is modelled on the rim, not with Blinn-Phong).
//               On hover the key light swings towards the pointer.
//   depth       a crisp line of light at the lip and a faint shadow inside the bevel away from the light.
//
// Every addition is 0 = off, so a host that does not set the new uniforms gets the old look.

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4  qt_Matrix;
    float qt_Opacity;
    vec2  size;              // widget size in px
    float radius;            // corner radius in px
    float roundness;         // superellipse exponent; 2 = circle, 5 ≈ iOS squircle
    float refractThickness;  // bevel width in px
    float refractIOR;
    float refractScale;      // lens strength: px of travel through the slab
    float chromaStrength;    // 0..1 dispersion at the rim
    vec4  tint;
    vec4  tintBottom;
    vec2  uvOffset;
    vec2  uvScale;
    vec2  mousePos;          // widget-local UV (0..1); (-1,-1) = no pointer
    float mouseFade;         // 0..1 hover fade
    float specStrength;      // 0..1
    vec4  overlayDarken;     // rgb = target colour, a = band height (0 = off)
    float sharpMix;          // 0..1 how clear the rim is
    float vibrancy;          // backdrop saturation, 1 = unchanged (0 is read as 1)
    float fresnel;           // 0..1 rim reflection
    float legibility;        // 0..1 extra tint over bright backdrops
    float depth;             // 0..1 edge light and inner shadow
};

layout(binding = 1) uniform sampler2D backdrop;   // frosted
layout(binding = 2) uniform sampler2D sharp;      // the same region, unblurred

// Squircle / rounded-box SDF with analytic gradient: vec3(d, outward normal).
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

vec2 toTex(vec2 localUV) {
    return clamp(uvOffset + localUV * uvScale, vec2(0.0), vec2(1.0));
}

// A 3D normal for a key light that sits up and to one side, in screen space (y down, z to the viewer).
vec3 lightFrom(vec2 dir2) {
    return normalize(vec3(dir2 * 0.82, 0.58));
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
    float sinI = pow(x, 1.6);                        // steep only near the rim: the lens hugs the edge
    vec3 N = vec3(ndir * sinI, sqrt(max(1.0 - sinI * sinI, 0.0)));

    float thetaI = asin(clamp(sinI, 0.0, 1.0));
    float thetaT = asin(clamp(sinI / max(refractIOR, 1.0), 0.0, 1.0));
    float bend = tan(thetaI - thetaT);
    vec2 shiftUV = -ndir * bend * refractScale / size;
    vec2 chromaUV = -ndir * bend * refractScale * 0.07 * chromaStrength / size;

    vec2 uvR = uv + shiftUV + chromaUV;
    vec2 uvG = uv + shiftUV;
    vec2 uvB = uv + shiftUV - chromaUV;

    vec3 col = vec3(texture(backdrop, toTex(uvR)).r,
                    texture(backdrop, toTex(uvG)).g,
                    texture(backdrop, toTex(uvB)).b);
    float clearW = sharpMix * smoothstep(0.30, 0.92, x);
    if (clearW > 0.001) {
        vec3 rim = vec3(texture(sharp, toTex(uvR)).r,
                        texture(sharp, toTex(uvG)).g,
                        texture(sharp, toTex(uvB)).b);
        col = mix(col, rim, clearW);
    }

    // --- Vibrancy, then the tint (deeper over bright backdrops when legibility is on).
    float vib = vibrancy > 0.0 ? vibrancy : 1.0;
    float luma = dot(col, vec3(0.2126, 0.7152, 0.0722));
    col = clamp(mix(vec3(luma), col, vib), 0.0, 1.0);

    vec3 tintColor = mix(tint.rgb, tintBottom.rgb, tintBottom.a > 0.0 ? uv.y : 0.0);
    float tintA = tint.a;
    if (legibility > 0.0 && tint.a < 1.0) {
        tintA = min(0.9, tintA + legibility * 0.34 * smoothstep(0.28, 0.82, luma));
    }
    col = mix(col, tintColor, tintA);

    if (overlayDarken.a > 0.0) {
        col = mix(col, overlayDarken.rgb, smoothstep(1.0 - overlayDarken.a, 1.0, uv.y));
    }

    // --- Lights. Key light top-left; while hovering it swings towards the pointer.
    vec2 restDir = normalize(vec2(-0.62, -0.78));
    vec2 keyDir = restDir;
    if (mouseFade > 0.0 && mousePos.x >= 0.0 && mousePos.y >= 0.0) {
        vec2 toPointer = (mousePos - vec2(0.5)) * size;
        if (length(toPointer) > 1.0) {
            keyDir = normalize(mix(restDir, normalize(toPointer), mouseFade));
        }
    }

    // Fresnel: Schlick with a broad exponent so the rim glows over a few pixels, not one.
    if (fresnel > 0.0 && x > 0.0) {
        float F = 0.04 + 0.96 * pow(1.0 - N.z, 4.0);
        float sky = 0.5 - 0.5 * ndir.y;              // 1 on the top edge, 0 on the bottom edge
        vec3 env = vec3(0.96, 0.98, 1.0) * mix(0.30, 0.95, sky);
        col = mix(col, env, clamp(F * fresnel * 0.35, 0.0, 1.0));
    }

    float facing = dot(ndir, keyDir);
    if (specStrength > 0.0 && x > 0.0) {
        float arc = pow(max(facing, 0.0), 2.5) + 0.5 * pow(max(-facing, 0.0), 2.5);
        float rim = pow(x, 7.0) * (0.12 + 0.88 * arc);
        col += vec3(1.0, 0.985, 0.96) * rim * specStrength * 0.95;
    }

    // --- Depth: a line of light at the lip (both lit corners), a faint shadow inside the bevel.
    if (depth > 0.0) {
        float lip = 1.0 - smoothstep(0.0, 1.6, max(depthPx, 0.0));
        float lit = 0.28 + 0.72 * pow(abs(facing), 3.0) * (facing > 0.0 ? 1.0 : 0.62);
        col += vec3(1.0, 0.99, 0.97) * lip * lit * depth * 0.42;

        float band = smoothstep(0.35, 0.7, x) * (1.0 - smoothstep(0.82, 0.97, x));
        float away = clamp(-facing, 0.0, 1.0);
        col *= 1.0 - depth * band * 0.14 * away;
    }

    // Silhouette: ~1 px feather on the geometric edge; Qt Quick blends premultiplied alpha.
    float mask = 1.0 - smoothstep(-0.5, 0.5, d);
    fragColor = vec4(clamp(col, 0.0, 1.0) * mask, mask) * qt_Opacity;
}

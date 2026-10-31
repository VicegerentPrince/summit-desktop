#version 440

// The Timer's liquid: one bead of ink with a neck behind it, that spreads into a film and condenses
// into a ring, which then runs down as an arc. Everything is a signed distance in logical pixels,
// so the edge stays sharp at any scale.

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4  qt_Matrix;
    float qt_Opacity;
    vec2  size;        // item size, logical px
    float pixel;       // one device pixel, in logical px
    vec4  lead;        // centre xy, outer radius, inner radius: a disc that opens into a ring
    float film;        // how soft the inner edge is, px: a spreading film, then a sharp ring
    float thin;        // how far the film has thinned: 0 solid, 1 the glass shows through it
    vec4  tail;        // centre xy, radius of the droplet at the end, radius of the neck (< 0: snapped)
    vec4  ink;         // not premultiplied
    vec4  track;       // centre xy, middle radius, half width of the ring's faint track
    float trackAlpha;
    float sweep;       // how much of the ring is left, radians, clockwise from twelve
    float glintAngle;  // where a highlight sits on the ring, radians from twelve
    float glint;       // its strength
    vec2  halo;        // radius of the ripple around the ring, its strength
    float gloss;       // 0 flat colour, 1 a wet bead
};

const float TAU = 6.2831853;

// The bead's neck: full at the bead, thin in the middle, a small droplet at the far end.
float neck(vec2 p) {
    vec2 ab = tail.xy - lead.xy;
    float l2 = dot(ab, ab);
    float t = l2 > 0.01 ? clamp(dot(p - lead.xy, ab) / l2, 0.0, 1.0) : 0.0;
    float r = mix(lead.z, tail.w, smoothstep(0.0, 0.72, t));
    r += (tail.z - tail.w) * smoothstep(0.72, 1.0, t);
    return length(p - lead.xy - ab * t) - r;
}

float scene(vec2 p) {
    vec2 q = p - lead.xy;
    float d = length(q) - lead.z;

    if (sweep < TAU - 0.001) {
        float mid = 0.5 * (lead.z + lead.w);
        float wid = 0.5 * (lead.z - lead.w);
        if (sweep <= 0.0) {
            d = 1000.0;
        } else if (mod(atan(q.x, -q.y), TAU) > sweep) {
            vec2 from = vec2(0.0, -mid);
            vec2 to = mid * vec2(sin(sweep), -cos(sweep));
            d = min(length(q - from), length(q - to)) - wid;
        }
    }
    if (tail.z <= 0.0) return d;
    return min(d, neck(p));
}

void main() {
    vec2 p = qt_TexCoord0 * size;
    float aa = pixel * 0.75;

    vec4 under = vec4(0.0);

    // the bead's soft shadow on the glass
    if (gloss > 0.0) {
        float s = scene(p - vec2(0.0, 5.0));
        under = vec4(0.0, 0.0, 0.0, 0.26 * gloss * (1.0 - smoothstep(-7.0, 9.0, s)));
    }
    // the ring's track and the ripple
    if (trackAlpha > 0.0) {
        float d = abs(length(p - track.xy) - track.z) - track.w;
        float a = 0.18 * trackAlpha * (1.0 - smoothstep(-aa, aa, d));
        under = vec4(a) + under * (1.0 - a);
    }
    if (halo.y > 0.0) {
        float d = abs(length(p - track.xy) - halo.x) - 1.25;
        float a = halo.y * (1.0 - smoothstep(-1.25, 1.25, d));
        under = vec4(ink.rgb * a, a) + under * (1.0 - a);
    }

    float d = scene(p);
    float cover = 1.0 - smoothstep(-aa, aa, d);
    if (cover > 0.0) {
        float len = length(p - lead.xy);
        float edge = max(film, aa);
        cover *= smoothstep(lead.w - edge, lead.w + edge, len);
        // spread thin the liquid lets the glass through, and only its rim stays full
        cover *= mix(1.0, smoothstep(lead.z - 20.0, lead.z - 2.0, len), thin);
    }
    if (cover <= 0.0) {
        fragColor = under * qt_Opacity;
        return;
    }

    vec3 col = ink.rgb;

    // The wet look: a rounded edge gives a surface normal. The key light top-left leaves a sharp
    // highlight, and the light that went through comes out as a glow on the far side, as in a
    // drop of water.
    if (gloss > 0.0) {
        const float bevel = 8.0;
        float t = clamp(-d / bevel, 0.0, 1.0);
        vec2 e = vec2(0.5, 0.0);
        vec2 g = vec2(scene(p + e.xy) - d, scene(p + e.yx) - d);
        g = length(g) > 0.0001 ? normalize(g) : vec2(0.0);
        float slope = sqrt(max(1.0 - t * t, 0.0));
        vec3 n = normalize(vec3(g * slope, max(t, 0.1)));
        vec3 l = normalize(vec3(-0.45, -0.72, 0.53));
        vec3 h = normalize(l + vec3(0.0, 0.0, 1.0));
        float spec = pow(max(dot(n, h), 0.0), 90.0);
        float through = pow(max(dot(n.xy, -l.xy), 0.0), 1.5);
        float fresnel = pow(1.0 - n.z, 4.0);
        col *= 1.0 - 0.1 * gloss * max(dot(n.xy, l.xy), 0.0);
        col += gloss * (col * through * 0.55 + vec3(1.0) * spec * 0.85 + vec3(1.0, 0.99, 0.96) * fresnel * 0.14);
    }

    if (glint > 0.0) {
        vec2 q = p - lead.xy;
        float a = mod(atan(q.x, -q.y) - glintAngle + 0.5 * TAU, TAU) - 0.5 * TAU;
        col = mix(col, vec3(1.0), glint * smoothstep(0.62, 0.0, abs(a)));
    }

    float alpha = ink.a * cover;
    vec4 top = vec4(clamp(col, 0.0, 1.0) * alpha, alpha);
    fragColor = (top + under * (1.0 - alpha)) * qt_Opacity;
}

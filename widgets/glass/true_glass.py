#!/usr/bin/env python3
"""Summit's glass for every card: Apple-style Liquid Glass on top of the Liquid Glass widgets' pipeline.

Applied to each installed copy of LiquidGlass.qml, after patch_glass.py:
  - the glass shader is replaced by glass/liquidglass.frag (clear lens rim around a frosted middle,
    vibrancy, adaptive legibility tint, Fresnel rim, two-light specular, edge light and bevel shadow)
  - the shader gets the unblurred backdrop next to the frosted one, plus the new terms' strengths
  - the card casts a soft shadow, deeper for bigger cards (RectangularShadow, one analytic quad)

Nothing here animates or redraws on its own: the glass still renders only when the blur chain does.

    true_glass.py FILE [FILE...]      exact-match and idempotent
"""
import os
import shutil
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
MARK = "[summit true glass]"

EDITS = [
    ("import QtQuick\n", "import QtQuick\nimport QtQuick.Effects\n"),
    ("    property vector4d overlayDarken: Qt.vector4d(0, 0, 0, 0)\n",
     """    property vector4d overlayDarken: Qt.vector4d(0, 0, 0, 0)

    // [summit true glass] strengths of the terms liquidglass.frag adds (true_glass.py)
    property real sharpMix: 0.85        // how clear the lens rim is next to the frosted middle
    property real vibrancy: 1.4         // backdrop saturation through the glass
    property real fresnel: 0.85         // rim reflection
    property real legibility: 0.65      // extra tint where the backdrop is bright
    property real depthStrength: 0.85   // edge light and bevel shadow
    property real shadowOpacity: 0.28   // the soft shadow under the card
"""),
    ("    ShaderEffect {\n        id: glassShader\n",
     """    // [summit true glass] the slab lifts off the wallpaper. A squircle's corner looks tighter than
    // a circle of the same radius, so the shadow's radius is scaled to match the visible curve.
    RectangularShadow {
        anchors.fill: parent
        visible: glass.shadowOpacity > 0 && (glass.solidMode || glass.active)
        radius: Math.min(glass.radius, Math.min(width, height) / 2)
                * (1 - Math.pow(2, -1 / Math.max(2, glass.roundness))) / 0.2929
        blur: Math.max(14, Math.min(36, Math.min(width, height) * 0.13))
        offset: Qt.vector2d(0, Math.round(blur * 0.3))
        spread: -2
        color: Qt.rgba(0, 0, 0, glass.shadowOpacity)
        cached: true
    }

    ShaderEffect {
        id: glassShader
"""),
    ("        property vector4d overlayDarken: glass.overlayDarken\n",
     """        property vector4d overlayDarken: glass.overlayDarken

        // [summit true glass]
        property variant sharp: glass._blurActive ? cropTex : wallpaperTex
        property real sharpMix: glass.solidMode ? 0.0 : glass.sharpMix
        property real vibrancy: glass.vibrancy
        property real fresnel: glass.fresnel
        property real legibility: glass.solidMode ? 0.0 : glass.legibility
        property real depth: glass.depthStrength
"""),
]

rc = 0
for path in sys.argv[1:]:
    shaders = os.path.join(os.path.dirname(path), "shaders")
    for name in ("liquidglass.frag", "liquidglass.frag.qsb"):
        target = os.path.join(shaders, name)
        if os.path.isdir(shaders):
            if os.path.islink(target) or os.path.exists(target):
                os.remove(target)          # never write through a link into the vendored copy
            shutil.copyfile(os.path.join(HERE, name), target)
    s = open(path).read()
    if MARK in s:
        continue
    missing = [old.strip().splitlines()[0] for old, _ in EDITS if old not in s]
    if missing:
        print(f"  WARN  true glass not applied to {path}: upstream changed near {missing}")
        rc = 3
        continue
    for old, new in EDITS:
        s = s.replace(old, new, 1)
    open(path, "w").write(s)
sys.exit(rc)

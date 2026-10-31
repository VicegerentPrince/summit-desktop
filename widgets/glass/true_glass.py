#!/usr/bin/env python3
"""Summit's glass for every card: Apple-style Liquid Glass on top of the Liquid Glass widgets' pipeline.

Applied to each installed copy of LiquidGlass.qml, after patch_glass.py:
  - the glass shader is replaced by glass/liquidglass.frag (clear lens rim around a frosted middle,
    vibrancy, adaptive legibility tint, Fresnel rim, two-light specular, edge light and bevel shadow;
    for the liquid look also a slightly magnifying slab and a glossy hairline on the rim)
  - the shader gets the unblurred backdrop next to the frosted one, plus the new terms' strengths
  - the card casts a soft shadow, deeper for bigger cards (RectangularShadow, one analytic quad)
  - the card's Appearance page is rebuilt (appearance_page.py) with a Glass choice, Liquid or
    Frosted, and a button that puts the same glass on every card; its settings schema gets
    glassStyle, and Liquid's lighter frost (blur radius 4) becomes the default. Frosted goes back
    to the card's own original blur.
  - a card can draw the rim light towards something on it for a moment (lightPoint)

Nothing here animates or redraws on its own: the glass still renders only when the blur chain does.

    true_glass.py FILE [FILE...]      FILE = a card's contents/ui/components/LiquidGlass.qml;
                                      exact-match and idempotent
"""
import os
import re
import shutil
import sys

import appearance_page

HERE = os.path.dirname(os.path.abspath(__file__))
MARK = "[summit true glass 2]"
OLD_MARK = "[summit true glass]"

EDITS = [
    ("import QtQuick\n", "import QtQuick\nimport QtQuick.Effects\n"),
    ("    property vector4d overlayDarken: Qt.vector4d(0, 0, 0, 0)\n",
     """    property vector4d overlayDarken: Qt.vector4d(0, 0, 0, 0)

    // [summit true glass 2] the look, from the card's Appearance page: Glass = Liquid (0) or Frosted (1)
    readonly property bool liquid: (Plasmoid.configuration.glassStyle ?? 0) === 0
    // strengths of the terms liquidglass.frag adds (true_glass.py)
    property real sharpMix: 0.85        // how clear the lens rim is next to the frosted middle
    property real vibrancy: 1.4         // backdrop saturation through the glass
    property real fresnel: liquid ? 0.45 : 0.85   // sky reflected in the rim
    property real legibility: 0.65      // extra tint where the backdrop is bright
    property real depthStrength: 0.85   // edge light and bevel shadow
    property real shadowOpacity: 0.28   // the soft shadow under the card
    property real magnify: liquid ? 0.5 : 0.0     // the slab enlarges what is behind it (1 = 20 %)
    property real gloss: liquid ? 0.9 : 0.0       // hairline of light on the silhouette
"""),
    ("    // --- Mouse tracking for specular highlight ---\n",
     """    // [summit true glass 2] something on the card can draw the rim light towards it for a moment:
    // x, y in widget UV, strength. It mixes with the pointer, so nothing jumps when it lets go.
    property vector3d lightPoint: Qt.vector3d(0, 0, 0)

    // --- Mouse tracking for specular highlight ---
"""),
    ("        property vector2d mousePos: Qt.vector2d(glass._mouseU, glass._mouseV)\n        property real mouseFade: glass._mouseFade\n",
     """        property vector2d mousePos: {
            const k = glass.lightPoint.z
            if (k <= 0) return Qt.vector2d(glass._mouseU, glass._mouseV)
            const u = glass._mouseU < 0 ? glass.lightPoint.x : glass._mouseU
            const v = glass._mouseV < 0 ? glass.lightPoint.y : glass._mouseV
            return Qt.vector2d(u + (glass.lightPoint.x - u) * k, v + (glass.lightPoint.y - v) * k)
        }
        property real mouseFade: Math.max(glass._mouseFade, glass.lightPoint.z)
"""),
    ("    ShaderEffect {\n        id: glassShader\n",
     """    // [summit true glass 2] the slab lifts off the wallpaper. A squircle's corner looks tighter than
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

        // [summit true glass 2]
        property variant sharp: glass._blurActive ? cropTex : wallpaperTex
        property real sharpMix: glass.solidMode ? 0.0 : glass.sharpMix
        property real vibrancy: glass.vibrancy
        property real fresnel: glass.fresnel
        property real legibility: glass.solidMode ? 0.0 : glass.legibility
        property real depth: glass.depthStrength
        property real magnify: glass.solidMode ? 0.0 : glass.magnify
        property real gloss: glass.gloss
"""),
]

# The Appearance page (vendor 1-common/config/ConfigAppearance.qml, copied into every card)
PAGE_EDITS = [
    ("import org.kde.kirigami as Kirigami\n",
     "import org.kde.kirigami as Kirigami\nimport org.kde.plasma.plasma5support as P5Support\n"),
    ("    property alias cfg_realtimeRefraction: realtimeCheck.checked\n",
     "    property alias cfg_realtimeRefraction: realtimeCheck.checked\n"
     "    property alias cfg_glassStyle: glassCombo.currentIndex     // [summit true glass 2]\n"),
    ("            s: styleCombo.currentIndex,\n",
     "            s: styleCombo.currentIndex,\n            gs: glassCombo.currentIndex,\n"),
    ("            if (o.s  !== undefined) styleCombo.currentIndex      = o.s\n",
     "            if (o.s  !== undefined) styleCombo.currentIndex      = o.s\n"
     "            if (o.gs !== undefined) glassCombo.currentIndex      = o.gs\n"),
    ("    function _serialize() {\n",
     """    // [summit true glass 2] puts this glass on every glass card on the desktop, through Plasma's own
    // scripting interface (the one the layout scripts use)
    P5Support.DataSource {
        id: glassRunner
        engine: "executable"
        onNewData: (source, data) => {
            disconnectSource(source)
            const n = parseInt(((data["stdout"] || "").match(/(\\d+) cards/) || [])[1])
            root.glassNote = isFinite(n) ? i18np("Done: %1 card", "Done: all %1 cards", n)
                                         : i18n("Could not reach Plasma")
            glassNoteTimer.restart()
        }
    }
    // the result shows in the button itself for a moment, so the form does not move under the pointer
    property string glassNote: ""
    Timer { id: glassNoteTimer; interval: 2500; onTriggered: root.glassNote = "" }
    function useGlassEverywhere() {
        // Frosted is each card's own original blur: 30 on Music, 6 on the others
        const blur = glassCombo.currentIndex === 0 ? blurRadiusSpin.value : "(/[.]music$/.test(w.type) ? 30 : 6)"
        const js = "var n = 0; desktops().forEach(function (d) { d.widgets().forEach(function (w) {"
                 + " if (/^(com[.]jaxparrow07[.]macoswidgets[.]|summit[.](vitals|claude|projects|github)$)/.test(w.type)) {"
                 + " w.currentConfigGroup = [\\"General\\"]; w.writeConfig(\\"glassStyle\\", " + glassCombo.currentIndex + ");"
                 + " w.writeConfig(\\"blurRadiusPx\\", " + blur + "); w.reloadConfig(); n++; } }); });"
                 + " print(n + \\" cards\\");"
        glassRunner.connectSource("for q in qdbus6 qdbus-qt6 qdbus; do command -v $q >/dev/null && exec $q"
            + " org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript '" + js + "'; done;"
            + " exec dbus-send --session --print-reply --dest=org.kde.plasmashell /PlasmaShell"
            + " org.kde.PlasmaShell.evaluateScript 'string:" + js + "' #" + Date.now())
    }

    function _serialize() {
"""),
]


BLUR_ENTRY = r'([ \t]*)<entry name="blurRadiusPx" type="Int">(\s*)<default>(\d+)</default>(\s*)</entry>\n'


def own_copy(path):
    """Never write through a link into the vendored copy."""
    if os.path.islink(path):
        data = open(path).read()
        os.remove(path)
        open(path, "w").write(data)


def patch_page(path, schema):
    if not os.path.exists(path):
        return 0
    own_copy(path)
    s = open(path).read()
    if MARK in s:
        return 0
    frosted = re.search(BLUR_ENTRY, open(schema).read()) if os.path.exists(schema) else None
    frosted = frosted.group(3) if frosted else "6"
    missing = [old.strip().splitlines()[0] for old, _ in PAGE_EDITS if old not in s]
    if missing:
        print(f"  WARN  Glass setting not added to {path}: upstream changed near {missing}")
        return 3
    for old, new in PAGE_EDITS:
        s = s.replace(old, new, 1)
    open(path, "w").write(appearance_page.rebuild(s, frosted))
    return 0


def patch_schema(path):
    """glassStyle (0 = Liquid) after blurRadiusPx, whose default becomes Liquid's frost."""
    if not os.path.exists(path):
        return 0
    own_copy(path)
    s = open(path).read()
    if 'name="glassStyle"' in s:
        return 0
    m = re.search(BLUR_ENTRY, s)
    if not m:
        print(f"  WARN  glassStyle not added to {path}: no blurRadiusPx entry")
        return 3
    ind = m.group(1)
    new = (f'{ind}<entry name="blurRadiusPx" type="Int">{m.group(2)}<default>4</default>{m.group(4)}</entry>\n'
           f'{ind}<entry name="glassStyle" type="Int">{m.group(2)}<default>0</default>{m.group(4)}</entry>\n')
    open(path, "w").write(s[:m.start()] + new + s[m.end():])
    return 0


rc = 0
for path in sys.argv[1:]:
    contents = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(path))))
    shaders = os.path.join(os.path.dirname(path), "shaders")
    for name in ("liquidglass.frag", "liquidglass.frag.qsb"):
        target = os.path.join(shaders, name)
        if os.path.isdir(shaders):
            if os.path.islink(target) or os.path.exists(target):
                os.remove(target)          # never write through a link into the vendored copy
            shutil.copyfile(os.path.join(HERE, name), target)
    schema = os.path.join(contents, "config", "main.xml")
    rc = max(rc, patch_page(os.path.join(contents, "ui", "config", "ConfigAppearance.qml"), schema))
    rc = max(rc, patch_schema(schema))
    s = open(path).read()
    if MARK in s:
        continue
    if OLD_MARK in s:
        print(f"  WARN  {path} has the first true glass; copy LiquidGlass.qml fresh from the vendor and rerun")
        rc = 3
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

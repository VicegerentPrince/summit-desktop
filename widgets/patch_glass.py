#!/usr/bin/env python3
"""Local fix for LiquidGlass.qml (Liquid Glass widgets): re-capture the wallpaper once it has
really been drawn.

Upstream captures the wallpaper once when a widget is created and again only when the widget
moves. A widget restored at login is created before the wallpaper image has loaded, so it samples
nothing and stays black; a later wallpaper change is not picked up either, so the card keeps
showing the old picture. Each trigger re-captures four times over about ten seconds, which covers
slow loads and the cross-fade between two wallpapers.

    patch_glass.py FILE [FILE...]      exact-match and idempotent
"""
import sys

OLD = "    Component.onCompleted: updateGeometry()\n"
NEW = '''    // [local fix] see patch_glass.py
    function recapture() {
        if (solidMode || !wallpaperItem) return
        wallpaperTex.scheduleUpdate()
        markDirty()
    }
    property int _settleStep: 0
    readonly property var _settleDelays: [400, 1200, 3000, 6000]
    Timer {
        id: settleCapture
        interval: 400
        onTriggered: {
            glass.recapture()
            glass._settleStep += 1
            if (glass._settleStep < glass._settleDelays.length) {
                interval = glass._settleDelays[glass._settleStep]
                restart()
            }
        }
    }
    function settle() {
        _settleStep = 0
        settleCapture.interval = _settleDelays[0]
        settleCapture.restart()
    }
    // What can change the picture behind the card: the image setting (the usual case, including
    // the `wall` command and System Settings), the wallpaper's own loading state, and its
    // extracted accent colour (slideshows change the image without touching the setting).
    readonly property var wpImage: (wallpaperItem && wallpaperItem.configuration) ? wallpaperItem.configuration.Image : undefined
    onWpImageChanged: settle()
    Connections {
        target: glass.wallpaperItem
        ignoreUnknownSignals: true
        function onIsLoadingChanged() { glass.settle() }
        function onAccentColorChanged() { glass.settle() }
        function onPluginNameChanged() { glass.settle() }
    }
    Component.onCompleted: { updateGeometry(); settle() }
'''
rc = 0
for p in sys.argv[1:]:
    s = open(p).read()
    if "function recapture()" in s:
        continue
    if OLD not in s:
        print(f"  WARN  glass re-capture fix not applied to {p}: upstream code changed"); rc = 3; continue
    open(p, "w").write(s.replace(OLD, NEW, 1))
sys.exit(rc)

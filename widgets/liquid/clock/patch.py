#!/usr/bin/env python3
"""The Clock card: a Clock settings page (12 or 24 hours; Soft, Clear or Thin digits), figures that
keep their width, and digits that lift over when they change: only the ones that changed, once a
minute."""
import sys

c = sys.argv[1]


def edit(path, edits):
    s = open(path).read()
    for a, b in edits:
        assert s.count(a) == 1, a
        s = s.replace(a, b)
    open(path, "w").write(s)


edit(c + "/ui/main.qml", [
    ("readonly property int hour12: ((now.getHours() + 11) % 12) + 1",
     "readonly property int hour12: plasmoid.configuration.hourFormat === 1 ? now.getHours() : ((now.getHours() + 11) % 12) + 1"),
    ("fontFamily: barlowMedium.name",
     'fontFamily: plasmoid.configuration.digitStyle === 2 ? "Inter Display" : barlowMedium.name\n'
     "            fontWeight: plasmoid.configuration.digitStyle === 2 ? Font.ExtraLight : Font.Medium\n"
     "            padHour: plasmoid.configuration.hourFormat === 1"),
    ("digitOpacity: colors.isGlass ? 0.55 : 1.0",
     "digitOpacity: colors.isGlass ? [0.55, 0.9, 1.0][plasmoid.configuration.digitStyle] : 1.0"),
])

p = c + "/ui/widget/DigitalTime.qml"
s = open(p).read()
a = '    property string fontFamily: ""\n'
assert s.count(a) == 1
s = s.replace(a, a + """    property int fontWeight: Font.Medium
    property bool padHour: false        // 24 hours: 09:05
    readonly property string hourLabel: padHour && hour12 < 10 ? "0" + hour12 : String(hour12)
""")
a = "import QtQuick\n"
s = s.replace(a, a + 'import "../components"\n', 1)
a = "        text: String(root.hour12)\n"
assert s.count(a) == 1
s = s.replace(a, "        text: root.hourLabel\n")
# the width is measured with the same figures that are drawn
a = """        font.weight: Font.Medium
        font.letterSpacing: -root.fontPixelSize * 0.03
"""
assert s.count(a) == 2
s = s.replace(a, """        font.weight: root.fontWeight
        font.features: { "tnum": 1 }
        font.letterSpacing: -root.fontPixelSize * 0.03
""")

a = s.index("        Text {\n            id: hourText\n")
b = s.index("        // Colon dots.")
s = s[:a] + """        component Figure: SwapText {
            color: root.textColor
            opacity: root.digitOpacity
            font.family: root.fontFamily
            font.pixelSize: root._effectiveFontSize
            font.weight: root.fontWeight
            font.letterSpacing: root._letterSpacing
            font.features: { "tnum": 1 }
            renderType: Text.NativeRendering
        }

        Figure {
            id: hourText
            anchors.verticalCenter: parent.verticalCenter
            text: root.hourLabel
        }

""" + s[b:]
a = s.index("        Text {\n            id: minText\n")
b = s.rindex("    }\n}")
s = s[:a] + """        Row {
            anchors.verticalCenter: parent.verticalCenter
            Figure { text: Math.floor(root.minute / 10) }
            Figure { text: root.minute % 10 }
        }
""" + s[b:]
open(p, "w").write(s)

edit(c + "/config/main.xml", [("    </group>", """        <entry name="hourFormat" type="Int"><default>0</default></entry>
        <entry name="digitStyle" type="Int"><default>0</default></entry>
    </group>""")])
edit(c + "/config/config.qml", [("ConfigModel {\n", """ConfigModel {
    ConfigCategory {
        name: i18n("Clock")
        icon: "preferences-system-time"
        source: "config/ConfigClock.qml"
    }
""")])

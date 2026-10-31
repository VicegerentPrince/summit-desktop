#!/usr/bin/env python3
"""The Timer card's layouts and fixes, on an installed copy of the vendor Timer.

    patch.py CONTENTS      CONTENTS = the card's contents folder, copied fresh from the vendor

Layouts: Wheels and Ring (the default, new FaceFlow.qml), Wheels, Ring, Bar, chosen on the Timer
settings page, which also edits the presets. Only the layout in use is loaded. A card too narrow
for them keeps the vendor's own layout.

Fixes to the vendor's countdown:
  - the time is shown in whole seconds rounded up, so it starts at 25:00 and reaches 00:00 as it
    ends, and anything drawn from it changes once a second instead of ten times
  - pausing during the first second no longer loses the time (the end time is not set yet)
  - "Ends 3:42" never shows the end time of the run before
  - Done: the primary button runs the same timer again
"""
import re
import sys

c = sys.argv[1]
p = c + "/ui/main.qml"
s = open(p).read()


def swap(old, new):
    global s
    assert s.count(old) == 1, old
    s = s.replace(old, new)


swap("""    readonly property int displayMinutes: Math.floor(remainingMs / 60000)
    readonly property int displaySeconds: Math.floor((remainingMs % 60000) / 1000)
""", """    // [summit timer] whole seconds, rounded up: 25:00 at the start, 00:00 at the end
    readonly property int wholeSeconds: Math.ceil(remainingMs / 1000)
    readonly property int displayMinutes: Math.floor(wholeSeconds / 60)
    readonly property int displaySeconds: wholeSeconds % 60
    readonly property real remainingShare: totalMs > 0 ? wholeSeconds * 1000 / totalMs : 1

    // presets from the Timer settings page, each "minutes|name"
    readonly property var presetList: (plasmoid.configuration.presets || []).map(s => {
        const i = s.indexOf("|")
        return { mins: parseInt(i < 0 ? s : s.slice(0, i)) || 1, name: i < 0 ? "" : s.slice(i + 1) }
    })
    property string activeName: ""
    readonly property int face: plasmoid.configuration.timerFace
    readonly property string endsLabel: timerState === 2 ? i18n("Paused") : timerState === 3 ? i18n("Done")
        : i18n("Ends %1", Qt.formatTime(new Date(targetTime > 0 ? targetTime : Date.now() + totalMs), Qt.locale().timeFormat(Locale.ShortFormat)))
    function stepMinutes(d) { selectedMinutes = (selectedMinutes + d + 100) % 100 }
    function stepSeconds(d) { selectedSeconds = (selectedSeconds + d + 60) % 60 }
    function startPreset(p) { selectedMinutes = p.mins; selectedSeconds = 0; activeName = p.name; startTimer() }
    function startCustom() {
        const p = presetList.find(p => p.mins === selectedMinutes && selectedSeconds === 0)
        activeName = p ? p.name : ""
        startTimer()
    }
    function primaryAction() {
        if (timerState === 0) startCustom()
        else if (timerState === 1) pauseTimer()
        else if (timerState === 2) resumeTimer()
        else startTimer()
    }
    Component.onCompleted: if (presetList.length > 0) selectedMinutes = presetList[0].mins
""")
swap("""        remainingMs = ms
        timerState = 1
        startDelayTimer.restart()
""", """        remainingMs = ms
        targetTime = 0
        timerState = 1
        startDelayTimer.restart()
""")
swap("""        remainingMs = Math.max(0, targetTime - Date.now())
        timerState = 2
""", """        if (startDelayTimer.running) startDelayTimer.stop()
        else remainingMs = Math.max(0, targetTime - Date.now())
        timerState = 2
""")

# The faces take over from the vendor's preset list, which goes
a = s.index("        // ── Left panel: Presets (wide mode only)")
b = s.index("        // ── Right panel: Timer content")
s = s[:a] + """        // [summit timer] the chosen layout; only that one is loaded
        Loader {
            anchors.fill: parent
            active: full.isWide
            sourceComponent: [wheelsFace, ringFace, barFace, flowFace][root.face] || flowFace
        }
        Component { id: wheelsFace; FaceWheels { t: root; c: colors } }
        Component { id: ringFace; FaceRing { t: root; c: colors } }
        Component { id: barFace; FaceBar { t: root; c: colors } }
        Component { id: flowFace; FaceFlow { t: root; c: colors; card: glass } }

""" + s[b:]
swap("""            id: rightPanel
            width: full.isWide ? full.height : full.width
""", """            id: rightPanel
            visible: !full.isWide
            width: full.isWide ? full.height : full.width
""")
swap("""            visible: root.timerState === 0
            opacity: root.timerState === 0 ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 180 } }

            Row {
""", """            visible: root.timerState === 0
            opacity: root.timerState === 0 ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 180 } }

            // A wheel with no size yet must keep its own position binding, so it is only told the index.
            function place(picker, index) {
                if (picker._itemHeight > 0) picker.setIndex(index)
                else picker.currentIndex = index
            }
            Component.onCompleted: {
                place(minPicker, root.selectedMinutes)
                place(secPicker, root.selectedSeconds)
            }
            Connections {
                target: root
                function onSelectedMinutesChanged() { pickerArea.place(minPicker, root.selectedMinutes) }
                function onSelectedSecondsChanged() { pickerArea.place(secPicker, root.selectedSeconds) }
            }

            Row {
""")
s, n = re.subn(r"    ListModel \{\n        id: presetsModel\n.*?\n    \}\n", "", s, flags=re.S)
assert n == 1, "presetsModel"
open(p, "w").write(s)

p = c + "/config/main.xml"
s = open(p).read()
swap("    </group>", """        <entry name="timerFace" type="Int"><default>3</default></entry>
        <entry name="presets" type="StringList"><default>25|Focus,5|Break,15|,45|,10|,2|</default></entry>
    </group>""")
open(p, "w").write(s)

p = c + "/config/config.qml"
s = open(p).read()
swap("ConfigModel {\n", """ConfigModel {
    ConfigCategory {
        name: i18n("Timer")
        icon: "chronometer"
        source: "config/ConfigTimer.qml"
    }
""")
open(p, "w").write(s)

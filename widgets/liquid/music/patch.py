#!/usr/bin/env python3
"""The Music card. With nothing to play it goes Quiet: the timeline, the artist and the Lyrics pill
leave and the cover grows into the space. As soon as there is a song, even a paused one, the full
player comes back. The same change runs both ways from one number, so it can turn round half way.

A new song slides its title out the way the cover turns, and the play and pause icons swap at the
bottom of a small dip. The setting is on the Filter page: "When nothing is playing"."""
import re
import sys

c = sys.argv[1]
PLAIN = """
    // nothing to play: 0 keeps the full player, 1 Quiet drops what has nothing to show, 2 Minimal also the buttons
    readonly property int idleStyle: Plasmoid.configuration.idleStyle
    readonly property bool idle: track === ""
    readonly property bool plain: idle && idleStyle > 0
"""


def read(name):
    return open(f"{c}/ui/{name}").read()


def write(name, s):
    open(f"{c}/ui/{name}", "w").write(s)


def swap(s, a, b):
    assert s.count(a) == 1, a[:60]
    return s.replace(a, b)


def after_id(s, name, line):
    """adds a line straight after `id: name`, at the same indent"""
    m = re.search(rf"^( *)id: {name}\n", s, re.M)
    assert m, name
    return s[:m.end()] + f"{m.group(1)}{line}\n" + s[m.end():]


# ── Wide, the layout this card normally uses ───────────────────────────────
s = read("widget/WideLayout.qml")
s = swap(s, "import QtQuick.Layouts\n", "import QtQuick.Layouts\nimport org.kde.plasma.plasmoid\nimport org.kde.kirigami as Kirigami\n")
s = swap(s, "    id: layout\n", "    id: layout\n" + PLAIN + """
    // 0 the full player, 1 quiet. All that differs between them is worked out from this one number.
    property real quiet: plain ? 1 : 0
    Behavior on quiet { NumberAnimation { duration: Kirigami.Units.veryLongDuration * 0.9; easing.type: Easing.InOutCubic } }

    // A new song: the title leaves the way the cover turns and the next one comes in behind it.
    // What arrives while it is out is shown together, as a title and an artist come separately.
    property string shownTrack: ""
    property string shownArtist: ""
    Component.onCompleted: {
        shownTrack = track
        shownArtist = artist
    }
    function titleChanged() {
        if (shownTrack === track && shownArtist === artist) return
        if (!visible || Kirigami.Units.longDuration === 0) {
            shownTrack = track
            shownArtist = artist
        } else if (!titleChange.running) titleChange.start()
    }
    onTrackChanged: titleChanged()
    onArtistChanged: titleChanged()
    SequentialAnimation {
        id: titleChange
        ParallelAnimation {
            NumberAnimation { target: infoCol; property: "opacity"; to: 0; duration: Kirigami.Units.longDuration * 0.55; easing.type: Easing.InQuad }
            NumberAnimation { target: infoShift; property: "x"; to: -14 * layout.flipDirection; duration: Kirigami.Units.longDuration * 0.55; easing.type: Easing.InQuad }
        }
        ScriptAction {
            script: {
                layout.shownTrack = layout.track
                layout.shownArtist = layout.artist
                infoShift.x = 14 * layout.flipDirection
            }
        }
        ParallelAnimation {
            NumberAnimation { target: infoCol; property: "opacity"; to: 1; duration: Kirigami.Units.veryLongDuration * 0.6; easing.type: Easing.OutCubic }
            NumberAnimation { target: infoShift; property: "x"; to: 0; duration: Kirigami.Units.veryLongDuration * 0.6; easing.type: Easing.OutCubic }
        }
        onFinished: layout.titleChanged()
    }
""")
s = swap(s, """                id: slider
                anchors.left: parent.left""", """                id: slider
                visible: layout.quiet < 1
                opacity: 1 - layout.quiet
                anchors.left: parent.left""")
s = swap(s, """                anchors.bottom: slider.top
                anchors.bottomMargin: Math.round(layout._s * 0.03)
""", """                anchors.bottom: parent.bottom
                anchors.bottomMargin: (slider.height + Math.round(layout._s * 0.03)) * (1 - layout.quiet)
""")
s = swap(s, """                            id: infoCol
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: parent.width
                            spacing: 2
""", """                            id: infoCol
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: parent.width
                            spacing: 2 * (1 - layout.quiet)
                            transform: Translate { id: infoShift }
""")
s = swap(s, 'text: layout.track || "Not Playing"', 'text: layout.shownTrack || "Not Playing"')
s = swap(s, """                                height: Math.max(11, Math.round(layout._s * 0.059)) + 4
                                text: layout.artist || "—\"""", """                                height: (Math.max(11, Math.round(layout._s * 0.059)) + 4) * (1 - layout.quiet)
                                visible: layout.quiet < 1
                                opacity: 1 - layout.quiet
                                text: layout.shownArtist || "—\"""")
s = swap(s, """                            id: controls
                            anchors.horizontalCenter: parent.horizontalCenter""", """                            id: controls
                            visible: !(layout.idle && layout.idleStyle === 2)
                            anchors.horizontalCenter: parent.horizontalCenter""")
s = swap(s, """        id: lyricsBtn
        anchors.top: parent.top""", """        id: lyricsBtn
        visible: layout.quiet < 1
        opacity: 1 - layout.quiet
        scale: 1 - 0.12 * layout.quiet
        anchors.top: parent.top""")
write("widget/WideLayout.qml", s)

# ── The other shapes the card can be resized to ────────────────────────────
for name, hide in (("SquareLayout", ()), ("TallWideLayout", ("slider", "lyricsBtn")), ("BarLayout", ("progressLine",))):
    s = read(f"widget/{name}.qml")
    s = re.sub(r"^import QtQuick\n", "import QtQuick\nimport org.kde.plasma.plasmoid\n", s, count=1, flags=re.M)
    s = swap(s, "    id: layout\n", "    id: layout\n" + PLAIN)
    for item in hide:
        s = after_id(s, item, "visible: !layout.plain")
    if "id: controls\n" in s:
        s = after_id(s, "controls", "visible: !(layout.idle && layout.idleStyle === 2)")
    s, n = re.subn(r"^( *)text: layout\.artist \|\| \"—\"\n", lambda m: f"{m.group(1)}visible: !layout.plain\n{m.group(0)}", s, flags=re.M)
    assert n == 1, name
    write(f"widget/{name}.qml", s)

# ── Play and pause ─────────────────────────────────────────────────────────
s = read("widget/ControlButton.qml")
s = swap(s, "    signal clicked()\n", """    signal clicked()

    // play and pause swap at the bottom of a small dip, however they were changed
    property bool ready: false
    Component.onCompleted: ready = true
    onIconSourceChanged: if (ready) bounceAnim.restart()
    Behavior on opacity { NumberAnimation { duration: 200 } }
""")
write("widget/ControlButton.qml", s)

# ── Lyrics have nothing to show without a song, and Quiet has no pill to leave them with ───
s = read("main.qml")
s, n = re.subn(r"lyricsActive: root\.lyricsActive\n", 'lyricsActive: root.lyricsActive && root.track !== ""\n', s)
assert n == 2, n
write("main.qml", s)

# ── The setting ────────────────────────────────────────────────────────────
s = read("config/ConfigFilter.qml")
s = swap(s, "    property alias cfg_autoHideEnabled: autoHideCheck.checked\n",
         "    property alias cfg_autoHideEnabled: autoHideCheck.checked\n    property alias cfg_idleStyle: idleCombo.currentIndex\n")
s = swap(s, """        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Auto-hide")
        }
""", """        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("When nothing is playing")
        }

        ComboBox {
            id: idleCombo
            Kirigami.FormData.label: i18n("Card shows:")
            model: [i18n("Full player"), i18n("Quiet: buttons, no timeline"), i18n("Minimal: title only")]
        }
""")
s = swap(s, """            Kirigami.FormData.label: i18n("When idle:")
            text: i18n("Hide widget when nothing is playing")""", """            Kirigami.FormData.label: i18n("Auto-hide:")
            text: i18n("Hide the card after a while")""")
write("config/ConfigFilter.qml", s)

p = c + "/config/main.xml"
s = open(p).read()
s = swap(s, "    </group>", """        <entry name="idleStyle" type="Int"><default>1</default></entry>
    </group>""")
# the same glass as the other cards, also when it is added by hand or on its own
s = swap(s, """<entry name="styleMode" type="Int">
            <default>1</default>""", """<entry name="styleMode" type="Int">
            <default>0</default>""")
open(p, "w").write(s)

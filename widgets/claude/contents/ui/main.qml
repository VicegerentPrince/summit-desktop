/*
    Claude plan usage: the 5-hour and weekly windows, or one alone on a plan without the other.

    The numbers come from ~/.cache/summit/claude-usage.json, which the Claude Code status line
    script (~/.claude/statusline.sh) writes from the data Claude Code hands it. This widget
    reads that file once a minute. It makes no network requests and reads no credentials.
*/
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami
import "components"

PlasmoidItem {
    id: root

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: fullRepresentation

    width: 368
    height: 144

    // Inter Display ships inside the widget (contents/fonts), so the card looks the same everywhere
    FontLoader { id: interLight; source: Qt.resolvedUrl("../fonts/InterDisplay-ExtraLight.ttf") }
    FontLoader { id: interMedium; source: Qt.resolvedUrl("../fonts/InterDisplay-Medium.ttf") }
    readonly property string face: interMedium.status === FontLoader.Ready ? interMedium.font.family : "Inter Display"
    readonly property string command: "cat \"${XDG_CACHE_HOME:-$HOME/.cache}/summit/claude-usage.json\" 2>/dev/null || echo MISSING"
    property bool connected: true

    property int fiveHour: -1
    property real fiveHourReset: 0
    property int week: -1
    property real weekReset: 0
    property real nowSec: Date.now() / 1000
    // The plan has no such limit: the file holds null for that window and the other fills the card.
    property bool noFiveHour: false
    property bool noWeek: false
    property bool loaded: false     // the first reading sets the layout without moving it

    readonly property string waiting: connected ? "waiting for Claude Code" : "Not connected yet: right-click › Configure › Setup"
    readonly property color warn: "#FF9F0A"
    readonly property color bad: "#FF453A"

    MacOSColors {
        id: colors
        styleMode: Plasmoid.configuration.styleMode
        appearance: Plasmoid.configuration.appearance
    }

    P5Support.DataSource {
        id: reader
        engine: "executable"
        connectedSources: [root.command]
        interval: 60000
        onNewData: (source, data) => {
            root.nowSec = Date.now() / 1000
            const text = (data["stdout"] || "").trim()
            root.connected = text !== "MISSING"
            if (text !== "" && text !== "MISSING") {
                try {
                    const j = JSON.parse(text)
                    const five = j.five_hour, week = j.seven_day
                    root.noFiveHour = !five && !!week
                    root.noWeek = !week && !!five
                    // a window the plan lost keeps its last figures while its column fades out
                    if (!root.noFiveHour) {
                        root.fiveHour = five ? Math.round(five.used) : -1
                        root.fiveHourReset = five ? Number(five.resets_at) : 0
                    }
                    if (!root.noWeek) {
                        root.week = week ? Math.round(week.used) : -1
                        root.weekReset = week ? Number(week.resets_at) : 0
                    }
                } catch (e) { }
            }
            root.loaded = true
        }
    }

    // A window that has already reset reads as empty until Claude Code reports again.
    function shown(pct, reset) { return pct < 0 ? -1 : (reset > 0 && root.nowSec >= reset ? 0 : pct) }
    function until(reset, roomy) {
        if (reset <= 0) return ""
        const s = reset - root.nowSec
        if (s <= 0) return "window has reset"
        const time = Qt.formatDateTime(new Date(reset * 1000), Qt.locale().timeFormat(Locale.ShortFormat))
        if (s >= 172800) return "resets " + Qt.formatDateTime(new Date(reset * 1000), "dddd") + (roomy ? ", " + time : "")
        if (s >= 86400) return "resets tomorrow, " + time
        const h = Math.floor(s / 3600), m = Math.floor((s % 3600) / 60)
        return h > 0 ? "resets in " + h + " h " + m + " min" : "resets in " + Math.max(1, m) + " min"
    }
    function tone(pct) {
        const c = Plasmoid.configuration
        if (!c.warnColours) return colors.foreground
        return pct >= c.alertAt ? root.bad : (pct >= c.warnAt ? root.warn : colors.foreground)
    }

    fullRepresentation: Item {
        id: full

        Layout.preferredWidth: full.width > 0 ? full.width : 368
        Layout.preferredHeight: full.height > 0 ? full.height : 144
        Layout.minimumWidth: 288
        Layout.minimumHeight: 112

        readonly property real u: Math.min(height / 144, width / 368)
        readonly property real pad: Math.round(20 * u)
        readonly property real small: Math.max(10, Math.round(12 * u))
        readonly property real big: Math.round(34 * u)

        // How far the card has gone over to one window: 0 is two columns, 1 that window alone.
        property real fiveOnly: root.noWeek ? 1 : 0
        property real weekOnly: root.noFiveHour ? 1 : 0
        // the column that leaves is gone before the other one slides over it
        readonly property real fiveShown: 1 - Math.min(1, weekOnly * 2.5)
        readonly property real weekShown: 1 - Math.min(1, fiveOnly * 2.5)
        Behavior on fiveOnly {
            enabled: root.loaded
            NumberAnimation { duration: Kirigami.Units.veryLongDuration * 0.75; easing.type: Easing.OutCubic }
        }
        Behavior on weekOnly {
            enabled: root.loaded
            NumberAnimation { duration: Kirigami.Units.veryLongDuration * 0.75; easing.type: Easing.OutCubic }
        }

        LiquidGlass {
            anchors.fill: parent
            radius: Plasmoid.configuration.cornerRadius
            roundness: Plasmoid.configuration.roundnessX10 / 10
            refractThickness: Plasmoid.configuration.refractThickness
            refractIOR: Plasmoid.configuration.refractIORx100 / 100
            refractScale: Plasmoid.configuration.refractScale
            tint: colors.glassTint
            tintAlpha: Plasmoid.configuration.tintAlphaPct / 100
            chromaStrength: Plasmoid.configuration.chromaStrengthPct / 100
            specStrength: Plasmoid.configuration.specStrengthPct / 100
            blurRadius: Plasmoid.configuration.blurRadiusPx
            realtimeRefraction: Plasmoid.configuration.realtimeRefraction
            fallbackOpacity: colors.glassFallbackOpacity
            solidMode: colors.isSolid
            solidColor: colors.solidBackground
        }

        component Window: Item {
            id: w
            property string label
            property int pct: -1

            Column {
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: 0

                Text {
                    text: w.label
                    color: colors.foreground
                    opacity: 0.62
                    font.family: root.face
                    font.pixelSize: full.small
                    font.weight: Font.Medium
                }
                Row {
                    spacing: Math.round(3 * full.u)
                    SwapText {
                        id: figure
                        text: w.pct < 0 ? "–" : w.pct.toString()
                        color: colors.foreground
                        font.family: root.face
                        font.pixelSize: full.big
                        font.weight: Font.ExtraLight
                        font.features: { "tnum": 1 }
                    }
                    Text {
                        visible: w.pct >= 0
                        text: "%"
                        color: colors.foreground
                        opacity: 0.62
                        font.family: root.face
                        font.pixelSize: Math.round(full.big * 0.42)
                        font.weight: Font.Medium
                        anchors.baseline: figure.baseline
                    }
                }
                Item { width: 1; height: Math.round(6 * full.u) }
                Rectangle {
                    width: parent.width
                    height: Math.max(3, Math.round(4 * full.u))
                    radius: height / 2
                    color: Qt.rgba(colors.foreground.r, colors.foreground.g, colors.foreground.b, 0.2)
                    Rectangle {
                        // moves with the figure; when the column changes width it simply keeps its share
                        property real share: Math.max(0, Math.min(1, w.pct / 100))
                        visible: w.pct > 0
                        width: Math.max(parent.height, Math.round(parent.width * share))
                        height: parent.height
                        radius: height / 2
                        color: root.tone(w.pct)
                        Behavior on share { NumberAnimation { duration: Kirigami.Units.veryLongDuration; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: Kirigami.Units.veryLongDuration } }
                    }
                }
            }
        }

        Item {
            id: cols
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: full.pad
            anchors.topMargin: Math.round(15 * full.u)
            height: Math.round(70 * full.u)

            readonly property real gap: Math.round(28 * full.u)
            readonly property real half: (width - gap) / 2

            Window {
                width: Math.round(cols.half + (cols.width - cols.half) * full.fiveOnly)
                height: parent.height
                opacity: full.fiveShown
                visible: opacity > 0
                label: "Claude · 5-hour"
                pct: root.shown(root.fiveHour, root.fiveHourReset)
            }
            Window {
                x: Math.round((cols.half + cols.gap) * (1 - full.weekOnly))
                width: Math.round(cols.half + (cols.width - cols.half) * full.weekOnly)
                height: parent.height
                opacity: full.weekShown
                visible: opacity > 0
                label: "Claude · week"
                pct: root.shown(root.week, root.weekReset)
            }
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: footer.top
            anchors.leftMargin: full.pad
            anchors.rightMargin: full.pad
            anchors.bottomMargin: Math.round(10 * full.u)
            height: 1
            color: Qt.rgba(colors.foreground.r, colors.foreground.g, colors.foreground.b, 0.16)
        }

        Item {
            id: footer
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: full.pad
            anchors.rightMargin: full.pad
            anchors.bottomMargin: Math.round(16 * full.u)
            height: Math.round(16 * full.u)

            // a window alone may use the width the "no … limit" note leaves free
            readonly property real extra: footer.width - cols.half - absent.implicitWidth - cols.gap

            component Note: Text {
                elide: Text.ElideRight
                color: colors.foreground
                font.family: root.face
                font.pixelSize: full.small
                font.weight: Font.Medium
                font.features: { "tnum": 1 }
                anchors.verticalCenter: parent.verticalCenter
            }
            Note {
                width: root.connected ? cols.half + footer.extra * full.fiveOnly : footer.width
                opacity: 0.8 * full.fiveShown
                visible: opacity > 0
                text: root.fiveHour < 0 ? root.waiting : root.until(root.fiveHourReset)
            }
            Note {
                x: Math.round((cols.half + cols.gap) * (1 - full.weekOnly))
                width: cols.half + footer.extra * full.weekOnly
                opacity: 0.8 * full.weekShown
                visible: root.connected && opacity > 0
                text: root.week < 0 ? "" : root.until(root.weekReset, root.noFiveHour)
            }
            // says which limit is missing, so one figure on the card does not read as a fault
            Note {
                id: absent
                anchors.right: parent.right
                opacity: 0.62 * Math.max(full.fiveOnly, full.weekOnly)
                visible: opacity > 0
                text: full.fiveOnly > 0 ? "no weekly limit" : "no 5-hour limit"
            }
        }
    }
}

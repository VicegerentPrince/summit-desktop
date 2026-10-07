/*
    Claude plan usage: the 5-hour and weekly windows.

    The numbers come from ~/.cache/summit/claude-usage.json, which the Claude Code status line
    script (~/.claude/statusline.sh) writes from the data Claude Code hands it. This widget
    reads that file once a minute. It makes no network requests and reads no credentials.
*/
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support
import "components"

PlasmoidItem {
    id: root

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: fullRepresentation

    width: 368
    height: 144

    readonly property string face: "Inter Display"
    readonly property string command: "cat \"${XDG_CACHE_HOME:-$HOME/.cache}/summit/claude-usage.json\" 2>/dev/null; echo"

    property int fiveHour: -1
    property real fiveHourReset: 0
    property int week: -1
    property real weekReset: 0
    property real nowSec: Date.now() / 1000

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
            if (text === "") return
            try {
                const j = JSON.parse(text)
                root.fiveHour = j.five_hour ? Math.round(j.five_hour.used) : -1
                root.fiveHourReset = j.five_hour ? Number(j.five_hour.resets_at) : 0
                root.week = j.seven_day ? Math.round(j.seven_day.used) : -1
                root.weekReset = j.seven_day ? Number(j.seven_day.resets_at) : 0
            } catch (e) { }
        }
    }

    // A window that has already reset reads as empty until Claude Code reports again.
    function shown(pct, reset) { return pct < 0 ? -1 : (reset > 0 && root.nowSec >= reset ? 0 : pct) }
    function until(reset) {
        if (reset <= 0) return ""
        const s = reset - root.nowSec
        if (s <= 0) return "window has reset"
        if (s >= 172800) return "resets " + Qt.formatDateTime(new Date(reset * 1000), "dddd")
        if (s >= 86400) return "resets tomorrow, " + Qt.formatDateTime(new Date(reset * 1000), Qt.locale().timeFormat(Locale.ShortFormat))
        const h = Math.floor(s / 3600), m = Math.floor((s % 3600) / 60)
        return h > 0 ? "resets in " + h + " h " + m + " min" : "resets in " + Math.max(1, m) + " min"
    }
    function tone(pct) { return pct >= 90 ? root.bad : (pct >= 70 ? root.warn : colors.foreground) }

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
            property string caption

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
                    Text {
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
                        visible: w.pct > 0
                        width: Math.max(parent.height, Math.round(parent.width * Math.min(1, w.pct / 100)))
                        height: parent.height
                        radius: height / 2
                        color: root.tone(w.pct)
                    }
                }
            }
        }

        Row {
            id: cols
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: full.pad
            anchors.topMargin: Math.round(15 * full.u)
            height: Math.round(70 * full.u)
            spacing: Math.round(28 * full.u)

            readonly property real colWidth: (width - spacing) / 2

            Window {
                width: cols.colWidth
                height: parent.height
                label: "Claude · 5-hour"
                pct: root.shown(root.fiveHour, root.fiveHourReset)
                caption: root.fiveHour < 0 ? "updates when Claude Code runs" : root.until(root.fiveHourReset)
            }
            Window {
                width: cols.colWidth
                height: parent.height
                label: "Claude · week"
                pct: root.shown(root.week, root.weekReset)
                caption: root.week < 0 ? "" : root.until(root.weekReset)
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

        Row {
            id: footer
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: full.pad
            anchors.rightMargin: full.pad
            anchors.bottomMargin: Math.round(16 * full.u)
            height: Math.round(16 * full.u)
            spacing: cols.spacing

            component Note: Text {
                width: cols.colWidth
                elide: Text.ElideRight
                color: colors.foreground
                opacity: 0.8
                font.family: root.face
                font.pixelSize: full.small
                font.weight: Font.Medium
                font.features: { "tnum": 1 }
                anchors.verticalCenter: parent.verticalCenter
            }
            Note { text: root.fiveHour < 0 ? "updates when Claude Code runs" : root.until(root.fiveHourReset) }
            Note { text: root.week < 0 ? "" : root.until(root.weekReset) }
        }
    }
}

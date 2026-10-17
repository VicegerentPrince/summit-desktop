/*
    Projects: the repositories you worked in last and your week in commits.

    Top: how many commits you made in the last seven days, with a bar per day stacked by project.
    Below: the four projects you touched last, each on its own colour tile, with the branch and
    badges for uncommitted changes and for commits no remote has yet. Click a project for a
    terminal there; on hover a VS Code button opens it in the editor.

    The data comes from contents/code/projects.py once a minute, and again when the pointer comes
    onto the card after a pause. It runs git read-only (no index rewrites) and never the network.

    Performance rule: nothing animates on its own. Hover and press feedback are short and only
    run while you interact.
*/
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami
import "components"
import "parts"
import "parts/palette.js" as Palette

PlasmoidItem {
    id: root

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: fullRepresentation

    width: 368
    height: 368

    readonly property string face: "Inter Display"
    readonly property int count: 4
    readonly property string helper: decodeURIComponent(Qt.resolvedUrl("../code/projects.py").toString().replace(/^file:\/\//, ""))
    readonly property string listCommand: "python3 -I " + quote(helper) + " " + count

    property var projects: []
    property var week: ({ total: 0, projects: [], start: 0 })
    property bool loaded: false
    property real fetchedAt: 0
    property real nowSec: Date.now() / 1000

    readonly property color warn: "#FF9F0A"
    readonly property color bad: "#FF453A"
    readonly property color good: "#30D158"

    MacOSColors {
        id: colors
        styleMode: Plasmoid.configuration.styleMode
        appearance: Plasmoid.configuration.appearance
    }

    function quote(s) { return "'" + String(s).replace(/'/g, "'\\''") + "'" }

    P5Support.DataSource {
        id: lister
        engine: "executable"
        connectedSources: [root.listCommand]
        interval: 60000
        onNewData: (source, data) => {
            root.nowSec = Date.now() / 1000
            const text = (data["stdout"] || "").trim()
            if (text === "") return
            try {
                const j = JSON.parse(text)
                root.projects = j.projects || []
                root.week = j.week || { total: 0, projects: [], start: 0 }
                root.loaded = true
                root.fetchedAt = root.nowSec
            } catch (e) { }
        }
    }
    function refresh() {
        lister.disconnectSource(root.listCommand)
        lister.connectSource(root.listCommand)
    }

    P5Support.DataSource {
        id: launcher
        engine: "executable"
        onNewData: (source) => disconnectSource(source)
    }
    function openTerminal(path) { launcher.connectSource("setsid -f kitty --directory " + quote(path) + " >/dev/null 2>&1 || setsid -f konsole --workdir " + quote(path) + " >/dev/null 2>&1") }
    function openEditor(path)   { launcher.connectSource("setsid -f code " + quote(path) + " >/dev/null 2>&1") }

    function ago(t) {
        if (!t) return ""
        const s = Math.max(0, root.nowSec - t)
        if (s < 3600) return Math.max(1, Math.floor(s / 60)) + "m ago"
        if (s < 86400) return Math.floor(s / 3600) + "h ago"
        if (s < 86400 * 30) return Math.floor(s / 86400) + "d ago"
        return Qt.formatDate(new Date(t * 1000), "MMM d")
    }
    function changes(p) { return (p.changed || 0) + (p.untracked || 0) }
    function toPush(p) { return p.ahead || 0 }

    // The header says the one thing worth knowing first.
    readonly property int pushCount: projects.filter(p => toPush(p) > 0).length
    readonly property int dirtyCount: projects.filter(p => toPush(p) === 0 && changes(p) > 0).length

    // Seven days, today last; each bar stacks the projects in their tile colours.
    readonly property var dayTotals: {
        const t = [0, 0, 0, 0, 0, 0, 0]
        for (const p of (week.projects || [])) for (let i = 0; i < 7; i++) t[i] += p.counts[i]
        return t
    }
    readonly property int dayMax: Math.max(1, Math.max.apply(null, dayTotals))
    function dayLetter(i) {
        if (!week.start) return ""
        return Qt.formatDate(new Date((week.start + i * 86400 + 43200) * 1000), "ddd").charAt(0)
    }

    fullRepresentation: Item {
        id: full

        Layout.preferredWidth: full.width > 0 ? full.width : 368
        Layout.preferredHeight: full.height > 0 ? full.height : 368
        Layout.minimumWidth: 300
        Layout.minimumHeight: 300

        // Designed at 368 x 368; everything scales from that, like the cards beside it.
        readonly property real u: Math.min(height / 368, width / 368)
        readonly property real pad: Math.round(20 * u)
        readonly property real small: Math.max(10, Math.round(12 * u))
        readonly property real title: Math.round(14.5 * u)
        // Rows sit inside the card's curve: their corners are the card's corner minus the inset.
        readonly property real rowRadius: Math.round(18 * u)

        HoverHandler {
            onHoveredChanged: if (hovered && Date.now() / 1000 - root.fetchedAt > 15) root.refresh()
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

        // --- Header: what this is, and the one thing that needs you.
        Item {
            id: header
            x: full.pad
            y: Math.round(18 * full.u)
            width: parent.width - 2 * full.pad
            height: Math.round(22 * full.u)

            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: Math.round(7 * full.u)
                Glyph {
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.round(15 * full.u); height: width
                    name: "repo"
                    color: Kirigami.Theme.highlightColor
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Projects"
                    color: colors.foreground
                    opacity: 0.9
                    font.family: root.face
                    font.pixelSize: Math.round(13 * full.u)
                    font.weight: Font.DemiBold
                }
            }
            Capsule {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                visible: root.loaded && (root.pushCount > 0 || root.dirtyCount > 0)
                size: Math.max(10, Math.round(11 * full.u))
                face: root.face
                glyph: root.pushCount > 0 ? "arrow-up" : "pencil"
                tone: root.pushCount > 0 ? root.bad : root.warn
                text: root.pushCount > 0 ? root.pushCount + " to push" : root.dirtyCount + " with changes"
            }
            Capsule {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                visible: root.loaded && root.pushCount === 0 && root.dirtyCount === 0 && root.projects.length > 0
                size: Math.max(10, Math.round(11 * full.u))
                face: root.face
                glyph: "check-circle-fill"
                tone: root.good
                text: "all pushed"
            }
        }

        // --- Hero: the week in commits.
        Item {
            id: hero
            x: full.pad
            anchors.top: header.bottom
            anchors.topMargin: Math.round(12 * full.u)
            width: parent.width - 2 * full.pad
            height: Math.round(62 * full.u)

            Column {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 0
                Text {
                    text: root.loaded ? root.week.total.toLocaleString(Qt.locale(), "f", 0) : "–"
                    color: colors.foreground
                    font.family: root.face
                    font.pixelSize: Math.round(36 * full.u)
                    font.weight: Font.ExtraLight
                    font.letterSpacing: -0.02 * Math.round(36 * full.u)   // tight tracking for display size
                    font.features: { "tnum": 1 }
                }
                Text {
                    text: root.week.total === 1 ? "commit this week" : "commits this week"
                    color: colors.foreground
                    opacity: 0.62
                    font.family: root.face
                    font.pixelSize: full.small
                    font.weight: Font.Medium
                }
            }

            // One canvas for the seven bars: each is a rounded track, filled from the bottom with the
            // day's commits stacked by project in their tile colours, clipped to the bar's round ends.
            // Painted only when the numbers change.
            Column {
                id: chart
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                spacing: Math.round(5 * full.u)
                readonly property real barW: Math.round(10 * full.u)
                readonly property real gap: Math.round(7 * full.u)
                readonly property real barH: Math.round(40 * full.u)

                Canvas {
                    id: bars
                    width: 7 * chart.barW + 6 * chart.gap
                    height: chart.barH
                    readonly property var totals: root.dayTotals
                    readonly property var stack: root.week.projects || []
                    readonly property color track: Qt.rgba(colors.foreground.r, colors.foreground.g, colors.foreground.b, 0.10)
                    onTotalsChanged: requestPaint()
                    onStackChanged: requestPaint()
                    onWidthChanged: requestPaint()
                    function pill(ctx, x, y, w, h) {
                        const r = w / 2
                        ctx.beginPath()
                        ctx.moveTo(x, y + r)
                        ctx.arc(x + r, y + r, r, Math.PI, 0, false)
                        ctx.lineTo(x + w, y + h - r)
                        ctx.arc(x + r, y + h - r, r, 0, Math.PI, false)
                        ctx.closePath()
                    }
                    onPaint: {
                        const ctx = getContext("2d")
                        ctx.reset()
                        for (let i = 0; i < 7; i++) {
                            const x = i * (chart.barW + chart.gap)
                            pill(ctx, x, 0, chart.barW, chart.barH)
                            ctx.fillStyle = track
                            ctx.fill()
                            const total = totals[i]
                            if (!total) continue
                            const h = Math.max(chart.barW, chart.barH * total / root.dayMax)
                            ctx.save()
                            pill(ctx, x, chart.barH - h, chart.barW, h)
                            ctx.clip()
                            let y = chart.barH
                            for (const p of stack) {
                                const seg = h * p.counts[i] / total
                                if (seg <= 0) continue
                                ctx.fillStyle = Palette.forName(p.name)
                                ctx.fillRect(x, y - seg, chart.barW, seg + 0.5)
                                y -= seg
                            }
                            ctx.restore()
                        }
                    }
                }
                Row {
                    spacing: chart.gap
                    Repeater {
                        model: 7
                        delegate: Text {
                            required property int index
                            width: chart.barW
                            horizontalAlignment: Text.AlignHCenter
                            text: root.dayLetter(index)
                            color: colors.foreground
                            opacity: index === 6 ? 0.9 : 0.4
                            font.family: root.face
                            font.pixelSize: Math.max(9, Math.round(10 * full.u))
                            font.weight: index === 6 ? Font.DemiBold : Font.Medium
                        }
                    }
                }
            }
        }

        // --- The projects.
        Column {
            id: list
            anchors.top: hero.bottom
            anchors.topMargin: Math.round(12 * full.u)
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: Math.round(10 * full.u)
            anchors.rightMargin: Math.round(10 * full.u)
            anchors.bottomMargin: Math.round(10 * full.u)
            spacing: Math.round(2 * full.u)

            readonly property real rowHeight: (height - spacing * (root.count - 1)) / root.count

            Repeater {
                model: root.projects
                delegate: Item {
                    id: row
                    required property var modelData
                    readonly property var p: modelData
                    readonly property bool hot: area.containsMouse || editorArea.containsMouse
                    width: list.width
                    height: list.rowHeight

                    // Answered on press, settled back like a critically damped spring (~0.3 s).
                    scale: area.pressed ? 0.975 : 1.0
                    Behavior on scale { NumberAnimation { duration: area.pressed ? 90 : 280; easing.type: Easing.OutCubic } }

                    Rectangle {
                        anchors.fill: parent
                        radius: full.rowRadius
                        color: colors.cardBackground
                        opacity: area.pressed ? colors.cardPressOpacity : (row.hot ? colors.cardHoverOpacity : 0)
                        Behavior on opacity { NumberAnimation { duration: 120 } }
                    }
                    MouseArea {
                        id: area
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.openTerminal(row.p.path)
                    }

                    Tile {
                        id: tile
                        anchors.left: parent.left
                        anchors.leftMargin: Math.round(10 * full.u)
                        anchors.verticalCenter: parent.verticalCenter
                        width: Math.round(32 * full.u); height: width
                        label: row.p.name
                        face: root.face
                    }

                    Column {
                        anchors.left: tile.right
                        anchors.leftMargin: Math.round(11 * full.u)
                        anchors.right: trailing.left
                        anchors.rightMargin: Math.round(8 * full.u)
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Math.round(2 * full.u)

                        Text {
                            width: parent.width
                            elide: Text.ElideRight
                            text: row.p.name
                            color: colors.foreground
                            font.family: root.face
                            font.pixelSize: full.title
                            font.weight: Font.DemiBold
                            font.letterSpacing: -0.1
                        }
                        Row {
                            width: parent.width
                            spacing: Math.round(4 * full.u)
                            clip: true
                            Glyph {
                                anchors.verticalCenter: parent.verticalCenter
                                width: Math.round(11 * full.u); height: width
                                name: "git-branch"
                                color: colors.foreground
                                opacity: 0.55
                                visible: !row.p.error
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                width: Math.min(implicitWidth, parent.width * 0.6)
                                elide: Text.ElideRight
                                text: row.p.error ? "can't read this repository" : row.p.branch
                                color: colors.foreground
                                opacity: 0.62
                                font.family: root.face
                                font.pixelSize: full.small
                                font.weight: Font.Medium
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "·  " + root.ago(row.p.active_time)
                                color: colors.foreground
                                opacity: 0.4
                                font.family: root.face
                                font.pixelSize: full.small
                                font.weight: Font.Medium
                                font.features: { "tnum": 1 }
                            }
                        }
                    }

                    // At rest: the project's state as badges. On hover: the two ways to open it.
                    Item {
                        id: trailing
                        anchors.right: parent.right
                        anchors.rightMargin: Math.round(10 * full.u)
                        anchors.verticalCenter: parent.verticalCenter
                        width: Math.max(badges.implicitWidth, actions.implicitWidth)
                        height: Math.round(28 * full.u)

                        Row {
                            id: badges
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Math.round(5 * full.u)
                            visible: !row.hot
                            readonly property real s: Math.max(10, Math.round(11 * full.u))
                            Capsule {
                                visible: !row.p.error && root.changes(row.p) > 0
                                size: badges.s; face: root.face; tone: root.warn
                                glyph: "pencil"; text: root.changes(row.p)
                            }
                            Capsule {
                                visible: !row.p.error && root.toPush(row.p) > 0
                                size: badges.s; face: root.face; tone: root.bad
                                glyph: "arrow-up"; text: root.toPush(row.p)
                            }
                            Capsule {
                                visible: !row.p.error && !row.p.remote
                                size: badges.s; face: root.face
                                tone: Qt.rgba(colors.foreground.r, colors.foreground.g, colors.foreground.b, 0.8)
                                text: "local"
                            }
                            Glyph {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: !row.p.error && row.p.remote && root.changes(row.p) === 0 && root.toPush(row.p) === 0
                                width: Math.round(15 * full.u); height: width
                                name: "check-circle-fill"
                                color: root.good
                                opacity: 0.85
                            }
                        }

                        Row {
                            id: actions
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Math.round(6 * full.u)
                            visible: row.hot
                            Kirigami.Icon {
                                anchors.verticalCenter: parent.verticalCenter
                                width: Math.round(16 * full.u); height: width
                                source: "utilities-terminal"
                                opacity: 0.85
                            }
                            Rectangle {
                                width: Math.round(28 * full.u); height: width; radius: width / 2
                                color: Qt.rgba(1, 1, 1, editorArea.pressed ? 0.30 : (editorArea.containsMouse ? 0.22 : 0.12))
                                Kirigami.Icon {
                                    anchors.centerIn: parent
                                    width: Math.round(16 * full.u); height: width
                                    source: "com.microsoft.VSCode"
                                    scale: editorArea.pressed ? 0.88 : 1.0
                                    Behavior on scale { NumberAnimation { duration: editorArea.pressed ? 90 : 240; easing.type: Easing.OutCubic } }
                                }
                                MouseArea {
                                    id: editorArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.openEditor(row.p.path)
                                }
                            }
                        }
                    }
                }
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: hero.bottom
            anchors.topMargin: Math.round(40 * full.u)
            visible: root.loaded && root.projects.length === 0
            width: parent.width - 2 * full.pad
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            text: "No git projects in ~/Documents/Projects yet"
            color: colors.foreground
            opacity: 0.45
            font.family: root.face
            font.pixelSize: full.small
            font.weight: Font.Medium
        }
    }
}

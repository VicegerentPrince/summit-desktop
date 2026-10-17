/*
    GitHub: the build status of the repositories you pushed to last, your open pull requests with
    their checks, reviews asked of you, and the notifications that are about you (CI noise left out).

    Data comes from contents/code/github.py through your GitHub CLI login: at start from its cache
    (instant), then from GitHub every five minutes and when the pointer comes onto the card after
    two minutes. Offline, the last good answer stays with a note saying how old it is.

    Performance rule: nothing animates on its own; feedback runs only while you interact.
*/
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support
import "components"
import "parts"
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: fullRepresentation

    width: 368
    height: 560

    readonly property string face: "Inter Display"
    readonly property string helper: decodeURIComponent(Qt.resolvedUrl("../code/github.py").toString().replace(/^file:\/\//, ""))
    readonly property string cachedCommand: "python3 -I " + quote(helper) + " --cached"
    readonly property string liveCommand: "python3 -I " + quote(helper)

    property var data: ({})
    property real askedAt: 0
    property real nowSec: Date.now() / 1000

    readonly property color warn: "#FF9F0A"
    readonly property color bad: "#FF453A"
    readonly property color good: "#30D158"
    readonly property color info: "#64D2FF"

    MacOSColors {
        id: colors
        styleMode: Plasmoid.configuration.styleMode
        appearance: Plasmoid.configuration.appearance
    }

    function quote(s) { return "'" + String(s).replace(/'/g, "'\\''") + "'" }

    function take(text) {
        root.nowSec = Date.now() / 1000
        text = (text || "").trim()
        if (text === "") return
        try {
            const j = JSON.parse(text)
            if (j.updated || j.error) root.data = j
        } catch (e) { }
    }
    P5Support.DataSource {
        id: cache
        engine: "executable"
        connectedSources: [root.cachedCommand]
        onNewData: (source, d) => { if (!root.data.updated) root.take(d["stdout"]); disconnectSource(source) }
    }
    P5Support.DataSource {
        id: live
        engine: "executable"
        connectedSources: [root.liveCommand]
        interval: 300000
        onNewData: (source, d) => root.take(d["stdout"])
    }
    function refresh() {
        root.askedAt = Date.now() / 1000
        live.disconnectSource(root.liveCommand)
        live.connectSource(root.liveCommand)
    }
    Component.onCompleted: askedAt = Date.now() / 1000

    function ago(t) {
        if (!t) return ""
        const s = Math.max(0, root.nowSec - t)
        if (s < 3600) return Math.max(1, Math.floor(s / 60)) + "m"
        if (s < 86400) return Math.floor(s / 3600) + "h"
        if (s < 86400 * 30) return Math.floor(s / 86400) + "d"
        return Qt.formatDate(new Date(t * 1000), "MMM d")
    }
    function buildColor(b) { return b.state === "failed" ? bad : (b.state === "running" ? warn : good) }
    function buildLine(b) { return (b.workflow || "build") + (b.branch ? "  ·  " + b.branch : "") + "  ·  " + ago(b.time) }
    function buildGlyph(b) { return b.state === "failed" ? "x-circle-fill" : (b.state === "running" ? "clock-fill" : "check-circle-fill") }
    function buildBadge(b) { return b.state === "failed" ? (b.failing > 1 ? b.failing + " failing" : "failed") : b.state }
    function prColor(p) {
        if (p.kind === "review") return info
        return p.checks === "failure" || p.checks === "error" ? bad
             : (p.checks === "pending" || p.checks === "expected" ? warn
             : (p.checks === "success" ? good : Qt.rgba(colors.foreground.r, colors.foreground.g, colors.foreground.b, 0.35)))
    }
    function prLine(p) { return p.repo + "  ·  #" + p.number + (p.draft ? "  ·  draft" : "") + "  ·  " + ago(p.time) }
    function prBadge(p) {
        if (p.kind === "review") return "review"
        if (p.review === "APPROVED") return "approved"
        if (p.review === "CHANGES_REQUESTED") return "changes"
        if (p.checks === "failure" || p.checks === "error") return "failing"
        if (p.checks === "pending" || p.checks === "expected") return "running"
        if (p.checks === "success") return "passing"
        return ""
    }
    function prTone(p) {
        if (p.kind === "review") return info
        if (p.review === "CHANGES_REQUESTED") return warn
        return prColor(p)
    }

    fullRepresentation: Item {
        id: full

        Layout.preferredWidth: full.width > 0 ? full.width : 368
        Layout.preferredHeight: full.height > 0 ? full.height : 560
        Layout.minimumWidth: 288
        Layout.minimumHeight: 400

        readonly property real u: Math.min(height / 560, width / 368)
        readonly property real pad: Math.round(20 * u)
        readonly property real small: Math.max(10, Math.round(12 * u))
        readonly property real title: Math.round(14.5 * u)
        readonly property real rowHeight: Math.round(48 * u)
        readonly property real rowRadius: Math.round(18 * u)

        HoverHandler {
            onHoveredChanged: if (hovered && Date.now() / 1000 - root.askedAt > 120) root.refresh()
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

        component Label: Text {
            color: colors.foreground
            opacity: 0.62
            font.family: root.face
            font.pixelSize: full.small
            font.weight: Font.Medium
        }

        component Entry: Item {
            id: e
            property string heading
            property string line
            property string url
            // leading: a repository tile with a status badge, or a glyph on a tinted disc
            property string tileFor: ""
            property string badge: ""
            property color tone: colors.foreground
            property string glyph: ""
            // trailing pill
            property string pill: ""
            property string pillGlyph: ""

            width: parent ? parent.width : 0
            height: full.rowHeight
            scale: area.pressed ? 0.975 : 1.0
            Behavior on scale { NumberAnimation { duration: area.pressed ? 90 : 280; easing.type: Easing.OutCubic } }

            Rectangle {
                anchors.fill: parent
                radius: full.rowRadius
                color: colors.cardBackground
                opacity: area.pressed ? colors.cardPressOpacity : (area.containsMouse ? colors.cardHoverOpacity : 0)
                Behavior on opacity { NumberAnimation { duration: 120 } }
            }
            MouseArea {
                id: area
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: e.url ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: if (e.url) Qt.openUrlExternally(e.url)
            }
            Item {
                id: lead
                anchors.left: parent.left
                anchors.leftMargin: Math.round(10 * full.u)
                anchors.verticalCenter: parent.verticalCenter
                width: Math.round(32 * full.u); height: width
                Tile {
                    anchors.fill: parent
                    visible: e.tileFor !== ""
                    label: e.tileFor
                    face: root.face
                    badge: e.badge
                    badgeColor: e.tone
                }
                Rectangle {
                    anchors.fill: parent
                    visible: e.tileFor === ""
                    radius: width / 2
                    color: Qt.rgba(e.tone.r, e.tone.g, e.tone.b, 0.18)
                    Glyph {
                        anchors.centerIn: parent
                        width: Math.round(16 * full.u); height: width
                        name: e.glyph
                        color: e.tone
                    }
                }
            }
            Column {
                anchors.left: lead.right
                anchors.leftMargin: Math.round(11 * full.u)
                anchors.right: pillItem.visible ? pillItem.left : parent.right
                anchors.rightMargin: Math.round(10 * full.u)
                anchors.verticalCenter: parent.verticalCenter
                spacing: Math.round(2 * full.u)
                Text {
                    width: parent.width
                    elide: Text.ElideRight
                    text: e.heading
                    color: colors.foreground
                    font.family: root.face
                    font.pixelSize: full.title
                    font.weight: Font.DemiBold
                    font.letterSpacing: -0.1
                }
                Text {
                    width: parent.width
                    elide: Text.ElideRight
                    text: e.line
                    color: colors.foreground
                    opacity: 0.6
                    font.family: root.face
                    font.pixelSize: full.small
                    font.weight: Font.Medium
                }
            }
            Capsule {
                id: pillItem
                anchors.right: parent.right
                anchors.rightMargin: Math.round(10 * full.u)
                anchors.verticalCenter: parent.verticalCenter
                visible: e.pill !== ""
                size: Math.max(10, Math.round(11 * full.u))
                face: root.face
                tone: e.tone
                glyph: e.pillGlyph
                text: e.pill
            }
        }

        Column {
            anchors.fill: parent
            visible: !!root.data.updated
            anchors.leftMargin: Math.round(10 * full.u)
            anchors.rightMargin: Math.round(10 * full.u)
            anchors.topMargin: Math.round(18 * full.u)
            spacing: 0

            Item {
                width: parent.width
                height: Math.round(18 * full.u)
                Row {
                    x: Math.round(10 * full.u)
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Math.round(7 * full.u)
                    Glyph {
                        anchors.verticalCenter: parent.verticalCenter
                        width: Math.round(15 * full.u); height: width
                        name: "mark-github"
                        color: colors.foreground
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "GitHub"
                        color: colors.foreground
                        opacity: 0.9
                        font.family: root.face
                        font.pixelSize: Math.round(13 * full.u)
                        font.weight: Font.DemiBold
                    }
                }
                Capsule {
                    readonly property int n: root.data.notifications ? root.data.notifications.about_you : 0
                    anchors.right: parent.right
                    anchors.rightMargin: Math.round(10 * full.u)
                    anchors.verticalCenter: parent.verticalCenter
                    visible: n > 0
                    size: Math.max(10, Math.round(11 * full.u))
                    face: root.face
                    tone: root.info
                    glyph: "bell"
                    text: n + " for you"
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Qt.openUrlExternally("https://github.com/notifications")
                    }
                }
            }

            Item { width: 1; height: Math.round(10 * full.u) }
            Label { x: Math.round(10 * full.u); text: "Builds"; font.pixelSize: Math.max(10, Math.round(11.5 * full.u)); font.weight: Font.DemiBold; opacity: 0.5 }
            Item { width: 1; height: Math.round(2 * full.u) }
            Repeater {
                model: root.data.builds || []
                delegate: Entry {
                    required property var modelData
                    tileFor: modelData.repo
                    badge: root.buildGlyph(modelData)
                    tone: root.buildColor(modelData)
                    heading: modelData.repo
                    line: root.buildLine(modelData)
                    pill: root.buildBadge(modelData)
                    url: modelData.url
                }
            }
            Label {
                x: Math.round(10 * full.u)
                visible: !!root.data.updated && (root.data.builds || []).length === 0
                height: full.rowHeight
                verticalAlignment: Text.AlignVCenter
                text: "No builds in your recent repositories"
                opacity: 0.45
            }

            Item { width: 1; height: Math.round(10 * full.u) }
            Label { x: Math.round(10 * full.u); text: "Pull requests"; font.pixelSize: Math.max(10, Math.round(11.5 * full.u)); font.weight: Font.DemiBold; opacity: 0.5 }
            Item { width: 1; height: Math.round(2 * full.u) }
            Repeater {
                model: (root.data.prs || []).slice(0, 3)
                delegate: Entry {
                    required property var modelData
                    glyph: "git-pull-request"
                    tone: root.prTone(modelData)
                    heading: modelData.title
                    line: root.prLine(modelData)
                    pill: root.prBadge(modelData)
                    url: modelData.url
                }
            }
            Label {
                x: Math.round(10 * full.u)
                visible: !!root.data.updated && (root.data.prs || []).length === 0
                height: full.rowHeight
                verticalAlignment: Text.AlignVCenter
                text: "No open pull requests"
                opacity: 0.45
            }

            Item { width: 1; height: Math.round(10 * full.u) }
            Label { x: Math.round(10 * full.u); text: "For you"; font.pixelSize: Math.max(10, Math.round(11.5 * full.u)); font.weight: Font.DemiBold; opacity: 0.5 }
            Item { width: 1; height: Math.round(2 * full.u) }
            Repeater {
                model: root.data.for_you || []
                delegate: Entry {
                    required property var modelData
                    glyph: modelData.reason.indexOf("mention") >= 0 ? "mention" : "comment"
                    tone: root.info
                    heading: modelData.title
                    line: modelData.repo + "  ·  " + modelData.reason + "  ·  " + root.ago(modelData.time)
                    url: modelData.url
                }
            }
            Label {
                x: Math.round(10 * full.u)
                visible: !!root.data.updated && (root.data.for_you || []).length === 0
                height: full.rowHeight
                verticalAlignment: Text.AlignVCenter
                text: "Nothing waiting on you"
                opacity: 0.45
            }
        }

        // Offline with an earlier answer: say how old it is, in one quiet line.
        Label {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: full.pad
            anchors.bottomMargin: Math.round(12 * full.u)
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            visible: !!root.data.error && !!root.data.updated
            text: root.data.error + "  ·  showing " + root.ago(root.data.updated) + " ago"
            opacity: 0.45
            font.pixelSize: Math.max(10, Math.round(11 * full.u))
        }
        // Nothing yet: one centred line, never a stack of empty sections.
        Column {
            anchors.centerIn: parent
            width: parent.width - 2 * full.pad
            visible: !root.data.updated
            spacing: Math.round(6 * full.u)
            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: "GitHub"
                color: colors.foreground
                font.family: root.face
                font.pixelSize: full.title
                font.weight: Font.Medium
            }
            Label {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                text: root.data.error || "Asking GitHub…"
                opacity: 0.6
            }
        }
    }
}

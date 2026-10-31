import QtQuick
import QtQuick.Shapes

// Layout "Ring": the time inside a ring that runs down, as in Apple's Clock, and every preset in
// plain view beside it.
Item {
    id: face
    required property var t
    required property var c
    readonly property real u: Math.min(width / 368, height / 176)
    readonly property real pad: Math.round(20 * u)
    readonly property real ringSize: height - 2 * pad
    readonly property real stroke: Math.max(3, Math.round(5 * u))
    readonly property bool active: t.timerState !== 0
    readonly property real rightX: ringSize + pad + Math.round(18 * u)
    readonly property real rightWidth: width - rightX - pad
    readonly property real btn: Math.round(44 * u)
    readonly property color accent: t.timerState === 2 ? Qt.rgba(1, 1, 1, 0.62) : "#FF9F0A"

    Shape {
        id: ring
        x: face.pad
        y: face.pad
        width: face.ringSize
        height: face.ringSize
        preferredRendererType: Shape.CurveRenderer
        readonly property real r: (width - face.stroke) / 2
        ShapePath {
            fillColor: "transparent"
            strokeColor: Qt.rgba(1, 1, 1, 0.18)
            strokeWidth: face.stroke
            PathAngleArc { centerX: ring.width / 2; centerY: ring.height / 2; radiusX: ring.r; radiusY: ring.r; startAngle: 0; sweepAngle: 360 }
        }
        ShapePath {
            fillColor: "transparent"
            strokeColor: face.active ? face.accent : "transparent"
            strokeWidth: face.stroke
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: ring.width / 2
                centerY: ring.height / 2
                radiusX: ring.r
                radiusY: ring.r
                startAngle: -90
                sweepAngle: 360 * face.t.remainingShare
            }
        }
    }

    TimeEdit {
        id: time
        anchors.horizontalCenter: ring.horizontalCenter
        anchors.verticalCenter: ring.verticalCenter
        anchors.verticalCenterOffset: face.active ? 0 : -Math.round(12 * face.u)
        Behavior on anchors.verticalCenterOffset { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        minutes: face.active ? face.t.displayMinutes : face.t.selectedMinutes
        seconds: face.active ? face.t.displaySeconds : face.t.selectedSeconds
        editable: !face.active
        pixelSize: Math.round(34 * face.u)
        fg: face.c.countdownText
        onStepMinutes: delta => face.t.stepMinutes(delta)
        onStepSeconds: delta => face.t.stepSeconds(delta)
    }
    TimerButton {
        anchors.horizontalCenter: ring.horizontalCenter
        anchors.top: time.bottom
        anchors.topMargin: Math.round(2 * face.u)
        diameter: Math.round(30 * face.u)
        iconSource: Qt.resolvedUrl("icons/play.svg")
        iconColor: "#ffffff"
        backgroundColor: face.c.actionGreenBg
        visible: !face.active
        enabled: face.t.selectedMinutes > 0 || face.t.selectedSeconds > 0
        opacity: enabled ? 1.0 : 0.35
        onClicked: face.t.startCustom()
    }

    // ── Presets ──
    Grid {
        id: grid
        x: face.rightX
        y: face.pad
        columns: 2
        spacing: Math.round(8 * face.u)
        opacity: face.active ? 0 : 1
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 180 } }
        Repeater {
            model: face.t.presetList.slice(0, 6)
            delegate: PresetChip {
                required property var modelData
                width: (face.rightWidth - grid.spacing) / 2
                height: Math.round((face.ringSize - 2 * grid.spacing) / 3)
                radius: Math.round(14 * face.u)
                text: modelData.mins + " min"
                sub: modelData.name
                align: Text.AlignLeft
                inset: Math.round(12 * face.u)
                pixelSize: Math.round(12.5 * face.u)
                fg: face.c.foreground
                onClicked: face.t.startPreset(modelData)
            }
        }
    }

    // ── Counting ──
    Item {
        x: face.rightX
        y: face.pad
        width: face.rightWidth
        height: face.ringSize
        opacity: face.active ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 180 } }

        Text {
            y: Math.round(10 * face.u)
            text: face.t.activeName || i18n("Timer")
            color: face.c.foreground
            font.family: "Inter Display"
            font.pixelSize: Math.round(22 * face.u)
            font.weight: Font.Normal
        }
        Text {
            y: Math.round(40 * face.u)
            text: face.t.endsLabel
            color: face.c.foreground
            opacity: 0.62
            font.family: "Inter Display"
            font.pixelSize: Math.round(12 * face.u)
            font.weight: Font.Medium
        }
        Row {
            anchors.bottom: parent.bottom
            spacing: Math.round(10 * face.u)
            TimerButton {
                diameter: face.btn
                iconSource: Qt.resolvedUrl("icons/cancel.svg")
                iconColor: face.c.buttonIcon
                backgroundColor: face.c.cancelButtonBg
                onClicked: face.t.cancelTimer()
            }
            TimerButton {
                diameter: face.btn
                iconSource: Qt.resolvedUrl(face.t.timerState === 1 ? "icons/pause.svg" : face.t.timerState === 3 ? "icons/reload.svg" : "icons/play.svg")
                iconColor: "#ffffff"
                backgroundColor: face.t.timerState === 1 ? face.c.actionOrangeBg : face.c.actionGreenBg
                onClicked: face.t.primaryAction()
            }
        }
    }
}

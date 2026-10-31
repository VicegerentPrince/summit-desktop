import QtQuick

// Layout "Bar": the anatomy of the Vitals and Claude cards (a label, one large figure, a thin bar,
// then a bottom row), so the Timer reads as one of the family.
Item {
    id: face
    required property var t
    required property var c
    readonly property real u: Math.min(width / 368, height / 176)
    readonly property real pad: Math.round(20 * u)
    readonly property bool active: t.timerState !== 0
    readonly property real btn: Math.round(44 * u)
    readonly property color accent: t.timerState === 2 ? Qt.rgba(1, 1, 1, 0.62) : "#FF9F0A"

    Text {
        x: face.pad
        y: face.pad - 2 * face.u
        text: face.active ? (face.t.activeName || i18n("Timer")) : i18n("Timer")
        color: face.c.foreground
        opacity: 0.62
        font.family: "Inter Display"
        font.pixelSize: Math.round(12 * face.u)
        font.weight: Font.Medium
        font.letterSpacing: 0.3
    }
    Text {
        x: parent.width - face.pad - width
        y: face.pad - 2 * face.u
        text: face.t.endsLabel
        visible: face.active
        color: face.c.foreground
        opacity: 0.62
        font.family: "Inter Display"
        font.pixelSize: Math.round(12 * face.u)
        font.weight: Font.Medium
        font.letterSpacing: 0.3
    }

    TimeEdit {
        id: time
        x: face.pad - Math.round(3 * face.u)
        y: Math.round((face.active ? 40 : 28) * face.u)
        Behavior on y { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        transformOrigin: Item.TopLeft
        scale: face.active ? 1.0 : 0.76
        Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        minutes: face.active ? face.t.displayMinutes : face.t.selectedMinutes
        seconds: face.active ? face.t.displaySeconds : face.t.selectedSeconds
        editable: !face.active
        pixelSize: Math.round(72 * face.u)
        fg: face.c.countdownText
        onStepMinutes: delta => face.t.stepMinutes(delta)
        onStepSeconds: delta => face.t.stepSeconds(delta)
    }

    Row {
        x: parent.width - face.pad - width
        y: face.active ? Math.round(62 * face.u) : Math.round(36 * face.u)
        Behavior on y { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        spacing: Math.round(10 * face.u)
        TimerButton {
            visible: face.active
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
            enabled: face.active || face.t.selectedMinutes > 0 || face.t.selectedSeconds > 0
            opacity: enabled ? 1.0 : 0.35
            onClicked: face.t.primaryAction()
        }
    }

    // the bar, as on Vitals and Claude
    Rectangle {
        x: face.pad
        y: Math.round((face.active ? 148 : 102) * face.u)
        Behavior on y { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        width: parent.width - 2 * face.pad
        height: 4
        radius: 2
        color: Qt.rgba(1, 1, 1, 0.18)
        Rectangle {
            width: parent.width * face.t.remainingShare
            height: 4
            radius: 2
            color: face.active ? face.accent : "transparent"
        }
    }

    Row {
        id: chips
        x: face.pad
        y: Math.round(122 * face.u)
        spacing: Math.round(6 * face.u)
        opacity: face.active ? 0 : 1
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 160 } }
        readonly property var list: face.t.presetList.slice(0, 6)
        Repeater {
            model: chips.list
            delegate: PresetChip {
                required property var modelData
                width: (face.width - 2 * face.pad - (chips.list.length - 1) * chips.spacing) / chips.list.length
                height: Math.round(34 * face.u)
                radius: Math.round(13 * face.u)
                text: modelData.mins + " min"
                pixelSize: Math.round(12 * face.u)
                fg: face.c.foreground
                onClicked: face.t.startPreset(modelData)
            }
        }
    }
}

import QtQuick

// Layout "Wheels": the presets on the left, Apple's time picker on the right.
Item {
    id: face
    required property var t
    required property var c
    readonly property real u: Math.min(width / 368, height / 176)
    readonly property real pad: Math.round(20 * u)
    readonly property bool active: t.timerState !== 0
    readonly property real leftWidth: 140 * u
    readonly property real btn: Math.round(44 * u)
    readonly property color accent: t.timerState === 2 ? Qt.rgba(1, 1, 1, 0.62) : "#FF9F0A"

    // ── Idle ──
    Item {
        anchors.fill: parent
        opacity: face.active ? 0 : 1
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 180 } }

        Text {
            x: face.pad
            y: face.pad - 2 * face.u
            text: i18n("Presets")
            color: face.c.foreground
            opacity: 0.62
            font.family: "Inter Display"
            font.pixelSize: Math.round(12 * face.u)
            font.weight: Font.Medium
            font.letterSpacing: 0.3
        }
        Grid {
            id: grid
            x: face.pad
            y: Math.round(40 * face.u)
            columns: 2
            spacing: Math.round(6 * face.u)
            Repeater {
                model: face.t.presetList.slice(0, 6)
                delegate: PresetChip {
                    required property var modelData
                    width: (face.leftWidth - grid.spacing) / 2
                    height: Math.round((116 * face.u - 2 * grid.spacing) / 3)
                    radius: Math.round(12 * face.u)
                    text: modelData.mins + (modelData.name ? " " + modelData.name.toLowerCase() : " min")
                    pixelSize: Math.round(12 * face.u)
                    fg: face.c.foreground
                    onClicked: face.t.startPreset(modelData)
                }
            }
        }

        // the band behind the selected row, as in Apple's picker
        Rectangle {
            id: band
            x: Math.round(174 * face.u)
            anchors.verticalCenter: parent.verticalCenter
            width: Math.round(122 * face.u)
            height: Math.round(30 * face.u)
            radius: Math.round(11 * face.u)
            color: face.c.foreground
            opacity: 0.10
        }
        WheelColumn {
            id: minutes
            x: band.x + Math.round(10 * face.u)
            y: face.pad
            width: Math.round(44 * face.u)
            height: parent.height - 2 * face.pad
            count: 100
            rowHeight: Math.round(27 * face.u)
            pixelSize: Math.round(20 * face.u)
            fg: face.c.foreground
            onPicked: value => face.t.selectedMinutes = value
            Connections {
                target: face.t
                function onSelectedMinutesChanged() { if (minutes.currentIndex !== face.t.selectedMinutes) minutes.currentIndex = face.t.selectedMinutes }
            }
            Component.onCompleted: currentIndex = face.t.selectedMinutes
        }
        Text {
            x: minutes.x + Math.round(30 * face.u)
            anchors.verticalCenter: parent.verticalCenter
            text: "min"
            color: face.c.foreground
            opacity: 0.62
            font.family: "Inter Display"
            font.pixelSize: Math.round(12 * face.u)
            font.weight: Font.Medium
        }
        WheelColumn {
            id: seconds
            x: band.x + Math.round(66 * face.u)
            y: face.pad
            width: Math.round(44 * face.u)
            height: parent.height - 2 * face.pad
            count: 60
            rowHeight: Math.round(27 * face.u)
            pixelSize: Math.round(20 * face.u)
            fg: face.c.foreground
            onPicked: value => face.t.selectedSeconds = value
            Connections {
                target: face.t
                function onSelectedSecondsChanged() { if (seconds.currentIndex !== face.t.selectedSeconds) seconds.currentIndex = face.t.selectedSeconds }
            }
            Component.onCompleted: currentIndex = face.t.selectedSeconds
        }
        Text {
            x: seconds.x + Math.round(30 * face.u)
            anchors.verticalCenter: parent.verticalCenter
            text: "sec"
            color: face.c.foreground
            opacity: 0.62
            font.family: "Inter Display"
            font.pixelSize: Math.round(12 * face.u)
            font.weight: Font.Medium
        }
        TimerButton {
            x: parent.width - face.pad - width
            anchors.verticalCenter: parent.verticalCenter
            diameter: face.btn
            iconSource: Qt.resolvedUrl("icons/play.svg")
            iconColor: "#ffffff"
            backgroundColor: face.c.actionGreenBg
            enabled: face.t.selectedMinutes > 0 || face.t.selectedSeconds > 0
            opacity: enabled ? 1.0 : 0.35
            onClicked: face.t.startCustom()
        }
    }

    // ── Counting ──
    Item {
        anchors.fill: parent
        opacity: face.active ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 180 } }

        Text {
            x: face.pad
            y: face.pad - 2 * face.u
            text: face.t.activeName || i18n("Timer")
            color: face.c.foreground
            font.family: "Inter Display"
            font.pixelSize: Math.round(14.5 * face.u)
            font.weight: Font.Medium
        }
        Text {
            x: face.pad
            y: Math.round(40 * face.u)
            text: face.t.endsLabel
            color: face.c.foreground
            opacity: 0.62
            font.family: "Inter Display"
            font.pixelSize: Math.round(12 * face.u)
            font.weight: Font.Medium
        }
        Rectangle {
            x: face.pad
            y: parent.height - face.pad - height
            width: face.leftWidth
            height: 4
            radius: 2
            color: Qt.rgba(1, 1, 1, 0.18)
            Rectangle {
                width: parent.width * face.t.remainingShare
                height: 4
                radius: 2
                color: face.accent
            }
        }
        TimeEdit {
            x: parent.width - face.pad - width
            y: face.pad - 8 * face.u
            minutes: face.t.displayMinutes
            seconds: face.t.displaySeconds
            pixelSize: Math.round(54 * face.u)
            fg: face.c.countdownText
        }
        Row {
            x: parent.width - face.pad - width
            y: parent.height - face.pad - height
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

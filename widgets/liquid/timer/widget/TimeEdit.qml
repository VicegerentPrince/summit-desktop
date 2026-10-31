import QtQuick

// mm:ss in thin figures that keep their width as they change. While idle, scrolling over either
// pair sets it, and the pair under the pointer gets a faint capsule so it reads as adjustable.
Item {
    id: edit
    property int minutes: 0
    property int seconds: 0
    property bool editable: false
    property real pixelSize: 54
    property color fg: "#ffffff"
    signal stepMinutes(int delta)
    signal stepSeconds(int delta)

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    component Field: Item {
        id: field
        property int value: 0
        signal stepped(int delta)
        implicitWidth: label.implicitWidth
        implicitHeight: label.implicitHeight
        Rectangle {
            anchors.centerIn: parent
            width: parent.width + edit.pixelSize * 0.16
            height: edit.pixelSize * 0.96
            radius: height * 0.26
            color: edit.fg
            opacity: edit.editable && hover.hovered ? 0.10 : 0
            Behavior on opacity { NumberAnimation { duration: 120 } }
        }
        Text {
            id: label
            text: field.value < 10 ? "0" + field.value : String(field.value)
            color: edit.fg
            font.family: "Inter Display"
            font.pixelSize: edit.pixelSize
            font.weight: Font.ExtraLight
            font.features: { "tnum": 1 }
        }
        HoverHandler { id: hover; enabled: edit.editable }
        WheelHandler {
            property real sum: 0
            enabled: edit.editable
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: event => {
                sum += event.angleDelta.y
                while (Math.abs(sum) >= 120) {
                    field.stepped(sum > 0 ? 1 : -1)
                    sum -= sum > 0 ? 120 : -120
                }
            }
        }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: edit.pixelSize * 0.02
        Field { value: edit.minutes; onStepped: delta => edit.stepMinutes(delta) }
        Text {
            text: ":"
            color: edit.fg
            font.family: "Inter Display"
            font.pixelSize: edit.pixelSize
            font.weight: Font.ExtraLight
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: -edit.pixelSize * 0.05
        }
        Field { value: edit.seconds; onStepped: delta => edit.stepSeconds(delta) }
    }
}

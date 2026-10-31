import QtQuick

// One preset. Feedback lands on press, not on release.
Item {
    id: chip
    property string text
    property string sub: ""
    property real pixelSize: 12
    property real radius: height / 2
    property color fg: "#ffffff"
    property int align: Text.AlignHCenter
    property real inset: 0
    signal clicked()

    scale: area.pressed ? 0.97 : 1.0
    Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }

    Rectangle {
        anchors.fill: parent
        radius: chip.radius
        color: chip.fg
        opacity: area.pressed ? 0.24 : (area.containsMouse ? 0.17 : 0.10)
        Behavior on opacity { NumberAnimation { duration: 100 } }
    }
    Column {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: chip.inset
        anchors.rightMargin: chip.inset
        anchors.verticalCenter: parent.verticalCenter
        spacing: 1
        Text {
            width: parent.width
            text: chip.text
            color: chip.fg
            horizontalAlignment: chip.align
            font.family: "Inter Display"
            font.pixelSize: chip.pixelSize
            font.weight: Font.Medium
            font.letterSpacing: 0.2
        }
        Text {
            width: parent.width
            visible: chip.sub !== ""
            text: chip.sub
            color: chip.fg
            opacity: 0.62
            horizontalAlignment: chip.align
            font.family: "Inter Display"
            font.pixelSize: Math.round(chip.pixelSize * 0.92)
            font.weight: Font.Medium
            font.letterSpacing: 0.2
        }
    }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: chip.clicked()
    }
}

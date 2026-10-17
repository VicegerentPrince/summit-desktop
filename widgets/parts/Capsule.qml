// A small pill for a count or a state, tinted with its own colour, like the badges in Apple's widgets.
import QtQuick

Rectangle {
    id: c
    property color tone: "white"
    property string text
    property string glyph: ""
    property real size: 11
    property string face: "Inter Display"

    implicitHeight: Math.round(size * 1.7)
    implicitWidth: row.implicitWidth + Math.round(size * 1.15)
    radius: height / 2
    color: Qt.rgba(tone.r, tone.g, tone.b, 0.20)

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Math.round(c.size * 0.3)
        Glyph {
            visible: c.glyph !== ""
            name: c.glyph
            color: c.tone
            width: Math.round(c.size * 0.95)
            height: width
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            visible: c.text !== ""
            text: c.text
            color: c.tone
            font.family: c.face
            font.pixelSize: c.size
            font.weight: Font.DemiBold
            font.features: { "tnum": 1 }
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}

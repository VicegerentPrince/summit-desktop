// A project's tile: its initials on a colour picked from its name, lit from the top like glass, with
// an optional status glyph sitting on the corner the way an app icon carries a badge.
import QtQuick
import "palette.js" as Palette

Item {
    id: t
    property string label
    property string face: "Inter Display"
    property string badge: ""            // an Octicon name, e.g. "x-circle-fill"
    property color badgeColor: "white"
    readonly property color base: Palette.forName(label)

    Rectangle {
        id: body
        anchors.fill: parent
        radius: Math.round(width * 0.3)
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.lighter(t.base, 1.22) }
            GradientStop { position: 1.0; color: Qt.darker(t.base, 1.18) }
        }
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.22)
    }
    Text {
        anchors.centerIn: parent
        text: Palette.monogram(t.label)
        color: "white"
        font.family: t.face
        font.pixelSize: Math.round(t.height * (text.length > 1 ? 0.38 : 0.46))
        font.weight: Font.DemiBold
        font.letterSpacing: -0.2
    }
    // The badge sits on a disc of the card's dark so it reads on any tile colour.
    Rectangle {
        visible: t.badge !== ""
        width: Math.round(t.width * 0.5)
        height: width
        radius: width / 2
        x: t.width - width * 0.72
        y: t.height - height * 0.72
        color: "#1c1c1e"
        Glyph {
            anchors.centerIn: parent
            width: Math.round(parent.width * 0.82)
            height: width
            name: t.badge
            color: t.badgeColor
        }
    }
}

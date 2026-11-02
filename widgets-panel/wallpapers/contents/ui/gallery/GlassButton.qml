import QtQuick
import org.kde.kirigami as Kirigami

// A round glass button with an icon, or a capsule when it has text too.
Item {
    id: b
    required property Item scene
    property string icon
    property string text
    property string tip
    property bool plain: false         // no glass of its own: for buttons that sit on a slab
    property real size: 40
    signal clicked()

    implicitHeight: size
    implicitWidth: text !== "" ? row.implicitWidth + 28 : size
    Accessible.role: Accessible.Button
    Accessible.name: tip !== "" ? tip : text

    scale: hit.pressed ? 0.93 : 1
    Behavior on scale { NumberAnimation { duration: (hit.pressed ? 70 : 220) * Kirigami.Units.longDuration / 200; easing.type: Easing.OutCubic } }

    Loader {
        anchors.fill: parent
        active: !b.plain
        sourceComponent: Glass {
            source: b.scene
            tintAlpha: hit.containsMouse ? 0.12 : 0.2
        }
    }
    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: Qt.rgba(1, 1, 1, hit.containsMouse ? (b.plain ? 0.14 : 0.08) : (b.plain ? 0.07 : 0))
        Behavior on color { ColorAnimation { duration: 140 * Kirigami.Units.longDuration / 200 } }
    }
    Row {
        id: row
        anchors.centerIn: parent
        spacing: 7
        Kirigami.Icon {
            anchors.verticalCenter: parent.verticalCenter
            width: 18; height: 18
            source: b.icon
            isMask: true
            color: "white"
        }
        Label {
            visible: b.text !== ""
            anchors.verticalCenter: parent.verticalCenter
            text: b.text
        }
    }
    MouseArea {
        id: hit
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: b.clicked()
    }
}

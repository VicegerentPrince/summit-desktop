import QtQuick
import org.kde.kirigami as Kirigami

// A glass capsule that rises from the bottom of the slab: what just happened, and the way back.
Item {
    id: toast
    required property var app
    required property Item scene
    property real bottomGap: 16

    readonly property bool showing: app.toastText !== ""
    width: row.width + 34
    height: 44
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    anchors.bottomMargin: bottomGap - (1 - rise.value) * 60
    opacity: Math.min(1, rise.value * 1.6)
    visible: rise.value > 0.01

    Spring { id: rise; target: toast.showing ? 1 : 0; response: 0.44; damping: toast.showing ? 0.82 : 1 }

    Glass {
        anchors.fill: parent
        source: toast.scene
        tintAlpha: 0.32
    }
    Row {
        id: row
        anchors.centerIn: parent
        spacing: 12
        Label { anchors.verticalCenter: parent.verticalCenter; text: toast.app.toastText; width: Math.min(implicitWidth, 360) }
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            visible: toast.app.previous !== "" && toast.app.toastUndo
            width: undoRow.width + 22
            height: 30
            radius: 15
            color: Qt.rgba(1, 1, 1, undoHit.containsMouse ? 0.24 : 0.14)
            scale: undoHit.pressed ? 0.94 : 1
            Behavior on scale { NumberAnimation { duration: 90 * Kirigami.Units.longDuration / 200 } }
            Row {
                id: undoRow
                anchors.centerIn: parent
                spacing: 6
                Kirigami.Icon { anchors.verticalCenter: parent.verticalCenter; width: 15; height: 15; source: "edit-undo-symbolic"; isMask: true; color: "white" }
                Label { anchors.verticalCenter: parent.verticalCenter; text: "Undo"; font.weight: Font.DemiBold }
            }
            MouseArea { id: undoHit; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: toast.app.undo() }
        }
    }
}

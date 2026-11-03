import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

// One picture. It answers the press on the way down, lifts under the pointer, and fades in only if it
// really had to load: pictures that come straight from memory just appear, so scrolling never flickers.
Item {
    id: t
    property url picture
    property url fallback
    property color tone: Qt.rgba(1, 1, 1, 0.07)
    property real radius: 16
    property bool inLibrary: false
    property bool isBusy: false
    property bool isFocus: false
    property string badge: ""
    property bool marksLow: false          // the corner marks sit low, for when controls float over the top
    // Where the corner marks are drawn. Under refracting glass they go to a layer above it, so the rim
    // bends the picture but never the marks; markOrigin is this tile's parent in that layer's coordinates.
    property Item markLayer: null
    property point markOrigin: Qt.point(0, 0)
    property real lift: 1.035
    property int decodeWidth: 640
    signal chosen()
    signal peeked()

    readonly property alias hovered: hit.containsMouse
    readonly property double born: Date.now()

    z: hit.containsMouse ? 3 : 1
    onHoveredChanged: if (hovered) peeked()

    Item {
        id: face
        anchors.fill: parent
        scale: hit.pressed ? 0.965 : (hit.containsMouse ? t.lift : 1)
        Behavior on scale { NumberAnimation { duration: (hit.pressed ? 70 : 240) * Kirigami.Units.longDuration / 200; easing.type: Easing.OutCubic } }

        Rectangle {
            anchors.fill: parent
            radius: t.radius
            color: t.tone
            opacity: image.opacity < 1 ? 1 : 0
        }
        Kirigami.ShadowedImage {
            id: image
            anchors.fill: parent
            radius: t.radius
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            sourceSize.width: t.decodeWidth
            sourceSize.height: Math.round(t.decodeWidth * 9 / 16)
            source: t.picture
            color: "transparent"
            opacity: 0
            shadow.size: hit.containsMouse ? 22 : 6
            shadow.yOffset: hit.containsMouse ? 8 : 2
            shadow.color: Qt.rgba(0, 0, 0, hit.containsMouse ? 0.5 : 0.22)
            border.width: t.isFocus ? 2 : 1
            border.color: t.isFocus ? Qt.rgba(1, 1, 1, 0.9) : Qt.rgba(1, 1, 1, 0.07)

            Behavior on opacity {
                enabled: Date.now() - t.born > 70
                NumberAnimation { duration: 260 * Kirigami.Units.longDuration / 200; easing.type: Easing.OutCubic }
            }
            onStatusChanged: {
                if (status === Image.Ready) opacity = t.isBusy ? 0.55 : 1
                else if (status === Image.Error && t.fallback != "" && source != t.fallback) source = t.fallback
            }
        }
        Connections {
            target: t
            function onIsBusyChanged() { if (image.status === Image.Ready) image.opacity = t.isBusy ? 0.55 : 1 }
        }

        Rectangle {   // downloading
            visible: t.isBusy
            anchors.centerIn: parent
            width: 44; height: 44; radius: 22
            color: Qt.rgba(0, 0, 0, 0.45)
            PlasmaComponents.BusyIndicator {
                anchors.centerIn: parent
                width: 28; height: 28
                running: t.isBusy
            }
        }
    }
    Item {
        id: marks
        parent: t.markLayer ? t.markLayer : t
        x: t.markLayer ? t.markOrigin.x + t.x : 0
        y: t.markLayer ? t.markOrigin.y + t.y : 0
        width: t.width; height: t.height
        z: t.z
        visible: t.visible
        scale: face.scale
        Rectangle {   // size, while the pointer is on it
            visible: opacity > 0
            opacity: t.badge !== "" && hit.containsMouse ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 140 * Kirigami.Units.longDuration / 200 } }
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.margins: 8
            width: badgeText.implicitWidth + 14
            height: 20
            radius: 10
            color: Qt.rgba(0, 0, 0, 0.55)
            Label {
                id: badgeText
                anchors.centerIn: parent
                text: t.badge
                px: 11
                font.weight: Font.DemiBold
            }
        }
        Rectangle {   // already in the library
            visible: t.inLibrary
            anchors.top: t.marksLow ? undefined : parent.top
            anchors.bottom: t.marksLow ? parent.bottom : undefined
            anchors.right: parent.right
            anchors.margins: 8
            width: 20; height: 20; radius: 10
            color: Qt.rgba(0, 0, 0, 0.5)
            Kirigami.Icon {
                anchors.centerIn: parent
                width: 12; height: 12
                source: "checkmark-symbolic"
                isMask: true
                color: "white"
            }
        }
    }
    MouseArea {
        id: hit
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: t.chosen()
    }
}

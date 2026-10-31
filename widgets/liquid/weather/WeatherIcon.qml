import QtQuick
import org.kde.kirigami as Kirigami

// The weather's icon. When the sky changes the old one dissolves into the new one.
Item {
    id: iconItem

    property string iconName: "sunny"
    property string iconSet: "default"
    property real iconSize: 48
    readonly property url wanted: Qt.resolvedUrl("../icons/weather/" + iconSet + "/" + iconName + ".png")
    property real done: 1

    implicitWidth: iconSize
    implicitHeight: iconSize
    width: iconSize
    height: iconSize

    Component.onCompleted: now.source = wanted
    onWantedChanged: {
        if (now.source == "" || now.source === wanted) return
        if (Kirigami.Units.longDuration > 0) {
            was.source = now.source
            done = 0
            change.restart()
        }
        now.source = wanted
    }
    NumberAnimation {
        id: change
        target: iconItem
        property: "done"
        to: 1
        duration: Kirigami.Units.veryLongDuration
        easing.type: Easing.InOutSine
    }

    Image {
        id: was
        anchors.fill: parent
        visible: iconItem.done < 1
        opacity: 1 - iconItem.done
        scale: 1 + 0.06 * iconItem.done
        fillMode: Image.PreserveAspectFit
        smooth: true
        mipmap: true
    }
    Image {
        id: now
        anchors.fill: parent
        opacity: iconItem.done
        scale: 0.9 + 0.1 * iconItem.done
        fillMode: Image.PreserveAspectFit
        smooth: true
        mipmap: true
    }
}

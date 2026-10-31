import QtQuick
import QtQuick.Effects

// A round button whose glyph changes by cross-fading. It dips the moment it is pressed.
Item {
    id: btn
    property real diameter: 44
    property color fill: "transparent"
    property color tint: "#ffffff"
    property string glyph: "play"
    property bool still: false          // no press dip of its own: the liquid under it dips instead
    readonly property real dip: pressScale
    property real pressScale: area.pressed ? 0.92 : 1.0
    Behavior on pressScale { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }
    signal clicked()

    width: diameter
    height: diameter
    scale: still ? 1 : pressScale

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: btn.fill
        Behavior on color { enabled: !btn.still; ColorAnimation { duration: 180 } }
    }

    Repeater {
        model: ["cancel", "pause", "play", "reload"]
        delegate: Image {
            id: icon
            required property string modelData
            readonly property bool on: btn.glyph === modelData
            anchors.centerIn: parent
            width: btn.diameter * 0.42
            height: width
            source: Qt.resolvedUrl("icons/" + modelData + ".svg")
            sourceSize.width: 96
            sourceSize.height: 96
            fillMode: Image.PreserveAspectFit
            smooth: true
            opacity: on ? 1 : 0
            scale: on ? (btn.still ? btn.pressScale : 1) : 0.55
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 140 } }
            Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }
            layer.enabled: visible
            layer.effect: MultiEffect {
                colorization: 1.0
                colorizationColor: btn.tint
                brightness: 1.0
            }
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: btn.clicked()
    }
}

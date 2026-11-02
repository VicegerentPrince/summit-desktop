import QtQuick
import org.kde.kirigami as Kirigami

// Library / Discover: a capsule with a drop of glass that flows between the two. The leading edge
// runs ahead of the trailing one, so the drop stretches the way it travels and then settles.
Item {
    id: seg
    required property Item scene
    property var model: []                 // [{ text, icon }]
    property int currentIndex: 0
    property bool bare: false              // no capsule of its own: for controls that sit on a slab
    property bool iconsOnly: false         // shrinks to the icons
    property real itemHeight: 34
    signal picked(int index)
    readonly property bool moving: leftEdge.moving || rightEdge.moving

    implicitHeight: itemHeight + 8
    implicitWidth: row.width + 8

    Glass {
        visible: !seg.bare
        anchors.fill: parent
        source: seg.scene
    }
    Rectangle {
        visible: seg.bare
        anchors.fill: parent
        radius: height / 2
        color: Qt.rgba(1, 1, 1, 0.07)
    }

    readonly property Item currentItem: {
        repeater.count
        return repeater.itemAt(seg.currentIndex)
    }
    Spring { id: leftEdge;  target: seg.currentItem ? seg.currentItem.x + row.x : 0
             response: target > value ? 0.46 : 0.3; damping: 1 }
    Spring { id: rightEdge; target: seg.currentItem ? seg.currentItem.x + seg.currentItem.width + row.x : 0
             response: target > value ? 0.3 : 0.46; damping: 1 }

    Glass {
        id: lens
        x: leftEdge.value
        y: 4
        width: Math.max(0, rightEdge.value - leftEdge.value)
        height: seg.itemHeight
        source: seg.scene
        tintColor: "white"
        tintAlpha: 0.13
        legibility: 0
        shade: 0.72
        frost: 2
        magnify: 0.9
        refractThickness: 11
        refractScale: 18
    }

    Row {
        id: row
        x: 4
        y: 4
        Repeater {
            id: repeater
            model: seg.model
            Item {
                id: entry
                required property var modelData
                required property int index
                readonly property bool chosen: index === seg.currentIndex
                width: (seg.iconsOnly ? 0 : label.implicitWidth + 7) + 18 + 32
                height: seg.itemHeight
                Behavior on width { NumberAnimation { duration: 220 * Kirigami.Units.longDuration / 200; easing.type: Easing.OutCubic } }

                Row {
                    anchors.centerIn: parent
                    spacing: seg.iconsOnly ? 0 : 7
                    Kirigami.Icon {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 18; height: 18
                        source: entry.modelData.icon
                        isMask: true
                        color: "white"
                        opacity: entry.chosen ? 1 : 0.72
                        Behavior on opacity { NumberAnimation { duration: 160 * Kirigami.Units.longDuration / 200 } }
                    }
                    Label {
                        id: label
                        anchors.verticalCenter: parent.verticalCenter
                        text: entry.modelData.text
                        font.weight: entry.chosen ? Font.DemiBold : Font.Medium
                        level: entry.chosen ? 1 : 0.76
                        width: seg.iconsOnly ? 0 : implicitWidth
                        opacity: seg.iconsOnly ? 0 : 1
                        Behavior on opacity { NumberAnimation { duration: 140 * Kirigami.Units.longDuration / 200 } }
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onPressed: seg.picked(entry.index)   // on the way down: nothing to wait for
                }
                Accessible.role: Accessible.PageTab
                Accessible.name: entry.modelData.text
            }
        }
    }
}

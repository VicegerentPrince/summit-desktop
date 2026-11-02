import QtQuick
import org.kde.kirigami as Kirigami

// Topics in one line that scrolls sideways and fades at its ends. The highlight slides from chip to chip.
Item {
    id: chips
    property var model: []                 // [[label, key], ...]
    property string currentKey: ""
    signal picked(var chip)

    implicitHeight: 34
    clip: true

    Flickable {
        id: flick
        anchors.fill: parent
        contentWidth: row.width
        contentHeight: height
        flickableDirection: Flickable.HorizontalFlick
        boundsBehavior: Flickable.StopAtBounds
        leftMargin: 0

        layer.enabled: true
        layer.effect: ShaderEffect {
            fragmentShader: Qt.resolvedUrl("shaders/edgefade.frag.qsb")
            property vector4d fade: Qt.vector4d(flick.atXBeginning ? 0 : 0.05, 0, flick.atXEnd ? 0 : 0.05, 0)
        }

        readonly property Item currentItem: {
            let found = null
            for (let i = 0; i < repeater.count; i++) {
                const it = repeater.itemAt(i)
                if (it && it.key === chips.currentKey) found = it
            }
            return found
        }
        onCurrentItemChanged: reveal()
        function reveal() {
            const it = currentItem
            if (!it) return
            const max = Math.max(0, contentWidth - width)
            let want = contentX
            if (it.x < contentX + 24) want = it.x - 24
            else if (it.x + it.width > contentX + width - 24) want = it.x + it.width - width + 24
            scroller.target = Math.max(0, Math.min(max, want))
        }

        Spring { id: scroller; response: 0.4; onValueChanged: if (moving) flick.contentX = value
                 Component.onCompleted: jump(0) }

        Spring { id: leftEdge;  target: flick.currentItem ? flick.currentItem.x : 0
                 response: target > value ? 0.44 : 0.28 }
        Spring { id: rightEdge; target: flick.currentItem ? flick.currentItem.x + flick.currentItem.width : 0
                 response: target > value ? 0.28 : 0.44 }

        Rectangle {
            visible: flick.currentItem !== null
            x: leftEdge.value
            y: (parent.height - height) / 2
            width: Math.max(0, rightEdge.value - leftEdge.value)
            height: 30
            radius: 15
            color: Qt.rgba(1, 1, 1, 0.17)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.26)
        }

        Row {
            id: row
            height: flick.height
            Repeater {
                id: repeater
                model: chips.model
                Item {
                    id: chip
                    required property var modelData
                    readonly property string key: modelData[1]
                    readonly property bool chosen: key === chips.currentKey
                    width: text.implicitWidth + 26
                    height: row.height
                    Label {
                        id: text
                        anchors.centerIn: parent
                        text: chip.modelData[0]
                        px: 13
                        font.weight: chip.chosen ? Font.DemiBold : Font.Medium
                        level: chip.chosen ? 1 : hit.containsMouse ? 0.92 : 0.72
                    }
                    MouseArea {
                        id: hit
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onPressed: chips.picked(chip.modelData)
                    }
                    Accessible.role: Accessible.Button
                    Accessible.name: chip.modelData[0]
                }
            }
        }
    }
    WheelHandler {
        target: null
        orientation: Qt.Vertical
        onWheel: event => {
            const max = Math.max(0, flick.contentWidth - flick.width)
            scroller.target = Math.max(0, Math.min(max, scroller.target - event.angleDelta.y * 0.7))
        }
    }
}

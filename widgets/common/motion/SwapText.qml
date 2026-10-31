import QtQuick
import org.kde.kirigami as Kirigami

// A text that changes with a small lift: the old value rises away as the new one comes up from
// below. It moves only when its value changes, so at rest it costs nothing. A figure that ticks
// every second or two passes shouldSwap, so that only a change of kind moves and a new number
// costs one frame.
Item {
    id: swap
    property string text
    property color color: "#ffffff"
    property alias font: now.font
    property alias renderType: now.renderType
    property int align: Text.AlignLeft
    property var shouldSwap: null       // (from, to) => bool
    readonly property real rise: Math.round(now.font.pixelSize * 0.32)
    property real done: 1
    property bool ready: false

    implicitWidth: now.implicitWidth
    implicitHeight: now.implicitHeight
    baselineOffset: now.baselineOffset

    Component.onCompleted: {
        now.text = text
        ready = true
    }
    onTextChanged: {
        if (!ready) return
        const moves = Kirigami.Units.longDuration > 0 && now.text !== "" && (!shouldSwap || shouldSwap(now.text, text))
        if (moves) {
            was.text = now.text
            done = 0
            change.restart()
        }
        now.text = text
    }
    NumberAnimation {
        id: change
        target: swap
        property: "done"
        to: 1
        duration: Kirigami.Units.veryLongDuration * 0.75
        easing.type: Easing.OutCubic
    }

    function startOf(item) {
        return swap.align === Text.AlignRight ? swap.width - item.implicitWidth
             : swap.align === Text.AlignHCenter ? (swap.width - item.implicitWidth) / 2 : 0
    }
    Text {
        id: was
        visible: swap.done < 1
        x: swap.startOf(was)
        y: -swap.rise * swap.done
        opacity: Math.max(0, 1 - swap.done * 1.8)     // gone before the new value lands on it
        color: swap.color
        font: now.font
        renderType: now.renderType
    }
    Text {
        id: now
        x: swap.startOf(now)
        y: swap.rise * (1 - swap.done)
        opacity: swap.done
        color: swap.color
    }
}

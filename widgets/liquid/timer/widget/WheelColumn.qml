import QtQuick

// A wheel in the manner of Apple's time picker: it wraps round, so 59 sits above 00, and the rows
// fade away from the middle. Drag it or scroll over it.
PathView {
    id: wheel
    property int count: 60
    property color fg: "#ffffff"
    property real rowHeight: 27
    property real pixelSize: 20
    property bool lifted: false         // the chosen row has been picked up, so it leaves its place
    property real rest: 1               // how much of the other rows still shows
    signal picked(int value)

    model: count
    pathItemCount: 7
    preferredHighlightBegin: 0.5
    preferredHighlightEnd: 0.5
    highlightRangeMode: PathView.StrictlyEnforceRange
    snapMode: PathView.SnapOneItem
    highlightMoveDuration: 180
    dragMargin: width
    clip: true
    onCurrentIndexChanged: picked(currentIndex)

    path: Path {
        startX: wheel.width / 2
        startY: wheel.height / 2 - 3.5 * wheel.rowHeight
        PathAttribute { name: "fade"; value: 0.0 }
        PathLine { x: wheel.width / 2; y: wheel.height / 2 }
        PathAttribute { name: "fade"; value: 1.0 }
        PathLine { x: wheel.width / 2; y: wheel.height / 2 + 3.5 * wheel.rowHeight }
        PathAttribute { name: "fade"; value: 0.0 }
    }

    delegate: Text {
        required property int index
        width: wheel.width
        height: wheel.rowHeight
        text: index < 10 ? "0" + index : String(index)
        color: wheel.fg
        opacity: wheel.lifted && PathView.isCurrentItem ? 0
               : wheel.rest * Math.pow(PathView.fade === undefined ? 0 : PathView.fade, 2.6)
        horizontalAlignment: Text.AlignLeft
        verticalAlignment: Text.AlignVCenter
        font.family: "Inter Display"
        font.pixelSize: wheel.pixelSize
        font.weight: Font.Light
        font.features: { "tnum": 1 }
    }

    WheelHandler {
        property real sum: 0
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => {
            sum += event.angleDelta.y
            while (Math.abs(sum) >= 120) {
                if (sum > 0) wheel.decrementCurrentIndex(); else wheel.incrementCurrentIndex()
                sum -= sum > 0 ? 120 : -120
            }
        }
    }
}

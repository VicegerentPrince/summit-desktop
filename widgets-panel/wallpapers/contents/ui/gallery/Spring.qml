import QtQuick
import org.kde.kirigami as Kirigami

// A spring with Apple's two numbers: response (seconds) and damping (1 = no overshoot). The value moves
// from where it is on screen and keeps its velocity when the target changes, so any motion can be
// reversed halfway. It follows Plasma's animation speed; with animations off it jumps. Each frame uses
// the exact solution, not steps towards it, so no speed or slow frame can make it diverge.
Item {
    id: s
    visible: false

    property real target: 0
    property real value: 0
    property real velocity: 0
    property real response: 0.36
    property real damping: 1
    property real precision: 0.0015

    readonly property real speed: Kirigami.Units.longDuration / 200
    // Plasma's "Instant" is a long duration of 1 ms, not 0
    readonly property bool instant: Kirigami.Units.longDuration <= 1
    readonly property alias moving: frames.running

    // to a value at once, for targets set from code
    function jump(v) {
        target = v
        rest()
    }
    // to the target at once; must not write `target`, which may be a binding
    function rest() {
        value = target; velocity = 0
        frames.running = false
    }

    onTargetChanged: {
        if (instant) rest()
        else frames.running = true
    }
    Component.onCompleted: rest()

    FrameAnimation {
        id: frames
        onTriggered: {
            const period = s.response * s.speed
            if (s.instant || period < 0.001) { s.rest(); return }
            const t = Math.min(frameTime, 0.05)
            const w = 2 * Math.PI / period
            const z = Math.min(1, s.damping)
            const x0 = s.value - s.target, v0 = s.velocity
            const fall = Math.exp(-z * w * t)
            let x, v
            if (z > 0.999) {
                const b = v0 + w * x0
                x = fall * (x0 + b * t)
                v = fall * (v0 - w * b * t)
            } else {
                const wd = w * Math.sqrt(1 - z * z)
                const b = (v0 + z * w * x0) / wd
                const cos = Math.cos(wd * t), sin = Math.sin(wd * t)
                x = fall * (x0 * cos + b * sin)
                v = fall * (v0 * cos - (x0 * wd + z * w * b) * sin)
            }
            if (Math.abs(x) < s.precision && Math.abs(v) < s.precision * 10) {
                s.value = s.target; s.velocity = 0
                running = false
            } else {
                s.value = s.target + x; s.velocity = v
            }
        }
    }
}

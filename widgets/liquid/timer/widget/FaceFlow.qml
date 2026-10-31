import QtQuick
import org.kde.kirigami as Kirigami

// Layout "Wheels and Ring": the wheels while idle, the ring while counting, and between them one
// bead of liquid. The play button lets go, runs left along the wheels, picks up the digits on its
// way and opens into the ring around them. Cancelling plays the same path backwards.
//
// One number, f, goes from 0 (idle) to 1 (counting) and everything is worked out from it, so the
// change can be turned round at any moment and carries on from where it is. f moves only during a
// change: at rest this face asks for no frames at all, and a count asks for one a second.
Item {
    id: face
    required property var t
    required property var c
    property var card: null             // the card's glass: its rim light follows the bead

    readonly property real u: Math.min(width / 368, height / 176)
    readonly property bool active: t.timerState !== 0
    readonly property color orange: "#FF9F0A"

    // ── The one number ─────────────────────────────────────────────────────
    property real f: 0
    readonly property real speed: Kirigami.Units.veryLongDuration / 400     // Plasma's animation speed
    onActiveChanged: {
        if (active) {
            refill.stop()
            share = wantedShare
        }
        flow.stop()
        flow.from = f
        flow.to = active ? 1 : 0
        flow.duration = Math.abs(flow.to - f) * (active ? 900 : 650) * speed
        flow.start()
    }
    NumberAnimation { id: flow; target: face; property: "f" }
    onFChanged: if (f === 0) originAtPlay()

    function seg(v, a, b) { return Math.max(0, Math.min(1, (v - a) / (b - a))) }
    function mix(a, b, k) { return a + (b - a) * k }
    function soft(k) { return k * k * (3 - 2 * k) }
    function inOut(k) { return k < 0.5 ? 4 * k * k * k : 1 - Math.pow(2 - 2 * k, 3) / 2 }
    function back(k) { const q = k - 1; return 1 + q * q * (2.1 * q + 1.1) }
    function linear(v) { return Math.pow(v, 2.2) }
    function gamma(v) { return Math.pow(v, 1 / 2.2) }
    function softMin(a, b, k) { const h = Math.max(k - Math.abs(a - b), 0) / k; return Math.min(a, b) - h * h * k * 0.25 }
    function pad(n) { return n < 10 ? "0" + n : String(n) }

    // ── What a cancelled run keeps showing on its way back ─────────────────
    property int shownMinutes: 0
    property int shownSeconds: 0
    property string shownName: ""
    property string shownEnds: ""
    property int shownState: 1
    // Written by hand: a Binding with RestoreNone stays attached, so a cancelled run would drop to 00:00.
    function hold() {
        if (face.t.timerState === 0) return
        face.shownState = face.t.timerState
        face.shownMinutes = face.t.displayMinutes
        face.shownSeconds = face.t.displaySeconds
        face.shownName = face.t.activeName || i18n("Timer")
        face.shownEnds = face.t.endsLabel
    }
    Connections {
        target: face.t
        function onTimerStateChanged() { face.hold() }
        function onWholeSecondsChanged() { face.hold() }
        function onActiveNameChanged() { face.hold() }
        function onEndsLabelChanged() { face.hold() }
    }
    Component.onCompleted: hold()
    property real share: 1

    // the ring steps once a second; only a big jump, such as starting over, runs back round
    readonly property real wantedShare: t.remainingShare
    onWantedShareChanged: {
        if (!active) return
        if (Math.abs(wantedShare - share) > 0.1 && f === 1) {
            refill.from = share
            refill.to = wantedShare
            refill.restart()
        } else if (!refill.running) share = wantedShare
    }
    NumberAnimation { id: refill; target: face; property: "share"; duration: 420 * face.speed; easing.type: Easing.OutCubic }

    readonly property real pausedMix: shownState === 2 ? 1 : 0
    property real paused: pausedMix
    Behavior on paused { NumberAnimation { duration: 200 } }

    // when the time is up the ring sends out three ripples and rests
    property real ping: 0
    readonly property bool finished: t.timerState === 3
    onFinishedChanged: if (finished) pings.restart(); else pings.stop()
    SequentialAnimation {
        id: pings
        loops: 3
        NumberAnimation { target: face; property: "ping"; from: 0; to: 1; duration: 760 * face.speed; easing.type: Easing.OutCubic }
        ScriptAction { script: face.ping = 0 }
    }

    // ── Where the bead starts ──────────────────────────────────────────────
    readonly property real playX: 326
    readonly property real playY: 88
    readonly property real ringX: 88
    readonly property real ringY: 88
    property bool fromChip: false
    property real originX: playX
    property real originY: playY
    property real originR: 22
    property int pickedChip: -1
    function startFrom(chip, preset, index) {
        if (f === 0) {
            const at = chip.mapToItem(box, chip.width / 2, chip.height / 2)
            originX = at.x / u
            originY = at.y / u
            originR = chip.height / 2 / u
            pickedChip = index
            fromChip = true
        }
        t.startPreset(preset)
    }
    function originAtPlay() {
        originX = playX
        originY = playY
        originR = 22
        fromChip = false
    }

    // ── The bead, in card units ────────────────────────────────────────────
    readonly property real flight: seg(f, 0.02, 0.32)
    readonly property real leadX: mix(originX, ringX, inOut(flight))
    readonly property real leadY: mix(originY, ringY, inOut(flight))
    readonly property real tailT: seg(f, 0.05, 0.37)
    readonly property real tailX: mix(originX, ringX, inOut(tailT))
    readonly property real tailY: mix(originY, ringY, inOut(tailT))
    readonly property real tailR: fromChip ? 0 : 8.5 * (1 - seg(f, 0.31, 0.38))
    // the longer the neck is drawn out the thinner it gets, until it snaps and the droplet catches up
    readonly property real stretch: Math.min(1.2, Math.hypot(tailX - leadX, tailY - leadY) / 100)
    readonly property real neckR: tailR * (1 - 1.15 * stretch)
    readonly property real squeeze: 1 - 0.1 * Math.sin(Math.PI * flight)     // a little thin at full speed
    readonly property real iris: seg(f, 0.3, 0.72)
    readonly property real outerR: mix(originR * squeeze * (f === 0 ? playButton.dip : 1), 68, back(iris))
    // the bead lands and spreads into a thin film, which draws back into the ring
    readonly property real opening: soft(seg(f, 0.34, 0.64))
    readonly property real innerR: mix(-24, 63, opening)
    readonly property real film: mix(24, 0, soft(seg(f, 0.46, 0.74)))

    readonly property real warm: soft(seg(f, 0.42, 0.76))
    readonly property color green: Qt.colorEqual(c.actionGreenBg, "#00A832") ? c.actionGreenBg : c.actionGreen
    readonly property color inkNow: {
        // mixed in linear light and kept bright, so green turns to orange by way of gold, never neon
        const m = (a, b) => gamma(mix(linear(a), linear(b), warm))
        const r = m(green.r, orange.r), g = m(green.g, orange.g), b = m(green.b, orange.b)
        const v = mix(Math.max(green.r, green.g, green.b), 1, Math.sqrt(warm)) / Math.max(r, g, b, 0.01)
        const p = paused * seg(f, 0.6, 0.85)
        return Qt.rgba(mix(r * v, 1, p), mix(g * v, 1, p), mix(b * v, 1, p), mix(1, 0.62, p))
    }
    readonly property bool canStart: t.selectedMinutes > 0 || t.selectedSeconds > 0

    Item {
        id: box
        anchors.centerIn: parent
        width: 368 * face.u
        height: 176 * face.u

        // ── Idle: presets and wheels ───────────────────────────────────────
        Item {
            id: idle
            anchors.fill: parent
            visible: face.f < 1
            enabled: !face.active

            Text {
                x: 20 * face.u
                y: 18 * face.u
                text: i18n("Presets")
                color: face.c.foreground
                opacity: 0.62 * (1 - face.seg(face.f, 0.08, 0.22))
                font.family: "Inter Display"
                font.pixelSize: Math.round(12 * face.u)
                font.weight: Font.Medium
                font.letterSpacing: 0.3
            }
            Grid {
                id: grid
                x: 20 * face.u
                y: 40 * face.u
                columns: 2
                spacing: Math.round(6 * face.u)
                Repeater {
                    model: face.t.presetList.slice(0, 6)
                    delegate: PresetChip {
                        id: chip
                        required property var modelData
                        required property int index
                        readonly property real col: index % 2
                        readonly property real row: Math.floor(index / 2)
                        readonly property bool picked: face.fromChip && face.pickedChip === index
                        // a wave that runs ahead of the bead: the column nearest it leaves first
                        readonly property real start: picked ? 0 : 0.07 + (1 - col) * 0.05 + Math.abs(row - 1) * 0.02
                        readonly property real gone: face.soft(face.seg(face.f, start, start + (picked ? 0.08 : 0.15)))
                        width: Math.round((140 * face.u - grid.spacing) / 2)
                        height: Math.round((116 * face.u - 2 * grid.spacing) / 3)
                        radius: Math.round(12 * face.u)
                        text: modelData.mins + (modelData.name ? " " + modelData.name.toLowerCase() : " min")
                        pixelSize: Math.round(12 * face.u)
                        fg: face.c.foreground
                        opacity: 1 - gone
                        scale: 1 - 0.14 * gone
                        onClicked: face.startFrom(chip, modelData, index)
                    }
                }
            }

            readonly property real wheelsLeft: 1 - face.soft(face.seg(face.f, 0.03, 0.2))
            Rectangle {
                id: band
                x: Math.round(174 * face.u)
                anchors.verticalCenter: parent.verticalCenter
                width: Math.round(122 * face.u)
                height: Math.round(30 * face.u)
                radius: Math.round(11 * face.u)
                color: face.c.foreground
                opacity: 0.10 * idle.wheelsLeft
            }
            WheelColumn {
                id: minutes
                x: band.x + Math.round(10 * face.u)
                y: 20 * face.u
                width: Math.round(44 * face.u)
                height: parent.height - 40 * face.u
                count: 100
                rowHeight: Math.round(27 * face.u)
                pixelSize: Math.round(20 * face.u)
                fg: face.c.foreground
                lifted: face.f > 0
                rest: idle.wheelsLeft
                onPicked: value => face.t.selectedMinutes = value
                Connections {
                    target: face.t
                    function onSelectedMinutesChanged() { if (minutes.currentIndex !== face.t.selectedMinutes) minutes.currentIndex = face.t.selectedMinutes }
                }
                Component.onCompleted: currentIndex = face.t.selectedMinutes
            }
            Text {
                x: minutes.x + Math.round(30 * face.u)
                anchors.verticalCenter: parent.verticalCenter
                text: "min"
                color: face.c.foreground
                opacity: 0.62 * idle.wheelsLeft
                font.family: "Inter Display"
                font.pixelSize: Math.round(12 * face.u)
                font.weight: Font.Medium
            }
            WheelColumn {
                id: seconds
                x: band.x + Math.round(66 * face.u)
                y: 20 * face.u
                width: Math.round(44 * face.u)
                height: parent.height - 40 * face.u
                count: 60
                rowHeight: Math.round(27 * face.u)
                pixelSize: Math.round(20 * face.u)
                fg: face.c.foreground
                lifted: face.f > 0
                rest: idle.wheelsLeft
                onPicked: value => face.t.selectedSeconds = value
                Connections {
                    target: face.t
                    function onSelectedSecondsChanged() { if (seconds.currentIndex !== face.t.selectedSeconds) seconds.currentIndex = face.t.selectedSeconds }
                }
                Component.onCompleted: currentIndex = face.t.selectedSeconds
            }
            Text {
                x: seconds.x + Math.round(30 * face.u)
                anchors.verticalCenter: parent.verticalCenter
                text: "sec"
                color: face.c.foreground
                opacity: 0.62 * idle.wheelsLeft
                font.family: "Inter Display"
                font.pixelSize: Math.round(12 * face.u)
                font.weight: Font.Medium
            }
        }

        // ── The liquid: play button, bead, ring and arc are all this one quad ──
        ShaderEffect {
            anchors.fill: parent
            fragmentShader: Qt.resolvedUrl("shaders/flow.frag.qsb")
            blending: true
            property vector2d size: Qt.vector2d(width, height)
            property real pixel: 1 / Math.max(1, Screen.devicePixelRatio)
            property vector4d lead: Qt.vector4d(face.leadX * face.u, face.leadY * face.u, face.outerR * face.u, face.innerR * face.u)
            property real film: face.film * face.u
            property real thin: 0.8 * face.soft(face.seg(face.f, 0.33, 0.47)) * (1 - face.soft(face.seg(face.f, 0.58, 0.76)))
            property vector4d tail: Qt.vector4d(face.tailX * face.u, face.tailY * face.u,
                                                (face.f > 0 ? face.tailR : 0) * face.u, face.neckR * face.u)
            property vector4d ink: Qt.vector4d(face.inkNow.r, face.inkNow.g, face.inkNow.b,
                face.inkNow.a * (face.fromChip ? face.seg(face.f, 0, 0.07) : (face.canStart || face.f > 0 ? 1 : 0.35)))
            property vector4d track: Qt.vector4d(face.ringX * face.u, face.ringY * face.u, 65.5 * face.u, 2.5 * face.u)
            property real trackAlpha: face.seg(face.f, 0.5, 0.76)
            property real sweep: 2 * Math.PI * face.mix(1, face.share, face.seg(face.f, 0.72, 0.95))
            property real glintAngle: 2 * Math.PI * face.soft(face.seg(face.f, 0.6, 1))
            property real glint: Math.sin(Math.PI * face.seg(face.f, 0.6, 1)) * 0.6
            property vector2d halo: {
                const k = face.ping > 0 ? face.ping : face.seg(face.f, 0.56, 0.88)
                return Qt.vector2d(mix2(68, 118, k) * face.u, (face.ping > 0 ? 0.55 : 0.34) * (k > 0 && k < 1 ? 1 - k : 0))
            }
            function mix2(a, b, k) { return a + (b - a) * (1 - Math.pow(1 - k, 2.2)) }
            property real gloss: face.seg(face.f, 0, 0.05) * (1 - face.soft(face.seg(face.f, 0.27, 0.52)))
        }

        // ── The digits: picked up by the bead, carried, then set down in the ring ──
        readonly property real gapNow: (minutesFly.implicitWidth + colon.implicitWidth) / 2 / face.u + 0.7
        readonly property real grown: face.soft(face.seg(face.f, 0.18, 0.62))
        readonly property real spread: gapNow * face.mix(0.588, 1, grown)
        readonly property real minutesHome: 184 + minutesFly.implicitWidth * 0.294 / face.u
        readonly property real secondsHome: 240 + secondsFly.implicitWidth * 0.294 / face.u
        readonly property real chipCarry: face.inOut(face.seg(face.f, 0.04, 0.5))
        readonly property real minutesCx: face.fromChip ? face.mix(minutesHome, face.ringX - gapNow, chipCarry)
                                                        : face.softMin(minutesHome, face.leadX - spread, 26)
        readonly property real secondsCx: face.fromChip ? face.mix(secondsHome, face.ringX + gapNow, chipCarry)
                                                        : face.softMin(secondsHome, face.leadX + spread, 26)
        readonly property real digitScale: face.mix(0.588, 1, grown)
        readonly property bool sameDigits: face.shownMinutes === face.t.selectedMinutes && face.shownSeconds === face.t.selectedSeconds
        // cancelled at 14:32: those digits lift away and the chosen time rises into their place
        readonly property real liveDigits: sameDigits ? 1 : face.seg(face.f, 0.74, 0.84)
        readonly property real chosenDigits: sameDigits ? 0 : 1 - face.seg(face.f, 0.62, 0.72)

        component Digits: Text {
            color: face.c.countdownText
            font.family: "Inter Display"
            font.pixelSize: Math.round(34 * face.u)
            font.weight: Font.ExtraLight
            font.features: { "tnum": 1 }
            visible: face.f > 0 && opacity > 0
            y: 88 * face.u - height / 2
        }
        Digits {
            id: minutesFly
            text: face.pad(face.shownMinutes)
            x: box.minutesCx * face.u - width / 2
            y: 88 * face.u - height / 2 - 8 * face.u * (1 - box.liveDigits)
            scale: box.digitScale
            opacity: box.liveDigits
        }
        Digits {
            id: secondsFly
            text: face.pad(face.shownSeconds)
            x: box.secondsCx * face.u - width / 2
            y: 88 * face.u - height / 2 - 8 * face.u * (1 - box.liveDigits)
            scale: box.digitScale
            opacity: box.liveDigits
        }
        Digits {
            text: face.pad(face.t.selectedMinutes)
            x: box.minutesCx * face.u - width / 2
            y: 88 * face.u - height / 2 + 8 * face.u * (1 - box.chosenDigits)
            scale: box.digitScale
            opacity: box.chosenDigits
        }
        Digits {
            text: face.pad(face.t.selectedSeconds)
            x: box.secondsCx * face.u - width / 2
            y: 88 * face.u - height / 2 + 8 * face.u * (1 - box.chosenDigits)
            scale: box.digitScale
            opacity: box.chosenDigits
        }
        Digits {
            id: colon
            text: ":"
            x: face.ringX * face.u - width / 2
            y: 88 * face.u - height / 2 - 34 * face.u * 0.05
            opacity: face.seg(face.f, 0.44, 0.62)
        }

        // ── Play, on top of the liquid ─────────────────────────────────────
        FlowButton {
            id: playButton
            x: (face.playX - 22) * face.u
            y: (face.playY - 22) * face.u
            diameter: 44 * face.u
            glyph: "play"
            still: true
            fill: face.fromChip ? face.green : "transparent"
            tint: "#ffffff"       // the bead under it is the full green in every style
            visible: opacity > 0
            enabled: !face.active && face.canStart
            opacity: (face.fromChip ? 1 - face.seg(face.f, 0, 0.22) : 1 - face.seg(face.f, 0, 0.07)) * (face.canStart || face.f > 0 ? 1 : 0.35)
            onClicked: face.t.startCustom()
        }

        // ── Counting: the right side ───────────────────────────────────────
        Item {
            anchors.fill: parent
            visible: face.f > 0.5
            enabled: face.active

            readonly property real nameIn: face.soft(face.seg(face.f, 0.54, 0.8))
            readonly property real endsIn: face.soft(face.seg(face.f, 0.62, 0.86))
            readonly property real closeIn: face.seg(face.f, 0.66, 0.94)
            readonly property real primaryIn: face.seg(face.f, 0.72, 1)

            Text {
                x: 174 * face.u
                y: (30 + 10 * (1 - parent.nameIn)) * face.u
                opacity: parent.nameIn
                text: face.shownName
                color: face.c.foreground
                font.family: "Inter Display"
                font.pixelSize: Math.round(22 * face.u)
                font.weight: Font.Normal
            }
            Text {
                x: 174 * face.u
                y: (60 + 10 * (1 - parent.endsIn)) * face.u
                opacity: 0.62 * parent.endsIn
                text: face.shownEnds
                color: face.c.foreground
                font.family: "Inter Display"
                font.pixelSize: Math.round(12 * face.u)
                font.weight: Font.Medium
            }
            FlowButton {
                x: 174 * face.u
                y: 112 * face.u
                diameter: 44 * face.u
                glyph: "cancel"
                tint: face.c.buttonIcon
                fill: face.c.cancelButtonBg
                opacity: parent.closeIn
                scale: pressScale * (0.7 + 0.3 * face.back(parent.closeIn))
                onClicked: face.t.cancelTimer()
            }
            FlowButton {
                x: 228 * face.u
                y: 112 * face.u
                diameter: 44 * face.u
                glyph: face.shownState === 1 ? "pause" : face.shownState === 3 ? "reload" : "play"
                tint: face.c.isGlass ? "#ffffff" : (face.shownState === 1 ? face.c.actionOrange : face.c.actionGreen)
                fill: face.shownState === 1 ? face.c.actionOrangeBg : face.c.actionGreenBg
                opacity: parent.primaryIn
                scale: pressScale * (0.7 + 0.3 * face.back(parent.primaryIn))
                onClicked: face.t.primaryAction()
            }
        }
    }

    // The card's rim light leans towards the bead while it moves.
    Binding {
        when: face.card !== null && face.f > 0 && face.f < 1
        target: face.card
        property: "lightPoint"
        value: Qt.vector3d((box.x + face.leadX * face.u) / face.width, (box.y + face.leadY * face.u) / face.height,
                           Math.sin(Math.PI * face.seg(face.f, 0, 0.5)))
    }
}

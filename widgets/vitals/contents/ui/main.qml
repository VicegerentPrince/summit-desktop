/*
    Vitals: up to three figures with thin bars (CPU, GPU, memory, swap or disk free, chosen on
    the Readings settings page) and a quiet bottom row (network, disk free, temperature,
    battery). Drawn on the same glass as the Liquid Glass widgets.

    Performance rule for this widget: nothing animates continuously. Values change at most
    every two seconds and each change costs one frame. Only a change of state moves: a warning
    colour, or the GPU going to sleep. Sensors are subscribed only while their reading is
    shown, and a dedicated GPU that is asleep is never woken (contents/code/gpu).
*/
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support
import org.kde.ksysguard.sensors as Sensors
import org.kde.plasma.private.battery
import org.kde.kirigami as Kirigami
import "components"

PlasmoidItem {
    id: root

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: fullRepresentation

    width: 368
    height: 144

    readonly property int rate: 2000
    // Inter Display ships inside the widget (contents/fonts), so the card looks the same everywhere
    FontLoader { id: interLight; source: Qt.resolvedUrl("../fonts/InterDisplay-ExtraLight.ttf") }
    FontLoader { id: interMedium; source: Qt.resolvedUrl("../fonts/InterDisplay-Medium.ttf") }
    readonly property string face: interMedium.status === FontLoader.Ready ? interMedium.font.family : "Inter Display"

    MacOSColors {
        id: colors
        styleMode: Plasmoid.configuration.styleMode
        appearance: Plasmoid.configuration.appearance
    }

    // What the card shows: the top row's figures left to right ("none" leaves a slot out)
    readonly property var cfg: Plasmoid.configuration
    readonly property var figures: [cfg.figureLeft, cfg.figureMiddle, cfg.figureRight].filter(f => f && f !== "none")
    function shows(key) { return figures.indexOf(key) >= 0 }
    readonly property bool diskShown: shows("disk") || cfg.showDisk

    Sensors.Sensor { id: cpu;       sensorId: root.shows("cpu") ? "cpu/all/usage" : "";                      updateRateLimit: root.rate }
    Sensors.Sensor { id: cpuTemp;   sensorId: root.cfg.showTemperature ? "cpu/all/averageTemperature" : "";  updateRateLimit: root.rate * 2 }
    Sensors.Sensor { id: memUsed;   sensorId: root.shows("memory") ? "memory/physical/used" : "";             updateRateLimit: root.rate }
    Sensors.Sensor { id: memTotal;  sensorId: root.shows("memory") ? "memory/physical/total" : "";            updateRateLimit: 60000 }
    Sensors.Sensor { id: swapUsed;  sensorId: root.shows("swap") ? "memory/swap/used" : "";                   updateRateLimit: root.rate }
    Sensors.Sensor { id: swapTotal; sensorId: root.shows("swap") ? "memory/swap/total" : "";                  updateRateLimit: 60000 }
    Sensors.Sensor { id: diskFree;  sensorId: root.diskShown ? "disk/all/free" : "";                          updateRateLimit: 30000 }
    Sensors.Sensor { id: diskUsed;  sensorId: root.shows("disk") ? "disk/all/usedPercent" : "";               updateRateLimit: 30000 }
    Sensors.Sensor { id: netDown;   sensorId: root.cfg.showNetwork ? "network/all/download" : "";             updateRateLimit: root.rate }
    Sensors.Sensor { id: netUp;     sensorId: root.cfg.showNetwork ? "network/all/upload" : "";               updateRateLimit: root.rate }

    BatteryControlModel { id: battery }

    function num(v) { const n = Number(v); return isFinite(n) ? n : 0 }
    function pct(v) { return Math.max(0, Math.min(100, num(v))) }
    function gib(v) { return num(v) / 1073741824 }
    function speed(v) {
        const b = num(v)
        if (b >= 1024000) return (b / 1048576).toFixed(b >= 10485760 ? 0 : 1) + " MB/s"   // never four-digit KB/s
        return Math.round(b / 1024) + " KB/s"
    }

    readonly property real cpuPct: pct(cpu.value)
    readonly property real memPct: num(memTotal.value) > 0 ? 100 * num(memUsed.value) / num(memTotal.value) : 0
    readonly property real swapPct: num(swapTotal.value) > 0 ? 100 * num(swapUsed.value) / num(swapTotal.value) : 0
    readonly property real diskPct: pct(diskUsed.value)
    readonly property real temp: num(cpuTemp.value)

    readonly property color warn: "#FF9F0A"
    readonly property color bad: "#FF453A"
    readonly property color good: "#30D158"

    // ---- GPU ------------------------------------------------------------------------------
    // contents/code/gpu reads sysfs every two seconds: whether the card is awake, and for Intel
    // a counter of its idle time (busy = the share of time it was not idle). An NVIDIA card's
    // load needs nvidia-smi, which only runs while the card is already awake. Each query counts
    // as GPU activity, so after three idle readings in a row Vitals leaves the card alone for
    // 30 s to let it fall asleep; while it sleeps the figure reads Off.
    readonly property bool gpuShown: shows("gpu")
    readonly property string gpuTool: "'" + Qt.resolvedUrl("../code/gpu").toString().replace(/^file:\/\//, "") + "'"
    readonly property string gpuWanted: cfg.gpuDevice || "auto"
    property string gpuSlot: ""          // the card being read, once known
    property string gpuVendor: ""
    property bool gpuAwake: true
    property bool gpuCanSleep: false
    property real gpuBusy: -1            // -1 until the first reading
    property real gpuTemp: 0             // °C while awake; NVIDIA and AMD report it (Intel shares the CPU's)
    property var gpuLast: null           // Intel: the previous idle counter and when it was read
    property int gpuTick: 0
    property int gpuIdleReads: 0
    property double gpuQuietUntil: 0
    property bool gpuLoading: false

    onGpuWantedChanged: gpuSlot = ""

    P5Support.DataSource {
        id: gpuRead
        engine: "executable"
        interval: root.rate
        connectedSources: root.gpuShown ? [root.gpuTool + " read " + (root.gpuSlot || root.gpuWanted)] : []
        onNewData: (source, data) => root.gpuTake(data["stdout"] || "")
    }
    P5Support.DataSource {
        id: gpuLoad
        engine: "executable"
        onNewData: (source, data) => { disconnectSource(source); root.gpuLoadTake(data["stdout"] || "") }
    }

    function gpuTake(out) {
        const kv = {}
        out.trim().split(/\s+/).forEach(p => { const i = p.indexOf("="); if (i > 0) kv[p.slice(0, i)] = p.slice(i + 1) })
        if (!kv.slot) { gpuVendor = ""; return }
        if (kv.slot !== gpuSlot) {
            gpuSlot = kv.slot
            gpuLast = null; gpuBusy = -1; gpuTemp = 0; gpuIdleReads = 0; gpuQuietUntil = 0
        }
        gpuVendor = kv.vendor
        gpuCanSleep = kv.pm === "auto"
        gpuAwake = kv.state !== "off"
        if (!gpuAwake) { gpuIdleReads = 0; gpuTemp = 0; return }
        if (kv.busy !== undefined) { gpuBusy = pct(kv.busy); gpuTemp = num(kv.temp); return }
        if (kv.idle !== undefined) {
            const now = Date.now(), idle = num(kv.idle)
            if (gpuLast && now > gpuLast.t) gpuBusy = pct(100 * (1 - (idle - gpuLast.idle) / (now - gpuLast.t)))
            gpuLast = { t: now, idle: idle }
            return
        }
        // NVIDIA: every other reading (four seconds), unless it is being left alone to sleep
        if (kv.vendor === "nvidia" && !gpuLoading && Date.now() >= gpuQuietUntil && gpuTick++ % 2 === 0) {
            gpuLoading = true
            gpuLoad.connectSource(gpuTool + " load " + kv.slot + " #" + Date.now())
        }
    }

    function gpuLoadTake(out) {
        gpuLoading = false
        const parts = out.split(",")                       // "busy, temperature"
        const n = parseFloat(parts[0])
        if (!isFinite(n)) return
        gpuBusy = pct(n)
        const t = parseFloat(parts[1])
        gpuTemp = isFinite(t) ? t : 0
        if (n >= 1) { gpuIdleReads = 0; return }
        if (gpuCanSleep && ++gpuIdleReads >= 3) { gpuIdleReads = 0; gpuQuietUntil = Date.now() + 30000 }
    }

    // One figure for the top row: label, value, unit, how full its bar is, and the bar's colour
    function figure(key) {
        const fg = colors.foreground
        switch (key) {
        case "cpu":
            return { label: tempWithCpu ? "CPU · " + Math.round(temp) + "°" : "CPU",
                     value: Math.round(cpuPct).toString(), unit: "%", fraction: cpuPct / 100,
                     bar: cpuPct >= 90 ? warn : fg }
        case "gpu":
            if (gpuVendor === "" || (gpuAwake && gpuBusy < 0))
                return { label: "GPU", value: "–", unit: "", fraction: 0, bar: fg, status: true }
            if (!gpuAwake)
                return { label: "GPU", value: "Off", unit: "", fraction: 0, bar: fg, status: true }
            return { label: gpuTempShown ? "GPU · " + Math.round(gpuTemp) + "°" : "GPU",
                     value: Math.round(gpuBusy).toString(), unit: "%", fraction: gpuBusy / 100,
                     bar: gpuBusy >= 90 ? warn : fg }
        case "memory":
            return { label: "Memory", value: gib(memUsed.value).toFixed(1), unit: "GB", fraction: memPct / 100,
                     bar: memPct >= 90 ? warn : fg }
        case "swap":
            return { label: "Swap", value: gib(swapUsed.value).toFixed(1), unit: "GB", fraction: swapPct / 100,
                     bar: swapPct >= 90 ? warn : fg }
        case "disk":
            return { label: "Disk free", value: Math.round(gib(diskFree.value)).toString(), unit: "GB",
                     fraction: diskPct / 100, bar: diskPct >= 90 ? bad : fg }
        }
        return { label: "", value: "", unit: "", fraction: 0, bar: fg }
    }

    readonly property bool batteryShown: cfg.showBattery && battery.hasBatteries
    readonly property bool tempShown: cfg.showTemperature && temp > 0
    // The temperature is the CPU's, so it sits beside the CPU label when CPU is a figure; that also
    // keeps the bottom row from crowding. Without a CPU figure it stays in the bottom row.
    readonly property bool tempWithCpu: tempShown && shows("cpu")
    // The GPU's sits beside its label the same way, while the card is awake; it comes with the reading
    // that is taken anyway, so it never wakes the card.
    readonly property bool gpuTempShown: cfg.showGpuTemperature && gpuAwake && gpuTemp > 0
    readonly property bool footerShown: cfg.showNetwork || cfg.showDisk || (tempShown && !tempWithCpu) || batteryShown

    fullRepresentation: Item {
        id: full

        Layout.preferredWidth: full.width > 0 ? full.width : 368
        Layout.preferredHeight: full.height > 0 ? full.height : 144
        Layout.minimumWidth: 288
        Layout.minimumHeight: 112

        // Designed at 368 x 144; everything scales from that, like the widgets it sits beside.
        readonly property real u: Math.min(height / 144, width / 368)
        readonly property real pad: Math.round(20 * u)
        readonly property real small: Math.max(10, Math.round(12 * u))
        readonly property real big: Math.round(34 * u)
        readonly property real smallTrack: 0.025 * small

        LiquidGlass {
            anchors.fill: parent
            radius: Plasmoid.configuration.cornerRadius
            roundness: Plasmoid.configuration.roundnessX10 / 10
            refractThickness: Plasmoid.configuration.refractThickness
            refractIOR: Plasmoid.configuration.refractIORx100 / 100
            refractScale: Plasmoid.configuration.refractScale
            tint: colors.glassTint
            tintAlpha: Plasmoid.configuration.tintAlphaPct / 100
            chromaStrength: Plasmoid.configuration.chromaStrengthPct / 100
            specStrength: Plasmoid.configuration.specStrengthPct / 100
            blurRadius: Plasmoid.configuration.blurRadiusPx
            realtimeRefraction: Plasmoid.configuration.realtimeRefraction
            fallbackOpacity: colors.glassFallbackOpacity
            solidMode: colors.isSolid
            solidColor: colors.solidBackground
        }

        component Metric: Item {
            id: m
            property string label
            property string value
            property string unit
            property real fraction: 0
            property color barColor: colors.foreground
            property bool status: false     // a state ("Off") rather than a number: drawn as secondary text

            implicitHeight: col.implicitHeight

            Column {
                id: col
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: 0

                Text {
                    text: m.label
                    color: colors.foreground
                    opacity: 0.62
                    font.family: root.face
                    font.pixelSize: full.small
                    font.weight: Font.Medium
                    font.letterSpacing: full.smallTrack
                }
                Row {
                    spacing: Math.round(3 * full.u)
                    SwapText {
                        id: valueText
                        text: m.value
                        // a new number costs one frame; only Off turning into a number moves
                        shouldSwap: (from, to) => isNaN(parseFloat(from)) !== isNaN(parseFloat(to))
                        color: colors.foreground
                        opacity: m.status ? 0.62 : 1
                        Behavior on opacity { NumberAnimation { duration: Kirigami.Units.veryLongDuration * 0.75 } }
                        font.family: root.face
                        font.pixelSize: full.big
                        font.weight: Font.ExtraLight
                        font.features: { "tnum": 1 }
                    }
                    Text {
                        visible: m.unit !== ""
                        text: m.unit
                        color: colors.foreground
                        opacity: 0.62
                        font.family: root.face
                        font.pixelSize: Math.round(full.big * 0.42)
                        font.weight: Font.Medium
                        anchors.baseline: valueText.baseline
                    }
                }
                Item { width: 1; height: Math.round(6 * full.u) }
                Rectangle {
                    width: parent.width
                    height: Math.max(3, Math.round(4 * full.u))
                    radius: height / 2
                    color: Qt.rgba(colors.foreground.r, colors.foreground.g, colors.foreground.b, 0.2)
                    Rectangle {
                        visible: m.fraction > 0
                        width: Math.max(parent.height, Math.round(parent.width * Math.max(0, Math.min(1, m.fraction))))
                        height: parent.height
                        radius: height / 2
                        color: m.barColor
                        Behavior on color { ColorAnimation { duration: Kirigami.Units.veryLongDuration } }
                    }
                }
            }
        }

        Row {
            id: metrics
            x: full.pad
            // without a bottom row the figures sit in the middle of the card
            y: root.footerShown ? Math.round(15 * full.u) : Math.round((full.height - height) / 2)
            width: full.width - 2 * full.pad
            spacing: Math.round(22 * full.u)

            readonly property int count: Math.max(1, root.figures.length)
            readonly property real colWidth: (width - (count - 1) * spacing) / count

            Repeater {
                model: root.figures
                Metric {
                    readonly property var f: root.figure(modelData)
                    width: metrics.colWidth
                    label: f.label
                    value: f.value
                    unit: f.unit
                    fraction: f.fraction
                    barColor: f.bar
                    status: f.status === true
                }
            }
        }

        Rectangle {
            id: rule
            visible: root.footerShown
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: footer.top
            anchors.leftMargin: full.pad
            anchors.rightMargin: full.pad
            anchors.bottomMargin: Math.round(10 * full.u)
            height: 1
            color: Qt.rgba(colors.foreground.r, colors.foreground.g, colors.foreground.b, 0.16)
        }

        Item {
            id: footer
            visible: root.footerShown
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: full.pad
            anchors.rightMargin: full.pad
            anchors.bottomMargin: Math.round(16 * full.u)
            height: Math.round(16 * full.u)

            component Small: Text {
                color: colors.foreground
                font.family: root.face
                font.pixelSize: full.small
                font.weight: Font.Medium
                font.letterSpacing: full.smallTrack
                font.features: { "tnum": 1 }
                anchors.verticalCenter: parent.verticalCenter
            }

            Row {
                visible: root.cfg.showNetwork
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                height: parent.height
                spacing: Math.round(5 * full.u)
                Small { text: "↓"; opacity: 0.62 }
                Small { text: root.speed(netDown.value); width: Math.round(56 * full.u) }
                Small { text: "↑"; opacity: 0.62 }
                Small { text: root.speed(netUp.value) }
            }

            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                height: parent.height
                spacing: Math.round(10 * full.u)

                Row {
                    visible: root.cfg.showDisk
                    height: parent.height
                    spacing: Math.round(5 * full.u)

                    // drive glyph, drawn like the battery: outline, slot, light
                    Rectangle {
                        width: Math.round(16 * full.u)
                        height: Math.round(10 * full.u)
                        radius: Math.round(2.6 * full.u)
                        anchors.verticalCenter: parent.verticalCenter
                        color: "transparent"
                        border.width: 1
                        border.color: Qt.rgba(colors.foreground.r, colors.foreground.g, colors.foreground.b, 0.55)
                        Rectangle {
                            x: Math.round(3 * full.u)
                            width: Math.round(5 * full.u)
                            height: 1
                            anchors.verticalCenter: parent.verticalCenter
                            color: Qt.rgba(colors.foreground.r, colors.foreground.g, colors.foreground.b, 0.55)
                        }
                        Rectangle {
                            width: Math.max(2, Math.round(2.2 * full.u))
                            height: width
                            radius: width / 2
                            x: parent.width - width - Math.round(3 * full.u)
                            anchors.verticalCenter: parent.verticalCenter
                            color: Qt.rgba(colors.foreground.r, colors.foreground.g, colors.foreground.b, 0.55)
                        }
                    }
                    Small { text: Math.round(root.gib(diskFree.value)) + " GB" }
                }

                Small {
                    visible: root.tempShown && !root.tempWithCpu
                    text: Math.round(root.temp) + "°"
                    color: root.temp >= 90 ? root.bad : (root.temp >= 80 ? root.warn : colors.foreground)
                    Behavior on color { ColorAnimation { duration: Kirigami.Units.veryLongDuration } }
                }

                Row {
                    visible: root.batteryShown
                    height: parent.height
                    spacing: Math.round(5 * full.u)

                    // battery glyph: outline, level, terminal
                    Item {
                        width: Math.round(23 * full.u)
                        height: Math.round(11 * full.u)
                        anchors.verticalCenter: parent.verticalCenter
                        Rectangle {
                            id: shell
                            width: parent.width - Math.round(3 * full.u)
                            height: parent.height
                            radius: Math.round(3.2 * full.u)
                            color: "transparent"
                            border.width: 1
                            border.color: Qt.rgba(colors.foreground.r, colors.foreground.g, colors.foreground.b, 0.55)
                            Rectangle {
                                x: 2; y: 2
                                height: parent.height - 4
                                width: Math.max(2, Math.round((parent.width - 4) * battery.percent / 100))
                                radius: Math.max(1, shell.radius - 2)
                                color: battery.state === BatteryControlModel.Charging || battery.state === BatteryControlModel.FullyCharged
                                       ? root.good
                                       : (battery.percent <= 15 ? root.bad : colors.foreground)
                            }
                        }
                        Rectangle {
                            x: shell.width + 1
                            width: Math.max(1, Math.round(1.6 * full.u))
                            height: Math.round(4 * full.u)
                            radius: width / 2
                            anchors.verticalCenter: parent.verticalCenter
                            color: Qt.rgba(colors.foreground.r, colors.foreground.g, colors.foreground.b, 0.55)
                        }
                    }
                    Small { text: battery.percent + "%" }
                }
            }
        }
    }
}

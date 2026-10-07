/*
    Vitals: CPU, memory and disk as three figures with thin bars; network, temperature and
    battery on a quiet bottom row. Drawn on the same glass as the Liquid Glass widgets.

    Performance rule for this widget: nothing animates continuously. Values change at most
    every two seconds and each change costs one frame.
*/
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.ksysguard.sensors as Sensors
import org.kde.plasma.private.battery
import "components"

PlasmoidItem {
    id: root

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: fullRepresentation

    width: 368
    height: 144

    readonly property int rate: 2000
    readonly property string face: "Inter Display"

    MacOSColors {
        id: colors
        styleMode: Plasmoid.configuration.styleMode
        appearance: Plasmoid.configuration.appearance
    }

    Sensors.Sensor { id: cpu;      sensorId: "cpu/all/usage";               updateRateLimit: root.rate }
    Sensors.Sensor { id: cpuTemp;  sensorId: "cpu/all/averageTemperature";  updateRateLimit: root.rate * 2 }
    Sensors.Sensor { id: memUsed;  sensorId: "memory/physical/used";        updateRateLimit: root.rate }
    Sensors.Sensor { id: memTotal; sensorId: "memory/physical/total";       updateRateLimit: 60000 }
    Sensors.Sensor { id: diskFree; sensorId: "disk/all/free";               updateRateLimit: 30000 }
    Sensors.Sensor { id: diskUsed; sensorId: "disk/all/usedPercent";        updateRateLimit: 30000 }
    Sensors.Sensor { id: netDown;  sensorId: "network/all/download";        updateRateLimit: root.rate }
    Sensors.Sensor { id: netUp;    sensorId: "network/all/upload";          updateRateLimit: root.rate }

    BatteryControlModel { id: battery }

    function num(v) { const n = Number(v); return isFinite(n) ? n : 0 }
    function gib(v) { return num(v) / 1073741824 }
    function speed(v) {
        const b = num(v)
        if (b >= 1048576) return (b / 1048576).toFixed(b >= 10485760 ? 0 : 1) + " MB/s"
        return Math.round(b / 1024) + " KB/s"
    }

    readonly property real cpuPct: Math.max(0, Math.min(100, num(cpu.value)))
    readonly property real memPct: num(memTotal.value) > 0 ? 100 * num(memUsed.value) / num(memTotal.value) : 0
    readonly property real diskPct: Math.max(0, Math.min(100, num(diskUsed.value)))
    readonly property real temp: num(cpuTemp.value)
    readonly property bool onBattery: battery.hasBatteries && !battery.pluggedIn

    readonly property color warn: "#FF9F0A"
    readonly property color bad: "#FF453A"
    readonly property color good: "#30D158"

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
                }
                Row {
                    spacing: Math.round(3 * full.u)
                    Text {
                        id: valueText
                        text: m.value
                        color: colors.foreground
                        font.family: root.face
                        font.pixelSize: full.big
                        font.weight: Font.ExtraLight
                        font.features: { "tnum": 1 }
                    }
                    Text {
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
                        width: Math.max(parent.height, Math.round(parent.width * Math.max(0, Math.min(1, m.fraction))))
                        height: parent.height
                        radius: height / 2
                        color: m.barColor
                    }
                }
            }
        }

        Row {
            id: metrics
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: full.pad
            anchors.topMargin: Math.round(15 * full.u)
            spacing: Math.round(22 * full.u)

            readonly property real colWidth: (width - 2 * spacing) / 3

            Metric {
                width: metrics.colWidth
                label: "CPU"
                value: Math.round(root.cpuPct).toString()
                unit: "%"
                fraction: root.cpuPct / 100
                barColor: root.cpuPct >= 90 ? root.warn : colors.foreground
            }
            Metric {
                width: metrics.colWidth
                label: "Memory"
                value: root.gib(memUsed.value).toFixed(1)
                unit: "GB"
                fraction: root.memPct / 100
                barColor: root.memPct >= 90 ? root.warn : colors.foreground
            }
            Metric {
                width: metrics.colWidth
                label: "Disk free"
                value: Math.round(root.gib(diskFree.value)).toString()
                unit: "GB"
                fraction: root.diskPct / 100
                barColor: root.diskPct >= 90 ? root.bad : colors.foreground
            }
        }

        Rectangle {
            id: rule
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
                font.features: { "tnum": 1 }
                anchors.verticalCenter: parent.verticalCenter
            }

            Row {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                height: parent.height
                spacing: Math.round(5 * full.u)
                Small { text: "↓"; opacity: 0.62 }
                Small { text: root.speed(netDown.value); width: Math.round(62 * full.u) }
                Small { text: "↑"; opacity: 0.62 }
                Small { text: root.speed(netUp.value) }
            }

            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                height: parent.height
                spacing: Math.round(10 * full.u)

                Small {
                    visible: root.temp > 0
                    text: Math.round(root.temp) + "°"
                    color: root.temp >= 90 ? root.bad : (root.temp >= 80 ? root.warn : colors.foreground)
                }

                Row {
                    visible: battery.hasBatteries
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

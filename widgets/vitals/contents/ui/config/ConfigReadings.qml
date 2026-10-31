/*
    Readings: what the Vitals card shows. The controls sit where their readings sit on the card:
    three menus across the top for the figures, the bottom-row items under a rule, grouped in a
    rounded panel like the card. Which GPU to read is a quiet sub-menu under the menu that shows
    the GPU, and only when the computer has more than one. A temperature is ticked under the figure
    it belongs to, because that is where it shows on the card.
*/
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as P5Support

ColumnLayout {
    id: page
    spacing: Kirigami.Units.smallSpacing

    property string cfg_figureLeft
    property string cfg_figureMiddle
    property string cfg_figureRight
    property string cfg_gpuDevice
    property bool cfg_showNetwork
    property bool cfg_showDisk
    property bool cfg_showTemperature
    property bool cfg_showGpuTemperature
    property bool cfg_showBattery

    readonly property var choices: [
        { value: "cpu", text: "CPU" },
        { value: "gpu", text: "GPU" },
        { value: "memory", text: "Memory" },
        { value: "swap", text: "Swap" },
        { value: "disk", text: "Disk free" },
        { value: "none", text: "Nothing" }
    ]
    readonly property bool gpuUsed: [cfg_figureLeft, cfg_figureMiddle, cfg_figureRight].indexOf("gpu") >= 0
    readonly property bool cpuUsed: [cfg_figureLeft, cfg_figureMiddle, cfg_figureRight].indexOf("cpu") >= 0
    // NVIDIA and AMD report a temperature; Intel graphics share the CPU's
    readonly property bool gpuHasTemp: {
        const g = gpus.find(g => g.value === cfg_gpuDevice) || gpus[0]
        return !!g && (g.vendor === "NVIDIA" || g.vendor === "AMD")
    }
    readonly property real gutter: Kirigami.Units.largeSpacing * 2

    // The computer's graphics cards, from contents/code/gpu (sysfs only, so listing wakes nothing)
    property var gpus: []
    P5Support.DataSource {
        engine: "executable"
        connectedSources: ["'" + Qt.resolvedUrl("../../code/gpu").toString().replace(/^file:\/\//, "") + "' list"]
        onNewData: (source, data) => {
            disconnectSource(source)
            const names = { nvidia: "NVIDIA", intel: "Intel", amd: "AMD", other: "Other" }
            const found = (data["stdout"] || "").trim().split("\n").filter(l => l).map(l => {
                const [slot, vendor, kind] = l.split(" ")
                return { value: slot, text: (names[vendor] || vendor) + ", " + kind, vendor: names[vendor] || vendor, kind: kind }
            })
            const first = found.find(g => g.kind === "dedicated") || found[0]
            page.gpus = [{ value: "auto", text: first ? "Auto (" + first.vendor + ")" : "Auto",
                           vendor: first ? first.vendor : "" }].concat(found)
        }
    }

    // One place on the card: the figure's menu, and under it the GPU's sub-menu when it shows the GPU
    component Place: ColumnLayout {
        id: place
        property string name
        property string current
        signal picked(string value)
        Layout.fillWidth: true
        Layout.preferredWidth: 1            // the three share the width equally, like the figures
        Layout.alignment: Qt.AlignTop
        spacing: Kirigami.Units.smallSpacing

        QQC2.ComboBox {
            Layout.fillWidth: true
            model: page.choices
            textRole: "text"
            valueRole: "value"
            currentIndex: Math.max(0, page.choices.findIndex(c => c.value === place.current))
            onActivated: place.picked(currentValue)
            Accessible.name: place.name + " figure"
        }
        // the figure's own temperature, which shows beside its name on the card
        QQC2.CheckBox {
            readonly property bool cpu: place.current === "cpu"
            visible: cpu || (place.current === "gpu" && page.gpuHasTemp)
            text: "Temperature"
            checked: cpu ? page.cfg_showTemperature : page.cfg_showGpuTemperature
            onToggled: {
                if (cpu) page.cfg_showTemperature = checked
                else page.cfg_showGpuTemperature = checked
            }
            Accessible.name: (cpu ? "CPU" : "GPU") + " temperature"
        }
        QQC2.ComboBox {
            Layout.fillWidth: true
            visible: place.current === "gpu" && page.gpus.length > 2
            flat: true
            font: Kirigami.Theme.smallFont
            model: page.gpus
            textRole: "text"
            valueRole: "value"
            currentIndex: Math.max(0, page.gpus.findIndex(g => g.value === page.cfg_gpuDevice))
            onActivated: page.cfg_gpuDevice = currentValue
            Accessible.name: "GPU to read"
        }
    }

    Rectangle {
        id: group
        Layout.fillWidth: true
        Layout.maximumWidth: Kirigami.Units.gridUnit * 34
        Layout.leftMargin: page.gutter
        Layout.rightMargin: page.gutter
        Layout.topMargin: page.gutter
        implicitHeight: inner.implicitHeight + 2 * Kirigami.Units.gridUnit
        radius: Kirigami.Units.cornerRadius * 2.5
        Kirigami.Theme.colorSet: Kirigami.Theme.View
        Kirigami.Theme.inherit: false
        color: Kirigami.Theme.backgroundColor
        border.width: 1
        border.color: Kirigami.ColorUtils.linearInterpolation(Kirigami.Theme.backgroundColor, Kirigami.Theme.textColor, 0.12)

        ColumnLayout {
            id: inner
            anchors.fill: parent
            anchors.margins: Kirigami.Units.gridUnit
            spacing: Kirigami.Units.gridUnit

            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.largeSpacing
                Place { name: "Left"; current: page.cfg_figureLeft; onPicked: value => page.cfg_figureLeft = value }
                Place { name: "Middle"; current: page.cfg_figureMiddle; onPicked: value => page.cfg_figureMiddle = value }
                Place { name: "Right"; current: page.cfg_figureRight; onPicked: value => page.cfg_figureRight = value }
            }

            Kirigami.Separator { Layout.fillWidth: true }

            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.largeSpacing
                QQC2.CheckBox {
                    text: "Network"
                    checked: page.cfg_showNetwork
                    onToggled: page.cfg_showNetwork = checked
                }
                Item { Layout.fillWidth: true }
                QQC2.CheckBox {
                    text: "Disk free"
                    checked: page.cfg_showDisk
                    onToggled: page.cfg_showDisk = checked
                }
                QQC2.CheckBox {
                    visible: !page.cpuUsed          // without a CPU figure it stays in this row
                    text: "CPU temperature"
                    checked: page.cfg_showTemperature
                    onToggled: page.cfg_showTemperature = checked
                }
                QQC2.CheckBox {
                    text: "Battery"
                    checked: page.cfg_showBattery
                    onToggled: page.cfg_showBattery = checked
                }
            }
        }
    }

    // footnote under the group, as in grouped settings
    QQC2.Label {
        Layout.fillWidth: true
        Layout.maximumWidth: group.Layout.maximumWidth - 2 * Kirigami.Units.gridUnit
        Layout.leftMargin: page.gutter + Kirigami.Units.gridUnit
        Layout.rightMargin: page.gutter + Kirigami.Units.gridUnit
        wrapMode: Text.Wrap
        font: Kirigami.Theme.smallFont
        opacity: 0.7
        text: "The menus are the card's figures, left to right; Nothing leaves a place empty."
              + (page.gpuUsed ? " A dedicated GPU that is asleep reads Off: Vitals never wakes it to take a reading." : "")
    }

    Item { Layout.fillHeight: true }
}

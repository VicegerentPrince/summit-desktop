/*
    Timer: which layout the card uses, shown as small sketches of the card, and its presets.
    Wheels → Ring picks the time on the wheels and counts down in the ring.
*/
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

ColumnLayout {
    id: page
    spacing: Kirigami.Units.smallSpacing

    property int cfg_timerFace
    property var cfg_presets: []
    property var cfg_presetsDefault: []

    readonly property color ink: Kirigami.Theme.textColor

    function nameOf(s) { const i = s.indexOf("|"); return i < 0 ? "" : s.slice(i + 1) }
    function replaced(index, mins, name) {
        const list = Array.from(cfg_presets)
        list[index] = mins + "|" + name
        cfg_presets = list
    }
    function moved(index, by) {
        const list = Array.from(cfg_presets)
        const item = list.splice(index, 1)[0]
        list.splice(index + by, 0, item)
        cfg_presets = list
    }

    component Pill: Rectangle { radius: height / 2; color: page.ink; opacity: 0.28 }
    // the sketches' small parts, in proportion to a tile
    QtObject { id: paper2; readonly property real pw: tiles.width * 0.045; readonly property real ph: pw * 0.43 }

    component Tile: ColumnLayout {
        id: tile
        property int value
        property string name
        default property alias sketch: paper.data
        readonly property bool chosen: page.cfg_timerFace === value
        Layout.fillWidth: true
        Layout.preferredWidth: 1
        spacing: Kirigami.Units.smallSpacing

        Rectangle {
            id: paper
            Layout.fillWidth: true
            Layout.preferredHeight: width * 176 / 368
            radius: height * 0.2
            color: Qt.rgba(page.ink.r, page.ink.g, page.ink.b, 0.05)
            border.width: tile.chosen ? 2 : 1
            border.color: tile.chosen ? Kirigami.Theme.highlightColor : Qt.rgba(page.ink.r, page.ink.g, page.ink.b, 0.15)
            MouseArea { z: 2; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: page.cfg_timerFace = tile.value }
        }
        QQC2.RadioButton {
            Layout.alignment: Qt.AlignHCenter
            text: tile.name
            checked: tile.chosen
            onToggled: page.cfg_timerFace = tile.value
        }
    }

    SettingsGroup {
        RowLayout {
            id: tiles
            Layout.fillWidth: true
            spacing: Kirigami.Units.largeSpacing

            Tile {
                value: 3; name: "Wheels → Ring"
                Rectangle {
                    x: parent.width * 0.06; anchors.verticalCenter: parent.verticalCenter
                    width: parent.height * 0.74; height: width; radius: width / 2
                    color: "transparent"; border.width: Math.max(2, width * 0.05); border.color: "#FF9F0A"
                }
                Rectangle { x: parent.width * 0.52; y: parent.height * 0.41; width: parent.width * 0.26; height: parent.height * 0.18; radius: height * 0.35; color: page.ink; opacity: 0.16 }
                Column {
                    x: parent.width * 0.56; anchors.verticalCenter: parent.verticalCenter; spacing: parent.height * 0.05
                    Repeater { model: 3; Rectangle { width: paper2.pw * 0.8; height: paper2.ph * 0.42; radius: height / 2; color: page.ink; opacity: index === 1 ? 0.7 : 0.25 } }
                }
                Rectangle { x: parent.width * 0.83; anchors.verticalCenter: parent.verticalCenter; width: parent.height * 0.22; height: width; radius: width / 2; color: "#00A832"; opacity: 0.9 }
            }
            Tile {
                value: 0; name: "Wheels"
                Grid {
                    x: parent.width * 0.06; y: parent.height * 0.2; columns: 2; spacing: parent.width * 0.016
                    Repeater { model: 6; Pill { width: paper2.pw; height: paper2.ph } }
                }
                Rectangle { x: parent.width * 0.52; y: parent.height * 0.41; width: parent.width * 0.3; height: parent.height * 0.18; radius: height * 0.35; color: page.ink; opacity: 0.16 }
                Column {
                    x: parent.width * 0.56; anchors.verticalCenter: parent.verticalCenter; spacing: parent.height * 0.05
                    Repeater { model: 3; Rectangle { width: paper2.pw * 0.8; height: paper2.ph * 0.42; radius: height / 2; color: page.ink; opacity: index === 1 ? 0.7 : 0.25 } }
                }
                Rectangle { x: parent.width * 0.85; anchors.verticalCenter: parent.verticalCenter; width: parent.height * 0.22; height: width; radius: width / 2; color: "#00A832"; opacity: 0.9 }
            }
            Tile {
                value: 1; name: "Ring"
                Rectangle {
                    x: parent.width * 0.06; anchors.verticalCenter: parent.verticalCenter
                    width: parent.height * 0.74; height: width; radius: width / 2
                    color: "transparent"; border.width: Math.max(2, width * 0.05); border.color: "#FF9F0A"
                    QQC2.Label { anchors.centerIn: parent; text: "25:00"; font.pixelSize: parent.width * 0.27; font.weight: Font.Light }
                }
                Grid {
                    x: parent.width * 0.5; y: parent.height * 0.14; columns: 2; spacing: parent.width * 0.02
                    Repeater { model: 6; Pill { width: paper3.pw; height: paper3.ph; radius: height * 0.35 } }
                }
                Item { id: paper3; readonly property real pw: parent.width * 0.21; readonly property real ph: parent.height * 0.22 }
            }
            Tile {
                value: 2; name: "Bar"
                QQC2.Label { x: parent.width * 0.06; y: parent.height * 0.09; text: "25:00"; font.pixelSize: parent.height * 0.34; font.weight: Font.Light }
                Rectangle { x: parent.width * 0.8; y: parent.height * 0.17; width: parent.height * 0.26; height: width; radius: width / 2; color: "#00A832"; opacity: 0.9 }
                Rectangle {
                    x: parent.width * 0.06; y: parent.height * 0.58; width: parent.width * 0.88; height: Math.max(2, parent.height * 0.03); radius: height / 2; color: page.ink; opacity: 0.25
                }
                Row {
                    x: parent.width * 0.06; y: parent.height * 0.7; spacing: parent.width * 0.018
                    Repeater { model: 6; Pill { width: parent.parent.width * 0.132; height: parent.parent.height * 0.17 } }
                }
            }
        }
    }

    SettingsGroup {
        Repeater {
            model: page.cfg_presets
            delegate: RowLayout {
                required property string modelData
                required property int index
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing
                QQC2.SpinBox {
                    id: minutes
                    from: 1; to: 99; editable: true
                    value: parseInt(modelData) || 1
                    onValueModified: page.replaced(index, value, name.text)
                    Accessible.name: "Minutes"
                }
                QQC2.Label { text: "min"; opacity: 0.7 }
                QQC2.TextField {
                    id: name
                    Layout.fillWidth: true
                    Layout.leftMargin: Kirigami.Units.smallSpacing
                    placeholderText: "Name (optional)"
                    text: page.nameOf(modelData)
                    onEditingFinished: if (text !== page.nameOf(modelData)) page.replaced(index, minutes.value, text)
                }
                QQC2.ToolButton {
                    icon.name: "go-up"; text: "Move up"; display: QQC2.AbstractButton.IconOnly
                    enabled: index > 0
                    onClicked: page.moved(index, -1)
                }
                QQC2.ToolButton {
                    icon.name: "go-down"; text: "Move down"; display: QQC2.AbstractButton.IconOnly
                    enabled: index < page.cfg_presets.length - 1
                    onClicked: page.moved(index, 1)
                }
                QQC2.ToolButton {
                    icon.name: "list-remove"; text: "Remove"; display: QQC2.AbstractButton.IconOnly
                    enabled: page.cfg_presets.length > 1
                    onClicked: { const l = Array.from(page.cfg_presets); l.splice(index, 1); page.cfg_presets = l }
                }
            }
        }
        QQC2.Button {
            icon.name: "list-add"
            text: "Add preset"
            enabled: page.cfg_presets.length < 6
            onClicked: page.cfg_presets = Array.from(page.cfg_presets).concat(["30|"])
        }
    }

    Footnote { text: "Click a preset on the card to start it. For any other time, scroll the wheels or the digits. The card holds six presets." }

    Item { Layout.fillHeight: true }
}

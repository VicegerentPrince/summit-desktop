// One setting in a group: its name on the left, the control on the right, as in System Settings
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

RowLayout {
    id: row
    property string title
    property string hint: ""
    default property alias control: slot.data
    Layout.fillWidth: true
    spacing: Kirigami.Units.largeSpacing

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 0
        QQC2.Label { Layout.fillWidth: true; text: row.title; elide: Text.ElideRight }
        QQC2.Label {
            Layout.fillWidth: true
            visible: row.hint !== ""
            text: row.hint
            wrapMode: Text.Wrap
            font: Kirigami.Theme.smallFont
            opacity: 0.7
        }
    }
    RowLayout { id: slot; spacing: Kirigami.Units.smallSpacing }
}

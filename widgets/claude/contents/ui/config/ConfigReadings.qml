// Claude: when the bars change colour.
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

ColumnLayout {
    id: page
    spacing: Kirigami.Units.smallSpacing

    property bool cfg_warnColours
    property int cfg_warnAt
    property int cfg_alertAt

    SettingsGroup {
        SettingRow {
            title: "Warning colours"
            hint: "Colour the figure and its bar as a limit gets close"
            QQC2.Switch { checked: page.cfg_warnColours; onToggled: page.cfg_warnColours = checked }
        }
        Kirigami.Separator { Layout.fillWidth: true }
        SettingRow {
            title: "Orange from"
            enabled: page.cfg_warnColours
            QQC2.SpinBox {
                from: 10; to: page.cfg_alertAt - 1; stepSize: 5; value: page.cfg_warnAt
                textFromValue: v => v + " %"
                valueFromText: t => parseInt(t)
                onValueModified: page.cfg_warnAt = value
            }
        }
        Kirigami.Separator { Layout.fillWidth: true }
        SettingRow {
            title: "Red from"
            enabled: page.cfg_warnColours
            QQC2.SpinBox {
                from: page.cfg_warnAt + 1; to: 100; stepSize: 5; value: page.cfg_alertAt
                textFromValue: v => v + " %"
                valueFromText: t => parseInt(t)
                onValueModified: page.cfg_alertAt = value
            }
        }
    }
    Item { Layout.fillHeight: true }
}

// Clock: how the time reads.
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

ColumnLayout {
    id: page
    spacing: Kirigami.Units.smallSpacing

    property int cfg_hourFormat
    property int cfg_digitStyle

    SettingsGroup {
        SettingRow {
            title: "Time format"
            QQC2.ComboBox {
                model: ["12-hour", "24-hour"]
                currentIndex: page.cfg_hourFormat
                onActivated: page.cfg_hourFormat = currentIndex
            }
        }
        Kirigami.Separator { Layout.fillWidth: true }
        SettingRow {
            title: "Digits"
            QQC2.ComboBox {
                model: ["Soft", "Clear", "Thin"]
                currentIndex: page.cfg_digitStyle
                onActivated: page.cfg_digitStyle = currentIndex
            }
        }
    }
    Footnote { text: "Soft lets the glass show through the digits. Clear reads better at a glance. Thin matches the figures on Vitals." }
    Item { Layout.fillHeight: true }
}

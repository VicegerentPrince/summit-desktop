// GitHub: which sections the card shows and how often it asks.
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

ColumnLayout {
    id: page
    spacing: Kirigami.Units.smallSpacing

    property bool cfg_showBuilds
    property bool cfg_showPullRequests
    property bool cfg_showForYou
    property int cfg_refreshMinutes

    readonly property var steps: [1, 5, 15, 30]

    SettingsGroup {
        SettingRow {
            title: "Builds"
            hint: "The last run in the repositories you pushed to"
            QQC2.Switch { checked: page.cfg_showBuilds; onToggled: page.cfg_showBuilds = checked }
        }
        Kirigami.Separator { Layout.fillWidth: true }
        SettingRow {
            title: "Pull requests"
            hint: "Yours, with their checks"
            QQC2.Switch { checked: page.cfg_showPullRequests; onToggled: page.cfg_showPullRequests = checked }
        }
        Kirigami.Separator { Layout.fillWidth: true }
        SettingRow {
            title: "For you"
            hint: "Reviews asked of you, and mentions"
            QQC2.Switch { checked: page.cfg_showForYou; onToggled: page.cfg_showForYou = checked }
        }
    }
    SettingsGroup {
        SettingRow {
            title: "Refresh"
            QQC2.ComboBox {
                model: page.steps.map(m => m === 1 ? "Every minute" : "Every " + m + " minutes")
                currentIndex: Math.max(0, page.steps.indexOf(page.cfg_refreshMinutes))
                onActivated: page.cfg_refreshMinutes = page.steps[currentIndex]
            }
        }
    }
    Footnote { text: "Each refresh makes about six requests to GitHub, through the gh login you already have. The card also refreshes when you point at it." }
    Item { Layout.fillHeight: true }
}

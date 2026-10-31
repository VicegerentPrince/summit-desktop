// Quiet text under a group
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

QQC2.Label {
    readonly property real gutter: Kirigami.Units.largeSpacing * 2 + Kirigami.Units.gridUnit
    Layout.fillWidth: true
    Layout.maximumWidth: Kirigami.Units.gridUnit * 32
    Layout.leftMargin: gutter
    Layout.rightMargin: gutter
    wrapMode: Text.Wrap
    font: Kirigami.Theme.smallFont
    opacity: 0.7
}

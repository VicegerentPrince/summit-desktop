// A rounded group of settings, in the style of the Vitals Readings page
import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Rectangle {
    id: group
    default property alias rows: inner.data
    Layout.fillWidth: true
    Layout.maximumWidth: Kirigami.Units.gridUnit * 34
    Layout.leftMargin: Kirigami.Units.largeSpacing * 2
    Layout.rightMargin: Kirigami.Units.largeSpacing * 2
    Layout.topMargin: Kirigami.Units.largeSpacing * 2
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
        spacing: Kirigami.Units.largeSpacing
    }
}

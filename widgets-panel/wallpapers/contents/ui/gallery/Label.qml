import QtQuick
import org.kde.kirigami as Kirigami

// Text on glass: a little heavier than flat text, with tracking that follows its size.
Text {
    property real level: 1          // 1 primary, 0.68 secondary
    color: Qt.rgba(1, 1, 1, 0.97 * level)
    font.family: Kirigami.Theme.defaultFont.family
    property int px: 13
    font.pixelSize: px
    font.weight: Font.Medium
    font.letterSpacing: px >= 20 ? -0.3 : px <= 12 ? 0.15 : 0
    renderType: Text.QtRendering
    verticalAlignment: Text.AlignVCenter
    elide: Text.ElideRight
}

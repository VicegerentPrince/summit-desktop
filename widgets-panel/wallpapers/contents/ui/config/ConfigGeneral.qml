import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    property alias cfg_matchAccent: accent.checked
    property bool cfg_matchAccentDefault: false

    Kirigami.FormLayout {
        QQC2.CheckBox {
            id: accent
            Kirigami.FormData.label: "Accent colour:"
            text: "Take it from each wallpaper"
        }
        QQC2.Label {
            Layout.maximumWidth: Kirigami.Units.gridUnit * 24
            wrapMode: Text.WordWrap
            opacity: 0.75
            text: "Picks a colour from the photo for highlights, buttons, focus rings and the task bar, "
                + "checked for readable contrast in your colour scheme (WCAG AA). Turning it off puts "
                + "your colour scheme's own accent back. Needs Python's Pillow library."
        }
        Item { Kirigami.FormData.isSection: true }
        QQC2.Label {
            Kirigami.FormData.label: "Library:"
            text: "~/Pictures/Wallpapers"
        }
        QQC2.Label {
            Layout.maximumWidth: Kirigami.Units.gridUnit * 24
            wrapMode: Text.WordWrap
            opacity: 0.75
            text: "Any picture you put in this folder appears in the gallery. Scroll on the panel icon to "
                + "step through them, middle-click it for a random one."
        }
    }
}

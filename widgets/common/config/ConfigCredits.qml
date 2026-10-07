// Credits page shared by the Summit widgets. widgets/assemble.sh sets the two flags per widget.
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    readonly property bool glass: @GLASS@        // drawn with the Liquid Glass component
    readonly property bool photos: @PHOTOS@      // shows photos from Wallhaven

    ColumnLayout {
        spacing: Kirigami.Units.largeSpacing

        Kirigami.Heading { text: "Summit"; level: 2 }
        QQC2.Label {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: "Part of Summit, a glass desktop and terminal setup for Plasma 6 by Muhammad Muneeb. "
                + "The full setup, the other widgets and the source are on GitHub."
        }
        Kirigami.UrlButton { url: "https://github.com/VicegerentPrince/summit-desktop" }

        Kirigami.Separator { Layout.fillWidth: true; visible: glass }
        Kirigami.Heading { text: "Glass"; level: 2; visible: glass }
        QQC2.Label {
            visible: glass
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: "The glass this card is drawn on, and its Appearance settings, come from Liquid Glass "
                + "by Jack Faith (jaxparrow07), used under the GNU GPL 3.0. His clock, calendar, weather, "
                + "music and other widgets are on the KDE Store and on GitHub. If you like the look, "
                + "consider supporting him."
        }
        Kirigami.UrlButton { visible: glass; url: "https://github.com/jaxparrow07/liquidglass-kde-widgets" }
        Kirigami.UrlButton { visible: glass; url: "https://ko-fi.com/devrinth"; text: "Support Jack Faith on Ko-fi" }

        Kirigami.Separator { Layout.fillWidth: true; visible: photos }
        Kirigami.Heading { text: "Photos"; level: 2; visible: photos }
        QQC2.Label {
            visible: photos
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: "Discover searches Wallhaven (safe-for-work General category only). Each photo belongs "
                + "to its photographer; check the picture's page on Wallhaven before using it elsewhere."
        }
        Kirigami.UrlButton { visible: photos; url: "https://wallhaven.cc" }

        Kirigami.Separator { Layout.fillWidth: true }
        QQC2.Label {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            opacity: 0.7
            text: "Licence: GNU General Public License 3.0." + (glass ? " Font: Inter by Rasmus Andersson, SIL Open Font Licence." : "")
        }
    }
}

import QtQuick
import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory { name: "Gallery"; icon: "view-preview"; source: "config/ConfigGallery.qml" }
    ConfigCategory { name: "General"; icon: "preferences-desktop-wallpaper"; source: "config/ConfigGeneral.qml" }
    ConfigCategory { name: "Credits"; icon: "help-about"; source: "config/ConfigCredits.qml" }
}

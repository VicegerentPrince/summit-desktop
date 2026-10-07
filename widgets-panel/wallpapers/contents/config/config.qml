import QtQuick
import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory { name: "General"; icon: "preferences-desktop-wallpaper"; source: "config/ConfigGeneral.qml" }
    ConfigCategory { name: "Credits"; icon: "help-about"; source: "config/ConfigCredits.qml" }
}

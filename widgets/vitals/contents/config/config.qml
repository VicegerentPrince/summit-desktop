import QtQuick
import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory { name: "Appearance"; icon: "preferences-desktop-theme"; source: "config/ConfigAppearance.qml" }
    ConfigCategory { name: "Credits"; icon: "help-about"; source: "config/ConfigCredits.qml" }
}

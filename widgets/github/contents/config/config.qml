import QtQuick
import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory { name: "Sections"; icon: "view-list-details"; source: "config/ConfigSections.qml" }
    ConfigCategory { name: "Links"; icon: "internet-web-browser"; source: "config/ConfigLinks.qml" }
    ConfigCategory { name: "Appearance"; icon: "preferences-desktop-theme"; source: "config/ConfigAppearance.qml" }
    ConfigCategory { name: "Credits"; icon: "help-about"; source: "config/ConfigCredits.qml" }
}

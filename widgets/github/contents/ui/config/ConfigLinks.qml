// GitHub: where the card's links open. Automatic finds the Chrome profile signed in with your GitHub
// email; the list shows every profile by its picture and email, because Chrome lets names repeat.
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as P5Support

ColumnLayout {
    id: page
    spacing: Kirigami.Units.smallSpacing

    property string cfg_linkProfile
    property bool cfg_linkNewWindow

    property var found: ({ email: "", match: "", profiles: [] })
    readonly property var matched: found.profiles.find(p => p.folder === found.match) || null
    readonly property var options: {
        const list = []
        if (found.profiles.length > 0) {
            list.push(matched
                ? { value: "auto", title: "Automatic", detail: matched.name + " · " + matched.email, picture: matched.picture, letter: matched.name }
                : { value: "auto", title: "Automatic", detail: "No profile matches, so your default browser", icon: "internet-web-browser" })
            for (const p of found.profiles)
                list.push({ value: p.folder, title: p.name, detail: p.email, picture: p.picture, letter: p.name })
        }
        list.push({ value: "browser", title: "Default browser", detail: "Where your other links open", icon: "internet-web-browser" })
        return list
    }
    readonly property bool usesChrome: cfg_linkProfile !== "browser" && (cfg_linkProfile !== "auto" || matched !== null)
    readonly property string note: {
        if (found.profiles.length === 0) return "Links open in your default browser, because Google Chrome was not found."
        if (matched) return "Automatic uses the Chrome profile signed in with " + found.email + ", the email on your GitHub account."
        if (found.email) return "No Chrome profile is signed in with " + found.email + ", so Automatic uses your default browser."
        return "Your GitHub account shows no email, so Automatic uses your default browser."
    }

    P5Support.DataSource {
        engine: "executable"
        connectedSources: ["python3 -I '" + decodeURIComponent(Qt.resolvedUrl("../../code/github.py").toString().replace(/^file:\/\//, "")) + "' --profiles"]
        onNewData: (source, data) => {
            disconnectSource(source)
            try {
                page.found = JSON.parse(data["stdout"])
            } catch (e) { }
        }
    }

    // One choice: a picture or initial, the name, and what tells it apart
    component Choice: RowLayout {
        id: choice
        property var item: ({})
        property bool current: false
        spacing: Kirigami.Units.largeSpacing
        readonly property real size: Kirigami.Units.iconSizes.medium

        Rectangle {
            implicitWidth: choice.size
            implicitHeight: choice.size
            radius: width / 2
            visible: !choice.item.icon
            color: Kirigami.ColorUtils.linearInterpolation(Kirigami.Theme.backgroundColor, Kirigami.Theme.highlightColor, 0.55)
            QQC2.Label {
                anchors.centerIn: parent
                visible: !choice.item.picture
                text: (choice.item.letter || "?").charAt(0).toUpperCase()
                color: Kirigami.Theme.highlightedTextColor
            }
            Kirigami.ShadowedImage {
                anchors.fill: parent
                visible: !!choice.item.picture
                source: choice.item.picture ? "file://" + encodeURI(choice.item.picture) : ""
                radius: width / 2
                color: "transparent"
            }
        }
        Kirigami.Icon {
            implicitWidth: choice.size
            implicitHeight: choice.size
            visible: !!choice.item.icon
            source: choice.item.icon || ""
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            QQC2.Label { Layout.fillWidth: true; text: choice.item.title || ""; elide: Text.ElideRight }
            QQC2.Label {
                Layout.fillWidth: true
                text: choice.item.detail || ""
                elide: Text.ElideRight
                font: Kirigami.Theme.smallFont
                opacity: 0.7
            }
        }
        Kirigami.Icon {
            implicitWidth: Kirigami.Units.iconSizes.small
            implicitHeight: Kirigami.Units.iconSizes.small
            visible: choice.current
            source: "checkmark"
        }
    }

    SettingsGroup {
        QQC2.Label { Layout.fillWidth: true; text: "Open links with" }
        QQC2.ComboBox {
            id: picker
            Layout.fillWidth: true
            Layout.preferredHeight: shown.implicitHeight + Kirigami.Units.largeSpacing * 2
            model: page.options
            textRole: "title"
            valueRole: "value"
            displayText: ""         // the row below shows the choice; the style would draw it again
            currentIndex: Math.max(0, page.options.findIndex(o => o.value === page.cfg_linkProfile))
            onActivated: page.cfg_linkProfile = currentValue
            Accessible.name: "Open links with"
            Choice {
                id: shown
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: Kirigami.Units.largeSpacing
                anchors.rightMargin: Kirigami.Units.gridUnit * 2
                anchors.verticalCenter: parent.verticalCenter
                item: page.options[picker.currentIndex] || ({})
            }
            delegate: QQC2.ItemDelegate {
                required property var modelData
                required property int index
                width: ListView.view ? ListView.view.width : implicitWidth
                highlighted: picker.highlightedIndex === index
                contentItem: Choice { item: modelData; current: index === picker.currentIndex }
            }
        }
        Kirigami.Separator { Layout.fillWidth: true; visible: page.usesChrome }
        SettingRow {
            visible: page.usesChrome
            title: "Open each link in"
            QQC2.ComboBox {
                model: ["New tab", "New window"]
                currentIndex: page.cfg_linkNewWindow ? 1 : 0
                onActivated: page.cfg_linkNewWindow = currentIndex === 1
            }
        }
    }
    Footnote { text: page.note }
    Item { Layout.fillHeight: true }
}

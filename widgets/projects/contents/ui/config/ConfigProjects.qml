// Projects: where the card looks, how many rows it shows, and what its two buttons open.
import QtQuick
import QtQuick.Layouts
import QtQuick.Dialogs
import QtCore
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as P5Support

ColumnLayout {
    id: page
    spacing: Kirigami.Units.smallSpacing

    property var cfg_folders: []
    property var cfg_foldersDefault: []
    property int cfg_rows
    property string cfg_terminalApp
    property string cfg_editorApp

    readonly property var terminalNames: ({ kitty: "Kitty", konsole: "Konsole", alacritty: "Alacritty", wezterm: "WezTerm", foot: "foot" })
    readonly property var editorNames: ({ code: "VS Code", cursor: "Cursor", codium: "VSCodium", zed: "Zed", kate: "Kate", subl: "Sublime Text" })
    property var terminals: [cfg_terminalApp]
    property var editors: [cfg_editorApp]

    function home(url) {
        const p = decodeURIComponent(url.toString().replace(/^file:\/\//, ""))
        const h = StandardPaths.writableLocation(StandardPaths.HomeLocation).toString().replace(/^file:\/\//, "")
        return p.startsWith(h + "/") ? "~" + p.slice(h.length) : p
    }

    // Offer only the apps this computer has
    P5Support.DataSource {
        engine: "executable"
        connectedSources: ["for a in " + Object.keys(page.terminalNames).concat(Object.keys(page.editorNames)).join(" ") + "; do command -v $a >/dev/null && echo $a; done"]
        onNewData: (source, data) => {
            disconnectSource(source)
            const found = (data["stdout"] || "").trim().split("\n")
            const pick = (names, now) => Object.keys(names).filter(a => found.indexOf(a) >= 0 || a === now)
            page.terminals = pick(page.terminalNames, page.cfg_terminalApp)
            page.editors = pick(page.editorNames, page.cfg_editorApp)
        }
    }

    SettingsGroup {
        Repeater {
            model: page.cfg_folders
            RowLayout {
                required property string modelData
                required property int index
                Layout.fillWidth: true
                Kirigami.Icon { source: "folder"; Layout.preferredWidth: Kirigami.Units.iconSizes.small; Layout.preferredHeight: Kirigami.Units.iconSizes.small }
                QQC2.Label { text: modelData; Layout.fillWidth: true; elide: Text.ElideMiddle }
                QQC2.ToolButton {
                    icon.name: "list-remove"
                    text: "Remove"
                    display: QQC2.AbstractButton.IconOnly
                    enabled: page.cfg_folders.length > 1
                    onClicked: { const f = Array.from(page.cfg_folders); f.splice(index, 1); page.cfg_folders = f }
                }
            }
        }
        QQC2.Button {
            icon.name: "list-add"
            text: "Add folder…"
            onClicked: picker.open()
        }
    }
    Footnote { text: "The card shows the git repositories you worked in last, found up to two folders deep in these." }

    SettingsGroup {
        SettingRow {
            title: "Rows"
            QQC2.ComboBox {
                model: ["3", "4", "5"]
                currentIndex: page.cfg_rows - 3
                onActivated: page.cfg_rows = currentIndex + 3
            }
        }
        Kirigami.Separator { Layout.fillWidth: true }
        SettingRow {
            title: "Terminal"
            hint: "Opens when you click a project's terminal button"
            QQC2.ComboBox {
                model: page.terminals.map(a => page.terminalNames[a] || a)
                currentIndex: Math.max(0, page.terminals.indexOf(page.cfg_terminalApp))
                onActivated: page.cfg_terminalApp = page.terminals[currentIndex]
            }
        }
        Kirigami.Separator { Layout.fillWidth: true }
        SettingRow {
            title: "Editor"
            QQC2.ComboBox {
                model: page.editors.map(a => page.editorNames[a] || a)
                currentIndex: Math.max(0, page.editors.indexOf(page.cfg_editorApp))
                onActivated: page.cfg_editorApp = page.editors[currentIndex]
            }
        }
    }

    FolderDialog {
        id: picker
        title: "Folder with your projects"
        currentFolder: StandardPaths.writableLocation(StandardPaths.DocumentsLocation)
        onAccepted: {
            const p = page.home(selectedFolder)
            if (page.cfg_folders.indexOf(p) < 0) page.cfg_folders = Array.from(page.cfg_folders).concat([p])
        }
    }
    Item { Layout.fillHeight: true }
}

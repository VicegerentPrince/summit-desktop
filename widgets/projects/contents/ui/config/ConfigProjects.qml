// Where the Projects card looks for git repositories (up to two folders deep).
import QtQuick
import QtQuick.Layouts
import QtQuick.Dialogs
import QtCore
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    property var cfg_folders: []
    property var cfg_foldersDefault: []

    function home(url) {
        const p = decodeURIComponent(url.toString().replace(/^file:\/\//, ""))
        const h = StandardPaths.writableLocation(StandardPaths.HomeLocation).toString().replace(/^file:\/\//, "")
        return p.startsWith(h + "/") ? "~" + p.slice(h.length) : p
    }

    ColumnLayout {
        spacing: Kirigami.Units.largeSpacing

        QQC2.Label {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: "The card shows the git repositories you worked in last, found up to two folders deep in these folders."
        }

        Repeater {
            model: cfg_folders
            RowLayout {
                required property string modelData
                required property int index
                Layout.fillWidth: true
                Kirigami.Icon { source: "folder"; Layout.preferredWidth: Kirigami.Units.iconSizes.small; Layout.preferredHeight: Layout.preferredWidth }
                QQC2.Label { text: modelData; Layout.fillWidth: true; elide: Text.ElideMiddle }
                QQC2.ToolButton {
                    icon.name: "list-remove"
                    text: "Remove"
                    display: QQC2.AbstractButton.IconOnly
                    enabled: cfg_folders.length > 1
                    QQC2.ToolTip.text: enabled ? text : "The card needs at least one folder"
                    QQC2.ToolTip.visible: hovered
                    onClicked: { const f = cfg_folders.slice(); f.splice(index, 1); cfg_folders = f }
                }
            }
        }

        QQC2.Button {
            icon.name: "list-add"
            text: "Add folder…"
            onClicked: picker.open()
        }

        FolderDialog {
            id: picker
            title: "Folder with your projects"
            currentFolder: StandardPaths.writableLocation(StandardPaths.DocumentsLocation)
            onAccepted: {
                const p = home(selectedFolder)
                if (cfg_folders.indexOf(p) < 0) cfg_folders = cfg_folders.concat([p])
            }
        }
    }
}

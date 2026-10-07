import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    readonly property string script: decodeURIComponent(Qt.resolvedUrl("../../code/statusline.sh").toString().replace(/^file:\/\//, ""))
    readonly property string snippet: '"statusLine": {\n  "type": "command",\n  "command": "bash \'' + script + '\'",\n  "padding": 0\n}'

    ColumnLayout {
        spacing: Kirigami.Units.largeSpacing

        QQC2.Label {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: "This card shows the 5-hour and weekly limits of your Claude plan, as Claude Code "
                + "reports them to its status line. To connect it, add the lines below to "
                + "~/.claude/settings.json (inside the outer { }, separated from the entry before "
                + "it by a comma). The card fills in the next time Claude Code shows its status line."
        }
        QQC2.TextArea {
            id: area
            Layout.fillWidth: true
            readOnly: true
            selectByMouse: true
            font.family: "monospace"
            text: snippet
        }
        QQC2.Button {
            icon.name: "edit-copy"
            text: "Copy"
            onClicked: { area.selectAll(); area.copy(); area.deselect(); text = "Copied" }
        }
        QQC2.Label {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            opacity: 0.75
            text: "The script also becomes Claude Code's status line: model, folder, git branch, "
                + "context use and plan limits. It needs jq. It reads only what Claude Code passes to "
                + "it, sends nothing anywhere, and saves the two figures to "
                + "~/.cache/summit/claude-usage.json for this card. Not affiliated with Anthropic."
        }
    }
}

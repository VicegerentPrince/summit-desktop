import QtQuick
import org.kde.kirigami as Kirigami

// A glass capsule to type in. With `collapsible` it rests as a round button and opens into the field.
Item {
    id: f
    required property Item scene
    property alias text: input.text
    property bool plain: false
    property bool collapsible: false
    property real openWidth: 260
    property string placeholder: "Search Wallhaven"
    readonly property bool opened: !collapsible || input.activeFocus || input.text !== ""
    signal accepted(string text)
    signal cleared()
    readonly property bool moving: grow.moving

    function focusField() { input.forceActiveFocus() }
    function type(s) { input.text += s; input.forceActiveFocus() }

    implicitHeight: 40
    Spring { id: grow; target: f.opened ? f.openWidth : 40; response: 0.42; damping: 0.86 }
    implicitWidth: grow.value

    Loader {
        anchors.fill: parent
        active: !f.plain
        sourceComponent: Glass { source: f.scene }
    }
    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: Qt.rgba(1, 1, 1, input.activeFocus ? 0.13 : 0.08)
        visible: f.plain
        border.width: input.activeFocus ? 1 : 0
        border.color: Qt.rgba(1, 1, 1, 0.3)
    }
    Kirigami.Icon {
        id: glyph
        x: 11
        anchors.verticalCenter: parent.verticalCenter
        width: 18; height: 18
        source: "search-symbolic"
        isMask: true
        color: "white"
        opacity: 0.8
    }
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.IBeamCursor
        onPressed: input.forceActiveFocus()
    }
    TextInput {
        id: input
        anchors.left: glyph.right
        anchors.leftMargin: 8
        anchors.right: clear.left
        anchors.rightMargin: 4
        anchors.verticalCenter: parent.verticalCenter
        clip: true
        color: "white"
        selectionColor: Kirigami.Theme.highlightColor
        selectedTextColor: Kirigami.Theme.highlightedTextColor
        font.family: Kirigami.Theme.defaultFont.family
        font.pixelSize: 13
        font.weight: Font.Medium
        opacity: f.width > 90 ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 120 * Kirigami.Units.longDuration / 200 } }
        onAccepted: if (text.trim() !== "") f.accepted(text.trim())
        Keys.onEscapePressed: event => {
            if (text !== "") { text = ""; f.cleared() }
            else { focus = false; event.accepted = false }
        }
        Label {
            anchors.fill: parent
            visible: input.text === ""
            text: f.placeholder
            level: 0.6
        }
    }
    Item {
        id: clear
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        width: input.text !== "" ? 24 : 0
        height: 24
        visible: width > 0
        Rectangle { anchors.fill: parent; radius: 12; color: Qt.rgba(1, 1, 1, 0.14) }
        Kirigami.Icon { anchors.centerIn: parent; width: 12; height: 12; source: "window-close-symbolic"; isMask: true; color: "white" }
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: { input.text = ""; f.cleared(); input.forceActiveFocus() } }
    }
}

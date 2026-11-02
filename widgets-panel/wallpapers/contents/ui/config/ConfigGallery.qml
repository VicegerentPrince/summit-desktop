/*
    Wallpapers: how the gallery looks, shown as small sketches of the popup.
*/
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: page

    property int cfg_galleryStyle
    property int cfg_galleryStyleDefault: 1
    // on the General page; Plasma hands every page every setting
    property bool cfg_matchAccent
    property bool cfg_matchAccentDefault: false
    property bool cfg_frostOtherScreens
    property bool cfg_frostOtherScreensDefault: false

    readonly property color ink: Kirigami.Theme.textColor
    readonly property color paper: Kirigami.Theme.backgroundColor
    readonly property var notes: [
        "A sheet of clear glass with your pictures as cards on it. Shows the most at once.",
        "Pictures run edge to edge, and the glass controls float over them and fold away as you scroll.",
        "The picture under your pointer fills the popup, with a shelf of pictures below. Click to use it."
    ]

    component Part: Rectangle {
        property real tone: 0.2
        color: Qt.rgba(page.ink.r, page.ink.g, page.ink.b, tone)
    }
    // floats over a sketch, so it reads as a control whatever is beneath it
    component Float: Rectangle {
        color: Qt.rgba(page.paper.r, page.paper.g, page.paper.b, 0.82)
        border.width: 1
        border.color: Qt.rgba(page.ink.r, page.ink.g, page.ink.b, 0.5)
    }
    component Tile: ColumnLayout {
        id: tile
        property int value
        property string name
        default property alias sketch: paperSheet.data
        readonly property bool chosen: page.cfg_galleryStyle === value
        Layout.fillWidth: true
        Layout.preferredWidth: 1
        spacing: Kirigami.Units.smallSpacing

        Rectangle {
            id: paperSheet
            Layout.fillWidth: true
            Layout.preferredHeight: width * 664 / 964
            radius: height * 0.1
            color: Qt.rgba(page.ink.r, page.ink.g, page.ink.b, 0.05)
            border.width: tile.chosen ? 2 : 1
            border.color: tile.chosen ? Kirigami.Theme.highlightColor : Qt.rgba(page.ink.r, page.ink.g, page.ink.b, 0.15)
            MouseArea { z: 2; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: page.cfg_galleryStyle = tile.value }
        }
        QQC2.RadioButton {
            Layout.alignment: Qt.AlignHCenter
            text: tile.name
            checked: tile.chosen
            onToggled: page.cfg_galleryStyle = tile.value
        }
    }

    ColumnLayout {
        spacing: Kirigami.Units.smallSpacing

        SettingsGroup {
            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.largeSpacing

                Tile {
                    value: 0; name: "Clear"
                    Item {
                        id: clear
                        anchors.fill: parent
                        anchors.margins: parent.width * 0.06
                        Part { width: parent.width * 0.36; height: parent.height * 0.1; radius: height / 2; tone: 0.3 }
                        Row {
                            anchors.right: parent.right
                            spacing: clear.width * 0.03
                            Repeater {
                                model: 2
                                Part { width: clear.height * 0.1; height: width; radius: width / 2; tone: 0.3 }
                            }
                        }
                        Grid {
                            y: parent.height * 0.19
                            columns: 4
                            spacing: clear.width * 0.03
                            Repeater {
                                model: 12
                                Part {
                                    width: (clear.width - 3 * clear.width * 0.03) / 4
                                    height: (clear.height * 0.81 - 2 * clear.width * 0.03) / 3
                                    radius: width * 0.1
                                }
                            }
                        }
                    }
                }
                Tile {
                    value: 1; name: "Float"
                    Grid {
                        id: float
                        anchors.fill: parent
                        anchors.margins: 3
                        columns: 3
                        spacing: 2
                        Repeater {
                            model: 9
                            Kirigami.ShadowedRectangle {
                                required property int index
                                readonly property real round: float.height * 0.09
                                width: (float.width - 2 * float.spacing) / 3
                                height: (float.height - 2 * float.spacing) / 3
                                color: Qt.rgba(page.ink.r, page.ink.g, page.ink.b, 0.2)
                                corners.topLeftRadius: index === 0 ? round : 0
                                corners.topRightRadius: index === 2 ? round : 0
                                corners.bottomLeftRadius: index === 6 ? round : 0
                                corners.bottomRightRadius: index === 8 ? round : 0
                            }
                        }
                    }
                    Part { x: parent.width * 0.07; y: parent.height * 0.09; width: parent.width * 0.2; height: parent.height * 0.055; radius: height / 2; tone: 0.75 }
                    Float {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: parent.height * 0.07
                        width: parent.width * 0.42; height: parent.height * 0.13; radius: height / 2
                    }
                }
                Tile {
                    value: 2; name: "Stage"
                    Part {
                        anchors.fill: parent
                        anchors.margins: 3
                        radius: parent.radius - 3
                    }
                    Float { x: parent.width * 0.05; y: parent.height * 0.07; width: parent.width * 0.36; height: parent.height * 0.12; radius: height / 2 }
                    Float {
                        id: shelf
                        x: parent.width * 0.05
                        width: parent.width * 0.9
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: parent.width * 0.05
                        height: parent.height * 0.25
                        radius: height * 0.26
                        Row {
                            anchors.centerIn: parent
                            spacing: shelf.width * 0.025
                            Repeater {
                                model: 4
                                Part {
                                    width: (shelf.width * 0.92 - 3 * shelf.width * 0.025) / 4
                                    height: shelf.height * 0.66
                                    radius: height * 0.18
                                    tone: 0.34
                                }
                            }
                        }
                    }
                }
            }
        }
        Footnote { text: page.notes[page.cfg_galleryStyle] || "" }
    }
}

import QtQuick
import QtQuick.Window
import QtQuick.Templates as T
import Qt.labs.folderlistmodel
import org.kde.kirigami as Kirigami
import org.kde.plasma.extras as PlasmaExtras

// The pictures of one tab, as a grid or as a sideways strip. A ring marks the wallpaper in use and flies
// to the new one when it changes, so the eye follows the switch.
Item {
    id: gallery
    required property var app
    property int mode: 0                   // 0 library, 1 discover
    property int columns: 4
    property real gap: 12
    property real radius: 16
    property real insetTop: 0
    property real insetBottom: 0
    property real insetLeft: 0
    property real insetRight: 0
    property bool strip: false             // one sideways row: columns is ignored
    property bool marksLow: false          // corner marks at the bottom: controls float over the top row
    property Item markLayer: null          // draw the corner marks here instead: above refracting glass
    property real stripCellWidth: 170
    property real lift: 1.035
    // only what the screen can show, up to the size of a thumbnail
    readonly property int decodeWidth: Math.min(640, Math.ceil(grid.cellWidth * lift * Screen.devicePixelRatio / 16) * 16)
    readonly property alias view: grid
    readonly property real cellW: grid.cellWidth
    signal peeked(var picture)
    signal moved(real y)

    // load the next page a little before the end is reached
    function nearEnd() {
        if (mode !== 1) return
        if (strip ? grid.contentX + grid.width > grid.contentWidth - 6 * grid.cellWidth
                  : grid.contentY + grid.height > grid.contentHeight - 2 * grid.cellHeight) app.discover.more()
    }

    // nothing to show, and why
    readonly property bool empty: mode === 0 ? app.files.count === 0 && app.files.status === FolderListModel.Ready
                                             : app.results.count === 0 && !app.discover.loading && app.discover.query !== ""
    readonly property bool offline: mode === 1 && app.discover.failed
    readonly property string emptyTitle: mode === 0 ? "No wallpapers yet" : offline ? "Could not reach Wallhaven" : "Nothing found"
    readonly property string emptyHint: mode === 0 ? "Pick some in Discover, or drop pictures into ~/Pictures/Wallpapers."
                                      : offline ? "The library still works offline." : "Try another topic or search."

    readonly property int currentIndex: {
        const a = gallery.app
        if (mode === 0) {
            a.files.count
            return a.current === "" ? -1 : a.files.indexOf("file://" + a.current)
        }
        const name = a.current.replace(/^.*\/wallhaven-(.*)\.jpg$/, "$1")
        a.results.count
        if (name === a.current) return -1
        for (let i = 0; i < a.results.count; i++)
            if (a.results.get(i).wid === name) return i
        return -1
    }

    function showCurrent() {
        if (currentIndex >= 0) grid.positionViewAtIndex(currentIndex, strip ? GridView.Center : GridView.Center)
    }

    Component {
        id: libraryCard
        Thumb {
            required property int index
            required property string filePath
            required property string fileBaseName
            required property url fileUrl
            required property real fileSize
            width: grid.cellWidth - gallery.gap
            height: grid.cellHeight - gallery.gap
            radius: gallery.radius
            lift: gallery.lift
            markLayer: gallery.markLayer ? marks : null
            markOrigin: Qt.point(grid.x + grid.contentItem.x, grid.y + grid.contentItem.y)
            decodeWidth: gallery.decodeWidth
            picture: gallery.app.thumbSet[fileBaseName] ? gallery.app.thumbs + fileBaseName + ".jpg" : fileUrl
            fallback: fileUrl    // a picture dropped in by hand has no thumbnail yet
            isFocus: grid.activeFocus && grid.currentIndex === index
            onChosen: gallery.app.use(filePath)
            onPeeked: gallery.peeked({ thumb: picture, width: gallery.decodeWidth, full: fileUrl, path: filePath, size: fileSize, label: "" })
        }
    }
    Component {
        id: discoverCard
        Thumb {
            required property string wid
            required property string thumb
            required property string label
            required property string colour
            required property string full
            required property string dims
            required property real bytes
            width: grid.cellWidth - gallery.gap
            height: grid.cellHeight - gallery.gap
            radius: gallery.radius
            lift: gallery.lift
            markLayer: gallery.markLayer ? marks : null
            markOrigin: Qt.point(grid.x + grid.contentItem.x, grid.y + grid.contentItem.y)
            decodeWidth: 432
            marksLow: gallery.marksLow
            picture: thumb
            tone: colour !== "" ? colour : Qt.rgba(1, 1, 1, 0.07)
            badge: label
            inLibrary: gallery.app.has(wid)
            isBusy: gallery.app.busy[wid] === true
            onChosen: inLibrary ? gallery.app.use(gallery.app.libraryPath + "/wallhaven-" + wid + ".jpg") : gallery.app.get(wid)
            onPeeked: gallery.peeked({ thumb: thumb, width: 432, full: full, size: bytes, label: label, dims: dims, wid: wid })
        }
    }

    clip: true

    // the marks of this gallery outside it: same place, same fade, same clip
    Item {
        id: marks
        parent: gallery.markLayer ? gallery.markLayer : gallery
        x: gallery.markLayer ? gallery.x : 0
        y: gallery.markLayer ? gallery.y : 0
        width: gallery.width; height: gallery.height
        opacity: gallery.markLayer ? gallery.opacity : 1
        visible: gallery.visible
        clip: true
        z: 7
    }

    GridView {
        id: grid
        // GridView fits floor(width / cellWidth) columns, and a cell includes its gap. Any other width
        // loses a column, which is what left a blank fourth column in the old grid.
        x: gallery.strip ? 0 : gallery.insetLeft
        width: gallery.strip ? gallery.width : gallery.columns * cellWidth
        height: gallery.height
        focus: true
        model: gallery.mode === 0 ? gallery.app.files : gallery.app.results
        delegate: gallery.mode === 0 ? libraryCard : discoverCard
        flow: gallery.strip ? GridView.FlowTopToBottom : GridView.FlowLeftToRight
        topMargin: gallery.insetTop
        bottomMargin: gallery.insetBottom
        leftMargin: gallery.strip ? gallery.insetLeft : 0
        rightMargin: gallery.strip ? gallery.insetRight : 0
        cellWidth: gallery.strip ? gallery.stripCellWidth
            : Math.floor((gallery.width - gallery.insetLeft - gallery.insetRight + gallery.gap) / gallery.columns)
        cellHeight: gallery.strip ? height - gallery.insetTop - gallery.insetBottom + gallery.gap
            : Math.round((cellWidth - gallery.gap) * 9 / 16) + gallery.gap
        boundsBehavior: Flickable.StopAtBounds
        keyNavigationEnabled: true
        highlightFollowsCurrentItem: false
        currentIndex: -1
        cacheBuffer: gallery.strip ? cellWidth * 6 : cellHeight * 3
        Keys.onReturnPressed: if (currentItem) currentItem.chosen()
        Keys.onEnterPressed: if (currentItem) currentItem.chosen()

        onContentYChanged: { gallery.moved(contentY); gallery.nearEnd() }
        onContentXChanged: gallery.nearEnd()
        onCountChanged: gallery.nearEnd()

        // a sideways strip scrolls with the ordinary wheel too
        Spring { id: stripScroll; response: 0.34; onValueChanged: if (moving) grid.contentX = value }
        WheelHandler {
            enabled: gallery.strip
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            orientation: Qt.Vertical
            onWheel: event => {
                const low = grid.originX - grid.leftMargin
                const high = Math.max(low, grid.originX + grid.contentWidth + grid.rightMargin - grid.width)
                if (!stripScroll.moving) stripScroll.jump(grid.contentX)
                stripScroll.target = Math.max(low, Math.min(high, stripScroll.target - event.angleDelta.y * 1.1))
            }
        }
        Kirigami.WheelHandler {
            target: gallery.strip ? null : grid
            filterMouseEvents: true
            keyNavigationEnabled: false
            verticalStepSize: grid.cellHeight * 0.5
            horizontalStepSize: grid.cellWidth * 0.5
        }

        T.ScrollBar.vertical: T.ScrollBar {
            id: bar
            parent: gallery
            visible: !gallery.strip
            anchors.right: parent.right
            anchors.rightMargin: 4
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.topMargin: gallery.insetTop + 6
            anchors.bottomMargin: gallery.insetBottom + 6
            width: 8
            padding: 0
            minimumSize: 0.08
            policy: T.ScrollBar.AsNeeded
            contentItem: Rectangle {
                implicitWidth: 4
                radius: 2
                x: bar.hovered || bar.pressed ? 0 : 2
                width: bar.hovered || bar.pressed ? 8 : 4
                color: Qt.rgba(1, 1, 1, bar.pressed ? 0.7 : 0.45)
                opacity: bar.active || bar.hovered ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 220 * Kirigami.Units.longDuration / 200 } }
            }
        }

        footer: Item {
            width: grid.width
            height: gallery.mode === 1 && !gallery.strip && gallery.app.results.count > 0 ? 64 : 0   // fixed: a changing footer would move the scroll position
            GlassButton {
                anchors.centerIn: parent
                scene: null
                plain: true
                visible: gallery.mode === 1 && gallery.app.discover.exhausted
                text: gallery.app.discover.stage < gallery.app.discover.stages.length - 1 ? "Load more" : "Load more random picks"
                icon: "view-more-symbolic"
                onClicked: gallery.app.discover.widen()
            }
        }

        // ---- the ring on the wallpaper in use, inside the content so that it scrolls with it
        Item {
            id: ring
            parent: grid.contentItem
            z: 6
            visible: gallery.currentIndex >= 0
            width: grid.cellWidth - gallery.gap
            height: grid.cellHeight - gallery.gap

            readonly property int col: gallery.strip ? gallery.currentIndex : gallery.currentIndex % Math.max(1, gallery.columns)
            readonly property int row: gallery.strip ? 0 : Math.floor(gallery.currentIndex / Math.max(1, gallery.columns))
            Spring { id: ringX; target: ring.col * grid.cellWidth; response: 0.42; damping: 0.88 }
            Spring { id: ringY; target: ring.row * grid.cellHeight; response: 0.42; damping: 0.88 }
            x: ringX.value
            y: ringY.value

            Rectangle {
                anchors.fill: parent
                anchors.margins: -3
                radius: gallery.radius + 3
                color: "transparent"
                border.width: 2.5
                border.color: Kirigami.Theme.highlightColor
                Behavior on border.color { ColorAnimation { duration: 500 * Kirigami.Units.longDuration / 200 } }
            }
            Item {   // its check, with the other marks
                parent: gallery.markLayer ? marks : ring
                x: gallery.markLayer ? grid.x + grid.contentItem.x + ring.x : 0
                y: gallery.markLayer ? grid.y + grid.contentItem.y + ring.y : 0
                width: ring.width; height: ring.height
                visible: ring.visible
                z: 8
                Rectangle {
                    anchors.top: gallery.marksLow ? undefined : parent.top
                    anchors.bottom: gallery.marksLow ? parent.bottom : undefined
                    anchors.right: parent.right
                    anchors.margins: 8
                    width: 22; height: 22; radius: 11
                    color: Kirigami.Theme.highlightColor
                    Behavior on color { ColorAnimation { duration: 500 * Kirigami.Units.longDuration / 200 } }
                    Kirigami.Icon {
                        anchors.centerIn: parent
                        width: 13; height: 13
                        source: "checkmark-symbolic"
                        isMask: true
                        color: Kirigami.Theme.highlightedTextColor
                    }
                }
            }
        }

        // ---- first page of a search: quiet tiles instead of an empty box
        Grid {
            parent: grid
            visible: gallery.mode === 1 && gallery.app.results.count === 0 && gallery.app.discover.loading
            x: gallery.insetLeft
            y: gallery.insetTop
            columns: gallery.strip ? 8 : gallery.columns
            rows: gallery.strip ? 1 : 4
            spacing: gallery.gap
            Repeater {
                model: gallery.strip ? 8 : gallery.columns * 4
                Rectangle {
                    width: grid.cellWidth - gallery.gap
                    height: grid.cellHeight - gallery.gap
                    radius: gallery.radius
                    color: Qt.rgba(1, 1, 1, 0.06)
                }
            }
        }

        PlasmaExtras.PlaceholderMessage {
            parent: grid
            anchors.centerIn: parent
            width: parent.width - Kirigami.Units.gridUnit * 4
            visible: gallery.empty && !gallery.strip
            iconName: gallery.offline ? "network-disconnect-symbolic" : "viewimage-symbolic"
            text: gallery.emptyTitle
            explanation: gallery.emptyHint
            helpfulAction: Kirigami.Action {
                enabled: gallery.offline
                icon.name: "view-refresh"
                text: "Try again"
                onTriggered: gallery.app.discover.reload()
            }
        }
        // a strip is too short for all that: one line, and the button still there
        Row {
            parent: grid
            anchors.centerIn: parent
            spacing: 12
            visible: gallery.empty && gallery.strip
            Label {
                anchors.verticalCenter: parent.verticalCenter
                text: gallery.emptyTitle
                font.weight: Font.DemiBold
            }
            Label {
                anchors.verticalCenter: parent.verticalCenter
                text: gallery.emptyHint
                level: 0.68
            }
            GlassButton {
                anchors.verticalCenter: parent.verticalCenter
                visible: gallery.offline
                scene: null
                plain: true
                size: 34
                icon: "view-refresh-symbolic"
                text: "Try again"
                onClicked: gallery.app.discover.reload()
            }
        }
    }
}

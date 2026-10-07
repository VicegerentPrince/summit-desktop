/*
    Wallpapers: a gallery in a panel popup.

      Library ..... ~/Pictures/Wallpapers. Click a picture to use it (desktop and lock screen).
      Discover .... top-rated pictures from Wallhaven, loaded as you scroll. Click one and it is
                    downloaded at a size that suits your screens, added to the library and used.

      scroll on the panel icon ... next / previous without opening anything
      middle-click the icon ...... a random one

    Files and wallpaper switching are done by the `wall` command (~/.local/bin/wall).
    Network use: only while the Discover tab is open (search results and their thumbnails),
    and when a picture is downloaded.
*/
import QtQuick
import QtQuick.Layouts
import QtCore
import Qt.labs.folderlistmodel
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    readonly property string home: StandardPaths.writableLocation(StandardPaths.HomeLocation).toString().replace(/^file:\/\//, "")
    readonly property string wall: "\"" + home + "/.local/bin/wall\""
    readonly property string libraryPath: home + "/Pictures/Wallpapers"
    readonly property url library: "file://" + libraryPath
    readonly property string thumbs: StandardPaths.writableLocation(StandardPaths.GenericCacheLocation) + "/summit/wallpapers/"

    property string current: ""
    property string notice: ""
    property var busy: ({})          // Wallhaven ids being downloaded

    // Ask for pictures at least as large as the largest connected screen, and never below 4K.
    readonly property size wanted: {
        let w = 3840, h = 2160
        const screens = Qt.application.screens
        for (let i = 0; i < screens.length; i++) {
            const sw = Math.round(screens[i].width * screens[i].devicePixelRatio)
            const sh = Math.round(screens[i].height * screens[i].devicePixelRatio)
            if (sw * sh > w * h) { w = sw; h = sh }
        }
        return Qt.size(w, h)
    }

    Plasmoid.icon: "viewimage-symbolic"
    toolTipMainText: "Wallpapers"
    toolTipSubText: "Click for the gallery · scroll to cycle · middle-click for a random one"
    activationTogglesExpanded: true

    switchWidth: Kirigami.Units.gridUnit * 40
    switchHeight: Kirigami.Units.gridUnit * 20

    function quote(s) { return "'" + String(s).replace(/'/g, "'\\''") + "'" }

    // One-shot commands. A serial keeps identical commands distinct so each one really runs.
    property int serial: 0
    function run(args, tag) {
        serial += 1
        runner.connectSource(wall + " " + args + " #" + tag + ":" + serial)
    }
    P5Support.DataSource {
        id: runner
        engine: "executable"
        connectedSources: []
        onNewData: (source, data) => {
            disconnectSource(source)
            const tag = source.replace(/^.*#([\w.-]+):\d+$/, "$1")
            const out = (data["stdout"] || "").trim()
            const ok = data["exit code"] === 0
            if (tag.startsWith("get.")) {
                const id = tag.slice(4)
                const b = Object.assign({}, root.busy); delete b[id]; root.busy = b
                const last = out.split("\n").pop()
                if (ok && last.startsWith("/")) root.current = last
                else root.say("Could not download that one")
            } else if (tag === "thumbs") {
                // nothing to show
            } else if (ok && out.length > 0) {
                root.current = out.split("\n").pop()
            }
        }
    }
    function say(text) { notice = text; noticeTimer.restart() }
    Timer { id: noticeTimer; interval: 5000; onTriggered: root.notice = "" }

    function use(path) { root.current = path; run("set " + quote(path), "set") }
    function get(id) {
        if (busy[id]) return
        const b = Object.assign({}, busy); b[id] = true; busy = b
        run("add --use " + quote(id), "get." + id)
    }

    Component.onCompleted: run("current", "current")
    onExpandedChanged: if (root.expanded) { run("current", "current"); run("thumbs", "thumbs") }

    compactRepresentation: MouseArea {
        id: compact
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        hoverEnabled: true
        property real wheelAcc: 0

        onClicked: mouse => {
            if (mouse.button === Qt.MiddleButton) root.run("random", "random")
            else root.expanded = !root.expanded
        }
        onWheel: wheel => {
            wheelAcc += wheel.angleDelta.y
            if (Math.abs(wheelAcc) < 120 || throttle.running) return
            root.run(wheelAcc > 0 ? "prev" : "next", "step")
            wheelAcc = 0
            throttle.start()
        }
        Timer { id: throttle; interval: 250 }

        Kirigami.Icon {
            anchors.fill: parent
            source: Plasmoid.icon
            active: compact.containsMouse
        }
    }

    fullRepresentation: Item {
        id: full

        readonly property int columns: 4
        readonly property int cardW: 216
        readonly property int cardH: 122
        readonly property int gap: 12
        readonly property int pad: Kirigami.Units.largeSpacing

        // four cards per row, three and a half rows visible so it is obvious there is more below
        Layout.minimumWidth: columns * (cardW + gap) + 2 * pad + Kirigami.Units.gridUnit
        Layout.preferredWidth: Layout.minimumWidth
        Layout.minimumHeight: Math.round(3.45 * (cardH + gap)) + Kirigami.Units.gridUnit * 5 + 3 * pad
        Layout.preferredHeight: Layout.minimumHeight
        Layout.maximumWidth: Layout.minimumWidth
        Layout.maximumHeight: Layout.minimumHeight

        // ---- one picture ---------------------------------------------------------------------
        component Card: Item {
            id: card
            property url picture
            property url fallback
            property bool isCurrent: false
            property bool inLibrary: false
            property bool isBusy: false
            property bool isFocus: false
            property string badge: ""
            signal chosen()

            z: hit.containsMouse ? 2 : 1

            Kirigami.ShadowedImage {
                id: face
                anchors.centerIn: parent
                width: parent.width - full.gap
                height: parent.height - full.gap
                radius: 10
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                sourceSize.width: 512
                sourceSize.height: 288
                source: card.picture
                onStatusChanged: if (status === Image.Error && card.fallback != "" && source != card.fallback) source = card.fallback
                color: Qt.rgba(1, 1, 1, 0.06)
                opacity: card.isBusy ? 0.45 : 1

                border.width: card.isCurrent ? 2 : (card.isFocus ? 1 : 0)
                border.color: card.isCurrent ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
                shadow.size: hit.containsMouse ? 18 : 8
                shadow.yOffset: hit.containsMouse ? 6 : 2
                shadow.color: Qt.rgba(0, 0, 0, hit.containsMouse ? 0.45 : 0.25)

                scale: hit.pressed ? 0.975 : (hit.containsMouse ? 1.035 : 1)
                Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }

                Rectangle {   // in use / already in the library
                    visible: card.isCurrent || card.inLibrary
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.margins: 8
                    width: 20; height: 20; radius: 10
                    color: card.isCurrent ? Kirigami.Theme.highlightColor : Qt.rgba(0, 0, 0, 0.55)
                    Kirigami.Icon {
                        anchors.centerIn: parent
                        width: 14; height: 14
                        source: "checkmark"
                        color: card.isCurrent ? Kirigami.Theme.highlightedTextColor : "white"
                    }
                }
                Rectangle {   // resolution, on pictures that are not downloaded yet
                    visible: card.badge !== "" && !card.inLibrary
                    anchors.left: parent.left
                    anchors.bottom: parent.bottom
                    anchors.margins: 8
                    width: badgeText.implicitWidth + 12
                    height: 18
                    radius: 9
                    color: Qt.rgba(0, 0, 0, 0.55)
                    Text {
                        id: badgeText
                        anchors.centerIn: parent
                        text: card.badge
                        color: "white"
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                    }
                }
            }
            PlasmaComponents.BusyIndicator {
                anchors.centerIn: parent
                visible: card.isBusy
                running: visible
            }
            MouseArea {
                id: hit
                anchors.fill: face
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: card.chosen()
            }
        }

        FolderListModel {
            id: files
            folder: root.library
            nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp", "*.avif"]
            showDirs: false
            sortField: FolderListModel.Name
        }
        function has(id) {   // is this Wallhaven picture already in the library?
            files.count      // re-evaluate when the folder changes
            return files.indexOf(root.library + "/wallhaven-" + id + ".jpg") >= 0
        }

        // ---- Discover: state and loading (kept out of the ScrollView, which must contain only
        // its GridView or it will not size it) ------------------------------------------------
        Item {
            id: discover
            visible: false

            property string query: ""
            property bool custom: false
            property int page: 0
            property int lastPage: 1
            property bool loading: false
            property bool failed: false
            readonly property string status: failed ? "No connection"
                : loading && results.count === 0 ? "Loading…"
                : results.count + " shown · " + root.wanted.width + "×" + root.wanted.height + " or larger"

            ListModel { id: results }

            function load(q, isCustom) {
                query = q; custom = isCustom; page = 0; lastPage = 1; failed = false
                results.clear()
                more()
            }
            function more() {
                if (query === "" || loading || page >= lastPage) return
                loading = true
                const asked = query, wasCustom = custom, next = page + 1
                const url = "https://wallhaven.cc/api/v1/search?q=" + encodeURIComponent(asked)
                    + "&categories=100&purity=100&ratios=16x9,16x10"
                    + "&atleast=" + root.wanted.width + "x" + root.wanted.height
                    + (wasCustom ? "&sorting=favorites&order=desc" : "&sorting=toplist&topRange=1y")
                    + "&page=" + next
                const xhr = new XMLHttpRequest()
                xhr.onreadystatechange = function () {
                    if (xhr.readyState !== XMLHttpRequest.DONE) return
                    discover.loading = false
                    // the topic changed while this was in flight: drop it and load the new one
                    if (asked !== discover.query || wasCustom !== discover.custom) { discover.more(); return }
                    if (xhr.status !== 200) { discover.failed = true; return }
                    let d
                    try { d = JSON.parse(xhr.responseText) } catch (e) { discover.failed = true; return }
                    discover.failed = false
                    discover.page = next
                    discover.lastPage = (d.meta && d.meta.last_page) || next
                    for (const w of d.data) {
                        const px = w.dimension_x || 0
                        results.append({ wid: w.id, thumb: w.thumbs.small,
                                         label: px >= 7680 ? "8K" : px >= 5120 ? "5K" : px >= 3840 ? "4K" : px >= 2560 ? "QHD" : "" })
                    }
                }
                xhr.open("GET", url)
                xhr.timeout = 20000      // must be set after open()
                xhr.send()
            }

            // start with a topic the first time the tab is shown
            readonly property bool shown: tabs.currentIndex === 1 && root.expanded
            onShownChanged: if (shown && query === "") load("mountains", false)
        }

        // ---- header --------------------------------------------------------------------------
        RowLayout {
            id: header
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: full.pad
            spacing: Kirigami.Units.smallSpacing

            PlasmaComponents.TabBar {
                id: tabs
                Layout.preferredWidth: Kirigami.Units.gridUnit * 15
                PlasmaComponents.TabButton { text: "Library"; icon.name: "folder-pictures-symbolic" }
                PlasmaComponents.TabButton { text: "Discover"; icon.name: "globe-symbolic" }
            }
            PlasmaComponents.Label {
                Layout.leftMargin: Kirigami.Units.largeSpacing
                Layout.fillWidth: true
                opacity: 0.6
                elide: Text.ElideRight
                text: root.notice !== "" ? root.notice
                    : tabs.currentIndex === 0 ? files.count + (files.count === 1 ? " picture" : " pictures")
                    : discover.status
            }
            PlasmaExtras.SearchField {
                id: search
                visible: tabs.currentIndex === 1
                Layout.preferredWidth: Kirigami.Units.gridUnit * 13
                placeholderText: "Search Wallhaven…"
                onAccepted: if (text.trim() !== "") discover.load(text.trim(), true)
            }
            PlasmaComponents.ToolButton {
                visible: tabs.currentIndex === 0
                icon.name: "media-playlist-shuffle"
                text: "Shuffle"
                enabled: files.count > 1
                onClicked: root.run("random", "random")
            }
            PlasmaComponents.ToolButton {
                visible: tabs.currentIndex === 0
                icon.name: "folder-open"
                display: PlasmaComponents.ToolButton.IconOnly
                text: "Open folder"
                onClicked: Qt.openUrlExternally(root.library)
                PlasmaComponents.ToolTip.text: "Open ~/Pictures/Wallpapers (drop your own pictures in)"
                PlasmaComponents.ToolTip.visible: hovered
                PlasmaComponents.ToolTip.delay: Kirigami.Units.toolTipDelay
            }
        }

        // ---- topics (Discover only) ------------------------------------------------------------
        Row {
            id: topics
            anchors.top: header.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: full.pad
            anchors.rightMargin: full.pad
            anchors.topMargin: visible ? Kirigami.Units.smallSpacing * 2 : 0
            height: visible ? implicitHeight : 0
            visible: tabs.currentIndex === 1
            spacing: Kirigami.Units.smallSpacing

            Repeater {
                model: ["Mountains", "Night sky", "Forest", "Lakes", "Aurora", "Ocean", "Desert", "City lights", "Minimal", "Space"]
                PlasmaComponents.ToolButton {
                    required property string modelData
                    text: modelData
                    checkable: true
                    checked: discover.query === modelData.toLowerCase() && !discover.custom
                    onClicked: { search.text = ""; discover.load(modelData.toLowerCase(), false) }
                }
            }
        }

        StackLayout {
            anchors.top: topics.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: full.pad
            currentIndex: tabs.currentIndex

            // ---- Library ---------------------------------------------------------------------
            PlasmaComponents.ScrollView {
                GridView {
                    id: grid
                    clip: true
                    focus: true
                    model: files
                    // always exactly `columns` per row, whatever the scroll bar takes
                    cellWidth: Math.floor(width / full.columns)
                    cellHeight: Math.round((cellWidth - full.gap) * 9 / 16) + full.gap
                    boundsBehavior: Flickable.StopAtBounds
                    keyNavigationEnabled: true
                    highlightFollowsCurrentItem: false
                    currentIndex: -1
                    cacheBuffer: cellHeight * 2

                    Keys.onReturnPressed: if (currentItem) root.use(currentItem.path)
                    Keys.onEnterPressed: if (currentItem) root.use(currentItem.path)

                    delegate: Card {
                        required property int index
                        required property string filePath
                        required property string fileBaseName
                        required property url fileUrl
                        readonly property string path: filePath

                        width: grid.cellWidth
                        height: grid.cellHeight
                        picture: root.thumbs + fileBaseName + ".jpg"
                        fallback: fileUrl   // a picture dropped in by hand has no thumbnail yet
                        isCurrent: root.current === filePath
                        isFocus: grid.activeFocus && grid.currentIndex === index
                        onChosen: { grid.currentIndex = index; root.use(filePath) }
                    }

                    PlasmaExtras.PlaceholderMessage {
                        anchors.centerIn: parent
                        width: parent.width - Kirigami.Units.gridUnit * 4
                        visible: files.count === 0 && files.status === FolderListModel.Ready
                        iconName: "viewimage-symbolic"
                        text: "No wallpapers yet"
                        explanation: "Pick some in Discover, or drop pictures into ~/Pictures/Wallpapers."
                    }
                }
            }

            // ---- Discover --------------------------------------------------------------------
            PlasmaComponents.ScrollView {
                GridView {
                    id: remote
                    clip: true
                    model: results
                    cellWidth: Math.floor(width / full.columns)
                    cellHeight: Math.round((cellWidth - full.gap) * 9 / 16) + full.gap
                    boundsBehavior: Flickable.StopAtBounds
                    cacheBuffer: cellHeight * 2
                    // load the next page a little before the end is reached
                    onContentYChanged: if (contentY + height > contentHeight - 2 * cellHeight) discover.more()
                    onCountChanged: if (contentHeight <= height) discover.more()

                    delegate: Card {
                        required property string wid
                        required property string thumb
                        required property string label

                        width: remote.cellWidth
                        height: remote.cellHeight
                        picture: thumb
                        badge: label
                        inLibrary: full.has(wid)
                        isCurrent: root.current === root.libraryPath + "/wallhaven-" + wid + ".jpg"
                        isBusy: root.busy[wid] === true
                        onChosen: inLibrary ? root.use(root.libraryPath + "/wallhaven-" + wid + ".jpg") : root.get(wid)
                    }

                    PlasmaExtras.PlaceholderMessage {
                        anchors.centerIn: parent
                        width: parent.width - Kirigami.Units.gridUnit * 4
                        visible: results.count === 0 && !discover.loading
                        iconName: discover.failed ? "network-disconnect-symbolic" : "viewimage-symbolic"
                        text: discover.failed ? "Could not reach Wallhaven" : "Nothing found"
                        explanation: discover.failed ? "The library still works offline." : "Try another topic or search."
                        helpfulAction: Kirigami.Action {
                            enabled: discover.failed
                            icon.name: "view-refresh"
                            text: "Try again"
                            onTriggered: discover.load(discover.query === "" ? "mountains" : discover.query, discover.custom)
                        }
                    }
                }
            }
        }
    }
}

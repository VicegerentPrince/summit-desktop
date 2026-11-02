/*
    Wallpapers: a gallery in a panel popup.

      Library ..... ~/Pictures/Wallpapers. Click a picture to use it (desktop and lock screen).
      Discover .... top-rated pictures from Wallhaven, loaded as you scroll. Click one and it is
                    downloaded at a size that suits your screens, added to the library and used.

      scroll on the panel icon ... next / previous without opening anything
      middle-click the icon ...... a random one

    The popup is its own frameless window (gallery/Popup.qml): that is what lets it be a shape of glass,
    with no frost behind it, and play its way out before it closes.

    Files and wallpaper switching are done by `wall` (contents/code/wall, also usable from a terminal).
    Network use: only while the Discover tab is open (search results and their thumbnails),
    and when a picture is downloaded.
*/
import QtQuick
import QtCore
import Qt.labs.folderlistmodel
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami
import "gallery"

PlasmoidItem {
    id: root

    readonly property string home: StandardPaths.writableLocation(StandardPaths.HomeLocation).toString().replace(/^file:\/\//, "")
    readonly property string wallScript: decodeURIComponent(Qt.resolvedUrl("../code/wall").toString().replace(/^file:\/\//, ""))
    readonly property string wall: "python3 " + quote(wallScript)
    readonly property string libraryPath: home + "/Pictures/Wallpapers"
    readonly property url library: "file://" + libraryPath
    readonly property string thumbs: StandardPaths.writableLocation(StandardPaths.GenericCacheLocation) + "/summit/wallpapers/"

    property string current: ""
    property string previous: ""     // what was on before the last change, for Undo
    property var busy: ({})          // Wallhaven ids being downloaded
    property int tab: 0              // 0 library, 1 discover
    property bool open: false
    property string toastText: ""
    property bool toastUndo: false
    readonly property int galleryStyle: Plasmoid.configuration.galleryStyle

    // The resolution pictures are asked for, from `wall size`, which reads the real screen modes. Qt
    // cannot be asked: with a fractional scale it reports 2 for 1.9, so a 3840×2160 panel read as
    // 4042×2274 and every true 4K picture was filtered out.
    property size wanted: Qt.size(3840, 2160)

    readonly property alias files: filesModel
    readonly property alias results: discoverStore.results
    readonly property alias discover: discoverStore

    Plasmoid.icon: "viewimage-symbolic"
    Plasmoid.status: open ? PlasmaCore.Types.RequiresAttentionStatus : PlasmaCore.Types.ActiveStatus
    toolTipMainText: "Wallpapers"
    toolTipSubText: "Click for the gallery · scroll to cycle · middle-click for a random one"
    activationTogglesExpanded: false
    preferredRepresentation: compactRepresentation
    fullRepresentation: Item {}      // the gallery is gallery/Popup.qml

    Connections {
        target: Plasmoid
        function onActivated() { root.open = !root.open }
    }

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
            if (data["exit code"] === 3) root.tell("Previews and the accent need Python Pillow (python3-pillow)", false)
            if (tag.startsWith("get.")) {
                const id = tag.slice(4)
                const b = Object.assign({}, root.busy); delete b[id]; root.busy = b
                const last = out.split("\n").pop()
                if (ok && last.startsWith("/")) root.changed(last)
                else root.tell("Could not download that one", false)
            } else if (tag === "size") {
                const m = out.match(/^(\d+)x(\d+)$/)
                if (ok && m) root.wanted = Qt.size(Number(m[1]), Number(m[2]))
            } else if (tag === "accentstatus") {
                const on = out === "on"
                if (Plasmoid.configuration.matchAccent !== on) Plasmoid.configuration.matchAccent = on
                root.accentSynced = true
            } else if (tag === "froststatus") {
                const on = out === "on"
                if (Plasmoid.configuration.frostOtherScreens !== on) Plasmoid.configuration.frostOtherScreens = on
                root.frostSynced = true
            } else if (tag === "accent" || tag === "thumbs" || tag === "frost") {
                // nothing to show
            } else if (ok && out.length > 0) {
                const path = out.split("\n").pop()
                if (tag === "current") root.current = path
                else root.changed(path)
            }
        }
    }

    function tell(text, undoable) {
        toastText = text
        toastUndo = undoable
        toastTimer.restart()
    }
    Timer { id: toastTimer; interval: 6000; onTriggered: root.toastText = "" }

    // the wallpaper really changed: remember the last one, so the change can be taken back
    function changed(path) {
        if (path === current) return
        if (current !== "") previous = current
        current = path
        tell("Wallpaper changed", true)
    }
    function use(path) {
        if (path === current) return
        changed(path)
        run("set " + quote(path), "set")
    }
    function get(id) {
        if (busy[id]) return
        const b = Object.assign({}, busy); b[id] = true; busy = b
        run("add --use " + quote(id), "get." + id)
    }
    function undo() {
        const back = previous
        if (back === "") return
        previous = ""
        toastText = ""
        current = back
        run("set " + quote(back), "set")
    }

    // The accent setting lives in wall (it also works from a terminal); the checkbox mirrors it.
    property bool accentSynced: false
    readonly property bool matchAccent: Plasmoid.configuration.matchAccent
    onMatchAccentChanged: if (accentSynced) run(matchAccent ? "accent on" : "accent off", "accent")
    // The frosted copy on other screens works the same way.
    property bool frostSynced: false
    readonly property bool frostOtherScreens: Plasmoid.configuration.frostOtherScreens
    onFrostOtherScreensChanged: if (frostSynced) run(frostOtherScreens ? "frost on" : "frost off", "frost")

    Component.onCompleted: {
        run("current", "current"); run("size", "size")
        run("accent status", "accentstatus"); run("frost status", "froststatus")
    }
    onOpenChanged: if (open) { run("current", "current"); run("thumbs", "thumbs") } else toastText = ""

    FolderListModel {
        id: filesModel
        folder: root.library
        nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp", "*.avif"]
        showDirs: false
        sortField: FolderListModel.Time     // newest first: what you just added is at the top
    }
    // Thumbnails that exist so far. A card shows its thumbnail once `wall thumbs` has made it,
    // and the picture itself (decoded at thumbnail size) until then.
    FolderListModel {
        id: thumbFiles
        folder: root.thumbs
        nameFilters: ["*.jpg"]
        showDirs: false
        onCountChanged: root.thumbSetRevision++
    }
    property int thumbSetRevision: 0
    readonly property var thumbSet: {
        thumbSetRevision
        const set = {}
        for (let i = 0; i < thumbFiles.count; i++) set[thumbFiles.get(i, "fileBaseName")] = true
        return set
    }
    function has(id) {   // is this Wallhaven picture already in the library?
        filesModel.count      // re-evaluate when the folder changes
        return filesModel.indexOf(root.library + "/wallhaven-" + id + ".jpg") >= 0
    }

    Discover { id: discoverStore; app: root }

    compactRepresentation: MouseArea {
        id: compact
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        hoverEnabled: true
        property real wheelAcc: 0
        property bool wasOpen: false

        onPressed: wasOpen = root.open     // a click outside closes it first: this click must not reopen it
        onClicked: mouse => {
            if (mouse.button === Qt.MiddleButton) root.run("random", "random")
            else root.open = !wasOpen
        }
        onWheel: wheel => {
            wheelAcc += wheel.angleDelta.y
            if (Math.abs(wheelAcc) < 120 || throttle.running) return
            root.run(wheelAcc > 0 ? "prev" : "next", "step")
            wheelAcc = 0
            throttle.start()
        }
        Timer { id: throttle; interval: 250 }

        Rectangle {   // the icon sits in a drop of light while its popup is open
            anchors.centerIn: parent
            width: Math.min(parent.width, parent.height) + 8
            height: width
            radius: width / 2
            color: Qt.rgba(1, 1, 1, 0.14)
            opacity: root.open ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Kirigami.Units.shortDuration } }
        }
        Kirigami.Icon {
            anchors.fill: parent
            source: Plasmoid.icon
            active: compact.containsMouse
        }
        Popup { app: root; anchorItem: compact }
    }
}

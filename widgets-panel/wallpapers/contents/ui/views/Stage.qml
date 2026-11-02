import QtQuick
import org.kde.kirigami as Kirigami
import "../gallery"

// Version C: the picture comes first. Whatever the pointer rests on fills the popup, large enough to judge;
// the glass controls and the shelf of pictures float over it. Click to use it, or leave and it goes back.
FocusScope {
    id: v
    required property var app
    required property Item desk
    property bool morphing: false

    readonly property Item slabSource: scene
    readonly property Item toastScene: scene
    readonly property real toastGap: 176
    readonly property real slabTint: 0
    readonly property real slabFrost: 0
    readonly property real slabMagnify: 0
    readonly property real slabVibrancy: 1
    readonly property real slabShade: 0
    readonly property real slabLegibility: 0

    readonly property int tab: app ? app.tab : 0
    property var shown: null          // the picture on the stage; null = the wallpaper in use
    readonly property url restFull: app && app.current !== "" ? "file://" + app.current : ""

    function opened() {
        if (!app) return
        (tab === 0 ? library : discover).view.forceActiveFocus()
        library.showCurrent()
        shown = null
        rest(true)
    }
    // back to the wallpaper in use
    function rest(instant) {
        const name = app.current.replace(/^.*\//, "").replace(/\.[^.]*$/, "")
        const thumb = app.thumbSet[name]
        hero.show(thumb ? app.thumbs + name + ".jpg" : restFull, thumb ? 640 : 960, restFull, false, instant)
    }
    function peek(p) {
        leave.stop()
        shown = p
        hero.show(p.thumb, p.width, p.full, p.wid !== undefined, false)
    }
    Timer { id: leave; interval: 420; onTriggered: { v.shown = null; v.rest(false) } }
    Connections {
        target: v.app
        function onCurrentChanged() { if (v.shown === null) v.rest(false) }
    }

    Spring { id: page; target: v.tab; response: 0.46 }
    Spring { id: topics; target: v.tab; response: 0.44; damping: 0.88 }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Tab) { app.tab = 1 - app.tab; event.accepted = true; return }
        if (event.text.length === 1 && event.text > " " && !(event.modifiers & Qt.ControlModifier)) {
            app.tab = 1
            search.type(event.text)
            event.accepted = true
        }
    }

    // ---- the stage. A new picture dissolves in over the old one, which stays until it is covered, so nothing
    // ever fades through black however long a picture takes to arrive. The soft image is the one the shelf
    // already decoded, straight from Qt's cache at the same size. Three layers let a pointer run along the shelf.
    component Layer: Item {
        id: layer
        property url low
        property url high
        property int lowWidth: 640
        property bool instant: false
        property bool waiting: false
        readonly property bool ready: soft.status === Image.Ready || sharp.status === Image.Ready
        signal covered()

        anchors.fill: parent
        opacity: 0
        visible: opacity > 0

        function enter(picture, width, full, now) {
            dissolve.stop()
            opacity = 0
            high = ""
            instant = now
            lowWidth = width
            low = picture
            high = full
            waiting = true
            arrive()
        }
        function arrive() {
            if (!waiting || !ready) return
            waiting = false
            if (instant) { opacity = 1; covered() }
            else dissolve.restart()
        }
        function clear() {
            dissolve.stop()
            waiting = false
            opacity = 0
            low = ""
            high = ""
        }
        onReadyChanged: arrive()

        NumberAnimation {
            id: dissolve
            target: layer
            property: "opacity"
            from: 0
            to: 1
            duration: Kirigami.Units.longDuration * 1.3
            easing.type: Easing.InOutSine
            onFinished: layer.covered()
        }
        Image {
            id: soft
            anchors.fill: parent
            source: layer.low
            fillMode: Image.PreserveAspectCrop
            asynchronous: !layer.instant
            sourceSize.width: layer.lowWidth
            sourceSize.height: Math.round(layer.lowWidth * 9 / 16)
        }
        Image {
            id: sharp
            anchors.fill: parent
            source: layer.high
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            sourceSize.width: 1928
            opacity: status === Image.Ready ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 260 * Kirigami.Units.longDuration / 200 } }
        }
    }
    Item {
        id: content
        anchors.fill: parent
        Rectangle { anchors.fill: parent; color: "#0b0d11" }
        Item {
            id: hero
            anchors.fill: parent
            property int newest: 0
            property int order: 0
            property string lastLow: ""
            function show(low, lowWidth, high, remote, instant) {
                if (String(low) === lastLow) return
                lastLow = String(low)
                upgrade.stop()
                newest = (newest + 1) % layers.count
                const next = layers.itemAt(newest)
                next.z = ++order
                next.enter(low, lowWidth, remote ? "" : high, instant)
                // a Wallhaven original is megabytes: only for a picture the pointer stays on
                if (remote) { upgrade.layer = next; upgrade.url = high; upgrade.restart() }
            }
            function covered(layer) {
                for (let i = 0; i < layers.count; ++i) {
                    const other = layers.itemAt(i)
                    if (other.z < layer.z) other.clear()
                }
            }
            Timer { id: upgrade; interval: 700; property var layer; property url url; onTriggered: layer.high = url }
            Repeater {
                id: layers
                model: 3
                Layer { id: one; onCovered: hero.covered(one) }
            }
        }
        Rectangle {
            width: parent.width; height: 110
            gradient: Gradient {
                GradientStop { position: 0; color: Qt.rgba(0, 0, 0, 0.42) }
                GradientStop { position: 1; color: "transparent" }
            }
        }
    }
    Scene {
        id: scene
        anchors.fill: parent
        sourceItem: content
        tracking: v.morphing || tabs.moving || search.moving || topics.moving
    }

    // ---- top
    Segmented {
        id: tabs
        x: 18; y: 18
        scene: scene
        currentIndex: v.tab
        model: [{ text: "Library", icon: "folder-pictures-symbolic" }, { text: "Discover", icon: "globe-symbolic" }]
        onPicked: index => { v.app.tab = index; (index === 0 ? library : discover).view.forceActiveFocus() }
    }
    Row {
        anchors.right: parent.right
        anchors.rightMargin: 18
        y: 19
        spacing: 8
        layoutDirection: Qt.RightToLeft
        GlassButton { visible: v.tab === 0; scene: scene; icon: "folder-open-symbolic"; tip: "Open the folder"
                      onClicked: Qt.openUrlExternally(v.app.library) }
        GlassButton { visible: v.tab === 0; scene: scene; icon: "media-playlist-shuffle-symbolic"; tip: "Shuffle"
                      onClicked: v.app.run("random", "random") }
        SearchField {
            id: search
            visible: v.tab === 1
            scene: scene
            collapsible: true
            openWidth: 300
            onAccepted: text => v.app.discover.load(text, true)
            onCleared: v.app.discover.load(v.app.discover.topic, false)
        }
    }

    // ---- what is on the stage
    Item {
        id: caption
        x: 18
        anchors.bottom: shelf.top
        anchors.bottomMargin: 10
        height: 34
        width: captionRow.width + 28
        visible: v.app !== null
        Glass { anchors.fill: parent; source: scene; tintAlpha: 0.26 }
        Row {
            id: captionRow
            anchors.centerIn: parent
            spacing: 8
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                visible: v.shown === null
                width: 7; height: 7; radius: 3.5
                color: Kirigami.Theme.highlightColor
            }
            Label {
                anchors.verticalCenter: parent.verticalCenter
                px: 12
                text: {
                    const p = v.shown
                    if (p === null) return "In use"
                    const mb = p.size > 0 ? (p.size / 1048576).toFixed(1) + " MB" : ""
                    return [p.dims || "", mb].filter(x => x !== "").join("  ·  ") || "Click to use"
                }
            }
        }
    }

    // ---- topics, over the stage on Discover
    Item {
        id: topicBar
        anchors.left: caption.right
        anchors.leftMargin: 8
        anchors.right: parent.right
        anchors.rightMargin: 18
        anchors.bottom: shelf.top
        anchors.bottomMargin: 10
        height: 34
        visible: topics.value > 0.02
        opacity: Math.min(1, topics.value * 1.4)
        Glass { anchors.fill: parent; source: scene }
        ChipRow {
            x: 4; y: 0
            width: parent.width - 8
            height: 34
            currentKey: v.app && !v.app.discover.custom ? v.app.discover.query : ""
            model: [["Mountains", "mountains"], ["Night sky", "night sky"], ["Forest", "forest"],
                    ["Lakes", "lake"], ["Aurora", "aurora"], ["Ocean", "ocean"], ["Desert", "desert"],
                    ["Snow", "snow"], ["Waterfalls", "waterfall"], ["Sunset", "sunset"],
                    ["Clouds", "clouds"], ["Landscape", "landscape"], ["City lights", "city lights"],
                    ["Minimal", "minimal"], ["Space", "space"]]
            onPicked: chip => { search.text = ""; v.app.discover.load(chip[1], false) }
        }
    }

    // ---- the shelf
    Item {
        id: shelf
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 14
        height: 124
        Glass {
            anchors.fill: parent
            source: scene
            radius: 28
            roundness: 3.2
            refractThickness: 22
            refractScale: 40
            tintAlpha: 0.28
            frost: 3
            frostPx: 10
        }
        HoverHandler {
            onHoveredChanged: if (!hovered) leave.restart()
        }
        Item {
            id: strip
            anchors.fill: parent
            anchors.leftMargin: 6
            anchors.rightMargin: 6
            clip: true
            Gallery {
                id: library
                width: strip.width; height: strip.height
                x: -page.value * 70
                opacity: 1 - page.value
                visible: opacity > 0.01 && v.app !== null
                app: v.app
                mode: 0
                strip: true
                stripCellWidth: 176
                gap: 10
                radius: 13
                lift: 1.07
                insetTop: 13; insetBottom: 13; insetLeft: 8; insetRight: 8
                onPeeked: picture => v.peek(picture)
            }
            Gallery {
                id: discover
                width: strip.width; height: strip.height
                x: (1 - page.value) * 70
                opacity: page.value
                visible: opacity > 0.01 && v.app !== null
                app: v.app
                mode: 1
                strip: true
                stripCellWidth: 176
                gap: 10
                radius: 13
                lift: 1.07
                insetTop: 13; insetBottom: 13; insetLeft: 8; insetRight: 8
                onPeeked: picture => v.peek(picture)
            }
        }
    }
}

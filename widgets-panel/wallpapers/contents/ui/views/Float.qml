import QtQuick
import org.kde.kirigami as Kirigami
import "../gallery"

// Version B: the pictures run edge to edge under the glass, the way Apple uses it: the controls float over
// the content, and what scrolls beneath them bends in their rims. The slab draws the gallery itself.
FocusScope {
    id: v
    required property var app
    required property Item desk
    property bool morphing: false

    readonly property Item slabSource: scene
    readonly property Item toastScene: scene
    readonly property real toastGap: 78
    readonly property real slabTint: 0
    readonly property real slabFrost: 0
    readonly property real slabMagnify: 0
    readonly property real slabVibrancy: 1
    readonly property real slabShade: 0
    readonly property real slabLegibility: 0

    readonly property int tab: app ? app.tab : 0
    property bool scrolledDown: false
    property real lastY: 0

    function opened() {
        if (!app) return
        (tab === 0 ? library : discover).view.forceActiveFocus()
        library.showCurrent()
        scrolledDown = false
    }
    onTabChanged: {
        scrolledDown = false
        lastY = (tab === 0 ? library : discover).view.contentY
    }
    // going down gives the pictures more room, going back up brings the labels back
    function scrolled(y) {
        if (Math.abs(y - lastY) < 6) return
        scrolledDown = y > lastY && y > 40
        lastY = y
    }

    Spring { id: page; target: v.tab; response: 0.46 }
    Spring { id: bar; target: v.tab; response: 0.44; damping: 0.88 }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Tab) { app.tab = 1 - app.tab; event.accepted = true; return }
        if (event.text.length === 1 && event.text > " " && !(event.modifiers & Qt.ControlModifier)) {
            app.tab = 1
            search.type(event.text)
            event.accepted = true
        }
    }

    // ---- everything the glass refracts
    Item {
        id: content
        anchors.fill: parent
        Rectangle { anchors.fill: parent; color: "#0b0d11" }
        Gallery {
            id: library
            anchors.fill: parent
            x: -page.value * 90
            opacity: 1 - page.value
            visible: opacity > 0.01 && v.app !== null
            app: v.app
            mode: 0
            columns: 3
            gap: 3
            radius: 4
            lift: 1.015
            marksLow: true
            insetTop: 0; insetBottom: 76
            onMoved: y => v.scrolled(y)
        }
        Gallery {
            id: discover
            anchors.fill: parent
            x: (1 - page.value) * 90
            opacity: page.value
            visible: opacity > 0.01 && v.app !== null
            app: v.app
            mode: 1
            columns: 3
            gap: 3
            radius: 4
            lift: 1.015
            marksLow: true
            insetTop: 0; insetBottom: 76
            onMoved: y => v.scrolled(y)
        }
        // the scroll edges: a soft fall into shadow, only where the controls float
        Rectangle {
            width: parent.width; height: 132
            gradient: Gradient {
                GradientStop { position: 0; color: Qt.rgba(0, 0, 0, 0.74) }
                GradientStop { position: 0.55; color: Qt.rgba(0, 0, 0, 0.44) }
                GradientStop { position: 1; color: "transparent" }
            }
        }
        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width; height: 110
            gradient: Gradient {
                GradientStop { position: 0; color: "transparent" }
                GradientStop { position: 1; color: Qt.rgba(0, 0, 0, 0.55) }
            }
        }
    }
    Scene {
        id: scene
        anchors.fill: parent
        sourceItem: content
        tracking: v.morphing || tabs.moving || search.moving || bar.moving
    }

    // ---- title, floating
    Column {
        x: 28; y: 20
        spacing: 1
        Label {
            px: 24
            font.weight: Font.Bold
            text: !v.app ? "" : v.app.discover.custom && v.tab === 1 ? v.app.discover.query : v.tab === 0 ? "Library" : "Discover"
        }
        Label {
            level: 0.76
            px: 13
            text: !v.app ? "" : v.tab === 0 ? v.app.files.count + " pictures"
                : v.app.discover.failed ? "No connection"
                : v.app.discover.loading && v.app.results.count === 0 ? "Loading…"
                : v.app.discover.total.toLocaleString(Qt.locale("en_US"), "f", 0) + " pictures, 4K and up"
        }
    }

    // ---- top right
    Row {
        anchors.right: parent.right
        anchors.rightMargin: 20
        y: 20
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

    // ---- the bar: tabs, and the topics flowing out of them on Discover
    Item {
        id: dock
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 18
        anchors.horizontalCenter: parent.horizontalCenter
        height: 42
        width: tabs.width + bar.value * (topicBar.fullWidth + 10)

        Segmented {
            id: tabs
            scene: scene
            iconsOnly: v.scrolledDown
            currentIndex: v.tab
            model: [{ text: "Library", icon: "folder-pictures-symbolic" }, { text: "Discover", icon: "globe-symbolic" }]
            onPicked: index => { v.app.tab = index; (index === 0 ? library : discover).view.forceActiveFocus() }
        }
        Item {
            id: topicBar
            readonly property real fullWidth: Math.min(v.width - 56 - tabs.width - 10, 640)
            x: tabs.width + 10 * bar.value
            width: Math.max(0.1, bar.value * fullWidth)
            height: dock.height
            visible: bar.value > 0.02
            opacity: Math.min(1, bar.value * 1.5)
            Glass { anchors.fill: parent; source: scene }
            ChipRow {
                x: 6; y: 4
                width: topicBar.fullWidth - 12
                height: 34
                opacity: Math.max(0, (bar.value - 0.5) * 2)
                currentKey: v.app && !v.app.discover.custom ? v.app.discover.query : ""
                model: [["Mountains", "mountains"], ["Night sky", "night sky"], ["Forest", "forest"],
                        ["Lakes", "lake"], ["Aurora", "aurora"], ["Ocean", "ocean"], ["Desert", "desert"],
                        ["Snow", "snow"], ["Waterfalls", "waterfall"], ["Sunset", "sunset"],
                        ["Clouds", "clouds"], ["Landscape", "landscape"], ["City lights", "city lights"],
                        ["Minimal", "minimal"], ["Space", "space"]]
                onPicked: chip => { search.text = ""; v.app.discover.load(chip[1], false) }
            }
        }
    }
}

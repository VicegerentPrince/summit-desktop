import QtQuick
import org.kde.kirigami as Kirigami
import "../gallery"

// Version A: the popup is a slab of the same glass as the desktop cards, with the wallpaper behind it.
FocusScope {
    id: v
    required property var app
    required property Item desk
    property bool morphing: false

    readonly property Item slabSource: null
    readonly property Item toastScene: desk
    readonly property real toastGap: 16
    readonly property real slabTint: 0.16
    readonly property real slabFrost: 0.9
    readonly property real slabMagnify: 0.5
    readonly property real slabVibrancy: 1.4
    readonly property real slabShade: 0.5
    readonly property real slabLegibility: 0.65

    readonly property int pad: 18
    readonly property int tab: app ? app.tab : 0

    function opened() {
        if (!app) return
        (tab === 0 ? library : discover).view.forceActiveFocus()
        library.showCurrent()
    }
    Component.onCompleted: desk.tracking = Qt.binding(() => v.morphing || tabs.moving || search.moving)

    Spring { id: page; target: v.tab; response: 0.46 }
    Spring { id: topics; target: v.tab; response: 0.42 }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Tab) { app.tab = 1 - app.tab; event.accepted = true; return }
        if (event.text.length === 1 && event.text >= " " && event.text !== " " && !(event.modifiers & Qt.ControlModifier)) {
            app.tab = 1
            search.type(event.text)
            event.accepted = true
        }
    }

    // ---- the header
    Segmented {
        id: tabs
        x: v.pad; y: v.pad
        scene: v.desk
        bare: true
        currentIndex: v.tab
        model: [{ text: "Library", icon: "folder-pictures-symbolic" }, { text: "Discover", icon: "globe-symbolic" }]
        onPicked: index => { v.app.tab = index; (index === 0 ? library : discover).view.forceActiveFocus() }
    }
    Label {
        anchors.left: tabs.right
        anchors.leftMargin: 16
        anchors.right: actions.left
        anchors.rightMargin: 12
        anchors.verticalCenter: tabs.verticalCenter
        level: 0.68
        px: 13
        text: !v.app ? "" : v.tab === 0 ? v.app.files.count + (v.app.files.count === 1 ? " picture" : " pictures")
            : v.app.discover.failed ? "No connection"
            : v.app.discover.loading && v.app.results.count === 0 ? "Loading…"
            : v.app.discover.total.toLocaleString(Qt.locale("en_US"), "f", 0) + " pictures, 4K and up"
    }
    Item {
        id: actions
        anchors.right: parent.right
        anchors.rightMargin: v.pad
        anchors.verticalCenter: tabs.verticalCenter
        height: 40
        width: v.tab === 0 ? 88 : search.width

        Row {
            anchors.right: parent.right
            spacing: 8
            opacity: 1 - page.value
            visible: opacity > 0.01
            GlassButton { scene: v.desk; plain: true; icon: "media-playlist-shuffle-symbolic"; tip: "Shuffle"
                          onClicked: v.app.run("random", "random") }
            GlassButton { scene: v.desk; plain: true; icon: "folder-open-symbolic"; tip: "Open the folder"
                          onClicked: Qt.openUrlExternally(v.app.library) }
        }
        SearchField {
            id: search
            anchors.right: parent.right
            scene: v.desk
            plain: true
            openWidth: 280
            opacity: page.value
            visible: opacity > 0.01
            onAccepted: text => v.app.discover.load(text, true)
            onCleared: v.app.discover.load(v.app.discover.topic, false)
        }
    }

    // ---- topics
    ChipRow {
        id: chips
        x: v.pad
        y: tabs.y + tabs.height + 10
        width: parent.width - 2 * v.pad
        opacity: topics.value
        visible: opacity > 0.01
        currentKey: v.app && !v.app.discover.custom ? v.app.discover.query : ""
        // label, then the Wallhaven search behind it (the singular finds more)
        model: [["Mountains", "mountains"], ["Night sky", "night sky"], ["Forest", "forest"],
                ["Lakes", "lake"], ["Aurora", "aurora"], ["Ocean", "ocean"], ["Desert", "desert"],
                ["Snow", "snow"], ["Waterfalls", "waterfall"], ["Sunset", "sunset"],
                ["Clouds", "clouds"], ["Landscape", "landscape"], ["City lights", "city lights"],
                ["Minimal", "minimal"], ["Space", "space"]]
        onPicked: chip => { search.text = ""; v.app.discover.load(chip[1], false) }
    }

    // ---- the pictures; the two tabs sit side by side and slide
    Item {
        id: pages
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: v.pad - 4
        anchors.rightMargin: v.pad - 4
        y: tabs.y + tabs.height + 12 + topics.value * 44
        height: parent.height - y
        clip: true
        layer.enabled: true
        layer.effect: ShaderEffect {
            fragmentShader: Qt.resolvedUrl("../gallery/shaders/edgefade.frag.qsb")
            property vector4d fade: Qt.vector4d(0, 0.022, 0, 0.06)
        }
        Gallery {
            id: library
            width: pages.width; height: pages.height
            x: -page.value * 70
            opacity: 1 - page.value
            visible: opacity > 0.01 && v.app !== null
            app: v.app
            mode: 0
            insetLeft: 4; insetRight: 4; insetTop: 4; insetBottom: 18
            gap: 12
            radius: 14
        }
        Gallery {
            id: discover
            width: pages.width; height: pages.height
            x: (1 - page.value) * 70
            opacity: page.value
            visible: opacity > 0.01 && v.app !== null
            app: v.app
            mode: 1
            insetLeft: 4; insetRight: 4; insetTop: 4; insetBottom: 18
            gap: 12
            radius: 14
        }
    }
}

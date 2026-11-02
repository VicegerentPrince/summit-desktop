import QtQuick
import QtQuick.Window
import QtQuick.Effects
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

// The gallery's window: frameless and fully transparent, with one slab of glass in it. The slab grows out
// of the panel icon and goes back into it, on two springs, so width and height arrive one after the
// other and the drop visibly pours into shape. Any open or close can be reversed halfway.
PlasmaCore.Dialog {
    id: dlg
    required property var app
    required property Item anchorItem

    visualParent: anchorItem
    location: Plasmoid.location
    type: PlasmaCore.Dialog.AppletPopup
    backgroundHints: PlasmaCore.Dialog.NoBackground
    flags: Qt.WindowStaysOnTopHint
    hideOnWindowDeactivate: false
    visible: false

    onActiveChanged: if (!active && app.open) app.open = false

    mainItem: FocusScope {
        id: win

        readonly property real margin: 44
        readonly property real gapToScreen: 8      // the same as a floating panel's: their edges line up
        readonly property var scr: dlg.anchorItem.Screen
        // beside the panel: a window that does not fit there gets flipped off the screen by Plasma
        readonly property real freeW: scr.width - (sidePanel && panel ? panel.width : 0)
        readonly property real freeH: scr.height - (!sidePanel && panel ? panel.height : 0)
        readonly property real slabW: Math.min(964, freeW - 2 * gapToScreen)
        readonly property real slabH: Math.min(664, freeH - 2 * gapToScreen)
        width: Math.min(slabW + 2 * margin, freeW)
        height: Math.min(slabH + 2 * margin, freeH)

        function clamp(v, lo, hi) { return Math.max(lo, Math.min(hi, v)) }
        // Plasma puts a popup this big where it sees fit (on a small screen, in the middle), so the slab
        // stays inside the window it got. `room` is for the shadow, unless the window meets the screen's edge.
        function inWindow(wanted, start, length, screenStart, screenEnd, size, room) {
            const end = start + length
            const lo = start <= screenStart + room ? screenStart + gapToScreen : start + room
            const hi = (end >= screenEnd - room ? screenEnd - gapToScreen : end - room) - size
            return clamp(wanted, lo, Math.max(lo, hi))
        }
        function mix(a, b, t) { return a + (b - a) * t }

        // ---- where things are, in screen coordinates
        readonly property var panel: dlg.anchorItem.Window.window
        // a floating panel's window includes the gap around it
        readonly property real gapToPanel: panel && panel.floating ? 2 : 10
        readonly property point icon: {
            dlg.x; dlg.y; dlg.visible
            const p = dlg.anchorItem.mapToItem(null, dlg.anchorItem.width / 2, dlg.anchorItem.height / 2)
            return panel ? Qt.point(panel.x + p.x, panel.y + p.y) : Qt.point(p.x, p.y)
        }
        readonly property int edge: Plasmoid.location
        readonly property real screenL: scr.virtualX
        readonly property real screenT: scr.virtualY
        readonly property real screenR: screenL + scr.width
        readonly property real screenB: screenT + scr.height

        readonly property bool sidePanel: edge === PlasmaCore.Types.LeftEdge || edge === PlasmaCore.Types.RightEdge
        // the room is along the panel: across it, the slab keeps its small gap from the panel
        readonly property real slabScreenX: inWindow(
            edge === PlasmaCore.Types.LeftEdge && panel ? panel.x + panel.width + gapToPanel
            : edge === PlasmaCore.Types.RightEdge && panel ? panel.x - gapToPanel - slabW
            : icon.x - slabW / 2, dlg.x, width, screenL, screenR, slabW, sidePanel ? 0 : margin)
        readonly property real slabScreenY: inWindow(
            edge === PlasmaCore.Types.TopEdge && panel ? panel.y + panel.height + gapToPanel
            : edge === PlasmaCore.Types.BottomEdge && panel ? panel.y - gapToPanel - slabH
            : icon.y - slabH / 2, dlg.y, height, screenT, screenB, slabH, sidePanel ? margin : 0)
        // the same, in this window
        readonly property real toL: slabScreenX - dlg.x
        readonly property real toT: slabScreenY - dlg.y
        readonly property real toR: toL + slabW
        readonly property real toB: toT + slabH

        // the drop it starts from, over the icon
        readonly property real dropSize: 46
        readonly property real fromX: clamp(icon.x - dlg.x, dropSize / 2, width - dropSize / 2)
        readonly property real fromY: clamp(icon.y - dlg.y, dropSize / 2, height - dropSize / 2)

        Spring { id: growW; response: dlg.app.open ? 0.42 : 0.26; damping: dlg.app.open ? 0.86 : 1 }
        Spring { id: growH; response: dlg.app.open ? 0.5 : 0.22; damping: dlg.app.open ? 0.9 : 1
                 onValueChanged: if (value < 0.015 && target === 0) dlg.visible = false }

        readonly property bool morphing: growW.moving || growH.moving
        readonly property real settled: Math.min(growW.value, growH.value)

        readonly property real nowL: mix(fromX - dropSize / 2, toL, growW.value)
        readonly property real nowR: mix(fromX + dropSize / 2, toR, growW.value)
        readonly property real nowT: mix(fromY - dropSize / 2, toT, growH.value)
        readonly property real nowB: mix(fromY + dropSize / 2, toB, growH.value)

        Connections {
            target: dlg.app
            function onOpenChanged() {
                if (dlg.app.open) {
                    if (!dlg.visible) {
                        growW.jump(0); growH.jump(0)
                        idle.stop(); content.active = true
                        dlg.visible = true
                    }
                    dlg.requestActivate()
                    win.forceActiveFocus()
                    growW.target = 1; growH.target = 1
                    if (content.item) content.item.opened()
                } else {
                    growW.target = 0; growH.target = 0
                    idle.restart()
                }
            }
        }
        // let go of the pictures a while after closing; opening again soon stays instant
        Timer { id: idle; interval: 120000; onTriggered: if (!dlg.app.open) content.active = false }

        Keys.onEscapePressed: dlg.app.open = false

        // ---- the desktop, exactly where it is behind this window
        Item {
            id: desk
            x: win.screenL - dlg.x
            y: win.screenT - dlg.y
            width: win.scr.width
            height: win.scr.height

            property url shown
            Image {
                id: back
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                sourceSize.width: Math.round(win.scr.width * dlg.devicePixelRatio)
                sourceSize.height: Math.round(win.scr.height * dlg.devicePixelRatio)
                cache: false
            }
            Image {
                id: front
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                sourceSize: back.sourceSize
                cache: false
                opacity: 0
                onStatusChanged: if (status === Image.Ready) fade.restart()
            }
            NumberAnimation {
                id: fade
                target: front
                property: "opacity"
                from: 0; to: 1
                duration: Kirigami.Units.veryLongDuration * 2
                easing.type: Easing.InOutSine
                onFinished: { back.source = front.source; }
            }
            Connections {
                target: back
                function onStatusChanged() { if (back.status === Image.Ready && front.opacity === 1) { front.opacity = 0; front.source = "" } }
            }
            readonly property string want: dlg.app.current
            onWantChanged: {
                if (want === "") return
                if (back.source == "") back.source = "file://" + want
                else front.source = "file://" + want
            }
        }
        Scene {
            id: deskScene
            anchors.fill: parent
            sourceItem: desk
            sourceRect: Qt.rect(-desk.x, -desk.y, win.width, win.height)
        }

        // ---- the slab
        RectangularShadow {
            x: win.nowL; y: win.nowT
            width: win.nowR - win.nowL; height: win.nowB - win.nowT
            radius: Math.min(30, height / 2)
            blur: 42
            offset: Qt.vector2d(0, 12)
            spread: -6
            color: Qt.rgba(0, 0, 0, 0.46 * Math.min(1, win.settled * 1.4))
        }
        Glass {
            id: slab
            x: win.nowL; y: win.nowT
            width: win.nowR - win.nowL; height: win.nowB - win.nowT
            source: content.item && content.item.slabSource ? content.item.slabSource : deskScene
            radius: 100 * win.settled + height / 2 * (1 - win.settled)
            roundness: 2 + 5.5 * win.settled
            refractThickness: 34
            refractScale: 62
            specStrength: 0.7
            depth: 0.85
            gloss: 0.9
            fresnel: 0.45
            tintAlpha: content.item ? content.item.slabTint : 0.2
            frost: content.item ? content.item.slabFrost : 2
            frostPx: 3
            magnify: content.item ? content.item.slabMagnify : 0.5
            vibrancy: content.item ? content.item.slabVibrancy : 1.4
            legibility: content.item ? content.item.slabLegibility : 0.65
            shade: content.item ? content.item.slabShade : 0.5
            mousePos: hover.hovered ? Qt.vector2d((hover.point.position.x - x) / width, (hover.point.position.y - y) / height)
                                    : Qt.vector2d(-1, -1)
            mouseFade: hover.hovered ? 1 : 0
            Behavior on mouseFade { NumberAnimation { duration: 180 * Kirigami.Units.longDuration / 200 } }
        }
        HoverHandler { id: hover }

        // ---- what is on it
        Item {
            id: clipper
            x: win.nowL; y: win.nowT
            width: win.nowR - win.nowL; height: win.nowB - win.nowT
            clip: win.morphing
            Loader {
                id: content
                x: win.toL - clipper.x
                y: win.toT - clipper.y
                width: win.slabW
                height: win.slabH
                focus: true
                active: false
                asynchronous: false
                opacity: Math.max(0, Math.min(1, (win.settled - 0.55) / 0.4))
                readonly property string view: ["Clear", "Float", "Stage"][dlg.app.galleryStyle] || "Clear"
                onViewChanged: if (active) load()
                onActiveChanged: if (active && !item) load()
                function load() {
                    setSource("../views/" + view + ".qml", { app: dlg.app, desk: deskScene })
                }
                onLoaded: {
                    item.morphing = Qt.binding(() => win.morphing)
                    item.opened()
                }
            }
            Toast {
                app: dlg.app
                scene: content.item && content.item.toastScene ? content.item.toastScene : deskScene
                bottomGap: content.item ? content.item.toastGap : 16
                x: 0
            }
        }
    }
}

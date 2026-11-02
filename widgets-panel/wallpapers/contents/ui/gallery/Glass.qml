import QtQuick

// One piece of Liquid Glass over a Scene. The defaults suit a small control; the slab sets its own.
ShaderEffect {
    id: g

    required property Item source          // the Scene behind this glass
    property real roundness: 2
    property real radius: Math.min(width, height) / 2
    property real refractThickness: 12
    property real refractIOR: 1.7
    property real refractScale: 22
    property real chromaStrength: 0.3
    property color tintColor: "black"
    property real tintAlpha: 0.2
    property real frost: 2.6               // mip level at scale 1; 0 = perfectly clear
    property real frostPx: 7               // reach of the frost, in logical px
    property real specStrength: 0.4
    property real sharpMix: 0.85
    property real vibrancy: 1.4
    property real fresnel: 0.3
    property real legibility: 0.65
    property real depth: 0.5
    property real magnify: 0.5
    property real gloss: 0.45
    property real shade: 0.6               // keeps white text readable over a bright backdrop

    // pointer light, in item UV
    property vector2d mousePos: Qt.vector2d(-1, -1)
    property real mouseFade: 0

    property size size: Qt.size(width, height)
    property vector4d tint: Qt.vector4d(tintColor.r, tintColor.g, tintColor.b, tintAlpha)
    property variant scene: source
    readonly property real dpr: Window.window ? Window.window.devicePixelRatio : 1
    property real frostLod: frost <= 0 ? 0 : frost + Math.log2(Math.max(1, dpr))
    property vector2d frostSpread: source && source.width > 0
        ? Qt.vector2d(frostPx / source.width, frostPx / source.height) : Qt.vector2d(0, 0)

    property vector2d uvOffset: Qt.vector2d(0, 0)
    property vector2d uvScale: Qt.vector2d(1, 1)

    function place() {
        if (!source || source.width <= 0 || source.height <= 0) return
        const p = g.mapToItem(source, 0, 0)
        uvOffset = Qt.vector2d(p.x / source.width, p.y / source.height)
        uvScale = Qt.vector2d(width / source.width, height / source.height)
    }
    onXChanged: place()
    onYChanged: place()
    onWidthChanged: place()
    onHeightChanged: place()
    onSourceChanged: place()
    Component.onCompleted: place()
    Connections {
        target: g.source
        function onWidthChanged() { g.place() }
        function onHeightChanged() { g.place() }
        function onMoved() { g.place() }
    }

    fragmentShader: Qt.resolvedUrl("shaders/glass.frag.qsb")
}

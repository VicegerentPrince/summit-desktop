import QtQuick

// What the glass above it refracts: one live, mipmapped capture of `sourceItem`. It redraws only when
// something inside changes, and nothing chains from it, so a still gallery costs nothing.
ShaderEffectSource {
    id: scene

    // Glass follows its own moves. While a parent moves, set this and all of it follows together.
    property bool tracking: false
    signal moved()
    FrameAnimation { running: scene.tracking; onTriggered: scene.moved() }

    opacity: 0
    live: true
    hideSource: true
    smooth: true
    mipmap: true
    recursive: false
}

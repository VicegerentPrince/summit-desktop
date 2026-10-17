// A GitHub Octicon (MIT, GitHub Inc.) drawn as a vector shape: crisp at any size, in any colour.
import QtQuick
import QtQuick.Shapes
import "octicons.js" as Octicons

Item {
    id: g
    property string name: "dot-fill"
    property color color: "white"

    implicitWidth: 16
    implicitHeight: 16

    Shape {
        anchors.centerIn: parent
        width: 16
        height: 16
        scale: Math.min(g.width, g.height) / 16
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            fillColor: g.color
            strokeColor: "transparent"
            fillRule: ShapePath.WindingFill     // SVG's default (nonzero); Qt defaults to odd-even
            PathSvg { path: Octicons.paths[g.name] || "" }
        }
    }
}

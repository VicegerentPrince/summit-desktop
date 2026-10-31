#!/usr/bin/env python3
"""The Calendar card: the list of events is rebuilt only when it has really changed, and then its
rows fade in, so a refresh with no news moves nothing. At midnight the new day's badge pops in."""
import re
import sys

c = sys.argv[1]
p = c + "/ui/main.qml"
s = open(p).read()


def swap(a, b):
    global s
    assert s.count(a) == 1, a
    s = s.replace(a, b)


swap('import org.kde.plasma.core as PlasmaCore\n', 'import org.kde.plasma.core as PlasmaCore\nimport org.kde.kirigami as Kirigami\n')
a = s.index("    function _doRebuildEventsModel() {")
b = s.index("    fullRepresentation: Item {")
f = s[a:b]
assert f.count("        eventsModel.clear();\n") == 1
f = f.replace("        eventsModel.clear();\n", "        const rows = [];\n").replace("eventsModel.append(", "rows.push(")
end = "\n    }\n\n"
assert f.endswith(end), repr(f[-20:])
f = f[:-len(end)] + """

        const text = JSON.stringify(rows);
        if (text === root._shownEvents) return;
        root._shownEvents = text;
        eventsModel.clear();
        for (var ri = 0; ri < rows.length; ri++) eventsModel.append(rows[ri]);
    }

    property string _shownEvents: ""

"""
s = s[:a] + f + s[b:]
swap("""                model: eventsModel
                spacing: leftPanel._cardSpacing
""", """                model: eventsModel
                spacing: leftPanel._cardSpacing
                add: Transition {
                    NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Kirigami.Units.veryLongDuration * 0.7; easing.type: Easing.OutCubic }
                }
""")
swap("""            const n = new Date();
            root.today = n;
""", """            const n = new Date();
            root.dayTurned = true;
            root.today = n;
""")
swap("""    Timer {
        id: midnightTimer
""", """    property bool dayTurned: false
    Timer {
        id: midnightTimer
""")
swap("""                            TodayBadge {
                                anchors.centerIn: parent
""", """                            TodayBadge {
                                id: todayBadge
                                anchors.centerIn: parent
""")
swap("""                            readonly property bool isWeekend: root.isWeekendCol(index % 7)
""", """                            readonly property bool isWeekend: root.isWeekendCol(index % 7)
                            onIsCurrentChanged: if (isCurrent && root.dayTurned) dayPop.restart()
                            NumberAnimation {
                                id: dayPop
                                target: todayBadge
                                property: "scale"
                                from: 0.55
                                to: 1
                                duration: Kirigami.Units.veryLongDuration
                                easing.type: Easing.OutBack
                            }
""")
open(p, "w").write(s)

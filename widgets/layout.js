// Desktop widget layout for a 1920x1080 screen. Use apply-layout.sh, which runs this twice:
// once with MODE = "clear" and, two seconds later, once with MODE = "add".
//
// Two passes are required. Plasma frees a removed widget's cells a moment after remove() returns,
// so adding in the same pass makes the new widgets dodge the old ones and land in the wrong place.
//
// Only widgets this layout owns (the ids below) are touched; other widgets and the wallpaper are
// left alone. Positions are relative to the available screen area and snap to Plasma's 16 px grid.
var OWNED = [
    "com.jaxparrow07.macoswidgets.clock-square",
    "com.jaxparrow07.macoswidgets.calendar",
    "com.jaxparrow07.macoswidgets.weather",
    "com.jaxparrow07.macoswidgets.music",
    "summit.vitals",
    "summit.claude"
];
// One glass for every card. The tint is deeper than the suite's default (10) so white text stays
// readable on the brighter wallpapers in the library, not only on dark ones.
var GLASS = { tintAlphaPct: 26 };
function merge(a, b) { var o = {}; for (var k in a) { o[k] = a[k]; } for (var j in b) { o[j] = b[j]; } return o; }
var d = desktopForScreen(0);
var report = [];
var mode = (typeof MODE === "undefined") ? "add" : MODE;
if (mode === "clear") {
    var n = 0;
    d.widgets().forEach(function (w) { if (OWNED.indexOf(w.type) !== -1) { w.remove(); n++; } });
    print("removed " + n);
}

function add(type, x, y, w, h, config) {
    var a = d.addWidget(type, x, y, w, h);
    if (!a) { report.push(type + ": could not be added"); return; }
    if (config) {
        a.currentConfigGroup = ["General"];
        for (var k in config) { a.writeConfig(k, config[k]); }
        a.reloadConfig();
    }
    report.push(type.split(".").pop() + "=" + a.id);
}

if (mode === "add") {
    // left column
    add("com.jaxparrow07.macoswidgets.clock-square", 64, 64, 176, 176, GLASS);
    add("com.jaxparrow07.macoswidgets.calendar", 256, 64, 176, 176, merge(GLASS, { enabledCalendarPlugins: [] }));
    add("summit.vitals", 64, 256, 368, 144, GLASS);
    add("summit.claude", 64, 416, 368, 144, GLASS);

    // right column
    add("com.jaxparrow07.macoswidgets.weather", 1488, 64, 368, 368,
        merge(GLASS, WEATHER ? { location: WEATHER[0], latitude: WEATHER[1], longitude: WEATHER[2], temperatureUnit: 0 } : { temperatureUnit: 0 }));
    add("com.jaxparrow07.macoswidgets.music", 1488, 448, 368, 176, merge(GLASS, { styleMode: 0 }));   // glass, like the rest

    print(report.join("  "));
}

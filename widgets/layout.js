// Desktop widget layout, one set per screen, for 1920x1080 screens. Use apply-layout.sh, which runs
// this twice: once with MODE = "clear" and, two seconds later, once with MODE = "add".
//
// Two passes are required. Plasma frees a removed widget's cells a moment after remove() returns,
// so adding in the same pass makes the new widgets dodge the old ones and land in the wrong place.
//
// Screen 0 is the main screen: the laptop on its own, the monitor when docked. It gets the everyday
// set (time, calendar, vitals, Claude usage, weather, music). Screen 1 is the second screen, the
// laptop when docked, and gets the work set (projects, GitHub, a focus timer). Plasma keeps each
// screen's desktop, so the work set waits while undocked and is back on the next dock.
//
// SCREENS (optional) limits a run to some screens, e.g. var SCREENS = [1]. Only widgets this
// layout owns are touched; other widgets and the wallpaper are left alone. Positions are relative
// to the available screen area and snap to Plasma's 16 px grid.
var OWNED = [
    "com.jaxparrow07.macoswidgets.clock-square",
    "com.jaxparrow07.macoswidgets.calendar",
    "com.jaxparrow07.macoswidgets.weather",
    "com.jaxparrow07.macoswidgets.music",
    "com.jaxparrow07.macoswidgets.timer",
    "summit.vitals",
    "summit.claude",
    "summit.projects",
    "summit.github"
];
// One glass for every card. The base tint is light so the wallpaper shows through; the glass shader
// deepens it by itself where the wallpaper is bright, which keeps white text readable.
var GLASS = { tintAlphaPct: 18 };
function merge(a, b) { var o = {}; for (var k in a) { o[k] = a[k]; } for (var j in b) { o[j] = b[j]; } return o; }

var LAYOUTS = [
    [   // main screen
        ["com.jaxparrow07.macoswidgets.clock-square", 64, 64, 176, 176, GLASS],
        ["com.jaxparrow07.macoswidgets.calendar", 256, 64, 176, 176, merge(GLASS, { enabledCalendarPlugins: [] })],
        ["summit.vitals", 64, 256, 368, 144, GLASS],
        ["summit.claude", 64, 416, 368, 144, GLASS],
        ["com.jaxparrow07.macoswidgets.weather", 1488, 64, 368, 368,
            merge(GLASS, (typeof WEATHER !== "undefined" && WEATHER)
                ? { location: WEATHER[0], latitude: WEATHER[1], longitude: WEATHER[2], temperatureUnit: 0 } : { temperatureUnit: 0 })],
        ["com.jaxparrow07.macoswidgets.music", 1488, 448, 368, 176, merge(GLASS, { styleMode: 0 })]
    ],
    [   // second screen: two columns as tall as the main screen's, mirrored
        ["summit.projects", 64, 64, 368, 368, GLASS],
        ["com.jaxparrow07.macoswidgets.timer", 64, 448, 368, 176, GLASS],
        ["summit.github", 1488, 64, 368, 560, GLASS]
    ]
];

var mode = (typeof MODE === "undefined") ? "add" : MODE;
var only = (typeof SCREENS === "undefined") ? null : SCREENS;
var report = [];

for (var s = 0; s < LAYOUTS.length; s++) {
    if (only && only.indexOf(s) === -1) { continue; }
    if (s >= screenCount) { report.push("screen " + s + ": not connected, skipped"); continue; }
    var d = desktopForScreen(s);
    if (!d) { report.push("screen " + s + ": no desktop"); continue; }

    if (mode === "clear") {
        var n = 0;
        d.widgets().forEach(function (w) { if (OWNED.indexOf(w.type) !== -1) { w.remove(); n++; } });
        report.push("screen " + s + ": removed " + n);
        continue;
    }

    var placed = [];
    LAYOUTS[s].forEach(function (spec) {
        var a = d.addWidget(spec[0], spec[1], spec[2], spec[3], spec[4]);
        if (!a) { placed.push(spec[0] + " could not be added"); return; }
        var config = spec[5];
        if (config) {
            a.currentConfigGroup = ["General"];
            for (var k in config) { a.writeConfig(k, config[k]); }
            a.reloadConfig();
        }
        placed.push(spec[0].split(".").pop() + "=" + a.id);
    });
    report.push("screen " + s + ": " + placed.join(" "));
}
print(report.join("\n"));

// A quiet panel on every screen except the main one, and a wallpaper on every desktop that has none.
//
// Plasma ties panels and desktops to screen numbers, not to monitors. Screen 0 is whichever screen is
// primary: docked, that is the monitor, which keeps the full panel and the widgets, and the laptop is
// screen 1 with this companion panel. On its own the laptop is screen 0 again and shows the full panel,
// so nothing here has to run when you plug in or unplug.
//
// The companion matches the main panel (height, floating, opacity, length) and holds the launcher, the
// windows on its own screen and a clock. The tray stays on the main screen only, so notifications have
// one home. Safe to re-run: a screen that already has a panel is left alone.
var report = [];
var main = panels().filter(function (p) { return p.screen === 0; })[0];

function copyConfig(from, to, groups, keys) {
    if (!from) { return; }
    from.currentConfigGroup = groups; to.currentConfigGroup = groups;
    keys.forEach(function (k) {
        var v = from.readConfig(k, "");
        if (v !== "") { to.writeConfig(k, v); }
    });
}
function mainWidget(type) {
    return main ? main.widgets(type)[0] : undefined;
}

for (var s = 1; s < screenCount; s++) {
    if (panels().some(function (p) { return p.screen === s; })) { continue; }
    var p = new Panel();
    p.screen = s;
    p.location = "bottom";
    p.height = main ? main.height : 46;
    p.floating = main ? main.floating : true;
    p.opacity = main ? main.opacity : "adaptive";
    p.lengthMode = main ? main.lengthMode : "fill";
    p.alignment = main ? main.alignment : "center";
    p.hiding = main ? main.hiding : "none";

    var launcher = p.addWidget("org.kde.plasma.kickoff");
    copyConfig(mainWidget("org.kde.plasma.kickoff"), launcher, ["General"], ["icon", "favoritesPortedToKAstats"]);
    copyConfig(mainWidget("org.kde.plasma.kickoff"), launcher, [], ["popupWidth", "popupHeight"]);

    p.addWidget("org.kde.plasma.panelspacer");
    var tasks = p.addWidget("org.kde.plasma.icontasks");
    tasks.currentConfigGroup = ["General"];
    tasks.writeConfig("launchers", []);              // windows only; pinned apps live on the main panel
    tasks.writeConfig("showOnlyCurrentScreen", true);
    p.addWidget("org.kde.plasma.panelspacer");       // two flexible spacers centre the windows
    p.addWidget("org.kde.plasma.marginsseparator");  // as on the main panel: the clock gets the tray's margins and size

    var clock = p.addWidget("org.kde.plasma.digitalclock");
    copyConfig(mainWidget("org.kde.plasma.digitalclock"), clock, [], ["popupWidth", "popupHeight"]);
    report.push("panel " + p.id + " on screen " + s);
}

// a new screen's desktop starts with the stock wallpaper: give it the main screen's
var d0 = desktopForScreen(0);
d0.currentConfigGroup = ["Wallpaper", "org.kde.image", "General"];
var image = d0.readConfig("Image", "");
var fill = d0.readConfig("FillMode", "");
desktops().forEach(function (d) {
    if (d.id === d0.id || image === "") { return; }
    if (d.wallpaperPlugin !== "org.kde.image") { return; }   // a different kind of wallpaper was chosen there
    d.currentConfigGroup = ["Wallpaper", "org.kde.image", "General"];
    if (d.readConfig("Image", "") !== "") { return; }        // has its own picture: leave it
    d.writeConfig("Image", image);
    if (fill !== "") { d.writeConfig("FillMode", fill); }
    report.push("wallpaper on desktop " + d.id);
});
print(report.length ? report.join(", ") : "nothing to do");

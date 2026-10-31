// Desktop widget layout, one set per screen. Every position is computed from the size of the screen
// the widgets are on: the left group is pinned to the top-left corner and the right group to the
// top-right corner, with the same 64 px margins at any resolution or scale. On a screen too narrow
// for two columns, the right group moves under the left one.
//
// MODE (set by the caller):
//   "clear"  remove the widgets this layout owns.
//   "add"    add them at the positions computed for each screen's current size. apply-layout.sh
//            runs "clear", waits two seconds, then "add": Plasma frees a removed widget's cells a
//            moment after remove() returns, so adding in the same pass makes the new widgets dodge
//            the old ones and land in the wrong place.
//   "seed"   leave the widgets alone and write their positions for every size in SIZES (["WxH"])
//            into Plasma's per-resolution layout entries (ItemGeometries-WxH). On a size it has never
//            seen, Plasma copies the old coordinates as they are, which strands right-hand cards in
//            the middle of a bigger screen. With the entries written beforehand, a scale change,
//            docking or a new monitor puts every card in place at once. A fingerprint of each entry
//            written is kept (SummitLayout), so an entry you arranged by hand is left alone. Prints
//            a JSON report; "misplaced" lists screens whose cards are not where their entry for the
//            current size says, which Plasma only applies after a restart. With DRY = true it only
//            reports ("would" lists the entries it would write).
//            summit-layout (the watcher) runs this whenever the screens change.
//
// Screen 0 is the main screen: the laptop on its own, the monitor when docked. It gets the everyday
// set (time, calendar, vitals, Claude usage, weather, music). Screen 1 is the second screen, the
// laptop when docked, and gets the work set (projects, GitHub, a focus timer). Plasma keeps each
// screen's desktop, so the work set waits while undocked and is back on the next dock.
//
// SCREENS (optional) limits "clear"/"add" to some screens, e.g. var SCREENS = [1]. Only widgets this
// layout owns are touched; other widgets and the wallpaper are left alone. Positions snap to
// Plasma's 16 px grid, as Plasma would snap them anyway.

// One glass for every card. The base tint is light so the wallpaper shows through; the glass shader
// deepens it by itself where the wallpaper is bright, which keeps white text readable.
var GLASS = { tintAlphaPct: 18 };
function merge(a, b) { var o = {}; for (var k in a) { o[k] = a[k]; } for (var j in b) { o[j] = b[j]; } return o; }
var WEATHER_CONFIG = (typeof WEATHER !== "undefined" && WEATHER)
    ? { location: WEATHER[0], latitude: WEATHER[1], longitude: WEATHER[2], temperatureUnit: 0 } : { temperatureUnit: 0 };

// Cards by plugin: which set (screen), which group (L = top-left, R = top-right), offset inside the
// group, size, and the configuration written when the card is added.
var CARDS = {
    "com.jaxparrow07.macoswidgets.clock-square": { set: 0, group: "L", x: 0, y: 0, w: 176, h: 176, config: GLASS },
    "com.jaxparrow07.macoswidgets.calendar": { set: 0, group: "L", x: 192, y: 0, w: 176, h: 176,
        config: merge(GLASS, { enabledCalendarPlugins: [] }) },
    "summit.vitals": { set: 0, group: "L", x: 0, y: 192, w: 368, h: 144, config: GLASS },
    "summit.claude": { set: 0, group: "L", x: 0, y: 352, w: 368, h: 144, config: GLASS },
    "com.jaxparrow07.macoswidgets.weather": { set: 0, group: "R", x: 0, y: 0, w: 368, h: 368,
        config: merge(GLASS, WEATHER_CONFIG) },
    "com.jaxparrow07.macoswidgets.music": { set: 0, group: "R", x: 0, y: 384, w: 368, h: 176,
        config: merge(GLASS, { styleMode: 0 }) },
    // second screen: two columns as tall as the main screen's, mirrored
    "summit.projects": { set: 1, group: "L", x: 0, y: 0, w: 368, h: 368, config: GLASS },
    "com.jaxparrow07.macoswidgets.timer": { set: 1, group: "L", x: 0, y: 384, w: 368, h: 176, config: GLASS },
    "summit.github": { set: 1, group: "R", x: 0, y: 0, w: 368, h: 560, config: GLASS }
};
var SETS = [[], []];
for (var t in CARDS) { SETS[CARDS[t].set].push(t); }
var GRID = 16, GROUP_W = 368, GAP = 16;

function snap(v) { return Math.round(v / GRID) * GRID; }
function groupHeight(set, group) {
    var hgt = 0;
    for (var t in CARDS) {
        var c = CARDS[t];
        if (c.set === set && c.group === group) { hgt = Math.max(hgt, c.y + c.h); }
    }
    return hgt;
}
// [x, y, w, h] of a card on a screen of logical size W x H
function place(type, W, H) {
    var c = CARDS[type];
    var m = W >= 1280 ? 64 : 32;
    var left = m, right = snap(W - m - GROUP_W);
    if (c.group === "L") { return [left + c.x, m + c.y, c.w, c.h]; }
    if (right >= left + GROUP_W + 2 * GAP) { return [right + c.x, m + c.y, c.w, c.h]; }
    return [left + c.x, m + groupHeight(c.set, "L") + GAP + c.y, c.w, c.h];
}

function parseEntry(v) {
    var out = {};
    String(v || "").split(";").forEach(function (e) {
        var p = e.split(":");
        if (p.length === 2 && p[0]) { out[p[0]] = p[1].split(",").map(Number); }
    });
    return out;
}
function serialise(entry) {
    var s = "";
    for (var k in entry) { s += k + ":" + entry[k].join(",") + ";"; }
    return s;
}

var mode = (typeof MODE === "undefined") ? "add" : MODE;
var only = (typeof SCREENS === "undefined") ? null : SCREENS;
var report = [];

if (mode === "seed") {
    var result = { written: 0, misplaced: [], kept: [] };
    var wanted = (typeof SIZES === "undefined") ? [] : SIZES;
    var dry = (typeof DRY !== "undefined") && DRY;            // report only, write nothing
    if (dry) { result.would = []; }
    desktops().forEach(function (d) {
        var owned = d.widgets().filter(function (w) { return CARDS[w.type] !== undefined; });
        if (owned.length === 0) { return; }
        d.currentConfigGroup = [];
        var current = d.screen >= 0
            ? Math.round(screenGeometry(d.screen).width) + "x" + Math.round(screenGeometry(d.screen).height) : null;
        var existing = {};
        d.configKeys.forEach(function (k) {
            if (k.indexOf("ItemGeometries-") === 0) { existing[k.substring(15)] = parseEntry(d.readConfig(k, "")); }
        });
        var fallback = parseEntry(d.readConfig("ItemGeometriesHorizontal", ""));
        // a fingerprint of what this layout last wrote for each size: an entry that still matches is
        // ours to update; one that no longer matches was arranged by hand and is kept
        var record = {};
        try { record = JSON.parse(d.readConfig("SummitLayout", "{}")) || {}; } catch (e) { record = {}; }
        function fingerprint(entry) {
            var str = owned.map(function (w) {
                var e = entry["Applet-" + w.id];
                return w.id + ":" + (e ? e.slice(0, 4).join(",") : "-");
            }).sort().join(";");
            var h = 0x811c9dc5;
            for (var i = 0; i < str.length; i++) { h = Math.imul(h ^ str.charCodeAt(i), 0x01000193) >>> 0; }
            return ("0000000" + h.toString(16)).slice(-8);
        }
        // every card of ours sits exactly where another size's entry has it: a copy Plasma made
        function isCopy(entry, size) {
            for (var other in existing) {
                if (other === size) { continue; }
                var same = owned.every(function (w) {
                    var a = entry["Applet-" + w.id], b = existing[other]["Applet-" + w.id];
                    return a && b && a[0] === b[0] && a[1] === b[1];
                });
                if (same) { return true; }
            }
            return false;
        }
        var sizes = {};
        wanted.concat(Object.keys(existing)).concat(current ? [current] : []).forEach(function (s) { sizes[s] = true; });
        var recordChanged = false;
        Object.keys(sizes).forEach(function (size) {
            var dims = size.split("x").map(Number);
            if (dims.length !== 2 || !(dims[0] > 0) || !(dims[1] > 0)) { return; }
            var entry = existing[size];
            var computed = {};
            owned.forEach(function (w) {
                var p = place(w.type, dims[0], dims[1]);
                computed["Applet-" + w.id] = [p[0], p[1], p[2], p[3], 0];
            });
            var has = owned.filter(function (w) { return entry && entry["Applet-" + w.id]; });
            var matches = has.length === owned.length && owned.every(function (w) {
                var e = entry["Applet-" + w.id], c = computed["Applet-" + w.id];
                return e[0] === c[0] && e[1] === c[1];
            });
            if (matches) {
                if (record[size] !== fingerprint(entry)) { record[size] = fingerprint(entry); recordChanged = true; }
                return;
            }
            var mine = record[size] !== undefined && entry && record[size] === fingerprint(entry);
            var target = {}, k;
            var base = entry || fallback;
            for (k in base) { target[k] = base[k].slice(); }
            if (!entry || has.length === 0 || mine || (record[size] === undefined && isCopy(entry, size))) {
                for (k in computed) { target[k] = computed[k]; }          // ours: the whole layout
                record[size] = fingerprint(target);
                recordChanged = true;
            } else if (has.length < owned.length) {
                owned.forEach(function (w) {                              // hand-arranged: only add new cards
                    if (!entry["Applet-" + w.id]) { target["Applet-" + w.id] = computed["Applet-" + w.id]; }
                });
            } else {
                if (size === current) { result.kept.push(d.id + "@" + size); }
                return;
            }
            if (dry) { result.would.push(d.id + "@" + size); } else { d.writeConfig("ItemGeometries-" + size, serialise(target)); }
            existing[size] = target;
            result.written++;
        });
        if (recordChanged && !dry) { d.writeConfig("SummitLayout", JSON.stringify(record)); }
        // cards whose live place differs from the entry this layout wrote for the current size:
        // Plasma applies an entry only when the size changes or the shell starts. An entry kept as
        // arranged by hand never asks for a restart.
        if (current && existing[current] && record[current] === fingerprint(existing[current])) {
            var off = owned.some(function (w) {
                var e = existing[current]["Applet-" + w.id], g = w.geometry;
                return e && (Math.abs(e[0] - g.x) > 1 || Math.abs(e[1] - g.y) > 1);
            });
            if (off) { result.misplaced.push(d.id + "@" + current); }
        }
    });
    print(JSON.stringify(result));
} else {
    for (var s = 0; s < SETS.length; s++) {
        if (only && only.indexOf(s) === -1) { continue; }
        if (s >= screenCount) { report.push("screen " + s + ": not connected, skipped"); continue; }
        var d = desktopForScreen(s);
        if (!d) { report.push("screen " + s + ": no desktop"); continue; }

        if (mode === "clear") {
            var n = 0;
            d.widgets().forEach(function (w) { if (CARDS[w.type] !== undefined) { w.remove(); n++; } });
            report.push("screen " + s + ": removed " + n);
            continue;
        }

        var geo = screenGeometry(s);
        var W = Math.round(geo.width), H = Math.round(geo.height);
        var placed = [];
        SETS[s].forEach(function (type) {
            var p = place(type, W, H);
            var a = d.addWidget(type, p[0], p[1], p[2], p[3]);
            if (!a) { placed.push(type + " could not be added"); return; }
            var config = CARDS[type].config;
            if (config) {
                a.currentConfigGroup = ["General"];
                for (var k in config) { a.writeConfig(k, config[k]); }
                a.reloadConfig();
            }
            placed.push(type.split(".").pop() + "=" + a.id + "@" + p[0] + "," + p[1]);
        });
        report.push("screen " + s + " (" + W + "x" + H + "): " + placed.join(" "));
    }
    print(report.join("\n"));
}

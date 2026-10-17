.pragma library
// Tile colours: Apple's system colours (dark appearance) without red, orange, yellow and green,
// which the cards keep for status. A name always maps to the same colour, so a project looks the
// same on every card.
var tiles = ["#0A84FF", "#5E5CE6", "#BF5AF2", "#40C8E0", "#64D2FF", "#66D4CF", "#AC8E68", "#7D7AFF"];

function hash(s) {
    var h = 2166136261;
    for (var i = 0; i < s.length; i++) {
        h ^= s.charCodeAt(i);
        h = Math.imul(h, 16777619) >>> 0;
    }
    return h;
}

function forName(name) {
    return tiles[hash(String(name || "").toLowerCase()) % tiles.length];
}

// "chalen" -> "C", "island-tuff-crm" -> "IT", "Bobby-Tailor-Automation-2.0" -> "BT"
function monogram(name) {
    var words = String(name || "?").split(/[^A-Za-z0-9]+/).filter(function (w) { return w.length > 0; });
    if (words.length === 0) return "?";
    if (words.length === 1) return words[0].charAt(0).toUpperCase();
    return (words[0].charAt(0) + words[1].charAt(0)).toUpperCase();
}

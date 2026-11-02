import QtQuick

// Wallhaven: top-rated pictures, loaded as you scroll. Holds no interface.
Item {
    id: d
    required property var app
    readonly property alias results: found

    property string query: ""
    property bool custom: false
    property string topic: "mountains"     // the last topic, to come back to when a search is cleared
    property int page: 0
    property int lastPage: 1
    property int total: 0
    property bool loading: false
    property bool failed: false
    // When a search runs out, "Load more" widens it: all-time favourites first, then the most viewed,
    // then random picks (endless). Ids already shown are skipped.
    property int stage: 0
    readonly property var stages: ["favorites", "views", "random"]
    readonly property bool exhausted: !loading && !failed && page >= lastPage && found.count > 0
    property var seen: ({})
    property string seed: ""

    ListModel { id: found }

    // Anime is only searched together with these left out: "safe for work" is set by hand on Wallhaven,
    // and fan service sometimes slips through it
    readonly property string clean: '-ecchi -nude -lingerie -underwear -panties -bikini -swimwear -cleavage -"big boobs" -thighs -"thigh-highs" -stockings -pantyhose -"bare shoulders"'

    function load(q, isCustom) {
        query = q; custom = isCustom; page = 0; lastPage = 1; failed = false; total = 0
        if (!isCustom) topic = q
        stage = 0; seen = ({})
        found.clear()
        more()
    }
    function reload() { load(query === "" ? "mountains" : query, custom) }
    function widen() {
        if (loading) return
        stage = Math.min(stage + 1, stages.length - 1)
        seed = Math.random().toString(36).slice(2, 8)
        page = 0; lastPage = 1
        more()
    }
    function more() {
        if (query === "" || loading || page >= lastPage) return
        loading = true
        const asked = query, wasCustom = custom, next = page + 1, sort = stages[stage]
        const url = "https://wallhaven.cc/api/v1/search?q="
            + encodeURIComponent(wasCustom ? asked + " " + clean : asked)
            // a typed search also covers Anime (a search for Gojo found 2 in General alone);
            // the topics stay with General photographs. Safe for work either way.
            + "&categories=" + (wasCustom ? "110" : "100") + "&purity=100&ratios=16x9,16x10"
            + "&atleast=" + app.wanted.width + "x" + app.wanted.height
            // all-time favourites: a year's toplist ran out after a few pages (Aurora had 13)
            + (sort === "random" ? "&sorting=random&seed=" + seed : "&sorting=" + sort + "&order=desc")
            + "&page=" + next
        const xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE) return
            d.loading = false
            // the topic changed while this was in flight: drop it and load the new one
            if (asked !== d.query || wasCustom !== d.custom || sort !== d.stages[d.stage]) { d.more(); return }
            if (xhr.status !== 200) { d.failed = true; return }
            let r
            try { r = JSON.parse(xhr.responseText) } catch (e) { d.failed = true; return }
            d.failed = false
            d.page = next
            d.lastPage = (r.meta && r.meta.last_page) || next
            if (r.meta && r.meta.total && d.stage === 0) d.total = r.meta.total
            const seen = Object.assign({}, d.seen)
            let added = 0
            for (const w of r.data) {
                if (seen[w.id]) continue
                seen[w.id] = true; added++
                const px = w.dimension_x || 0
                found.append({ wid: w.id, thumb: w.thumbs.large, full: w.path, dims: w.resolution || "",
                               bytes: w.file_size || 0, colour: (w.colors && w.colors[0]) || "",
                               label: px >= 7680 ? "8K" : px >= 5120 ? "5K" : px >= 3840 ? "4K" : px >= 2560 ? "QHD" : "" })
            }
            d.seen = seen
            // a page of nothing but repeats: keep going so the grid actually grows
            if (added === 0 && d.page < d.lastPage) d.more()
        }
        xhr.open("GET", url)
        xhr.timeout = 20000      // must be set after open()
        xhr.send()
    }

    // start with a topic the first time the tab is shown
    readonly property bool shown: app.tab === 1 && app.open
    onShownChanged: if (shown && query === "") load("mountains", false)
}

#!/bin/bash
# Builds the KDE Store files into dist/:
#   summit-vitals-<v>.plasmoid          Plasma 6 Monitoring
#   summit-claude-usage-<v>.plasmoid    Plasma 6 Monitoring
#   summit-wallpapers-<v>.plasmoid      Plasma 6 Applets
#   Summit.colors                       KDE Color Scheme
#   summit-glass-<v>.tar.gz             Plasma Theme
#   summit-desktop-<v>.tar.gz           the complete setup (Various Plasma 6 Improvements)
# Needs the Liquid Glass sources that fetch.sh downloads (~/.local/share/summit/vendor).
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
V=$(cat "$ROOT/VERSION")
OUT=$ROOT/dist
B=$OUT/build
rm -rf "$OUT"; mkdir -p "$B"

plasmoid() {   # plasmoid SRC_DIR FILE_NAME
    local src=$1 name=$2 id
    id=$(python3 -c "import json,sys;print(json.load(open(sys.argv[1]))['KPlugin']['Id'])" "$src/metadata.json")
    bash "$ROOT/widgets/assemble.sh" "$src" "$B/$id"
    (cd "$B/$id" && zip -q -r -X "$OUT/$name-$V.plasmoid" .)
    echo "  $name-$V.plasmoid"
}
plasmoid "$ROOT/widgets/vitals" summit-vitals
plasmoid "$ROOT/widgets/claude" summit-claude-usage
plasmoid "$ROOT/widgets-panel/wallpapers" summit-wallpapers

cp "$ROOT/look/Summit.colors" "$OUT/Summit.colors"; echo "  Summit.colors"

# The Plasma style holds only what differs from the stock style; Plasma takes everything else
# from it (so it keeps up with Breeze updates).
S=$B/summit-glass
mkdir -p "$S/translucent/widgets"
cp "$ROOT/plasma-style/metadata.json" "$S/"
cp "$ROOT/plasma-style/panel-background.svgz" "$S/translucent/widgets/"
(cd "$B" && tar -czf "$OUT/summit-glass-$V.tar.gz" summit-glass)
echo "  summit-glass-$V.tar.gz"

tar -C "$ROOT" --exclude=.git --exclude=dist --exclude='__pycache__' \
    --transform "s,^\.,summit-desktop-$V," -czf "$OUT/summit-desktop-$V.tar.gz" .
echo "  summit-desktop-$V.tar.gz"
rm -rf "$B"

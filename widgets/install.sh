#!/bin/bash
# Installs the desktop widgets. Safe to re-run.
#
#   install.sh [DATA_DIR]            DATA_DIR defaults to ~/.local/share
#
#   1. the Liquid Glass set (clock, calendar, weather, music, timer) with local fixes
#   2. the widgets written for this desktop (Vitals, Claude usage), which borrow the same
#      glass component so every card is drawn identically
#   3. the Wallpapers gallery for the panel
set -u
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
DATA=${1:-$HOME/.local/share}
DEST=$DATA/plasma/plasmoids
VENDOR=$HOME/.local/share/summit/vendor/liquidglass-kde-widgets

bash "$HERE/liquidglass.sh" "$DATA" || exit 1

for dir in "$HERE"/*/; do
    [ -f "$dir/metadata.json" ] || continue
    id=$(python3 -c "import json,sys;print(json.load(open(sys.argv[1]))['KPlugin']['Id'])" "$dir/metadata.json") || continue
    rm -rf "$DEST/$id.new"; mkdir -p "$DEST/$id.new"
    cp -r "$dir"/. "$DEST/$id.new/"
    mkdir -p "$DEST/$id.new/contents/ui/components" "$DEST/$id.new/contents/config"
    cp -rL "$VENDOR/1-common/components/LiquidGlass.qml" "$VENDOR/1-common/components/MacOSColors.qml" \
           "$VENDOR/1-common/components/shaders" "$DEST/$id.new/contents/ui/components/"
    [ -f "$DEST/$id.new/contents/config/main.xml" ] || cp "$HERE/glass-config.xml" "$DEST/$id.new/contents/config/main.xml"
    python3 "$HERE/patch_glass.py" "$DEST/$id.new/contents/ui/components/LiquidGlass.qml"
    rm -rf "$DEST/$id"; mv "$DEST/$id.new" "$DEST/$id"
    printf '  ok    %s\n' "$id"
done

# 3. panel widgets (plain Plasma popups, no glass component needed)
for dir in "$HERE"/../widgets-panel/*/; do
    [ -f "$dir/metadata.json" ] || continue
    id=$(python3 -c "import json,sys;print(json.load(open(sys.argv[1]))['KPlugin']['Id'])" "$dir/metadata.json") || continue
    rm -rf "$DEST/$id.new"; mkdir -p "$DEST/$id.new"; cp -r "$dir"/. "$DEST/$id.new/"
    rm -rf "$DEST/$id"; mv "$DEST/$id.new" "$DEST/$id"
    printf '  ok    %s\n' "$id"
done

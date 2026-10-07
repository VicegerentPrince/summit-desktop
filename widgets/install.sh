#!/bin/bash
# Installs the desktop widgets. Safe to re-run.
#
#   install.sh [DATA_DIR]            DATA_DIR defaults to ~/.local/share
#
#   1. the Liquid Glass set (clock, calendar, weather, music, timer) with local fixes
#   2. the Summit widgets (Vitals, Claude Code usage, Wallpapers), built by assemble.sh; the
#      glass ones borrow the same glass component, so every card is drawn identically
set -u
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
DATA=${1:-$HOME/.local/share}
DEST=$DATA/plasma/plasmoids

bash "$HERE/liquidglass.sh" "$DATA" || exit 1

for dir in "$HERE"/*/ "$HERE"/../widgets-panel/*/; do
    [ -f "$dir/metadata.json" ] || continue
    id=$(python3 -c "import json,sys;print(json.load(open(sys.argv[1]))['KPlugin']['Id'])" "$dir/metadata.json") || continue
    if bash "$HERE/assemble.sh" "$dir" "$DEST/$id.new"; then
        rm -rf "$DEST/$id"; mv "$DEST/$id.new" "$DEST/$id"
        printf '  ok    %s\n' "$id"
    else
        rm -rf "$DEST/$id.new"; printf '  FAIL  %s\n' "$id"
    fi
done

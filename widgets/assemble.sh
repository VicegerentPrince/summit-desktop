#!/bin/bash
# Turns one Summit widget folder into a complete Plasma package. Used by widgets/install.sh (your
# own desktop) and store/build.sh (the KDE Store files), so both get exactly the same widget.
#
#   assemble.sh SRC_DIR OUT_DIR
#
# Glass widgets (their main.qml imports "components") get the Liquid Glass component by Jack Faith
# (jaxparrow07, GPL-3.0) with its Appearance settings and the Summit fix, plus the Inter Display
# font. Every widget gets the shared Credits page.
set -euo pipefail
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
SRC=$1 OUT=$2
VENDOR=${SUMMIT_VENDOR:-$HOME/.local/share/summit/vendor/liquidglass-kde-widgets}

rm -rf "$OUT"; mkdir -p "$OUT"; cp -r "$SRC"/. "$OUT"/
glass=false; photos=false
grep -q '^import "components"' "$OUT/contents/ui/main.qml" && glass=true
[ -f "$OUT/contents/code/wall" ] && photos=true

mkdir -p "$OUT/contents/ui/config"
sed -e "s/@GLASS@/$glass/" -e "s/@PHOTOS@/$photos/" "$HERE/common/config/ConfigCredits.qml" > "$OUT/contents/ui/config/ConfigCredits.qml"

if $glass; then
    [ -f "$VENDOR/1-common/components/LiquidGlass.qml" ] || { echo "assemble: Liquid Glass sources missing in $VENDOR (run fetch.sh)" >&2; exit 1; }
    mkdir -p "$OUT/contents/ui/components" "$OUT/contents/config" "$OUT/contents/fonts"
    cp -rL "$VENDOR/1-common/components/LiquidGlass.qml" "$VENDOR/1-common/components/MacOSColors.qml" \
           "$VENDOR/1-common/components/shaders" "$OUT/contents/ui/components/"
    cp -L "$VENDOR/1-common/config/ConfigAppearance.qml" "$OUT/contents/ui/config/"
    cp "$VENDOR/LICENSE" "$OUT/contents/ui/components/LICENSE"
    cp "$HERE/glass-config.xml" "$OUT/contents/config/main.xml"
    python3 "$HERE/patch_glass.py" "$OUT/contents/ui/components/LiquidGlass.qml" >/dev/null
    cp "$HERE/common/fonts/"* "$OUT/contents/fonts/"
fi
[ -d "$OUT/contents/code" ] && chmod 755 "$OUT/contents/code/"* || true

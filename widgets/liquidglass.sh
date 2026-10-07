#!/bin/bash
# Installs the Liquid Glass desktop widgets (jaxparrow07, GPL-3.0) from the pinned copy in
# ~/.local/share/summit/vendor, with four local changes. Safe to re-run.
#
#   liquidglass.sh [DATA_DIR]        DATA_DIR defaults to ~/.local/share
#
# Local changes, and why:
#   1. Digital clock: the seconds marker steps once per second instead of redrawing the whole
#      desktop at 60 fps for a sweep.              measured: 23% of a core  ->  0.9%
#   2. Music: progress advances once per second instead of four times.
#   3. Music: lyrics are fetched only when the Lyrics view is switched on, so hidden lyric lines
#      are not animated and track names are not sent to lrclib.net unasked.
#                                                  measured with 2+3: 14.6%  ->  ~3.7% while playing
#   4. Fonts: the bundled Apple SF Pro files are replaced by Inter Display (already installed,
#      and the interface font here), so nothing proprietary is shipped and the type matches.
#   5. Glass: the wallpaper is re-captured once it has really been drawn (patch_glass.py).
#      Without this the cards come up solid black after every login and ignore wallpaper changes.
#   6. `Font.Regular` is not a QML font weight (it is undefined), so every text using it logged a
#      warning on each update: hundreds of journal lines an hour. Replaced by `Font.Normal`,
#      which is the weight that was being drawn anyway.
#   7. Music: the scrolling-title animation could be given a negative duration for a moment,
#      which Qt rejects with a warning each time. Clamped at zero.
#
# The upstream install.sh is deliberately not used: it restarts plasmashell by process name.
set -u
SRC=$HOME/.local/share/summit/vendor/liquidglass-kde-widgets
DATA=${1:-$HOME/.local/share}
DEST=$DATA/plasma/plasmoids
PKGS="clock-digital calendar weather music timer"
# Inter Display, wherever the distribution puts it (Fedora: rsms-inter-fonts, Debian: fonts-inter, Arch: inter-font)
INTER_THIN=$(fc-list -f '%{file}\n' 2>/dev/null | grep -m1 '/InterDisplay-Thin\.[ot]tf$' || true)
INTER=${INTER_THIN:+$(dirname "$INTER_THIN")}          # empty when Inter Display is not installed
ok() { printf '  ok    %s\n' "$*"; }; warn() { printf '  WARN  %s\n' "$*"; }
[ -d "$SRC/packages" ] || { echo "missing $SRC"; exit 1; }
mkdir -p "$DEST"

patch_file() {   # patch_file FILE DESCRIPTION  (python reads OLD/NEW from env; exact-match, idempotent)
    OLD="$3" NEW="$4" python3 - "$1" "$2" <<'EOF'
import os, sys
p, what = sys.argv[1], sys.argv[2]
old, new = os.environ["OLD"], os.environ["NEW"]
s = open(p).read()
if new in s and old not in s: print(f"  ok    {what} (already applied)")
elif old in s: open(p, "w").write(s.replace(old, new, 1)); print(f"  ok    {what}")
else: print(f"  WARN  {what}: upstream code changed, patch not applied"); sys.exit(3)
EOF
}

for p in $PKGS; do
    id=$(python3 -c "import json,sys;print(json.load(open(sys.argv[1]))['KPlugin']['Id'])" "$SRC/packages/$p/metadata.json") || continue
    rm -rf "$DEST/$id.new"; cp -rL "$SRC/packages/$p" "$DEST/$id.new" || { warn "copy $p"; continue; }
    rm -rf "$DEST/$id"; mv "$DEST/$id.new" "$DEST/$id"
    # 4. fonts
    if [ -n "$INTER" ] && [ -d "$INTER" ]; then
        F=$DEST/$id/contents/fonts
        for pair in sf_pro_display_thin.otf:InterDisplay-Thin.ttf sf_pro_display_regular.otf:InterDisplay-Regular.ttf \
                    SF-Pro-Display-Light.otf:InterDisplay-Light.ttf sf_pro_rounded.otf:InterDisplay-Medium.ttf; do
            a=${pair%%:*}; b=${pair##*:}
            [ -f "$F/$a" ] && [ -f "$INTER/$b" ] && cp -f "$INTER/$b" "$F/$a"
        done
        rm -f "$F"/ios_*.otf
    fi
    python3 "$(dirname "${BASH_SOURCE[0]}")/patch_glass.py" "$DEST/$id/contents/ui/components/LiquidGlass.qml" || warn "glass fix: $id"
    grep -rlZ 'Font\.Regular' "$DEST/$id/contents/ui" --include='*.qml' | xargs -0 -r sed -i 's/Font\.Regular/Font.Normal/g'
    f="$DEST/$id/contents/ui/widget/MarqueeText.qml"
    [ -f "$f" ] && sed -i 's/? (label\.implicitWidth - marquee\.width) \* marquee\.scrollSpeed$/? Math.max(0, (label.implicitWidth - marquee.width) * marquee.scrollSpeed)/' "$f"
    ok "$id"
done

U=$DEST/com.jaxparrow07.macoswidgets.clock-square/contents/ui/main.qml
patch_file "$U" "clock: seconds marker steps once per second" \
"            interval: 16
            repeat: true
            running: full.visible
            onTriggered: {
                const ms = Date.now() % 60000;
                ticks.secondHandAngle = (ms / 60000) * 360;
            }" \
"            interval: 1000
            repeat: true
            running: full.visible
            triggeredOnStart: true
            onTriggered: {
                const s = Math.floor((Date.now() % 60000) / 1000);
                ticks.secondHandAngle = (s / 60) * 360;
            }"

U=$DEST/com.jaxparrow07.macoswidgets.music/contents/ui/main.qml
patch_file "$U" "music: progress once per second" \
"        id: positionTimer
        interval: 250" \
"        id: positionTimer
        interval: 1000"
patch_file "$U" "music: lyrics fetched only when shown" \
"    function _fetchLyrics() {
        if (track === \"\" || artist === \"\") return" \
"    function _fetchLyrics() {
        if (!lyricsActive) return
        if (track === \"\" || artist === \"\") return"
# Plasma's PlayPause() does nothing for a player that reports it can pause but not play (or the
# reverse), which is what KDE Connect's remote players do; separate Pause() and Play() calls work.
patch_file "$U" "music: play/pause works for remote (KDE Connect) players" \
"        if (!root._activePlayer) return
        root._activePlayer.PlayPause()" \
"        if (!root._activePlayer) return
        if (root.isPlaying && root.canPause) root._activePlayer.Pause()
        else if (!root.isPlaying && root.canPlay) root._activePlayer.Play()
        else root._activePlayer.PlayPause()"
# "no album" placeholder that takes the wallpaper's colour instead of an opaque grey square
cp "$(dirname "${BASH_SOURCE[0]}")/assets/no_album.png" "$DEST/com.jaxparrow07.macoswidgets.music/contents/ui/icons/no_album.png" && ok "music: adaptive no-album placeholder"
echo "Installed into $DEST. A running plasmashell loads changed widgets after it restarts."

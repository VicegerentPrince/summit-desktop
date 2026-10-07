#!/bin/bash
# The Summit look: colour scheme, icons, cursor and fonts. No root needed; safe to re-run.
# Packages it uses when present (Fedora names): papirus-icon-theme, bibata-cursor-theme,
# rsms-inter-fonts, jetbrains-mono-fonts.
set -u
HERE=$(cd "$(dirname "$0")" && pwd)
ok()   { printf '  ok    %s\n' "$*"; }
skip() { printf '  skip  %s\n' "$*"; }

# colour scheme: slate graphite with a teal accent (the accent later follows the wallpaper, see `wall`)
install -D -m 644 "$HERE/Summit.colors" "$HOME/.local/share/color-schemes/Summit.colors"
if [ "$(kreadconfig6 --file kdeglobals --group General --key ColorScheme)" != "Summit" ]; then
    plasma-apply-colorscheme Summit >/dev/null 2>&1 && ok "Summit colour scheme"
else ok "Summit colour scheme (already set)"; fi

# icons: Papirus-Dark with teal folders, as a tiny theme that inherits Papirus-Dark
if [ -d /usr/share/icons/Papirus-Dark ]; then
    # Built next to the live theme and swapped in only when it differs: deleting a theme that
    # Plasma is using makes the panel fall back to generic icons until plasmashell restarts.
    T=$HOME/.local/share/icons/Papirus-Summit
    N=$T.new; rm -rf "${N:?}"; mkdir -p "$N"
    dirs=""; sections=""
    for d in /usr/share/icons/Papirus/*/places; do
        size=$(basename "$(dirname "$d")"); px=${size%%x*}
        ls "$d"/folder-teal.svg >/dev/null 2>&1 || continue
        mkdir -p "$N/$size/places"
        for f in "$d"/folder-teal*.svg "$d"/user-teal-*.svg; do
            [ -e "$f" ] || continue
            n=$(basename "$f"); ln -sf "$f" "$N/$size/places/${n/-teal/}"
        done
        dirs="$dirs$size/places,"
        sections="$sections
[$size/places]
Size=$px
Context=Places
Type=Fixed
"
    done
    printf '[Icon Theme]\nName=Papirus-Summit\nComment=Papirus-Dark with teal folders\nInherits=Papirus-Dark,breeze-dark,hicolor\nDirectories=%s\n%s' "${dirs%,}" "$sections" > "$N/index.theme"
    if [ -d "$T" ] && diff -r --no-dereference -q "$N" "$T" >/dev/null 2>&1; then
        rm -rf "${N:?}"
    else
        rm -rf "${T:?}.old"; [ -d "$T" ] && mv "$T" "$T.old"; mv "$N" "$T"; rm -rf "${T:?}.old"
    fi
    if [ "$(kreadconfig6 --file kdeglobals --group Icons --key Theme)" != "Papirus-Summit" ]; then
        /usr/libexec/plasma-changeicons Papirus-Summit >/dev/null 2>&1
    fi
    ok "icons: Papirus-Dark with teal folders"
else skip "icons: install papirus-icon-theme for the Papirus look"; fi

# cursor
if [ -d /usr/share/icons/Bibata-Modern-Ice ]; then
    [ "$(kreadconfig6 --file kcminputrc --group Mouse --key cursorTheme)" = Bibata-Modern-Ice ] \
        || plasma-apply-cursortheme Bibata-Modern-Ice >/dev/null 2>&1
    ok "cursor: Bibata Modern Ice"
else skip "cursor: install bibata-cursor-theme for Bibata Modern Ice"; fi

# fonts: Inter for the interface, JetBrains Mono for code (written, and announced to running apps,
# only when they differ)
changed=0
kset() {  # kset GROUP KEY VALUE
    [ "$(kreadconfig6 --file kdeglobals --group "$1" --key "$2")" = "$3" ] && return
    kwriteconfig6 --file kdeglobals --group "$1" --key "$2" "$3"; changed=1
}
UI=$(fc-list : family | tr ',' '\n' | grep -m1 -xE 'Inter( Variable)?')
MONO=$(fc-list : family | tr ',' '\n' | grep -m1 -xE 'JetBrains Mono')
if [ -n "$UI" ]; then
    for k in font menuFont toolBarFont; do kset General $k "$UI,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"; done
    kset General smallestReadableFont "$UI,8,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
    kset WM activeFont "$UI,10,-1,5,600,0,0,0,0,0,0,0,0,0,0,1"
    ok "interface font: $UI"
else skip "interface font: install rsms-inter-fonts"; fi
if [ -n "$MONO" ]; then
    kset General fixed "$MONO,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
    ok "fixed-width font: $MONO"
else skip "fixed-width font: install jetbrains-mono-fonts"; fi
[ $changed = 1 ] && dbus-send --session --type=signal /KGlobalSettings org.kde.KGlobalSettings.notifyChange int32:1 int32:0 2>/dev/null
exit 0

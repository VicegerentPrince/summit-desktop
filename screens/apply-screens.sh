#!/bin/bash
# Second-screen setup. Safe to re-run: it only adds what is missing.
#   companion.js   a panel matching the main one on every other screen, and the main wallpaper on
#                  desktops that have none (a screen's desktop starts with the stock picture)
#   rgb-range.py   full RGB range for HDMI monitors that accept it
# Plasma keeps the companion panel for "screen 2" while you are undocked and shows it again when a
# second screen comes back, so this only has to run once per setup, not at every plug-in.
# Talks to whichever plasmashell and KWin are on the current session.
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
qdbus-qt6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$(cat "$HERE/companion.js")" 2>&1 | tail -1
python3 "$HERE/rgb-range.py"

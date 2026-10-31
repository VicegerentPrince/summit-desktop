#!/bin/bash
# Turns on the watcher that keeps the Summit layout in place on every screen size and scale
# (summit-layout.py). Plasma remembers widget positions per screen size and copies stale ones onto a
# size it has not seen; the watcher writes the right ones before Plasma needs them, so a new monitor
# or scale puts the cards in place at once. It is copied out of this folder, sleeps until a screen
# changes, and leaves anything you arranged by hand alone.
#
# install.sh runs this with --layout only, so a desktop arranged by hand never gets it. To stop it:
#   systemctl --user disable --now summit-layout.service
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
D=$HOME/.local/share/summit/layout
install -D -m 644 "$HERE/layout.js" "$D/layout.js"
install -D -m 644 "$HERE/summit-layout.py" "$D/summit-layout.py"
install -D -m 644 "$HERE/summit-layout.service" "$HOME/.config/systemd/user/summit-layout.service"
systemctl --user daemon-reload && systemctl --user enable summit-layout.service >/dev/null 2>&1 &&
  systemctl --user restart summit-layout.service && echo "widget layout watch on"

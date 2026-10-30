#!/bin/bash
# Second-screen setup. Safe to re-run: it only adds what is missing.
#   companion.js   a panel matching the main one on every other screen, and the main wallpaper on
#                  desktops that have none (a screen's desktop starts with the stock picture)
#   rgb-range.py   full RGB range for HDMI monitors that accept it
#   monitor-power  a user service: the laptop takes over when the external monitor loses power
# Plasma keeps the companion panel for "screen 2" while you are undocked and shows it again when a
# second screen comes back, so this only has to run once per setup, not at every plug-in.
# Talks to whichever plasmashell and KWin are on the current session.
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
qdbus-qt6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$(cat "$HERE/companion.js")" 2>&1 | tail -1
python3 "$HERE/rgb-range.py"
# a monitor that loses power still looks plugged in; this service moves the desktop to the laptop and
# back. It needs ddcutil (whose udev rule lets you talk to the monitors) and kscreen-doctor. The script
# is copied out of this folder, so the service keeps working if the folder moves.
if command -v ddcutil >/dev/null && command -v kscreen-doctor >/dev/null; then
  install -D -m 644 "$HERE/monitor-power.py" "$HOME/.local/share/summit/screens/monitor-power.py"
  install -D -m 644 "$HERE/summit-monitor-power.service" "$HOME/.config/systemd/user/summit-monitor-power.service"
  systemctl --user daemon-reload && systemctl --user enable summit-monitor-power.service >/dev/null 2>&1 &&
    systemctl --user restart summit-monitor-power.service && echo "monitor power watch on"
else
  echo "monitor power watch skipped: needs ddcutil (sudo dnf install ddcutil) and kscreen-doctor"
fi

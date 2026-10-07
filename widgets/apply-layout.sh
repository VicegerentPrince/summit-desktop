#!/bin/bash
# Places the desktop widgets. Safe to re-run: it removes the widgets it owns and adds them again.
# Talks to whichever plasmashell is on the current session bus.
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ev() { qdbus-qt6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$1" 2>&1 | tail -1; }
ev "var MODE = \"clear\"; var WEATHER = null; $(cat "$HERE/layout.js")"
sleep 2
# Weather location, optional:  SUMMIT_WEATHER="City:latitude:longitude"  (e.g. "Berlin:52.52:13.405")
W=null
if [[ -n ${SUMMIT_WEATHER:-} ]]; then IFS=: read -r city lat lon <<<"$SUMMIT_WEATHER"; W="[\"$city\", $lat, $lon]"; fi
ev "var MODE = \"add\"; var WEATHER = $W; $(cat "$HERE/layout.js")"

#!/bin/bash
# The Summit changes to the Liquid Glass cards: their extra layouts, settings pages and transitions.
# Run by liquidglass.sh after it has copied the cards fresh from the vendor.
#
#   apply.sh DEST      DEST = the plasmoids folder
set -eu
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
DEST=$1
PRE=com.jaxparrow07.macoswidgets

T=$DEST/$PRE.timer/contents
cp "$HERE"/timer/widget/*.qml "$T/ui/widget/"
mkdir -p "$T/ui/widget/shaders"
cp "$HERE"/timer/widget/shaders/flow.frag "$HERE"/timer/widget/shaders/flow.frag.qsb "$T/ui/widget/shaders/"
cp "$HERE"/timer/config/*.qml "$T/ui/config/"
python3 "$HERE/timer/patch.py" "$T"

C=$DEST/$PRE.clock-square/contents
cp "$HERE"/clock/ConfigClock.qml "$C/ui/config/"
python3 "$HERE/clock/patch.py" "$C"

python3 "$HERE/music/patch.py" "$DEST/$PRE.music/contents"

W=$DEST/$PRE.weather/contents
cp "$HERE"/weather/WeatherIcon.qml "$W/ui/widget/"
python3 "$HERE/weather/patch.py" "$W"

python3 "$HERE/calendar/patch.py" "$DEST/$PRE.calendar/contents"

for card in "$DEST/$PRE".*/contents; do
    cp "$HERE"/../common/config/{SettingsGroup,SettingRow,Footnote}.qml "$card/ui/config/"
    cp "$HERE"/../common/motion/SwapText.qml "$card/ui/components/"
    # the vendor's own support page becomes the plain Credits page every Summit card has
    sed -i 's/name: i18n("More \& Support")/name: i18n("Credits")/; s/icon: "love"/icon: "help-about"/' "$card/config/config.qml"
    python3 "$HERE/credits.py" "$card"
done

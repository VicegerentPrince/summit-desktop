#!/usr/bin/env python3
"""The Weather card: when a reading arrives the temperature and the words lift over, and the icon
dissolves into the new sky (widget/WeatherIcon.qml). The same reading again moves nothing."""
import re
import sys

p = sys.argv[1] + "/ui/main.qml"
lines = open(p).read().split("\n")


def to_swap(needle, count, extra=""):
    found = 0
    for i, line in enumerate(lines):
        if line.strip() == needle:
            found += 1
            j = i
            while lines[j].strip() != "Text {":
                j -= 1
            lines[j] = lines[j].replace("Text {", "SwapText {")
            if extra:
                lines[i] = lines[i] + "\n" + " " * (len(line) - len(line.lstrip())) + extra
    assert found == count, needle


to_swap('text: weatherData.currentTemp + "°"', 3)
to_swap("text: weatherData.condition", 2, "align: Text.AlignRight")
open(p, "w").write("\n".join(lines))

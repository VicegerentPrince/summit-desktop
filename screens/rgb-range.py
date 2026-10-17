#!/usr/bin/env python3
"""Full RGB range for HDMI monitors that accept it.

KWin's "Automatic" range sends TV-style limited range (16-235) over HDMI for standard video modes
such as 1920x1080@60, because that is the CTA-861 default. A monitor whose EDID marks its RGB range
as selectable (the QS bit of the Video Capability Data Block) reads the range from the signal, so
full range (0-255) is safe there and keeps all 256 levels: no lifted blacks, less banding.

Only outputs still on Automatic are changed; a range set by hand is left alone. KWin remembers the
choice per monitor, so this needs to run once for each new monitor.
"""
import glob
import json
import subprocess


def rgb_range_selectable(edid: bytes) -> bool:
    for i in range(1, len(edid) // 128):
        block = edid[i * 128:(i + 1) * 128]
        if block[0] != 0x02:  # not a CTA-861 extension
            continue
        end, pos = block[2], 4  # data blocks sit between byte 4 and the DTD offset
        while pos < min(end, 127):
            tag, length = block[pos] >> 5, block[pos] & 0x1F
            if tag == 7 and length >= 2 and block[pos + 1] == 0x00:  # extended tag 0: Video Capability
                return bool(block[pos + 2] & 0x40)  # QS
            pos += 1 + length
    return False


def main() -> None:
    try:
        out = subprocess.run(["kscreen-doctor", "-j"], capture_output=True, text=True, timeout=10).stdout
        outputs = json.loads(out)["outputs"]
    except (OSError, subprocess.SubprocessError, ValueError, KeyError):
        print("could not read the screen setup (kscreen-doctor)")
        return
    hdmi = [o for o in outputs if o.get("connected") and o.get("enabled") and o["name"].startswith("HDMI")]
    if not hdmi:
        print("no HDMI monitor connected")
        return
    for o in hdmi:
        name = o["name"]
        edid = b""
        for path in glob.glob(f"/sys/class/drm/card*-{name}/edid"):
            with open(path, "rb") as f:
                edid = f.read()
        if o.get("rgbRange") != 0:  # 0 Automatic, 1 Full, 2 Limited
            print(f"{name}: RGB range already set ({'full' if o.get('rgbRange') == 1 else 'limited'})")
        elif not rgb_range_selectable(edid):
            print(f"{name}: monitor does not say it accepts full range, left on automatic")
        else:
            r = subprocess.run(["kscreen-doctor", f"output.{name}.rgbrange.full"], capture_output=True, text=True, timeout=15)
            print(f"{name}: full RGB range" if r.returncode == 0 else f"{name}: could not set full range")


if __name__ == "__main__":
    main()

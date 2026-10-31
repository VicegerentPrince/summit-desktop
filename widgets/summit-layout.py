#!/usr/bin/env python3
"""Keeps the Summit desktop widgets laid out for whatever screen they are on.

Plasma remembers widget positions per screen resolution, and on a size it has never seen it copies
the old coordinates as they are: after a scale change or on a new monitor, cards meant for the right
edge end up in the middle. This watcher writes the right positions (layout.js, mode "seed") for every
size a known screen can have, each scale from 100 % to 300 % plus common monitor modes, before
Plasma needs them, so docking, undocking and scale changes put the cards in place at once.

If Plasma has already copied stale positions for the size on screen (a monitor or scale it had
never seen), the corrected positions only apply after a restart, so the shell is restarted once.
That is rare by design.

Plain Python, no polling: it sleeps until KWin rewrites its display configuration or the kernel
reports a display hotplug, then does one pass. About 16 MB of memory.
`summit-layout.py --once` does a single pass and exits (apply-layout.sh uses it); with --dry-run it
only reports what it would write or restart.
"""
import ctypes
import ctypes.util
import json
import os
import select
import socket
import struct
import subprocess
import sys
import time

HERE = os.path.dirname(os.path.realpath(__file__))
LAYOUT_JS = os.path.join(HERE, "layout.js")
CONFIG_HOME = os.environ.get("XDG_CONFIG_HOME") or os.path.expanduser("~/.config")
OUTPUTS_NAME = "kwinoutputconfig.json"
OUTPUTS = os.path.join(CONFIG_HOME, OUTPUTS_NAME)
# a test session can swap the restart for its own (it has no systemd unit for its shell)
RESTART = os.environ.get("SUMMIT_LAYOUT_RESTART", "systemctl --user restart plasma-plasmashell.service")
COMMON_MODES = [(1280, 720), (1280, 800), (1280, 1024), (1366, 768), (1440, 900), (1536, 864),
                (1600, 900), (1680, 1050), (1920, 1080), (1920, 1200), (2560, 1080), (2560, 1440),
                (2560, 1600), (2880, 1800), (3440, 1440), (3840, 1600), (3840, 2160), (5120, 1440),
                (5120, 2880)]
COMMON_SCALES = (1.0, 1.25, 1.5, 1.75, 2.0)
MIN_W, MIN_H = 1000, 560          # smaller logical screens cannot hold the cards anyway
SETTLE = 2.5                      # seconds after the last event before a pass
RESTART_GAP = 60                  # seconds between shell restarts, at least


def log(*a):
    print(time.strftime("%H:%M:%S"), *a, flush=True)


def logical(w, h, scale):
    # Plasma keys its layouts on Math.round of the logical size, which is mode / scale
    return int(w / scale + 0.5), int(h / scale + 0.5)


def known_modes():
    modes = set()
    try:
        with open(OUTPUTS) as f:
            data = json.load(f)
    except (OSError, ValueError):
        return modes
    for section in data:
        if section.get("name") != "outputs":
            continue
        for out in section.get("data", []):
            mode = out.get("mode") or {}
            w, h = mode.get("width"), mode.get("height")
            if not w or not h:
                continue
            rotated = any(r in str(out.get("transform", "")) for r in ("90", "270"))
            modes.add((h, w) if rotated else (w, h))
    return modes


def sizes():
    found = set()
    for w, h in known_modes():
        for step in range(41):                       # 100 % to 300 % in 5 % steps
            found.add(logical(w, h, 1 + step * 0.05))
    for w, h in COMMON_MODES:
        for s in COMMON_SCALES:
            found.add(logical(w, h, s))
    return sorted("%dx%d" % (w, h) for w, h in found if max(w, h) >= MIN_W and min(w, h) >= MIN_H)


def shell_running():
    return subprocess.run(["qdbus-qt6", "org.kde.plasmashell", "/PlasmaShell"],
                          stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode == 0


class Watcher:
    def __init__(self):
        self.due = None           # monotonic time of the next pass
        self.why = ""
        self.last_restart = -1e9
        self.restarted_for = set()

    def schedule(self, delay, why):
        self.due = time.monotonic() + delay
        self.why = why

    def run_pass(self, why="", dry=False):
        if not shell_running():
            return None
        with open(LAYOUT_JS) as f:
            js = 'var MODE = "seed"; var DRY = %s; var SIZES = %s;\n%s' % (
                "true" if dry else "false", json.dumps(sizes()), f.read())
        try:
            r = subprocess.run(["qdbus-qt6", "org.kde.plasmashell", "/PlasmaShell",
                                "org.kde.PlasmaShell.evaluateScript", js],
                               capture_output=True, text=True, timeout=30)
            res = json.loads(r.stdout.strip().splitlines()[-1])
        except (OSError, subprocess.TimeoutExpired, ValueError, IndexError) as e:
            log("layout pass failed:", e)
            return None
        if dry:
            return res
        if res.get("written"):
            log("wrote positions for %d screen sizes%s" % (res["written"], " (" + why + ")" if why else ""))
        # cards that are not where their entry says: only a shell restart applies the entry. Never
        # twice for the same screen and size, so a layout Plasma refuses cannot cause a restart loop.
        off = [s for s in res.get("misplaced", []) if s not in self.restarted_for]
        if off:
            wait = self.last_restart + RESTART_GAP - time.monotonic()
            if wait > 0:
                self.schedule(wait + 1, "retry")
            else:
                self.restarted_for.update(off)
                self.last_restart = time.monotonic()
                log("restarting the shell to put the cards in place on", ", ".join(off))
                subprocess.run(RESTART, shell=True, check=False)
        return res


def inotify_dir(path):
    libc = ctypes.CDLL(ctypes.util.find_library("c") or "libc.so.6", use_errno=True)
    fd = libc.inotify_init1(os.O_NONBLOCK | os.O_CLOEXEC)
    # KWin saves through a temporary file and a rename, so watch the folder, not the file
    if fd < 0 or libc.inotify_add_watch(fd, path.encode(), 0x00000008 | 0x00000080) < 0:  # CLOSE_WRITE, MOVED_TO
        raise OSError(ctypes.get_errno(), "inotify on " + path)
    return fd


def inotify_names(fd):
    names, buf = [], b""
    try:
        buf = os.read(fd, 65536)
    except BlockingIOError:
        pass
    i = 0
    while i + 16 <= len(buf):
        _wd, _mask, _cookie, size = struct.unpack_from("iIII", buf, i)
        names.append(buf[i + 16:i + 16 + size].split(b"\0", 1)[0].decode(errors="replace"))
        i += 16 + size
    return names


def main():
    w = Watcher()
    if "--once" in sys.argv:
        res = w.run_pass("once", dry="--dry-run" in sys.argv)
        print(json.dumps(res) if res is not None else "plasmashell is not running")
        return 0 if res is not None else 1

    ino = inotify_dir(CONFIG_HOME)
    # kernel uevents: a display plugged in or out (an unplug does not always rewrite KWin's file)
    uev = socket.socket(socket.AF_NETLINK, socket.SOCK_DGRAM | socket.SOCK_NONBLOCK | socket.SOCK_CLOEXEC, 15)
    uev.bind((0, 1))
    w.schedule(8, "login")
    log("watching the screens")
    while True:
        timeout = None if w.due is None else max(0.0, w.due - time.monotonic())
        ready, _, _ = select.select([ino, uev], [], [], timeout)
        if ino in ready and OUTPUTS_NAME in inotify_names(ino):
            w.schedule(SETTLE, "display settings")
        if uev in ready:
            hotplug = False
            while True:
                try:
                    if b"SUBSYSTEM=drm" in uev.recv(65536):
                        hotplug = True
                except BlockingIOError:
                    break
            if hotplug:
                w.schedule(SETTLE, "display hotplug")
        if w.due is not None and time.monotonic() >= w.due:
            w.due = None
            if w.why == "login":
                for _ in range(60):                       # the shell may still be starting
                    if shell_running():
                        break
                    time.sleep(2)
            w.run_pass(w.why)


if __name__ == "__main__":
    sys.exit(main())

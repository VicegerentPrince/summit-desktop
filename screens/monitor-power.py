#!/usr/bin/env python3
"""Moves the desktop to the laptop when an external monitor loses power, and back when it returns.

An HDMI monitor without power still looks plugged in: the cable carries 5 V from the laptop, which
keeps the monitor's hot-plug line up, so neither the kernel nor KWin ever sees it go. Its DDC/CI
channel does go quiet, and Plasma's power daemon (through libddcutil) logs that as
DDCA_EVENT_DISPLAY_DISCONNECTED / _CONNECTED. This service follows those log lines (no polling while
all is well), confirms with one DDC read, and switches the output off or back on through KWin,
restoring the layout and which screen is primary.

While a monitor is switched off by this service it is also checked every 30 s, in case an event
was missed (and once at start, for a power cut that ended while the laptop was off).

Only acts when another screen stays on, so it never leaves you without a display. DDC also drops
for 5-8 s while the desktop shell starts, so a monitor counts as unpowered only after 15 s of
silence and two failed reads, and a "connected" event in that time cancels it. The layout is only
given back to the same monitor (by EDID); a cable unplugged meanwhile forgets it.

Only monitors that have answered DDC at least once since the service started are ever switched
off: one with DDC/CI turned off in its own menu never answers, and must not be taken for unpowered.
"""
import fcntl
import glob
import hashlib
import json
import os
import subprocess
import threading
import time

STATE = os.path.join(os.environ.get("XDG_STATE_HOME") or os.path.expanduser("~/.local/state"),
                     "summit", "monitor-power.json")
lock = threading.Lock()
pending = {}            # connector -> time its "disconnected" event arrived
answered = set()        # connectors whose DDC has answered; the only ones ever switched off
CONFIRM_AFTER = 15      # seconds; longer than the 5-8 s dropouts seen during shell restarts
BUILT_IN = ("eDP", "LVDS", "DSI")   # laptop panels, never watched


def log(msg):
    print(msg, flush=True)


def outputs():
    out = subprocess.run(["kscreen-doctor", "-j"], capture_output=True, text=True, timeout=10).stdout
    return json.loads(out)["outputs"]


def ddc_alive(connector):
    """One DDC read on the monitor's own I2C bus: answers only when the monitor has power."""
    for ddc in glob.glob(f"/sys/class/drm/card*-{connector}/ddc"):
        bus = os.path.basename(os.path.realpath(ddc)).replace("i2c-", "")
        r = subprocess.run(["ddcutil", "--bus", bus, "getvcp", "10"],
                           capture_output=True, text=True, timeout=15)
        return r.returncode == 0
    return False


def probe(connector):
    """One raw read at the DDC/CI address (0x37): about a millisecond, fails at once without power.
    Plasma's own DDC watcher does not always report a power cut, so this is the main signal.
    True: it answered. False: it did not. None: no way to ask (no bus, no permission)."""
    for ddc in glob.glob(f"/sys/class/drm/card*-{connector}/ddc"):
        dev = "/dev/" + os.path.basename(os.path.realpath(ddc))
        try:
            fd = os.open(dev, os.O_RDWR)
        except OSError:
            return None                      # cannot tell: never act on that
        try:
            fcntl.ioctl(fd, 0x0703, 0x37)    # I2C_SLAVE
            os.read(fd, 1)
            return True
        except OSError:
            return False
        finally:
            os.close(fd)
    return None


def watch():
    """Every 5 s: external monitors that are on get the raw probe; three misses in a row (15 s)
    hand over to switch_off, which still needs two failed full DDC reads. Monitors this service
    switched off get a full DDC read every 10 s and come back as soon as one answers."""
    misses, tick = {}, 0
    while True:
        tick += 1
        try:
            for o in outputs():
                name = o["name"]
                if name.startswith(BUILT_IN) or not o.get("connected"):
                    continue
                if o["enabled"]:
                    alive = probe(name)
                    if alive is not False:
                        if alive:
                            answered.add(name)
                        misses[name] = 0
                        continue
                    misses[name] = misses.get(name, 0) + 1
                    if misses[name] == 3:
                        switch_off(name)
                elif name in load() and tick % 2 == 0:
                    switch_on(name)
        except Exception as e:
            log(f"watch: {e}")
        time.sleep(5)


def sysfs(connector, name):
    for path in glob.glob(f"/sys/class/drm/card*-{connector}/{name}"):
        with open(path, "rb") as f:
            return f.read()
    return b""


def edid_id(connector):
    return hashlib.sha1(sysfs(connector, "edid")).hexdigest()[:16]


def load():
    try:
        with open(STATE) as f:
            return json.load(f)
    except (OSError, ValueError):
        return {}


def save(state):
    os.makedirs(os.path.dirname(STATE), exist_ok=True)
    with open(STATE + ".tmp", "w") as f:
        json.dump(state, f)
    os.replace(STATE + ".tmp", STATE)


def switch_off(connector):
    with lock:
        outs = outputs()
        me = next((o for o in outs if o["name"] == connector), None)
        others = [o for o in outs if o["enabled"] and o["name"] != connector]
        if not me or not me["enabled"] or not others or connector not in answered:
            return
        if ddc_alive(connector):
            log(f"{connector}: DDC still answers, leaving it on")
            return
        time.sleep(3)
        if ddc_alive(connector):
            log(f"{connector}: DDC answered on the second try, leaving it on")
            return
        state = load()
        # the whole layout as it was, so the way back is exact, and which monitor it belongs to
        state[connector] = {"edid": edid_id(connector),
                            "layout": [{"name": o["name"], "x": o["pos"]["x"], "y": o["pos"]["y"], "priority": o["priority"]}
                                       for o in outs if o["enabled"]]}
        save(state)
        subprocess.run(["kscreen-doctor", f"output.{connector}.disable"], capture_output=True, timeout=15)
        log(f"{connector}: no power, switched off; the laptop takes over")


def switch_on(connector):
    with lock:
        state = load()
        entry = state.get(connector)
        if not entry:
            return
        # unplugged since, or another monitor on this port: forget, never force the old layout on it
        if sysfs(connector, "status").strip() != b"connected" or entry.get("edid") != edid_id(connector):
            del state[connector]
            save(state)
            log(f"{connector}: unplugged or a different monitor now, forgetting the saved layout")
            return
        if not ddc_alive(connector):
            return
        layout = entry["layout"]
        args = [f"output.{connector}.enable"]
        for o in layout:
            args += [f"output.{o['name']}.position.{o['x']},{o['y']}", f"output.{o['name']}.priority.{o['priority']}"]
        r = subprocess.run(["kscreen-doctor", *args], capture_output=True, timeout=15)
        if r.returncode == 0:
            del state[connector]
            save(state)
            log(f"{connector}: power is back, switched on with the earlier layout")


def recheck():
    while True:
        for connector in list(load().keys()):
            try:
                switch_on(connector)
            except Exception as e:  # keep the service alive whatever one check does
                log(f"recheck {connector}: {e}")
        time.sleep(30)


def confirm_off(connector, since):
    time.sleep(CONFIRM_AFTER)
    with lock:
        if pending.get(connector) != since:     # a "connected" event (or a newer event) came in between
            return
        del pending[connector]
    switch_off(connector)


def main():
    threading.Thread(target=watch, daemon=True).start()
    follow = subprocess.Popen(["journalctl", "--user", "-f", "-n0", "-o", "cat",
                               "SYSLOG_IDENTIFIER=org_kde_powerdevil"],
                              stdout=subprocess.PIPE, text=True)
    for line in follow.stdout:
        if "DDCA_EVENT_" not in line or ", card" not in line:
            continue
        connector = line.split(", card", 1)[1].split(",", 1)[0].split("-", 1)[1]
        if connector.startswith(BUILT_IN):
            continue
        try:
            if "DDCA_EVENT_DISPLAY_DISCONNECTED" in line:
                since = time.monotonic()
                with lock:
                    pending[connector] = since
                threading.Thread(target=confirm_off, args=(connector, since), daemon=True).start()
            elif "DDCA_EVENT_DISPLAY_CONNECTED" in line or "DDCA_EVENT_DDC_ENABLED" in line:
                with lock:
                    pending.pop(connector, None)
                    answered.add(connector)
                time.sleep(2)                      # the monitor needs a moment before DDC answers
                switch_on(connector)
        except Exception as e:
            log(f"{connector}: {e}")


if __name__ == "__main__":
    main()

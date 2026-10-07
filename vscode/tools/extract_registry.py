#!/usr/bin/env python3
"""Reads the colour ids registered by the installed VS Code and Cursor.

Read-only: parses the workbench bundles and the built-in extensions'
package.json files on disk. Nothing is launched. Writes
tools/color-registry.json, which check_theme.py uses to confirm that every
theme key is a real colour id and to list the ids the theme leaves unset.

Run:  python3 tools/extract_registry.py
"""
import glob
import json
import os
import re

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "color-registry.json")

EDITORS = {
    "vscode": "/usr/share/code/resources/app",
    "cursor": "/usr/share/cursor/resources/app",
}
BUNDLES = [
    "out/vs/workbench/workbench.desktop.main.js",
    "out/vs/sessions/sessions.desktop.main.js",   # agents window (VS Code 1.14x)
]
ID = r'([A-Za-z][\w]*(?:\.[\w-]+)*)'


def call_args(src, start):
    """Arguments of a minified call, starting just after the first argument's comma."""
    depth, i, cur, quote, args = 0, start, start, None, []
    while i < len(src):
        c = src[i]
        if quote:
            if c == "\\":
                i += 2
                continue
            if c == quote:
                quote = None
        elif c in "\"'`":
            quote = c
        elif c in "([{":
            depth += 1
        elif c in ")]}":
            if depth == 0:
                args.append(src[cur:i])
                return args
            depth -= 1
        elif c == "," and depth == 0:
            args.append(src[cur:i])
            cur = i + 1
        i += 1
    return args


def core_ids(bundle):
    """Returns (ids, ids registered with needsTransparency=true)."""
    with open(bundle, encoding="utf-8", errors="replace") as fh:
        src = fh.read()
    # registerColor is minified; find its name from a registration that never changes.
    m = re.search(r'([A-Za-z_$][\w$]*)\("editor\.background",\{light:"#ffffff"', src)
    if not m:
        return set(), set()
    fn = re.escape(m.group(1))
    ids, translucent = set(), set()
    for call in re.finditer(r'(?<![\w$.])' + fn + r'\("' + ID + r'",', src):
        ids.add(call.group(1))
        args = call_args(src, call.end())     # defaults, description, needsTransparency
        if len(args) >= 3 and args[2].strip() in ("!0", "true"):
            translucent.add(call.group(1))
    # the 16 ANSI colours are registered from a table in a loop
    ids.update(re.findall(r'"(terminal\.ansi[A-Za-z]+)":\{index:\d+', src))
    return ids, translucent


def extension_ids(app):
    ids = set()
    for pj in glob.glob(os.path.join(app, "extensions", "*", "package.json")):
        try:
            with open(pj, encoding="utf-8") as fh:
                pkg = json.load(fh)
        except (OSError, ValueError):
            continue
        for c in (pkg.get("contributes") or {}).get("colors") or []:
            ids.add(c["id"])
    return ids


def main():
    out = {}
    for name, app in EDITORS.items():
        if not os.path.isdir(app):
            continue
        with open(os.path.join(app, "product.json"), encoding="utf-8") as fh:
            product = json.load(fh)
        ids, translucent = set(), set()
        for b in BUNDLES:
            p = os.path.join(app, b)
            if os.path.exists(p):
                found, needs_alpha = core_ids(p)
                ids |= found
                translucent |= needs_alpha
        ids |= extension_ids(app)
        out[name] = {
            "version": product.get("version"),
            "vscodeVersion": product.get("vscodeVersion", product.get("version")),
            "ids": sorted(ids),
            "mustBeTranslucent": sorted(translucent),
        }
        print("%-7s %s (VS Code base %s): %d colour ids, %d flagged as needing transparency"
              % (name, out[name]["version"], out[name]["vscodeVersion"], len(ids), len(translucent)))
    with open(OUT, "w", encoding="utf-8", newline="\n") as fh:
        json.dump(out, fh, indent=1)
        fh.write("\n")
    print("wrote %s" % OUT)


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""Draws an approximate mock of the workbench from the built theme file.

This is NOT a screenshot of VS Code: it is a hand-laid-out picture that uses
the real theme values and the real tokeniser output, so colour relationships
can be judged before the theme is installed. Layout, icons and metrics are
approximations.

Run:  python3 tools/preview.py      writes tools/preview-workbench.png (classic layout, Cursor),
                                    tools/preview-modern-ui.png (VS Code 1.14x Modern UI) and tools/preview-widgets.png
"""
import json
import os
import subprocess
import sys

from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
THEME = json.load(open(os.path.join(ROOT, "summit-theme", "themes", "summit-color-theme.json"), encoding="utf-8"))
C = THEME["colors"]

MONO = os.path.expanduser("~/.local/share/fonts/JetBrainsMonoNerdFont/JetBrainsMonoNerdFont-%s.ttf")
UI = "/usr/share/fonts/rsms-inter-fonts/Inter-%s.ttf"


def font(path, size):
    try:
        return ImageFont.truetype(path, size)
    except OSError:
        return ImageFont.load_default()


F_CODE = {"": font(MONO % "Regular", 14), "italic": font(MONO % "Italic", 14),
          "bold": font(MONO % "Bold", 14), "italic bold": font(MONO % "BoldItalic", 14)}
F_UI = font(UI % "Regular", 13)
F_UI_S = font(UI % "Regular", 11)
F_UI_B = font(UI % "SemiBold", 13)
F_UI_SB = font(UI % "SemiBold", 11)
CW = F_CODE[""].getlength("M")
LH = 21


def rgba(c):
    c = c.lstrip("#")
    r, g, b = (int(c[i:i + 2], 16) for i in (0, 2, 4))
    return (r, g, b, int(c[6:8], 16) if len(c) == 8 else 255)


class Canvas:
    def __init__(self, w, h, bg):
        self.im = Image.new("RGBA", (w, h), rgba(bg))
        self.d = ImageDraw.Draw(self.im)

    def rect(self, x0, y0, x1, y1, fill=None, outline=None, radius=0, width=1):
        x0, y0, x1, y1 = int(x0), int(y0), int(x1), int(y1)
        if x1 <= x0 or y1 <= y0:
            return
        layer = Image.new("RGBA", (x1 - x0, y1 - y0), (0, 0, 0, 0))
        d = ImageDraw.Draw(layer)
        box = (0, 0, x1 - x0 - 1, y1 - y0 - 1)
        f = rgba(fill) if fill else None
        o = rgba(outline) if outline else None
        if radius:
            d.rounded_rectangle(box, radius=radius, fill=f, outline=o, width=width)
        else:
            d.rectangle(box, fill=f, outline=o, width=width)
        self.im.alpha_composite(layer, (x0, y0))
        self.d = ImageDraw.Draw(self.im)

    def shadow(self, x0, y0, x1, y1, radius=6):
        col = rgba(C["widget.shadow"])
        for i in range(8, 0, -1):
            a_ = int(col[3] * (0.05 + 0.03 * (8 - i)))
            self.rect(x0 - i, y0 - i + 2, x1 + i, y1 + i + 2, fill="#%02x%02x%02x%02x" % (col[0], col[1], col[2], a_), radius=radius + i)

    def text(self, x, y, s, fill, f=None):
        self.d.text((x, y), s, font=f or F_UI, fill=rgba(fill))
        return x + (f or F_UI).getlength(s)

    def hline(self, x0, x1, y, col):
        self.rect(x0, y, x1, y + 1, fill=col)

    def vline(self, x, y0, y1, col):
        self.rect(x, y0, x + 1, y1, fill=col)


def tokens(sample_id):
    out = subprocess.run(["node", os.path.join(HERE, "tokenize_check.js"), "--json", "=" + sample_id],
                         capture_output=True, text=True, check=True).stdout
    return json.loads(out)[sample_id]


BRACKETS = [C["editorBracketHighlight.foreground%d" % i] for i in range(1, 7)]
PUNCT = {"#8693a1", "#b9a3f5"}   # punctuation and interpolation delimiters (not strings or comments)


def colourise_brackets(lines):
    """Approximates editor.bracketPairColorization (on by default): brackets take a colour per nesting level."""
    depth = 0
    out = []
    for line in lines:
        row = []
        for t in line:
            text = t["text"]
            if t["color"] in PUNCT and any(ch in "()[]{}" for ch in text) and not text.strip("()[]{} ,;:.$<>/=`"):
                for ch in text:
                    if ch in "([{":
                        row.append(dict(t, text=ch, color=BRACKETS[depth % 6]))
                        depth += 1
                    elif ch in ")]}":
                        depth = max(0, depth - 1)
                        row.append(dict(t, text=ch, color=BRACKETS[depth % 6]))
                    else:
                        row.append(dict(t, text=ch))
            else:
                row.append(t)
        out.append(row)
    return out


def draw_code(cv, x, y, lines, first_number=1, gutter=True, active=None, gutter_w=58, marks=None, brackets=True):
    """Lines of coloured tokens with line numbers. marks: {line_index: colour} git gutter bars."""
    if brackets:
        lines = colourise_brackets(lines)
    for i, line in enumerate(lines):
        yy = y + i * LH
        if gutter:
            n = str(first_number + i)
            col = C["editorLineNumber.activeForeground"] if i == active else C["editorLineNumber.foreground"]
            cv.text(x + gutter_w - 22 - F_CODE[""].getlength(n), yy + 1, n, col, F_CODE[""])
            if marks and i in marks:
                cv.rect(x + gutter_w - 12, yy, x + gutter_w - 9, yy + LH, fill=marks[i])
        xx = x + (gutter_w if gutter else 0)
        for t in line:
            t = dict(t, text=t["text"].replace("\t", "    "))
            style = " ".join(s for s in ("italic", "bold") if s in t["style"])
            f = F_CODE.get(style, F_CODE[""])
            cv.d.text((xx, yy + 1), t["text"], font=f, fill=rgba(t["color"]))
            w = CW * len(t["text"])
            if "underline" in t["style"]:
                cv.hline(xx, xx + w, yy + LH - 3, t["color"])
            if "strikethrough" in t["style"]:
                cv.hline(xx, xx + w, yy + LH // 2 + 1, t["color"])
            xx += w


def col_of(lines, li, needle, nth=0):
    text = "".join(t["text"] for t in lines[li])
    idx = -1
    for _ in range(nth + 1):
        idx = text.index(needle, idx + 1)
    return idx


# ===========================================================================
def workbench():
    W, H = 1600, 1000
    cv = Canvas(W, H, C["editor.background"])
    TB, SB, AB, SW = 36, 24, 48, 264
    PANEL_H = 250
    ex0 = AB + SW
    panel_y = H - SB - PANEL_H

    # ---- title bar
    cv.rect(0, 0, W, TB, fill=C["titleBar.activeBackground"])
    cv.hline(0, W, TB - 1, C["titleBar.border"])
    x = 14
    for label in ("File", "Edit", "Selection", "View", "Go", "Run", "Terminal", "Help"):
        if label == "View":
            cv.rect(x - 8, 6, x + F_UI.getlength(label) + 8, TB - 7, fill=C["menubar.selectionBackground"], radius=4)
        x = cv.text(x, 10, label, C["titleBar.activeForeground"]) + 18
    cw = 420
    cv.rect((W - cw) / 2, 7, (W + cw) / 2, TB - 7, fill=C["commandCenter.background"], outline=C["commandCenter.border"], radius=6)
    cv.text((W - F_UI.getlength("app")) / 2, 10, "app", C["commandCenter.foreground"])

    # ---- activity bar
    cv.rect(0, TB, AB, H - SB, fill=C["activityBar.background"])
    for i in range(6):
        cy = TB + 24 + i * 48
        active = i == 0
        col = C["activityBar.foreground"] if active else C["activityBar.inactiveForeground"]
        cv.rect(15, cy - 9, 33, cy + 9, outline=col, radius=4, width=2)
        if active:
            cv.rect(0, cy - 24, 2, cy + 24, fill=C["activityBar.activeBorder"])
        if i == 2:
            cv.rect(26, cy + 2, 42, cy + 18, fill=C["activityBarBadge.background"], radius=8)
            cv.text(31, cy + 3, "3", C["activityBarBadge.foreground"], F_UI_SB)

    # ---- side bar
    cv.rect(AB, TB, ex0, H - SB, fill=C["sideBar.background"])
    cv.vline(ex0 - 1, TB, H - SB, C["sideBar.border"])
    cv.text(AB + 20, TB + 11, "EXPLORER", C["sideBarTitle.foreground"], F_UI_S)
    y = TB + 36
    cv.hline(AB, ex0 - 1, y, C["sideBarSectionHeader.border"])
    cv.text(AB + 8, y + 5, "v", C["icon.foreground"], F_UI_S)
    cv.text(AB + 22, y + 4, "CHALEN", C["sideBarSectionHeader.foreground"], F_UI_SB)
    y += 24
    rows = [
        (0, "v", "apps", None, None, None),
        (1, "v", "web", None, None, None),
        (2, ">", "components", None, None, None),
        (2, "", "card.tsx", "M", "gitDecoration.modifiedResourceForeground", "active"),
        (2, "", "layout.tsx", None, None, "hover"),
        (2, "", "page.tsx", "U", "gitDecoration.untrackedResourceForeground", None),
        (2, "", "legacy.ts", "D", "gitDecoration.deletedResourceForeground", None),
        (2, "", "broken.ts", "2", "list.errorForeground", None),
        (1, ">", "api", None, None, None),
        (0, ">", "node_modules", None, "gitDecoration.ignoredResourceForeground", None),
        (0, "", "go.mod", None, None, "inactive"),
        (0, "", "docker-compose.yml", "R", "gitDecoration.renamedResourceForeground", None),
        (0, "", "schema.sql", "!", "gitDecoration.conflictingResourceForeground", None),
        (0, "", "README.md", None, None, None),
    ]
    for depth, twist, name, badge, colkey, state in rows:
        fg = C[colkey] if colkey else C["sideBar.foreground"]
        if state == "active":
            cv.rect(AB, y, ex0 - 1, y + 22, fill=C["list.activeSelectionBackground"], outline=C["list.focusAndSelectionOutline"])
            fg = C["list.activeSelectionForeground"]
        elif state == "inactive":
            cv.rect(AB, y, ex0 - 1, y + 22, fill=C["list.inactiveSelectionBackground"])
        elif state == "hover":
            cv.rect(AB, y, ex0 - 1, y + 22, fill=C["list.hoverBackground"])
        xx = AB + 10 + depth * 12
        if depth:
            for d in range(depth):
                cv.vline(AB + 15 + d * 12, y, y + 22, C["tree.inactiveIndentGuidesStroke"])
        if twist:
            cv.text(xx, y + 4, twist, C["icon.foreground"], F_UI_S)
        cv.text(xx + 14, y + 3, name, fg)
        if badge:
            cv.text(ex0 - 24, y + 3, badge, C[colkey] if state != "active" else C["list.activeSelectionForeground"])
        y += 22
    y += 14
    for title in ("OUTLINE", "TIMELINE"):
        cv.hline(AB, ex0 - 1, y, C["sideBarSectionHeader.border"])
        cv.text(AB + 8, y + 5, ">", C["icon.foreground"], F_UI_S)
        cv.text(AB + 22, y + 4, title, C["sideBarSectionHeader.foreground"], F_UI_SB)
        y += 24
    cv.hline(AB, ex0 - 1, y, C["sideBarSectionHeader.border"])

    # ---- tabs
    ty = TB
    cv.rect(ex0, ty, W, ty + 36, fill=C["editorGroupHeader.tabsBackground"])
    cv.hline(ex0, W, ty + 35, C["editorGroupHeader.tabsBorder"])
    x = ex0
    for name, state, dirty in (("card.tsx", "active", True), ("layout.tsx", "inactive", False), ("server.go", "hover", False), ("main.py", "inactive", False)):
        w = int(F_UI.getlength(name)) + 62
        if state == "active":
            cv.rect(x, ty, x + w, ty + 36, fill=C["tab.activeBackground"])
            cv.rect(x, ty, x + w, ty + 1, fill=C["tab.activeBorderTop"])
            fg = C["tab.activeForeground"]
        elif state == "hover":
            cv.rect(x, ty, x + w, ty + 35, fill=C["tab.hoverBackground"])
            fg = C["tab.hoverForeground"]
        else:
            fg = C["tab.inactiveForeground"]
        cv.text(x + 14, ty + 10, name, fg)
        if dirty:
            cv.rect(x + w - 26, ty + 14, x + w - 18, ty + 22, fill=fg, radius=4)
        else:
            cv.text(x + w - 27, ty + 9, "x", fg if state != "inactive" else C["tab.inactiveForeground"], F_UI_S)
        x += w

    # ---- breadcrumbs
    by = ty + 36
    cv.rect(ex0, by, W, by + 24, fill=C["breadcrumb.background"])
    x = ex0 + 18
    for i, part in enumerate(("apps", "web", "components", "card.tsx", "Card")):
        last = i == 4
        x = cv.text(x, by + 4, part, C["breadcrumb.focusForeground"] if last else C["breadcrumb.foreground"])
        if not last:
            x = cv.text(x + 6, by + 4, ">", C["breadcrumb.foreground"], F_UI_S) + 6

    # ---- editor
    ey = by + 26
    lines = tokens("tsx")
    gx = ex0
    code_x = gx + 58
    active = 5
    # current line
    cv.rect(gx, ey + active * LH, W - 14, ey + (active + 1) * LH, fill=C["editor.lineHighlightBackground"])
    # indent guides
    for i, line in enumerate(lines):
        text = "".join(t["text"] for t in line)
        indent = len(text) - len(text.lstrip(" "))
        for lvl in range(0, indent // 2):
            cv.vline(code_x + lvl * 2 * CW, ey + i * LH, ey + (i + 1) * LH, C["editorIndentGuide.background1"])
    # word highlights for "open"
    for li, nth in ((5, 0), (7, 0), (7, 1), (10, 0)):
        try:
            c0 = col_of(lines, li, "open", nth)
        except ValueError:
            continue
        cv.rect(code_x + c0 * CW, ey + li * LH, code_x + (c0 + 4) * CW, ey + (li + 1) * LH, fill=C["editor.wordHighlightBackground"])
    # selection: lines 8..9
    for li in (8, 9):
        text = "".join(t["text"] for t in lines[li])
        c0 = len(text) - len(text.lstrip(" "))
        cv.rect(code_x + c0 * CW, ey + li * LH, code_x + len(text) * CW + (CW if li == 8 else 0), ey + (li + 1) * LH, fill=C["editor.selectionBackground"])
    # find matches for "title": current on line 4, others elsewhere
    seen = 0
    for li, line in enumerate(lines):
        text = "".join(t["text"] for t in line)
        start = 0
        while True:
            idx = text.find("title", start)
            if idx < 0:
                break
            cur = seen == 1
            cv.rect(code_x + idx * CW, ey + li * LH, code_x + (idx + 5) * CW, ey + (li + 1) * LH,
                    fill=C["editor.findMatchBackground"] if cur else C["editor.findMatchHighlightBackground"],
                    outline=C["editor.findMatchBorder"] if cur else None)
            seen += 1
            start = idx + 5
    # bracket match on line 5
    for needle in ("(", ")"):
        text = "".join(t["text"] for t in lines[5])
        idx = text.index("(false") if needle == "(" else text.index(")", text.index("(false"))
        cv.rect(code_x + idx * CW, ey + 5 * LH, code_x + (idx + 1) * CW, ey + 6 * LH, fill=C["editorBracketMatch.background"], outline=C["editorBracketMatch.border"])
    draw_code(cv, gx, ey, lines, active=active,
              marks={3: C["editorGutter.modifiedBackground"], 9: C["editorGutter.addedBackground"], 10: C["editorGutter.addedBackground"]})
    # cursor
    cend = len("".join(t["text"] for t in lines[active]))
    cv.rect(code_x + cend * CW, ey + active * LH + 1, code_x + cend * CW + 2, ey + (active + 1) * LH - 1, fill=C["editorCursor.foreground"])
    # squiggles: error under Panel.Body, warning under prefetch
    for li, needle, key in ((10, "Panel.Body", "editorError.foreground"), (9, "prefetch", "editorWarning.foreground")):
        c0 = col_of(lines, li, needle)
        xx = code_x + c0 * CW
        for k in range(int(len(needle) * CW // 4)):
            cv.rect(xx + k * 4, ey + (li + 1) * LH - 3 + (k % 2), xx + k * 4 + 3, ey + (li + 1) * LH - 2 + (k % 2), fill=C[key])
    # inlay hint + code lens style text after line 5
    hx = code_x + (cend + 2) * CW
    label = "useState<boolean>"
    cv.rect(hx - 4, ey + active * LH + 2, hx + F_CODE[""].getlength(label) * 0.9 + 6, ey + (active + 1) * LH - 2, fill=C["editorInlayHint.background"], radius=3)
    cv.d.text((hx, ey + active * LH + 2), label, font=font(MONO % "Regular", 12), fill=rgba(C["editorInlayHint.foreground"]))
    # ghost text on an empty area
    gy = ey + len(lines) * LH
    cv.d.text((code_x, gy + 1), "export function useCard() {", font=F_CODE[""], fill=rgba(C["editorGhostText.foreground"]))
    cv.text(code_x - 58 + 58 - 22 - F_CODE[""].getlength(str(len(lines) + 1)), gy + 1, str(len(lines) + 1), C["editorLineNumber.foreground"], F_CODE[""])

    # suggest widget
    sx, sy = code_x + 22 * CW, ey + 6 * LH + 2
    sw, rowh = 430, 22
    items = [("useState", "function", "symbolIcon.functionForeground", "react"), ("useStore", "function", "symbolIcon.functionForeground", "zustand"),
             ("User", "interface", "symbolIcon.interfaceForeground", "types"), ("username", "property", "symbolIcon.propertyForeground", "string"),
             ("USER_ROLE", "constant", "symbolIcon.constantForeground", "Role"), ("useMemo", "function", "symbolIcon.functionForeground", "react")]
    sh = rowh * len(items) + 2
    cv.shadow(sx, sy, sx + sw, sy + sh)
    cv.rect(sx, sy, sx + sw, sy + sh, fill=C["editorSuggestWidget.background"], outline=C["editorSuggestWidget.border"], radius=4)
    for i, (label, kind, icon, detail) in enumerate(items):
        ry = sy + 1 + i * rowh
        sel = i == 0
        if sel:
            cv.rect(sx + 1, ry, sx + sw - 1, ry + rowh, fill=C["editorSuggestWidget.selectedBackground"])
        cv.rect(sx + 9, ry + 5, sx + 21, ry + 17, outline=C[icon], radius=3, width=2)
        hl = C["editorSuggestWidget.focusHighlightForeground"] if sel else C["editorSuggestWidget.highlightForeground"]
        fg = C["editorSuggestWidget.selectedForeground"] if sel else C["editorSuggestWidget.foreground"]
        cv.d.text((sx + 30, ry + 2), label[:3], font=F_CODE[""], fill=rgba(hl))
        cv.d.text((sx + 30 + CW * 3, ry + 2), label[3:], font=F_CODE[""], fill=rgba(fg))
        cv.text(sx + sw - 10 - F_UI_S.getlength(detail), ry + 5, detail, C["editorSuggestWidgetStatus.foreground"], F_UI_S)

    # scrollbar thumb + overview ruler marks
    cv.rect(W - 12, ey + 30, W - 2, ey + 190, fill=C["scrollbarSlider.background"])
    for yy, key in ((ey + 60, "editorOverviewRuler.errorForeground"), (ey + 96, "editorOverviewRuler.warningForeground"), (ey + 130, "editorOverviewRuler.findMatchForeground"), (ey + 150, "editorOverviewRuler.addedForeground")):
        cv.rect(W - 8, yy, W - 3, yy + 4, fill=C[key])

    # ---- panel
    cv.rect(ex0, panel_y, W, H - SB, fill=C["panel.background"])
    cv.hline(ex0, W, panel_y, C["panel.border"])
    x = ex0 + 20
    for name, act in (("PROBLEMS", False), ("OUTPUT", False), ("DEBUG CONSOLE", False), ("TERMINAL", True), ("PORTS", False)):
        w = F_UI_S.getlength(name)
        cv.text(x, panel_y + 11, name, C["panelTitle.activeForeground"] if act else C["panelTitle.inactiveForeground"], F_UI_S)
        if act:
            cv.rect(x, panel_y + 33, x + w, panel_y + 34, fill=C["panelTitle.activeBorder"])
        if name == "PROBLEMS":
            cv.rect(x + w + 6, panel_y + 9, x + w + 24, panel_y + 26, fill=C["panelTitleBadge.background"], radius=8)
            cv.text(x + w + 12, panel_y + 11, "2", C["panelTitleBadge.foreground"], F_UI_S)
            w += 24
        x += w + 26
    cv.hline(ex0, W, panel_y + 35, C["panelTitle.border"])
    ty0 = panel_y + 36
    cv.rect(ex0, ty0, W, H - SB, fill=C["terminal.background"])
    A = lambda n: C["terminal.ansi" + n]  # noqa: E731
    tl = [
        [("you", A("Cyan")), (" in ", C["terminal.foreground"]), ("~/Projects/app", A("Blue")), (" on ", C["terminal.foreground"]), (" main", A("Magenta")), (" [!?]", A("Red")), (" via ", C["terminal.foreground"]), ("go v1.26.6", A("Cyan"))],
        [("> ", A("Green")), ("go test ./... -run TestRoutes -v", C["terminal.foreground"])],
        [("=== RUN   TestRoutes", C["terminal.foreground"])],
        [("--- PASS: TestRoutes (0.02s)", A("Green"))],
        [("ok  ", A("Green")), ("    app/internal/server    0.412s", C["terminal.foreground"]), ("  coverage: 81.4% of statements", A("BrightBlack"))],
        [("> ", A("Green")), ("git status --short", C["terminal.foreground"])],
        [(" M ", A("Yellow")), ("apps/web/components/card.tsx", C["terminal.foreground"]), ("   ?? ", A("Red")), ("apps/web/page.tsx", C["terminal.foreground"])],
        [("warning: ", A("BrightYellow")), ("LF will be replaced by CRLF", C["terminal.foreground"]), ("   error: ", A("BrightRed")), ("exit status 1", C["terminal.foreground"])],
        [(n + " ", A(n)) for n in ("Black", "Red", "Green", "Yellow", "Blue", "Magenta", "Cyan", "White")],
        [("Bright" + n + " ", A("Bright" + n)) for n in ("Black", "Red", "Green", "Yellow", "Blue", "Magenta", "Cyan", "White")][:6],
    ]
    for i, line in enumerate(tl):
        xx = ex0 + 20
        for s, col in line:
            cv.d.text((xx, ty0 + 8 + i * 20), s, font=F_CODE[""], fill=rgba(col))
            xx += CW * len(s.expandtabs(4))
    cv.rect(ex0 + 20 + 2 * CW, ty0 + 8 + 10 * 20, ex0 + 20 + 3 * CW, ty0 + 8 + 11 * 20 - 2, fill=C["terminalCursor.foreground"])
    cv.d.text((ex0 + 20, ty0 + 8 + 10 * 20), "> ", font=F_CODE[""], fill=rgba(A("Green")))

    # ---- status bar
    sy0 = H - SB
    cv.rect(0, sy0, W, H, fill=C["statusBar.background"])
    cv.hline(0, W, sy0, C["statusBar.border"])
    cv.rect(0, sy0, 78, H, fill=C["statusBarItem.remoteBackground"])
    cv.text(10, sy0 + 5, "WSL: dev", C["statusBarItem.remoteForeground"], F_UI_S)
    x = 92
    for s in ("main*", "0 errors  2 warnings", "Go 1.26.6"):
        x = cv.text(x, sy0 + 5, s, C["statusBar.foreground"], F_UI_S) + 22
    cv.rect(x - 8, sy0 + 1, x + 96, H, fill=C["statusBarItem.hoverBackground"])
    cv.text(x, sy0 + 5, "hovered item", C["statusBarItem.hoverForeground"], F_UI_S)
    x = W - 14
    for s, kind in (("Prettier", None), ("TypeScript JSX", None), ("UTF-8", None), ("Spaces: 2", None), ("Ln 6, Col 52", None), ("lint failed", "warning"), ("tsserver", "error")):
        w = F_UI_S.getlength(s)
        x -= w
        if kind:
            cv.rect(x - 8, sy0 + 1, x + w + 8, H, fill=C["statusBarItem.%sBackground" % kind])
            cv.text(x, sy0 + 5, s, C["statusBarItem.%sForeground" % kind], F_UI_S)
        else:
            cv.text(x, sy0 + 5, s, C["statusBar.foreground"], F_UI_S)
        x -= 22
    cv.im.convert("RGB").save(os.path.join(HERE, "preview-workbench.png"))


# ===========================================================================
def widgets():
    W, H = 1600, 1000
    cv = Canvas(W, H, C["editor.background"])
    cv.rect(0, 0, 420, H, fill=C["sideBar.background"])
    cv.vline(419, 0, H, C["sideBar.border"])

    # --- left column: on the side bar surface
    x, y = 24, 20
    cv.text(x, y, "SEARCH", C["sideBarTitle.foreground"], F_UI_S)
    y += 26
    cv.rect(x, y, 396, y + 28, fill=C["input.background"], outline=C["focusBorder"], radius=4)
    cv.text(x + 8, y + 6, "useState", C["input.foreground"])
    cv.rect(350, y + 4, 370, y + 24, fill=C["inputOption.activeBackground"], outline=C["inputOption.activeBorder"], radius=3)
    cv.text(354, y + 6, "Aa", C["inputOption.activeForeground"], F_UI_S)
    cv.text(376, y + 6, ".*", C["icon.foreground"], F_UI_S)
    y += 36
    cv.rect(x, y, 396, y + 28, fill=C["input.background"], outline=C["input.border"], radius=4)
    cv.text(x + 8, y + 6, "Replace", C["input.placeholderForeground"])
    y += 36
    cv.rect(x, y, 396, y + 28, fill=C["input.background"], outline=C["inputValidation.errorBorder"], radius=4)
    cv.text(x + 8, y + 6, "[unclosed", C["input.foreground"])
    cv.rect(x, y + 28, 396, y + 54, fill=C["inputValidation.errorBackground"], outline=C["inputValidation.errorBorder"])
    cv.text(x + 8, y + 33, "Invalid regular expression: missing ]", C["inputValidation.errorForeground"], F_UI_S)
    y += 70
    cv.text(x, y, "12 results in 4 files", C["search.resultsInfoForeground"], F_UI_S)
    y += 24
    for name, count, state in (("card.tsx", "5", None), ("layout.tsx", "3", "active"), ("page.tsx", "2", "inactive"), ("hooks.ts", "2", "hover")):
        if state == "active":
            cv.rect(0, y, 419, y + 22, fill=C["list.activeSelectionBackground"], outline=C["list.focusAndSelectionOutline"])
        elif state == "inactive":
            cv.rect(0, y, 419, y + 22, fill=C["list.inactiveSelectionBackground"])
        elif state == "hover":
            cv.rect(0, y, 419, y + 22, fill=C["list.hoverBackground"])
        fg = C["list.activeSelectionForeground"] if state == "active" else C["sideBar.foreground"]
        cv.text(x + 14, y + 3, name, fg)
        xx = x + 14 + F_UI.getlength(name) + 10
        cv.text(xx, y + 4, "apps/web/components", C["descriptionForeground"], F_UI_S)
        cv.rect(372, y + 3, 396, y + 19, fill=C["badge.background"], radius=8)
        cv.text(381, y + 4, count, C["badge.foreground"], F_UI_S)
        y += 22
        if state is None:
            xx = cv.text(x + 30, y + 3, "const [open, setOpen] = ", C["sideBar.foreground"])
            w = F_UI.getlength("useState")
            cv.rect(xx, y + 1, xx + w, y + 21, fill=C["list.filterMatchBackground"])
            xx = cv.text(xx, y + 3, "useState", C["sideBar.foreground"])
            cv.text(xx, y + 3, "<boolean>(false)", C["sideBar.foreground"])
            y += 22
    y += 24
    cv.text(x, y, "CONTROLS", C["sideBarTitle.foreground"], F_UI_S)
    y += 26
    cv.rect(x, y, x + 110, y + 28, fill=C["button.background"], radius=4)
    cv.text(x + 22, y + 6, "Commit", C["button.foreground"], F_UI_B)
    cv.rect(x + 122, y, x + 232, y + 28, fill=C["button.hoverBackground"], radius=4)
    cv.text(x + 144, y + 6, "Hover", C["button.foreground"], F_UI_B)
    cv.rect(x + 244, y, x + 372, y + 28, fill=C["button.secondaryBackground"], outline=C["button.secondaryBorder"], radius=4)
    cv.text(x + 268, y + 6, "Secondary", C["button.secondaryForeground"])
    y += 42
    cv.rect(x, y, x + 18, y + 18, fill=C["checkbox.background"], outline=C["checkbox.border"], radius=3)
    cv.d.line([(x + 4, y + 9), (x + 8, y + 13), (x + 14, y + 5)], fill=rgba(C["checkbox.foreground"]), width=2)
    cv.text(x + 28, y + 1, "Format on save", C["foreground"])
    cv.rect(x + 170, y, x + 188, y + 18, fill=C["checkbox.background"], outline=C["checkbox.border"], radius=3)
    cv.text(x + 198, y + 1, "Word wrap", C["foreground"])
    y += 32
    cv.rect(x, y, x + 200, y + 28, fill=C["dropdown.background"], outline=C["dropdown.border"], radius=4)
    cv.text(x + 8, y + 6, "JetBrains Mono", C["dropdown.foreground"])
    cv.text(x + 180, y + 7, "v", C["icon.foreground"], F_UI_S)
    cv.text(x + 216, y + 6, "disabled text", C["disabledForeground"])
    y += 44
    xx = x
    for label, key in (("A", "added"), ("M", "modified"), ("D", "deleted"), ("R", "renamed"), ("U", "untracked"), ("!", "conflicting"), ("S", "submodule"), ("I", "ignored")):
        xx = cv.text(xx, y, "%s %s" % (label, key), C["gitDecoration.%sResourceForeground" % key], F_UI_S) + 12
        if xx > 360:
            xx, y = x, y + 20
    y += 34
    cv.rect(x, y, x + 70, y + 20, fill=C["keybindingLabel.background"], outline=C["keybindingLabel.border"], radius=3)
    cv.text(x + 8, y + 3, "Ctrl+P", C["keybindingLabel.foreground"], F_UI_S)
    cv.text(x + 84, y + 3, "link text", C["textLink.foreground"])
    cv.rect(x + 160, y, x + 232, y + 20, fill=C["textPreformat.background"], radius=3)
    cv.d.text((x + 166, y + 1), "pnpm dev", font=font(MONO % "Regular", 12), fill=rgba(C["textPreformat.foreground"]))
    y += 40
    # progress + scm graph lanes
    cv.rect(x, y, 396, y + 2, fill=C["progressBar.background"])
    y += 16
    for i, key in enumerate(("historyItemRefColor", "historyItemRemoteRefColor", "historyItemBaseRefColor", "foreground1", "foreground2", "foreground3", "foreground4", "foreground5")):
        cv.rect(x + i * 46, y, x + i * 46 + 34, y + 16, fill=C["scmGraph." + key], radius=8)
    y += 30
    for i, key in enumerate(("red", "orange", "yellow", "green", "blue", "purple")):
        cv.rect(x + i * 46, y, x + i * 46 + 34, y + 16, fill=C["charts." + key], radius=3)
    y += 30
    for i in range(1, 7):
        cv.d.text((x + (i - 1) * 46, y), "{[()]}"[i - 1] * 3, font=F_CODE[""], fill=rgba(C["editorBracketHighlight.foreground%d" % i]))

    # --- command palette
    qx, qy, qw = 520, 28, 620
    rows = [("Preferences: Color Theme", "Ctrl+K Ctrl+T", "recently used"), ("Preferences: Open User Settings (JSON)", "", ""),
            ("Developer: Reload Window", "", "other commands"), ("Format Document", "Ctrl+Shift+I", ""), ("Git: Commit", "", "")]
    qh = 46 + len(rows) * 24 + 6
    cv.shadow(qx, qy, qx + qw, qy + qh)
    cv.rect(qx, qy, qx + qw, qy + qh, fill=C["quickInput.background"], outline=C["widget.border"], radius=6)
    cv.rect(qx + 8, qy + 8, qx + qw - 8, qy + 36, fill=C["input.background"], outline=C["focusBorder"], radius=4)
    cv.text(qx + 16, qy + 14, ">theme", C["input.foreground"])
    for i, (label, kb, group) in enumerate(rows):
        ry = qy + 44 + i * 24
        focus = i == 0
        if focus:
            cv.rect(qx + 6, ry, qx + qw - 6, ry + 24, fill=C["quickInputList.focusBackground"], radius=3)
        if group and i:
            cv.hline(qx + 6, qx + qw - 6, ry, C["pickerGroup.border"])
        fg = C["quickInputList.focusForeground"] if focus else C["quickInput.foreground"]
        hl = C["quickInputList.focusHighlightForeground"] if focus else C["list.highlightForeground"]
        k = label.find("Theme")
        xx = qx + 16
        if k >= 0:
            xx = cv.text(xx, ry + 4, label[:k], fg)
            xx = cv.text(xx, ry + 4, "Theme", hl, F_UI_B)
            cv.text(xx, ry + 4, label[k + 5:], fg)
        else:
            cv.text(xx, ry + 4, label, fg)
        rx = qx + qw - 16
        if group:
            rx -= F_UI_S.getlength(group)
            cv.text(rx, ry + 5, group, C["pickerGroup.foreground"], F_UI_S)
            rx -= 12
        if kb:
            w = F_UI_S.getlength(kb) + 12
            cv.rect(rx - w, ry + 3, rx, ry + 21, fill=C["keybindingLabel.background"], outline=C["keybindingLabel.border"], radius=3)
            cv.text(rx - w + 6, ry + 5, kb, C["keybindingLabel.foreground"], F_UI_S)

    # --- context menu
    mx, my, mw = 1200, 28, 250
    entries = ["Go to Definition", "Go to References", "Peek", None, "Rename Symbol", "Change All Occurrences", "Format Document", None, "Cut", "Copy", "Paste"]
    mh = sum(9 if e is None else 26 for e in entries) + 8
    cv.shadow(mx, my, mx + mw, my + mh)
    cv.rect(mx, my, mx + mw, my + mh, fill=C["menu.background"], outline=C["menu.border"], radius=6)
    yy = my + 4
    for i, e in enumerate(entries):
        if e is None:
            cv.hline(mx + 1, mx + mw - 1, yy + 4, C["menu.separatorBackground"])
            yy += 9
            continue
        sel = e == "Rename Symbol"
        if sel:
            cv.rect(mx + 4, yy, mx + mw - 4, yy + 26, fill=C["menu.selectionBackground"], radius=4)
        fg = C["menu.selectionForeground"] if sel else (C["disabledForeground"] if e == "Paste" else C["menu.foreground"])
        cv.text(mx + 26, yy + 5, e, fg)
        if e in ("Rename Symbol", "Go to Definition"):
            cv.text(mx + mw - 34, yy + 6, "F2" if sel else "F12", fg if sel else C["descriptionForeground"], F_UI_S)
        yy += 26

    # --- hover widget
    hx, hy, hw, hh = 520, 250, 520, 112
    cv.shadow(hx, hy, hx + hw, hy + hh)
    cv.rect(hx, hy, hx + hw, hy + hh, fill=C["editorHoverWidget.background"], outline=C["editorHoverWidget.border"], radius=4)
    sig = [("(alias) ", "#8693a1"), ("function ", "#b9a3f5"), ("useState", "#7cb7ff"), ("<", "#8693a1"), ("boolean", "#4fd1c5"), (">(", "#8693a1"), ("initialState", "#dce3ea"), (": ", "#8693a1"), ("boolean", "#4fd1c5"), (")", "#8693a1")]
    xx = hx + 12
    for s, col in sig:
        cv.d.text((xx, hy + 10), s, font=F_CODE["italic"] if s == "initialState" else F_CODE[""], fill=rgba(col))
        xx += CW * len(s)
    cv.hline(hx + 1, hx + hw - 1, hy + 38, C["editorHoverWidget.border"])
    xx = cv.text(hx + 12, hy + 48, "Returns a stateful value, and a function to update it. See ", C["editorHoverWidget.foreground"])
    cv.text(xx, hy + 48, "the docs", C["textLink.foreground"])
    cv.rect(hx + 1, hy + hh - 30, hx + hw - 1, hy + hh - 1, fill=C["editorHoverWidget.statusBarBackground"])
    xx = cv.text(hx + 12, hy + hh - 24, "View Problem (Alt+F8)", C["textLink.foreground"], F_UI_S) + 18
    cv.text(xx, hy + hh - 24, "Quick Fix... (Ctrl+.)", C["textLink.foreground"], F_UI_S)

    # --- notification
    nx, ny, nw, nh = 1090, 250, 460, 104
    cv.shadow(nx, ny, nx + nw, ny + nh)
    cv.rect(nx, ny, nx + nw, ny + nh, fill=C["notifications.background"], outline=C["notificationToast.border"], radius=6)
    cv.rect(nx + 14, ny + 15, nx + 30, ny + 31, outline=C["notificationsWarningIcon.foreground"], radius=8, width=2)
    cv.text(nx + 42, ny + 14, "The Go extension needs gopls to be installed.", C["notifications.foreground"])
    cv.text(nx + 42, ny + 36, "Source: Go", C["descriptionForeground"], F_UI_S)
    cv.rect(nx + nw - 204, ny + 62, nx + nw - 112, ny + 90, fill=C["button.secondaryBackground"], outline=C["button.secondaryBorder"], radius=4)
    cv.text(nx + nw - 186, ny + 68, "Not Now", C["button.secondaryForeground"])
    cv.rect(nx + nw - 102, ny + 62, nx + nw - 14, ny + 90, fill=C["button.background"], radius=4)
    cv.text(nx + nw - 82, ny + 68, "Install", C["button.foreground"], F_UI_B)

    # --- diff editor (go sample lines)
    go = tokens("go")
    dy = 400
    cv.text(470, dy - 26, "DIFF EDITOR", C["descriptionForeground"], F_UI_S)
    left = go[32:38]
    right = go[32:38]
    half = (W - 440) // 2
    lx, rx_ = 440, 440 + half
    cv.vline(rx_ - 1, dy, dy + 6 * LH, C["diffEditor.border"])
    for i in (1, 2):
        cv.rect(lx, dy + i * LH, rx_ - 1, dy + (i + 1) * LH, fill=C["diffEditor.removedLineBackground"])
        cv.rect(lx, dy + i * LH, lx + 46, dy + (i + 1) * LH, fill=C["diffEditorGutter.removedLineBackground"])
        cv.rect(rx_, dy + i * LH, W, dy + (i + 1) * LH, fill=C["diffEditor.insertedLineBackground"])
        cv.rect(rx_, dy + i * LH, rx_ + 46, dy + (i + 1) * LH, fill=C["diffEditorGutter.insertedLineBackground"])
    text1 = "".join(t["text"] for t in left[1])
    c0 = len(text1) - len(text1.lstrip())
    cv.rect(lx + 58 + c0 * CW, dy + LH, lx + 58 + (c0 + 10) * CW, dy + 2 * LH, fill=C["diffEditor.removedTextBackground"])
    cv.rect(rx_ + 58 + c0 * CW, dy + LH, rx_ + 58 + (c0 + 10) * CW, dy + 2 * LH, fill=C["diffEditor.insertedTextBackground"])
    draw_code(cv, lx, dy, left, first_number=33)
    draw_code(cv, rx_, dy, right, first_number=33)

    # --- peek view (python sample)
    py = tokens("python")
    py0 = dy + 6 * LH + 40
    cv.text(470, py0 - 26, "PEEK VIEW", C["descriptionForeground"], F_UI_S)
    cv.hline(440, W, py0, C["peekView.border"])
    cv.rect(440, py0 + 1, W, py0 + 27, fill=C["peekViewTitle.background"])
    xx = cv.text(456, py0 + 6, "models.py", C["peekViewTitleLabel.foreground"], F_UI_B) + 10
    cv.text(xx, py0 + 7, "app/models  -  3 references", C["peekViewTitleDescription.foreground"], F_UI_S)
    body_y = py0 + 27
    body_h = 8 * LH
    cv.rect(440, body_y, W - 300, body_y + body_h, fill=C["peekViewEditor.background"])
    cv.rect(W - 300, body_y, W, body_y + body_h, fill=C["peekViewResult.background"])
    cv.vline(W - 301, body_y, body_y + body_h, C["peekView.border"])
    seg = py[9:17]
    t = "".join(tk["text"] for tk in seg[1])
    c0 = t.index("Item")
    cv.rect(440 + 58 + c0 * CW, body_y + LH, 440 + 58 + (c0 + 4) * CW, body_y + 2 * LH, fill=C["peekViewEditor.matchHighlightBackground"])
    draw_code(cv, 440, body_y, seg, first_number=10)
    ry = body_y + 6
    for name, state in (("models.py", "file"), ("class Item(BaseModel):", "sel"), ("def parse(cls) -> Item:", None), ("routes.py", "file"), ("item = Item.parse(raw)", None)):
        if state == "sel":
            cv.rect(W - 300, ry, W, ry + 22, fill=C["peekViewResult.selectionBackground"])
        fg = C["peekViewResult.fileForeground"] if state == "file" else (C["peekViewResult.selectionForeground"] if state == "sel" else C["peekViewResult.lineForeground"])
        cv.text(W - 284 + (0 if state == "file" else 14), ry + 3, name, fg, F_UI_B if state == "file" else F_UI)
        ry += 22
    cv.hline(440, W, body_y + body_h, C["peekView.border"])

    # --- markdown + yaml + css sample strip
    sy = body_y + body_h + 44
    cv.text(470, sy - 26, "MARKDOWN  /  YAML  /  CSS", C["descriptionForeground"], F_UI_S)
    md = tokens("markdown")
    ym = tokens("yaml")
    css = tokens("css")
    draw_code(cv, 440, sy, md[0:9] + md[12:16], first_number=1)
    draw_code(cv, 440 + 420, sy, ym[0:13], first_number=1, gutter_w=46)
    draw_code(cv, 440 + 760, sy, [l[:] for l in css[1:13]], first_number=2, gutter_w=46)
    cv.im.convert("RGB").save(os.path.join(HERE, "preview-widgets.png"))


# ===========================================================================
def modern():
    """VS Code 1.14x Modern UI (workbench.experimental.modernUI, on by default): floating cards, connected tabs."""
    W, H = 1600, 1000
    cv = Canvas(W, H, C["modernUI.shellBackground"])
    TB, SB, G, R = 36, 24, 4, 8
    top, bottom = TB + G, H - SB - G
    PANEL_H = 250

    # title bar and status bar sit on the shell
    cv.rect(0, 0, W, TB, fill=C["titleBar.activeBackground"])
    cv.hline(0, W, TB - 1, C["titleBar.border"])
    x = 14
    for label in ("File", "Edit", "Selection", "View", "Go", "Run", "Terminal", "Help"):
        x = cv.text(x, 10, label, C["titleBar.activeForeground"]) + 18
    cw = 420
    cv.rect((W - cw) / 2, 7, (W + cw) / 2, TB - 7, fill=C["commandCenter.background"], outline=C["commandCenter.border"], radius=6)
    cv.text((W - F_UI.getlength("app")) / 2, 10, "app", C["commandCenter.foreground"])
    cv.rect(0, H - SB, W, H, fill=C["statusBar.background"])
    cv.hline(0, W, H - SB, C["statusBar.border"])
    cv.rect(0, H - SB + 1, 78, H, fill=C["statusBarItem.remoteBackground"])
    cv.text(10, H - SB + 5, "WSL: dev", C["statusBarItem.remoteForeground"], F_UI_S)
    x = 92
    for s_ in ("main*", "0 errors  2 warnings", "Go 1.26.6"):
        x = cv.text(x, H - SB + 5, s_, C["statusBar.foreground"], F_UI_S) + 22
    x = W - 14
    for s_ in ("Prettier", "TypeScript JSX", "UTF-8", "Spaces: 2", "Ln 6, Col 52"):
        x -= F_UI_S.getlength(s_)
        cv.text(x, H - SB + 5, s_, C["statusBar.foreground"], F_UI_S)
        x -= 22

    # activity bar + side bar: one card with a seam
    ax0, ax1, sx1 = G, G + 48, G + 48 + 264
    cv.rect(ax0, top, sx1, bottom, fill=C["surface.background"], outline=C["surface.border"], radius=R)
    cv.rect(ax0, top, ax1 + R, bottom, fill=C["modernActivityBar.background"], outline=C["modernActivityBar.border"], radius=R)
    cv.rect(ax1, top + 1, ax1 + R + 1, bottom - 1, fill=C["surface.background"])
    cv.hline(ax1, ax1 + R + 1, top, C["surface.border"])
    cv.hline(ax1, ax1 + R + 1, bottom - 1, C["surface.border"])
    for i in range(6):
        cy = top + 30 + i * 44
        active, hover = i == 0, i == 3
        if active:
            cv.rect(ax0 + 8, cy - 16, ax1 - 8, cy + 16, fill=C["modernActivityBarItem.activeBackground"], radius=6)
        elif hover:
            cv.rect(ax0 + 8, cy - 16, ax1 - 8, cy + 16, fill=C["modernActivityBarItem.hoverBackground"], radius=6)
        col = C["modernActivityBarItem.activeForeground"] if active else (C["modernActivityBarItem.hoverForeground"] if hover else C["activityBar.inactiveForeground"])
        cv.rect(ax0 + 16, cy - 8, ax0 + 32, cy + 8, outline=col, radius=4, width=2)
        if i == 2:
            cv.rect(ax0 + 27, cy + 1, ax0 + 43, cy + 17, fill=C["activityBarBadge.background"], radius=8)
            cv.text(ax0 + 32, cy + 2, "3", C["activityBarBadge.foreground"], F_UI_SB)
    cv.text(ax1 + 18, top + 12, "EXPLORER", C["sideBarTitle.foreground"], F_UI_S)
    y = top + 38
    rows = [(0, "v", "apps", None, None, None), (1, "v", "web", None, None, None), (2, ">", "components", None, None, None),
            (2, "", "card.tsx", "M", "gitDecoration.modifiedResourceForeground", "inactive"), (2, "", "layout.tsx", None, None, "hover"),
            (2, "", "page.tsx", "U", "gitDecoration.untrackedResourceForeground", None), (2, "", "legacy.ts", "D", "gitDecoration.deletedResourceForeground", None),
            (1, ">", "api", None, None, None), (0, ">", "node_modules", None, "gitDecoration.ignoredResourceForeground", None),
            (0, "", "go.mod", None, None, None), (0, "", "README.md", None, None, None)]
    for depth, twist, name, badge, colkey, state in rows:
        fg = C[colkey] if colkey else C["surface.foreground"]
        if state == "inactive":
            cv.rect(ax1 + 6, y, sx1 - 6, y + 22, fill=C["list.inactiveSelectionBackground"], radius=4)
        elif state == "hover":
            cv.rect(ax1 + 6, y, sx1 - 6, y + 22, fill=C["list.hoverBackground"], radius=4)
        xx = ax1 + 14 + depth * 12
        if twist:
            cv.text(xx, y + 4, twist, C["icon.foreground"], F_UI_S)
        cv.text(xx + 14, y + 3, name, fg)
        if badge:
            cv.text(sx1 - 26, y + 3, badge, C[colkey])
        y += 22

    # editor card with connected tabs
    ex0, ex1 = sx1 + G, W - G
    panel_y = bottom - PANEL_H
    ey1 = panel_y - G
    cv.rect(ex0, top, ex1, ey1, fill=C["editor.background"], outline=C["editor.border"], radius=R)
    strip_h = 36
    cv.rect(ex0 + 1, top + 1, ex1 - 1, top + strip_h, fill=C["editorGroupHeader.connectedTabsBackground"], radius=R - 1)
    cv.rect(ex0 + 1, top + strip_h - R, ex1 - 1, top + strip_h, fill=C["editorGroupHeader.connectedTabsBackground"])
    cv.hline(ex0 + 1, ex1 - 1, top + strip_h, C["editorGroupHeader.tabsBorder"])
    x = ex0 + 8
    for name, state in (("card.tsx", "active"), ("layout.tsx", "inactive"), ("server.go", "hover"), ("main.py", "inactive")):
        w = int(F_UI.getlength(name)) + 58
        if state == "active":
            cv.rect(x, top + 5, x + w, top + strip_h + 8, fill=C["editor.background"], outline=C["editorGroupHeader.tabsBorder"], radius=6)
            cv.rect(x + 1, top + strip_h, x + w - 1, top + strip_h + 9, fill=C["editor.background"])
            fg = C["modernEditorTab.activeForeground"]
        elif state == "hover":
            cv.rect(x + 2, top + 6, x + w - 2, top + strip_h - 4, fill=mixfg(C["foreground"], C["editorGroupHeader.connectedTabsBackground"], 0.06), radius=5)
            fg = C["modernEditorTab.hoverForeground"]
        else:
            fg = C["tab.inactiveForeground"]
        cv.text(x + 14, top + 12, name, fg)
        cv.text(x + w - 22, top + 12, "x", fg, F_UI_S)
        x += w + 2
    by = top + strip_h + 10
    xx = ex0 + 18
    for i, part in enumerate(("apps", "web", "components", "card.tsx", "Card")):
        xx = cv.text(xx, by, part, C["breadcrumb.focusForeground"] if i == 4 else C["breadcrumb.foreground"])
        if i < 4:
            xx = cv.text(xx + 6, by, ">", C["breadcrumb.foreground"], F_UI_S) + 6
    ey = by + 26
    lines = tokens("tsx")
    active = 5
    cv.rect(ex0 + 1, ey + active * LH, ex1 - 1, ey + (active + 1) * LH, fill=C["editor.lineHighlightBackground"])
    for li in (8, 9):
        text = "".join(t["text"] for t in lines[li])
        c0 = len(text) - len(text.lstrip(" "))
        cv.rect(ex0 + 58 + c0 * CW, ey + li * LH, ex0 + 58 + len(text) * CW, ey + (li + 1) * LH, fill=C["editor.selectionBackground"])
    draw_code(cv, ex0, ey, lines, active=active, marks={3: C["editorGutter.modifiedBackground"], 9: C["editorGutter.addedBackground"]})
    cend = len("".join(t["text"] for t in lines[active]))
    cv.rect(ex0 + 58 + cend * CW, ey + active * LH + 1, ex0 + 58 + cend * CW + 2, ey + (active + 1) * LH - 1, fill=C["editorCursor.foreground"])

    # panel card with pill tabs
    cv.rect(ex0, panel_y, ex1, bottom, fill=C["panel.background"], outline=C["modernPanel.border"], radius=R)
    x = ex0 + 12
    for name, state in (("Problems", None), ("Output", "hover"), ("Debug Console", None), ("Terminal", "active"), ("Ports", None)):
        w = int(F_UI.getlength(name)) + 20
        if state == "active":
            cv.rect(x, panel_y + 7, x + w, panel_y + 31, fill=C["modernTab.activeBackground"], radius=5)
            fg = C["modernTab.activeForeground"]
        elif state == "hover":
            cv.rect(x, panel_y + 7, x + w, panel_y + 31, fill=C["modernTab.hoverBackground"], radius=5)
            fg = C["modernTab.hoverForeground"]
        else:
            fg = C["panelTitle.inactiveForeground"]
        cv.text(x + 10, panel_y + 11, name, fg)
        x += w + 4
    ty0 = panel_y + 38
    cv.rect(ex0 + 1, ty0, ex1 - 1, bottom - 1, fill=C["terminal.background"], radius=R - 1)
    cv.rect(ex0 + 1, ty0, ex1 - 1, ty0 + R, fill=C["terminal.background"])
    A = lambda n: C["terminal.ansi" + n]  # noqa: E731
    tl = [
        [("you", A("Cyan")), (" in ", C["terminal.foreground"]), ("~/Projects/app", A("Blue")), (" on ", C["terminal.foreground"]), (" main", A("Magenta")), (" [!?]", A("Red"))],
        [("> ", A("Green")), ("pnpm dev", C["terminal.foreground"])],
        [("  ready", A("Green")), (" - started server on 0.0.0.0:3000, url: ", C["terminal.foreground"]), ("http://localhost:3000", A("Blue"))],
        [("  warn", A("Yellow")), ("  - Fast Refresh had to perform a full reload", C["terminal.foreground"])],
        [("  error", A("Red")), (" - Module not found: ", C["terminal.foreground"]), ("./components/card", A("BrightBlack"))],
        [("> ", A("Green"))],
    ]
    for i, line in enumerate(tl):
        xx = ex0 + 20
        for s_, col in line:
            cv.d.text((xx, ty0 + 10 + i * 20), s_, font=F_CODE[""], fill=rgba(col))
            xx += CW * len(s_)
    cv.rect(ex0 + 20 + 2 * CW, ty0 + 10 + 5 * 20, ex0 + 20 + 3 * CW, ty0 + 10 + 6 * 20 - 2, fill=C["terminalCursor.foreground"])
    cv.im.convert("RGB").save(os.path.join(HERE, "preview-modern-ui.png"))


def mixfg(fg, bg, t):
    f, b = rgba(fg), rgba(bg)
    return "#%02x%02x%02x" % tuple(round(b[i] + (f[i] - b[i]) * t) for i in range(3))


if __name__ == "__main__":
    workbench()
    widgets()
    modern()
    print("wrote tools/preview-workbench.png, tools/preview-widgets.png and tools/preview-modern-ui.png (approximate mocks, not screenshots)")

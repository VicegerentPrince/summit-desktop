#!/usr/bin/env python3
"""Validates the Summit theme.

  1. both JSON files parse; no duplicate keys anywhere
  2. every colour is #rrggbb or #rrggbbaa; no pure black, no pure white
  3. every colour is an exact palette value or a declared derived tint
  4. required keys are present and the fixed values match the palette
  5. theme keys are real colour ids of the installed editors (if
     tools/color-registry.json exists) and unset ids are listed
  6. TextMate rules and semantic token rules agree, role by role
  7. WCAG contrast for the pairs a user reads (4.5:1; 3:1 for elements that
     are dim on purpose), with translucent layers composited first

Exit status is non-zero if anything fails.

Run:  python3 tools/check_theme.py            full report
      python3 tools/check_theme.py --quiet    failures and totals only
"""
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, HERE)
sys.dont_write_bytecode = True
import build_theme as B  # noqa: E402  (palette and derived tints; importing does not write)

THEME_PATH = B.THEME_PATH
PKG_PATH = B.PKG_PATH
REGISTRY_PATH = os.path.join(HERE, "color-registry.json")
QUIET = "--quiet" in sys.argv

failures = []


def fail(msg):
    failures.append(msg)


def say(msg=""):
    if not QUIET:
        print(msg)


# ---------------------------------------------------------------- 1. parse
def no_dupes(pairs):
    seen = {}
    for k, v in pairs:
        if k in seen:
            raise ValueError("duplicate key %r" % k)
        seen[k] = v
    return seen


def load(path):
    with open(path, encoding="utf-8") as fh:
        return json.load(fh, object_pairs_hook=no_dupes)


try:
    theme = load(THEME_PATH)
    pkg = load(PKG_PATH)
except ValueError as e:
    print("FAIL parse: %s" % e)
    sys.exit(1)

colors = theme["colors"]
token_rules = theme["tokenColors"]
semantic = theme["semanticTokenColors"]

say("1. JSON")
say("   %s parses, no duplicate keys" % os.path.relpath(THEME_PATH, ROOT))
say("   %s parses, no duplicate keys" % os.path.relpath(PKG_PATH, ROOT))
say("   colour keys: %d   TextMate rules: %d (%d scope selectors)   semantic rules: %d"
    % (len(colors), len(token_rules), sum(len(r["scope"]) for r in token_rules), len(semantic)))

# ------------------------------------------------------- 2. colour format
HEX = re.compile(r"^#[0-9a-f]{6}([0-9a-f]{2})?$")
all_values = []  # (where, value)
for k, v in colors.items():
    all_values.append(("colors." + k, v))
for r in token_rules:
    for field in ("foreground", "background"):
        if field in r["settings"]:
            all_values.append(("tokenColors[%s].%s" % (r["name"], field), r["settings"][field]))
for k, v in semantic.items():
    if isinstance(v, str):
        all_values.append(("semanticTokenColors." + k, v))
    elif "foreground" in v:
        all_values.append(("semanticTokenColors." + k, v["foreground"]))

bad_format = [(w, v) for w, v in all_values if not isinstance(v, str) or not HEX.match(v)]
pure = [(w, v) for w, v in all_values if isinstance(v, str) and v[1:7] in ("000000", "ffffff")]
for w, v in bad_format:
    fail("colour format: %s = %r" % (w, v))
for w, v in pure:
    fail("pure black/white: %s = %s" % (w, v))
say("\n2. Colour values")
say("   %d values checked: %d malformed, %d pure black or white" % (len(all_values), len(bad_format), len(pure)))

# ---------------------------------------------------- 3. palette discipline
palette_rgb = {v[:7]: name for name, v in B.PALETTE.items()}
derived_rgb = dict(B.DERIVED)
used_rgb = {}
for w, v in all_values:
    if isinstance(v, str) and HEX.match(v):
        used_rgb.setdefault(v[:7], []).append(w)
off_palette = sorted(c for c in used_rgb if c not in palette_rgb and c not in derived_rgb)
for c in off_palette:
    fail("colour %s is neither a palette value nor a declared derived tint (%s)" % (c, used_rgb[c][0]))
say("\n3. Palette")
say("   distinct RGB values: %d   exact palette: %d   derived tints: %d   undeclared: %d"
    % (len(used_rgb), sum(1 for c in used_rgb if c in palette_rgb),
       sum(1 for c in used_rgb if c in derived_rgb), len(off_palette)))
say("   derived tints in use:")
for c, why in B.DERIVED.items():
    if c in used_rgb:
        say("     %s  %s  (%d use%s)" % (c, why, len(used_rgb[c]), "" if len(used_rgb[c]) == 1 else "s"))
unused_palette = [n for n, v in B.PALETTE.items() if v[:7] not in used_rgb]
if unused_palette:
    say("   palette values not used directly: %s" % ", ".join(unused_palette))

# ------------------------------------------------ 4. required keys / values
REQUIRED_EXACT = {
    "editor.background": "#171c23", "editor.foreground": "#dce3ea",
    "editor.lineHighlightBackground": "#1d232c",
    "sideBar.background": "#1d232c", "panel.background": "#1d232c",
    "titleBar.activeBackground": "#1d232c", "statusBar.background": "#1d232c",
    "activityBar.background": "#1d232c",
    "input.background": "#28313d", "button.secondaryBackground": "#28313d",
    "button.background": "#4fd1c5", "button.foreground": "#0e161a",
    "focusBorder": "#4fd1c5", "editorCursor.foreground": "#4fd1c5",
    "tab.activeBorderTop": "#4fd1c5", "statusBarItem.remoteBackground": "#4fd1c5",
    "textLink.foreground": "#4fd1c5",
    "terminal.background": "#171c23", "terminal.foreground": "#dce3ea",
    "terminalCursor.foreground": "#4fd1c5",
    "terminal.ansiBlack": "#28313d", "terminal.ansiRed": "#f47067", "terminal.ansiGreen": "#84cc6a",
    "terminal.ansiYellow": "#e3b341", "terminal.ansiBlue": "#7cb7ff", "terminal.ansiMagenta": "#b9a3f5",
    "terminal.ansiCyan": "#4fd1c5", "terminal.ansiWhite": "#c5cfd9",
    "terminal.ansiBrightBlack": "#5c6773", "terminal.ansiBrightRed": "#ff8a80",
    "terminal.ansiBrightGreen": "#a0e088", "terminal.ansiBrightYellow": "#f2c968",
    "terminal.ansiBrightBlue": "#9ccaff", "terminal.ansiBrightMagenta": "#d0bfff",
    "terminal.ansiBrightCyan": "#81e6d9", "terminal.ansiBrightWhite": "#f0f4f8",
    "editorGutter.addedBackground": "#84cc6a", "editorGutter.modifiedBackground": "#e3b341",
    "editorGutter.deletedBackground": "#f47067",
}
REQUIRED_KEYS = """
foreground focusBorder errorForeground descriptionForeground disabledForeground icon.foreground
button.background button.foreground button.hoverBackground button.secondaryBackground button.secondaryForeground button.secondaryHoverBackground
input.background input.foreground input.border input.placeholderForeground inputOption.activeBackground inputValidation.errorBackground
dropdown.background dropdown.foreground dropdown.border checkbox.background checkbox.foreground checkbox.border
badge.background badge.foreground progressBar.background scrollbar.shadow scrollbarSlider.background scrollbarSlider.hoverBackground scrollbarSlider.activeBackground
list.hoverBackground list.activeSelectionBackground list.activeSelectionForeground list.inactiveSelectionBackground list.focusOutline
list.highlightForeground list.errorForeground list.warningForeground
activityBar.background activityBar.foreground activityBar.inactiveForeground activityBar.activeBorder activityBarBadge.background
activityBarTop.foreground activityBarTop.inactiveForeground activityBarTop.activeBorder
sideBar.background sideBar.foreground sideBar.border sideBarTitle.foreground sideBarSectionHeader.background sideBarSectionHeader.foreground
sideBarSectionHeader.border sideBarStickyScroll.background sideBarStickyScroll.border
editorGroup.border editorGroupHeader.tabsBackground tab.activeBackground tab.activeForeground tab.inactiveBackground tab.inactiveForeground
tab.hoverBackground tab.activeModifiedBorder tab.selectedBackground tab.selectedForeground tab.selectedBorderTop tab.activeBorderTop
editorLineNumber.foreground editorLineNumber.activeForeground editorCursor.foreground editor.selectionBackground
editor.inactiveSelectionBackground editor.selectionHighlightBackground editor.findMatchBackground editor.findMatchHighlightBackground
editor.wordHighlightBackground editor.wordHighlightStrongBackground editor.hoverHighlightBackground editorLink.activeForeground
editor.rangeHighlightBackground editorWhitespace.foreground editorIndentGuide.background1 editorIndentGuide.activeBackground1 editorRuler.foreground
editorBracketMatch.background editorBracketMatch.border editorBracketHighlight.foreground1 editorBracketHighlight.foreground2
editorBracketHighlight.foreground3 editorBracketHighlight.foreground4 editorBracketHighlight.foreground5 editorBracketHighlight.foreground6
editorCodeLens.foreground editorInlayHint.foreground editorInlayHint.background editorGhostText.foreground editorLightBulb.foreground
editorUnnecessaryCode.opacity editorError.foreground editorWarning.foreground editorInfo.foreground
editorGutter.addedBackground editorGutter.modifiedBackground editorGutter.deletedBackground editorGutter.background
diffEditor.insertedTextBackground diffEditor.removedTextBackground diffEditor.insertedLineBackground diffEditor.removedLineBackground
merge.currentHeaderBackground merge.incomingHeaderBackground editorOverviewRuler.border editorOverviewRuler.errorForeground
minimap.background minimap.selectionHighlight minimapSlider.background
editorWidget.background editorSuggestWidget.background editorSuggestWidget.selectedBackground editorHoverWidget.background
peekView.border peekViewEditor.background peekViewResult.background peekViewTitle.background
editorStickyScroll.background editorStickyScroll.border editorStickyScrollHover.background
breadcrumb.foreground breadcrumb.background titleBar.activeBackground titleBar.activeForeground titleBar.inactiveBackground titleBar.inactiveForeground
menu.background menu.foreground menu.selectionBackground menubar.selectionBackground
commandCenter.background commandCenter.foreground commandCenter.border commandCenter.activeBackground
notifications.background notifications.foreground notificationCenterHeader.background
quickInput.background quickInput.foreground quickInputList.focusBackground pickerGroup.foreground
keybindingLabel.background keybindingLabel.foreground keybindingLabel.border
panel.background panel.border panelTitle.activeForeground panelTitle.inactiveForeground panelTitle.activeBorder
statusBar.background statusBar.foreground statusBar.noFolderBackground statusBar.debuggingBackground statusBar.debuggingForeground
statusBarItem.remoteBackground statusBarItem.remoteForeground statusBarItem.prominentBackground statusBarItem.errorBackground
statusBarItem.errorForeground statusBarItem.warningBackground statusBarItem.warningForeground
terminal.background terminal.foreground terminal.selectionBackground terminalCursor.foreground terminalStickyScroll.background
terminalCommandDecoration.defaultBackground terminalCommandDecoration.successBackground terminalCommandDecoration.errorBackground
debugToolBar.background debugConsole.errorForeground debugExceptionWidget.background debugTokenExpression.name
testing.iconPassed testing.iconFailed gitDecoration.addedResourceForeground gitDecoration.modifiedResourceForeground
gitDecoration.deletedResourceForeground gitDecoration.untrackedResourceForeground gitDecoration.ignoredResourceForeground
settings.headerForeground settings.modifiedItemIndicator welcomePage.tileBackground charts.blue charts.red
notebook.cellBorderColor notebook.editorBackground
inlineChat.background inlineChatInput.background inlineChatDiff.inserted inlineChatDiff.removed
textLink.foreground textLink.activeForeground textBlockQuote.background textBlockQuote.border textCodeBlock.background
textPreformat.foreground textPreformat.background walkThrough.embeddedEditorBackground
extensionButton.prominentBackground extensionButton.prominentForeground
multiDiffEditor.background profileBadge.background profileBadge.foreground banner.background banner.foreground
keybindingTable.headerBackground keybindingTable.rowsBackground searchEditor.findMatchBackground
problemsErrorIcon.foreground problemsWarningIcon.foreground problemsInfoIcon.foreground
surface.background surface.foreground surface.border editor.border modernPanel.border modernSash.gripForeground
modernTab.activeBackground modernTab.hoverBackground modernTab.activeForeground modernTab.hoverForeground
modernEditorTab.activeBackground modernEditorTab.activeForeground modernEditorTab.inactiveBackground
modernEditorTab.hoverBackground modernEditorTab.hoverForeground modernEditorTab.activeHoverBackground
modernActivityBar.background modernActivityBar.inactiveBackground modernActivityBar.border
modernActivityBarItem.activeBackground modernActivityBarItem.hoverBackground modernActivityBarItem.activeForeground
modernActivityBarItem.hoverForeground modernUI.shellBackground modernUI.inactiveShellBackground
agents.background agentsPanel.background agentsPanel.foreground agentsPanel.border agentsCard.border
agentsChatInput.background agentsChatInput.foreground agentsChatInput.border agentsChatInput.focusBorder
agentsChatInput.placeholderForeground agentsBadge.background agentsBadge.foreground
chat.requestBubbleBackground chat.requestBubbleHoverBackground chat.requestCodeBorder chat.linesAddedForeground chat.linesRemovedForeground
""".split()
REQUIRED_PREFIXES = [
    "activityBarTop.", "sideBarTitle.", "sideBarSectionHeader.", "sideBarStickyScroll.", "tab.selected",
    "editorStickyScroll.", "commandCenter.", "terminal.ansi", "terminalStickyScroll.", "symbolIcon.",
    "chat.", "inlineChat.", "inlineChatInput.", "inlineChatDiff.", "inlineEdit.", "textLink.",
    "textBlockQuote.", "textPreformat.", "walkThrough.", "extensionButton.", "peekView", "editorGutter.",
    "scmGraph.", "multiDiffEditor.", "profileBadge.", "banner.", "keybindingTable.", "searchEditor.",
    "problems", "gauge.", "markdownAlert.", "terminalSymbolIcon.", "debugIcon.", "testing.", "notebook.",
    "charts.", "settings.", "welcomePage.", "gitDecoration.", "minimap.", "editorOverviewRuler.",
    "merge.", "diffEditor.", "statusBarItem.", "panelTitle.", "notifications.", "menu.", "titleBar.",
]
say("\n4. Required keys and fixed values")
missing_keys = [k for k in REQUIRED_KEYS if k not in colors]
missing_prefixes = [p for p in REQUIRED_PREFIXES if not any(k.startswith(p) for k in colors)]
wrong_values = [(k, v, colors.get(k)) for k, v in REQUIRED_EXACT.items() if colors.get(k) != v]
for k in missing_keys:
    fail("required key missing: %s" % k)
for p in missing_prefixes:
    fail("required key family missing: %s*" % p)
for k, want, got in wrong_values:
    fail("fixed value: %s is %s, expected %s" % (k, got, want))
if len(set(k for k, _ in B.ANSI)) != 16 or sum(1 for k in colors if k.startswith("terminal.ansi")) != 16:
    fail("terminal.ansi*: expected 16 keys")
say("   %d required keys, %d key families, %d fixed values: %d missing, %d wrong"
    % (len(REQUIRED_KEYS), len(REQUIRED_PREFIXES), len(REQUIRED_EXACT),
       len(missing_keys) + len(missing_prefixes), len(wrong_values)))
expected_pkg = {
    "name": "summit-theme", "displayName": "Summit", "publisher": "summit", "version": "1.0.0",
    "categories": ["Themes"],
}
for k, v in expected_pkg.items():
    if pkg.get(k) != v:
        fail("package.json %s is %r, expected %r" % (k, pkg.get(k), v))
if pkg.get("engines", {}).get("vscode") != "^1.90.0":
    fail("package.json engines.vscode is %r" % pkg.get("engines"))
themes = pkg.get("contributes", {}).get("themes", [])
if themes != [{"label": "Summit", "uiTheme": "vs-dark", "path": "./themes/summit-color-theme.json"}]:
    fail("package.json contributes.themes is %r" % themes)
if theme.get("type") != "dark" or theme.get("semanticHighlighting") is not True:
    fail("theme must declare type dark and semanticHighlighting true")
say("   package.json fields and theme header: ok" if not any("package.json" in f or "theme must" in f for f in failures) else "   package.json: see failures")

# ------------------------------------------------------- 5. registry check
say("\n5. Colour ids against the installed editors")
if os.path.exists(REGISTRY_PATH):
    with open(REGISTRY_PATH, encoding="utf-8") as fh:
        registry = json.load(fh)
    known = set()
    for name, info in registry.items():
        ids = set(info["ids"])
        known |= ids
        unset = sorted(ids - set(colors))
        say("   %-7s %s (VS Code base %s): %d ids registered, %d set by the theme, %d left at their default"
            % (name, info["version"], info["vscodeVersion"], len(ids), len(ids & set(colors)), len(unset)))
    unknown = sorted(k for k in colors if k not in known)
    say("   theme keys registered by neither editor (ignored at runtime): %s" % (", ".join(unknown) or "none"))
    vs = registry.get("vscode")
    if vs:
        unset = sorted(set(vs["ids"]) - set(colors))
        say("   left unset on purpose in VS Code %s (%d): %s" % (vs["version"], len(unset), ", ".join(unset)))
    # Colours the editors register as "must be translucent or they hide what is underneath".
    OPAQUE_ON_PURPOSE = {
        "terminal.findMatchBackground": "the terminal renderer drops the alpha channel of this colour, so it is pre-blended",
        "chat.linesAddedForeground": "a text colour; the registry flag is a quirk and the default is opaque too",
        "chat.linesRemovedForeground": "a text colour; the registry flag is a quirk and the default is opaque too",
        "chat.voiceGlowBaseColor": "the default is the opaque focus colour",
    }
    must = set()
    for info in registry.values():
        must |= set(info.get("mustBeTranslucent", []))
    opaque = sorted(k for k in must if k in colors and len(colors[k]) == 7)
    for k in opaque:
        if k not in OPAQUE_ON_PURPOSE:
            fail("%s must be translucent (it would hide what is underneath) but is %s" % (k, colors[k]))
    say("   colours that must be translucent: %d registered, %d set by the theme, %d opaque by design"
        % (len(must), sum(1 for k in must if k in colors), len(opaque)))
    for k in opaque:
        if k in OPAQUE_ON_PURPOSE:
            say("     %s: %s" % (k, OPAQUE_ON_PURPOSE[k]))
else:
    say("   tools/color-registry.json not found; run tools/extract_registry.py to enable this check")

# ---------------------------------------- 6. TextMate vs semantic agreement
def tm_color(scope):
    for r in token_rules:
        if scope in r["scope"]:
            return r["settings"].get("foreground"), r["settings"].get("fontStyle")
    raise KeyError(scope)


def sem_color(sel):
    v = semantic[sel]
    if isinstance(v, str):
        return v, None
    return v.get("foreground"), v.get("fontStyle")


AGREE = [
    ("comments", "comment", ["comment"]),
    ("keywords", "keyword", ["keyword", "modifier"]),
    ("functions", "entity.name.function", ["function", "method", "macro", "function.defaultLibrary"]),
    ("types", "entity.name.type", ["type", "class", "interface", "enum", "struct", "namespace", "typeParameter", "type.defaultLibrary", "class.defaultLibrary"]),
    ("built-in types", "storage.type.primitive", ["type.defaultLibrary", "builtinType"]),
    ("strings", "string", ["string"]),
    ("escapes and regex", "string.regexp", ["regexp"]),
    ("numbers and constants", "constant", ["number", "enumMember", "boolean", "variable.readonly.defaultLibrary"]),
    ("enum members", "variable.other.enummember", ["enumMember"]),
    ("variables", "variable", ["variable", "variable.readonly", "variable.defaultLibrary"]),
    ("parameters", "variable.parameter", ["parameter"]),
    ("properties", "variable.other.property", ["property", "property.readonly"]),
    ("operators", "keyword.operator", ["operator"]),
    ("decorators", "entity.name.function.decorator", ["decorator", "annotation"]),
    ("this / self", "variable.language", ["selfParameter", "clsParameter"]),
]
say("\n6. TextMate and semantic tokens")
disagree = 0
for label, scope, sels in AGREE:
    want = tm_color(scope)
    for sel in sels:
        got = sem_color(sel)
        if got[0] != want[0] or (got[1] or "") != (want[1] or ""):
            disagree += 1
            fail("syntax mapping: %s: TextMate %s is %s %s but semantic %s is %s %s"
                 % (label, scope, want[0], want[1] or "", sel, got[0], got[1] or ""))
say("   %d roles compared across %d semantic selectors: %d disagreements"
    % (len(AGREE), sum(len(s) for _, _, s in AGREE), disagree))

# --------------------------------------------------------------- 7. WCAG
def parse(c):
    c = c.lstrip("#")
    r, g, b = (int(c[i:i + 2], 16) for i in (0, 2, 4))
    al = int(c[6:8], 16) / 255.0 if len(c) == 8 else 1.0
    return (float(r), float(g), float(b), al)


def over(top, bottom):
    """Composite an RGBA colour over an opaque RGB colour."""
    al = top[3]
    return tuple(bottom[i] + (top[i] - bottom[i]) * al for i in range(3)) + (1.0,)


def lum(c):
    def lin(v):
        v /= 255.0
        return v / 12.92 if v <= 0.04045 else ((v + 0.055) / 1.055) ** 2.4
    return 0.2126 * lin(c[0]) + 0.7152 * lin(c[1]) + 0.0722 * lin(c[2])


def ratio(a_, b_):
    la, lb = lum(a_), lum(b_)
    if la < lb:
        la, lb = lb, la
    return (la + 0.05) / (lb + 0.05)


ROLE_SCOPES = {
    "@comment": "comment", "@keyword": "keyword", "@function": "entity.name.function",
    "@type": "entity.name.type", "@string": "string", "@escape": "constant.character.escape",
    "@constant": "constant", "@variable": "variable", "@property": "variable.other.property",
    "@punctuation": "punctuation", "@tag": "entity.name.tag", "@attribute": "entity.other.attribute-name",
    "@key": "support.type.property-name", "@heading": "markup.heading", "@link": "markup.underline.link",
}


def resolve(spec):
    if spec.startswith("@"):
        return tm_color(ROLE_SCOPES[spec])[0]
    if spec.startswith("#"):
        return spec
    return colors[spec]


def flatten(spec):
    """A background: one colour, or [base, layer, ...] composited bottom to top."""
    layers = spec if isinstance(spec, list) else [spec]
    base = parse(resolve(layers[0]))
    if base[3] != 1.0:
        raise ValueError("background base must be opaque: %r" % (layers[0],))
    for layer in layers[1:]:
        base = over(parse(resolve(layer)), base)
    return base


def name_of(spec):
    if isinstance(spec, list):
        return " + ".join(name_of(s) for s in spec)
    return spec


ED, LINE_HL, SIDE = "editor.background", "editor.lineHighlightBackground", "sideBar.background"
SYNTAX = [("@keyword", 4.5), ("@function", 4.5), ("@type", 4.5), ("@string", 4.5), ("@escape", 4.5),
          ("@constant", 4.5), ("@variable", 4.5), ("@property", 4.5), ("@punctuation", 4.5),
          ("@tag", 4.5), ("@attribute", 4.5), ("@key", 4.5), ("@heading", 4.5), ("@link", 4.5), ("@comment", 3.0)]

P = []   # (section, label, fg, bg, minimum or None for information only)


def pair(section, fg, bg, minimum, label=None):
    P.append((section, label or name_of(fg), fg, bg, minimum))


S = "Editor"
pair(S, "editor.foreground", ED, 4.5)
for role, m in SYNTAX:
    pair(S, role, ED, m, "syntax %s" % role[1:])
pair(S, "editorLineNumber.foreground", ED, 3.0)
pair(S, "editorLineNumber.activeForeground", LINE_HL, 4.5)
for i in range(1, 7):
    pair(S, "editorBracketHighlight.foreground%d" % i, ED, 4.5)
pair(S, "editorCodeLens.foreground", ED, 3.0)
pair(S, "editorGhostText.foreground", ED, 3.0)
pair(S, "editorInlayHint.foreground", [ED, "editorInlayHint.background"], 3.0)
pair(S, "editorInlayHint.foreground", [LINE_HL, "editorInlayHint.background"], 3.0, "editorInlayHint.foreground (current line)")
pair(S, "editor.placeholder.foreground", ED, 3.0)
pair(S, "editor.foldPlaceholderForeground", ED, 3.0)
pair(S, "editorLink.activeForeground", ED, 4.5)
pair(S, "editor.inlineValuesForeground", [ED, "editor.inlineValuesBackground"], 4.5)
pair(S, "breadcrumb.foreground", "breadcrumb.background", 4.5)
pair(S, "breadcrumb.focusForeground", "breadcrumb.background", 4.5)

S = "Editor, current line"
pair(S, "editor.foreground", LINE_HL, 4.5)
for role, m in SYNTAX:
    pair(S, role, LINE_HL, m, "syntax %s" % role[1:])
pair(S, "editorLineNumber.foreground", "editorStickyScrollHover.background", 3.0, "editorLineNumber.foreground (sticky scroll hover, peek)")

S = "Side bar and lists"
pair(S, "sideBar.foreground", SIDE, 4.5)
pair(S, "sideBarTitle.foreground", "sideBarTitle.background", 4.5)
pair(S, "sideBarSectionHeader.foreground", "sideBarSectionHeader.background", 4.5)
pair(S, "list.hoverForeground", [SIDE, "list.hoverBackground"], 4.5)
pair(S, "list.activeSelectionForeground", "list.activeSelectionBackground", 4.5)
pair(S, "list.inactiveSelectionForeground", "list.inactiveSelectionBackground", 4.5)
pair(S, "list.focusForeground", "list.focusBackground", 4.5)
pair(S, "list.highlightForeground", SIDE, 4.5)
pair(S, "list.highlightForeground", "list.inactiveSelectionBackground", 4.5, "list.highlightForeground (inactive selection)")
pair(S, "list.focusHighlightForeground", "list.activeSelectionBackground", 4.5)
for k in ("list.errorForeground", "list.warningForeground", "list.invalidItemForeground"):
    pair(S, k, SIDE, 4.5)
    pair(S, k, "list.inactiveSelectionBackground", 4.5, k + " (inactive selection)")
pair(S, "list.deemphasizedForeground", SIDE, 4.5)
pair(S, "list.deemphasizedForeground", "list.inactiveSelectionBackground", 3.0, "list.deemphasizedForeground (inactive selection)")
for k in ("added", "untracked", "modified", "stageModified", "deleted", "stageDeleted", "renamed", "conflicting", "submodule"):
    key = "gitDecoration.%sResourceForeground" % k
    pair(S, key, SIDE, 4.5)
    pair(S, key, "list.inactiveSelectionBackground", 4.5, key + " (inactive selection)")
pair(S, "gitDecoration.ignoredResourceForeground", SIDE, 3.0)
pair(S, "gitDecoration.ignoredResourceForeground", "list.inactiveSelectionBackground", 3.0, "gitDecoration.ignoredResourceForeground (inactive selection)")
pair(S, "descriptionForeground", SIDE, 4.5)
pair(S, "descriptionForeground", ED, 4.5, "descriptionForeground (editor)")
for bg in (ED, SIDE, "input.background"):
    pair(S, "disabledForeground", bg, 3.0, "disabledForeground on %s" % bg)
pair(S, "badge.foreground", "badge.background", 4.5)
pair(S, "activityBar.foreground", "activityBar.background", 4.5)
pair(S, "activityBar.inactiveForeground", "activityBar.background", 3.0, "activityBar.inactiveForeground (icon)")
pair(S, "activityBarTop.foreground", "activityBarTop.background", 4.5)
pair(S, "activityBarTop.inactiveForeground", "activityBarTop.background", 3.0, "activityBarTop.inactiveForeground (icon)")
pair(S, "activityBarBadge.foreground", "activityBarBadge.background", 4.5)
pair(S, "icon.foreground", SIDE, 3.0, "icon.foreground (icon)")

S = "Tabs, title bar, menus"
pair(S, "tab.activeForeground", "tab.activeBackground", 4.5)
pair(S, "tab.inactiveForeground", "tab.inactiveBackground", 4.5)
pair(S, "tab.hoverForeground", "tab.hoverBackground", 4.5)
pair(S, "tab.unfocusedActiveForeground", "tab.unfocusedActiveBackground", 4.5)
pair(S, "tab.unfocusedInactiveForeground", "tab.unfocusedInactiveBackground", 4.5)
pair(S, "tab.selectedForeground", "tab.selectedBackground", 4.5)
pair(S, "tab.inactiveForeground", "editorGroupHeader.connectedTabsBackground", 4.5, "tab.inactiveForeground (Modern UI connected tab strip)")
pair(S, "modernEditorTab.activeForeground", "editor.background", 4.5, "modernEditorTab.activeForeground (Modern UI connected active tab)")
pair(S, "titleBar.activeForeground", "titleBar.activeBackground", 4.5)
pair(S, "titleBar.inactiveForeground", "titleBar.inactiveBackground", 4.5)
pair(S, "commandCenter.foreground", "commandCenter.background", 4.5)
pair(S, "commandCenter.activeForeground", "commandCenter.activeBackground", 4.5)
pair(S, "commandCenter.inactiveForeground", "commandCenter.background", 3.0, "commandCenter.inactiveForeground (window not focused)")
pair(S, "menu.foreground", "menu.background", 4.5)
pair(S, "menu.selectionForeground", "menu.selectionBackground", 4.5)
pair(S, "menubar.selectionForeground", "menubar.selectionBackground", 4.5)
pair(S, "disabledForeground", "menu.background", 3.0, "disabled menu item")
pair(S, "banner.foreground", "banner.background", 4.5)

S = "Status bar"
pair(S, "statusBar.foreground", "statusBar.background", 4.5)
pair(S, "statusBar.noFolderForeground", "statusBar.noFolderBackground", 4.5)
pair(S, "statusBar.debuggingForeground", "statusBar.debuggingBackground", 4.5)
pair(S, "statusBarItem.hoverForeground", "statusBarItem.hoverBackground", 4.5)
pair(S, "statusBarItem.prominentForeground", "statusBarItem.prominentBackground", 4.5)
pair(S, "statusBarItem.prominentHoverForeground", "statusBarItem.prominentHoverBackground", 4.5)
pair(S, "statusBarItem.remoteForeground", "statusBarItem.remoteBackground", 4.5)
pair(S, "statusBarItem.remoteHoverForeground", "statusBarItem.remoteHoverBackground", 4.5)
pair(S, "statusBarItem.errorForeground", "statusBarItem.errorBackground", 4.5)
pair(S, "statusBarItem.errorHoverForeground", "statusBarItem.errorHoverBackground", 4.5)
pair(S, "statusBarItem.warningForeground", "statusBarItem.warningBackground", 4.5)
pair(S, "statusBarItem.warningHoverForeground", "statusBarItem.warningHoverBackground", 4.5)
pair(S, "statusBarItem.offlineForeground", "statusBarItem.offlineBackground", 4.5)
pair(S, "statusBarItem.offlineHoverForeground", "statusBarItem.offlineHoverBackground", 4.5)

S = "Panel and terminal"
pair(S, "panelTitle.activeForeground", "panel.background", 4.5)
pair(S, "panelTitle.inactiveForeground", "panel.background", 4.5)
pair(S, "panelTitleBadge.foreground", "panelTitleBadge.background", 4.5)
pair(S, "terminal.foreground", "terminal.background", 4.5)
for name, _ in B.ANSI:
    spec = name in ("Black", "BrightBlack")
    pair(S, "terminal.ansi" + name, "terminal.background", None if spec else 4.5,
         "terminal.ansi%s%s" % (name, " (value fixed by the palette)" if spec else ""))
pair(S, "terminal.foreground", ["terminal.background", "terminal.selectionBackground"], 4.5, "terminal.foreground (selected)")
pair(S, "terminal.foreground", "terminal.findMatchBackground", 4.5, "terminal.foreground (current find match)")
pair(S, "terminal.initialHintForeground", "terminal.background", 3.0)
pair(S, "terminalCursor.foreground", "terminal.background", 3.0, "terminalCursor.foreground (cursor)")
pair(S, "terminalCursor.background", "terminalCursor.foreground", 4.5, "character under the block cursor")
for k in ("debugConsole.infoForeground", "debugConsole.warningForeground", "debugConsole.errorForeground", "debugConsole.sourceForeground"):
    pair(S, k, "panel.background", 4.5)
for k in ("name", "type", "value", "string", "number", "boolean", "error"):
    pair(S, "debugTokenExpression." + k, SIDE, 4.5)

S = "Inputs and buttons"
pair(S, "input.foreground", "input.background", 4.5)
pair(S, "input.placeholderForeground", "input.background", 3.0)
pair(S, "inputOption.activeForeground", ["input.background", "inputOption.activeBackground"], 4.5)
for k in ("info", "warning", "error"):
    pair(S, "inputValidation.%sForeground" % k, "inputValidation.%sBackground" % k, 4.5)
pair(S, "dropdown.foreground", "dropdown.background", 4.5)
pair(S, "dropdown.foreground", "dropdown.listBackground", 4.5, "dropdown.foreground (open list)")
pair(S, "button.foreground", "button.background", 4.5)
pair(S, "button.foreground", "button.hoverBackground", 4.5, "button.foreground (hover)")
pair(S, "button.secondaryForeground", "button.secondaryBackground", 4.5)
pair(S, "button.secondaryForeground", "button.secondaryHoverBackground", 4.5, "button.secondaryForeground (hover)")
pair(S, "extensionButton.foreground", "extensionButton.background", 4.5)
pair(S, "extensionButton.prominentForeground", "extensionButton.prominentBackground", 4.5)
pair(S, "checkbox.foreground", "checkbox.background", 3.0, "checkbox.foreground (tick)")
pair(S, "radio.activeForeground", "radio.activeBackground", 4.5)
pair(S, "radio.inactiveForeground", "radio.inactiveBackground", 4.5)
pair(S, "keybindingLabel.foreground", ["quickInput.background", "keybindingLabel.background"], 4.5)
pair(S, "settings.textInputForeground", "settings.textInputBackground", 4.5)
pair(S, "settings.dropdownForeground", "settings.dropdownBackground", 4.5)
pair(S, "settings.headerForeground", ED, 4.5)

S = "Popups and widgets"
pair(S, "editorWidget.foreground", "editorWidget.background", 4.5)
pair(S, "editorSuggestWidget.foreground", "editorSuggestWidget.background", 4.5)
pair(S, "editorSuggestWidget.highlightForeground", "editorSuggestWidget.background", 4.5)
pair(S, "editorSuggestWidget.selectedForeground", "editorSuggestWidget.selectedBackground", 4.5)
pair(S, "editorSuggestWidget.focusHighlightForeground", "editorSuggestWidget.selectedBackground", 4.5)
pair(S, "editorSuggestWidgetStatus.foreground", "editorSuggestWidget.background", 4.5)
pair(S, "editorHoverWidget.foreground", "editorHoverWidget.background", 4.5)
pair(S, "editorHoverWidget.foreground", "editorHoverWidget.statusBarBackground", 4.5, "editorHoverWidget.foreground (status bar)")
pair(S, "textLink.foreground", "editorHoverWidget.statusBarBackground", 4.5, "textLink.foreground (hover status bar)")
pair(S, "quickInput.foreground", "quickInput.background", 4.5)
pair(S, "quickInputList.focusForeground", "quickInputList.focusBackground", 4.5)
pair(S, "quickInputList.focusHighlightForeground", "quickInputList.focusBackground", 4.5)
pair(S, "pickerGroup.foreground", "quickInput.background", 4.5)
pair(S, "pickerGroup.foreground", "quickInputList.focusBackground", 4.5, "pickerGroup.foreground (focused row)")
pair(S, "notifications.foreground", "notifications.background", 4.5)
pair(S, "notificationLink.foreground", "notifications.background", 4.5)
pair(S, "notificationCenterHeader.foreground", "notificationCenterHeader.background", 4.5)
pair(S, "peekViewTitleLabel.foreground", "peekViewTitle.background", 4.5)
pair(S, "peekViewTitleDescription.foreground", "peekViewTitle.background", 4.5)
pair(S, "peekViewResult.fileForeground", "peekViewResult.background", 4.5)
pair(S, "peekViewResult.lineForeground", "peekViewResult.background", 4.5)
pair(S, "peekViewResult.selectionForeground", "peekViewResult.selectionBackground", 4.5)
pair(S, "editor.foreground", "peekViewEditor.background", 4.5, "editor.foreground (peek editor)")
pair(S, "@comment", "peekViewEditor.background", 3.0, "syntax comment (peek editor)")
pair(S, "debugView.exceptionLabelForeground", "debugView.exceptionLabelBackground", 4.5)
pair(S, "debugView.stateLabelForeground", [SIDE, "debugView.stateLabelBackground"], 4.5)
pair(S, "foreground", "debugExceptionWidget.background", 4.5, "foreground (exception widget)")
pair(S, "testing.message.error.badgeForeground", "testing.message.error.badgeBackground", 4.5)
pair(S, "scmGraph.historyItemHoverLabelForeground", "scmGraph.historyItemRefColor", 4.5)
pair(S, "scmGraph.historyItemHoverLabelForeground", "scmGraph.historyItemRemoteRefColor", 4.5, "scmGraph label (remote ref)")
pair(S, "scmGraph.historyItemHoverLabelForeground", "scmGraph.historyItemBaseRefColor", 4.5, "scmGraph label (base ref)")
pair(S, "profileBadge.foreground", "profileBadge.background", 4.5)

S = "Text, welcome, settings"
pair(S, "textLink.foreground", ED, 4.5)
pair(S, "textLink.foreground", SIDE, 4.5, "textLink.foreground (side bar)")
pair(S, "textPreformat.foreground", [SIDE, "textPreformat.background"], 4.5)
pair(S, "textPreformat.foreground", [ED, "textPreformat.background"], 4.5, "textPreformat.foreground (editor)")
pair(S, "foreground", [ED, "textBlockQuote.background"], 4.5, "foreground (block quote)")
pair(S, "foreground", "welcomePage.tileBackground", 4.5, "foreground (welcome tile)")
pair(S, "walkthrough.stepTitle.foreground", "welcomePage.tileBackground", 4.5)
for k in ("note", "tip", "important", "warning", "caution"):
    pair(S, "markdownAlert.%s.foreground" % k, ED, 4.5)

S = "Chat, agents, Modern UI"
pair(S, "foreground", [SIDE, "chat.requestBubbleBackground"], 4.5, "foreground (chat request bubble)")
pair(S, "foreground", [SIDE, "chat.requestBubbleHoverBackground"], 4.5, "foreground (chat request bubble, hover)")
pair(S, "chat.slashCommandForeground", [SIDE, "chat.requestBubbleBackground", "chat.slashCommandBackground"], 4.5)
pair(S, "chat.avatarForeground", "chat.avatarBackground", 4.5)
pair(S, "chat.editedFileForeground", SIDE, 4.5)
pair(S, "chat.linesAddedForeground", SIDE, 4.5)
pair(S, "chat.linesRemovedForeground", SIDE, 4.5)
pair(S, "inlineChat.foreground", "inlineChat.background", 4.5)
pair(S, "input.foreground", "inlineChatInput.background", 4.5, "input text (inline chat)")
pair(S, "inlineChatInput.placeholderForeground", "inlineChatInput.background", 3.0)
pair(S, "agentsChatInput.foreground", "agentsChatInput.background", 4.5)
pair(S, "agentsChatInput.placeholderForeground", "agentsChatInput.background", 3.0)
pair(S, "agentsPanel.foreground", "agentsPanel.background", 4.5)
pair(S, "agentsBadge.foreground", "agentsBadge.background", 4.5)
pair(S, "agentsUnreadBadge.foreground", "agentsUnreadBadge.background", 4.5)
pair(S, "agentsNewSessionButton.foreground", "agentsNewSessionButton.hoverBackground", 4.5)
pair(S, "activeSessionView.foreground", "activeSessionView.background", 4.5)
pair(S, "inactiveSessionView.foreground", "inactiveSessionView.background", 4.5)
pair(S, "surface.foreground", "surface.background", 4.5)
pair(S, "modernTab.activeForeground", "modernTab.activeBackground", 4.5)
pair(S, "modernTab.hoverForeground", "modernTab.hoverBackground", 4.5)
pair(S, "modernEditorTab.activeForeground", "modernEditorTab.activeBackground", 4.5)
pair(S, "modernEditorTab.hoverForeground", "modernEditorTab.hoverBackground", 4.5)
pair(S, "modernActivityBarItem.activeForeground", "modernActivityBarItem.activeBackground", 4.5)
pair(S, "modernActivityBarItem.hoverForeground", "modernActivityBarItem.hoverBackground", 4.5)
pair(S, "inlineEdit.gutterIndicator.primaryForeground", [ED, "inlineEdit.gutterIndicator.primaryBackground"], 4.5)
pair(S, "inlineEdit.gutterIndicator.secondaryForeground", "inlineEdit.gutterIndicator.secondaryBackground", 4.5)
pair(S, "inlineEdit.gutterIndicator.successfulForeground", "inlineEdit.gutterIndicator.successfulBackground", 4.5)

# Layers the palette fixes (selection) or that every theme stacks over syntax
# colours. Reported, not gated: primary text is what must stay readable.
S = "Stacked highlights (information)"
for label, bg in [
    ("selection", [ED, "editor.selectionBackground"]),
    ("selection on the current line", [LINE_HL, "editor.selectionBackground"]),
    ("current find match", [ED, "editor.findMatchBackground"]),
    ("other find matches", [ED, "editor.findMatchHighlightBackground"]),
    ("word highlight", [ED, "editor.wordHighlightBackground"]),
    ("word highlight, write", [ED, "editor.wordHighlightStrongBackground"]),
    ("diff inserted line", [ED, "diffEditor.insertedLineBackground"]),
    ("diff inserted text", [ED, "diffEditor.insertedLineBackground", "diffEditor.insertedTextBackground"]),
    ("diff removed line", [ED, "diffEditor.removedLineBackground"]),
    ("diff removed text", [ED, "diffEditor.removedLineBackground", "diffEditor.removedTextBackground"]),
    ("merge current header", [ED, "merge.currentHeaderBackground"]),
    ("merge incoming header", [ED, "merge.incomingHeaderBackground"]),
]:
    pair(S, "editor.foreground", bg, 4.5, "text on %s" % label)
    for role in ("@comment", "@punctuation", "@tag", "@keyword"):
        pair(S, role, bg, None, "%s on %s" % (role[1:], label))

say("\n7. WCAG contrast")
rows = []
for section, label, fg, bg, minimum in P:
    try:
        bgc = flatten(bg)
        fgc = parse(resolve(fg))
    except KeyError as e:
        fail("contrast pair refers to a missing key: %s" % e)
        continue
    if fgc[3] != 1.0:
        fgc = over(fgc, bgc)
    r = ratio(fgc, bgc)
    ok = minimum is None or r + 1e-9 >= minimum
    rows.append((section, label, name_of(bg), r, minimum, ok))
    if not ok:
        fail("contrast %.2f < %.1f: %s on %s" % (r, minimum, label, name_of(bg)))

current = None
for section, label, bgname, r, minimum, ok in rows:
    if section != current:
        say("\n   %s" % section)
        current = section
    need = "info" if minimum is None else ("%.1f" % minimum)
    say("   %-6s %5.2f  (min %4s)  %s  /  %s" % ("ok" if ok else "FAIL", r, need, label, bgname))

gated = [r for r in rows if r[4] is not None]
say("\n   %d pairs checked against a threshold, %d below it; %d further pairs reported for information"
    % (len(gated), sum(1 for r in gated if not r[5]), len(rows) - len(gated)))
lowest = sorted(gated, key=lambda r: r[3] - r[4])[:6]
say("   smallest margins: " + "; ".join("%s %.2f (min %.1f)" % (r[1], r[3], r[4]) for r in lowest))

# ------------------------------------------------------------------ result
print()
if failures:
    print("FAILED: %d problem%s" % (len(failures), "" if len(failures) == 1 else "s"))
    for f in failures:
        print("  - " + f)
    sys.exit(1)
print("OK: %d colour keys, %d TextMate rules, %d semantic rules; %d contrast pairs pass, 0 fail"
      % (len(colors), len(token_rules), len(semantic), len(gated)))

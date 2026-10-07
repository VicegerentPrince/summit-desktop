#!/usr/bin/env python3
"""Summit colour theme generator.

Single source of truth for summit-theme/package.json and
summit-theme/themes/summit-color-theme.json. Every value is either an exact
Summit palette value, a palette value with an alpha channel, or a tint
derived by mixing a palette value into a Summit background (listed by
check_theme.py under "derived").

Run:  python3 tools/build_theme.py
"""
import json
import os
from collections import OrderedDict

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
EXT = os.path.join(ROOT, "summit-theme")
THEME_PATH = os.path.join(EXT, "themes", "summit-color-theme.json")
PKG_PATH = os.path.join(EXT, "package.json")

# --------------------------------------------------------------------------
# Palette (exact values of the Summit desktop colour scheme)
# --------------------------------------------------------------------------
BG0 = "#171c23"      # editor, terminal ("view")
BG1 = "#1d232c"      # side bar, panels, title bar, status bar, popups ("window")
BG2 = "#28313d"      # raised: inputs, buttons, hover
BG3 = "#323d4b"      # stronger hover, active, selected
LINE = "#2a333f"     # subtle border: structure between docked parts
FRAME = "#434952"    # strong border: outlines of controls and floating popups

FG = "#dce3ea"       # primary text
BRIGHT = "#f0f4f8"   # bright text
MUTED = "#8693a1"    # muted text, operators, punctuation
DIM = "#5c6773"      # dim (decorative only: below 3:1 on every surface)
COMMENT = "#6e7a88"  # comments
SOFT = "#c5cfd9"     # properties and fields, ANSI white

TEAL, TEAL_B = "#4fd1c5", "#81e6d9"
BLUE, BLUE_B = "#7cb7ff", "#9ccaff"
PURPLE, PURPLE_B = "#b9a3f5", "#d0bfff"
GREEN, GREEN_B = "#84cc6a", "#a0e088"
AMBER, AMBER_B = "#e3b341", "#f2c968"
RED, RED_B = "#f47067", "#ff8a80"

ON_ACCENT = "#0e161a"  # dark text on teal / solid colour chips
SELECTION = "#223f44"  # teal mixed into the background: text selection, active pills

PALETTE = OrderedDict([
    ("editor background", BG0), ("chrome background", BG1), ("raised", BG2),
    ("active", BG3), ("border subtle", LINE), ("border strong", FRAME),
    ("text", FG), ("text bright", BRIGHT), ("text muted", MUTED),
    ("text dim", DIM), ("comment", COMMENT), ("property / ansi white", SOFT),
    ("teal", TEAL), ("teal bright", TEAL_B), ("blue", BLUE),
    ("blue bright", BLUE_B), ("purple", PURPLE), ("purple bright", PURPLE_B),
    ("green", GREEN), ("green bright", GREEN_B), ("amber", AMBER),
    ("amber bright", AMBER_B), ("red", RED), ("red bright", RED_B),
    ("text on accent", ON_ACCENT), ("selection", SELECTION),
])


# --------------------------------------------------------------------------
# Colour helpers
# --------------------------------------------------------------------------
def _rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def mix(fg, bg, t):
    """Opaque blend: t of `fg` over `bg` (t=1 gives fg)."""
    f, b = _rgb(fg), _rgb(bg)
    return "#%02x%02x%02x" % tuple(round(b[i] + (f[i] - b[i]) * t) for i in range(3))


def a(color, alpha):
    """Palette colour with an alpha channel (0..1)."""
    return "%s%02x" % (color[:7], round(alpha * 255))


def scale(color, k):
    r, g, b = _rgb(color)
    return "#%02x%02x%02x" % (round(r * k), round(g * k), round(b * k))


# --------------------------------------------------------------------------
# Derived tints (the only values that are not exact palette colours)
# --------------------------------------------------------------------------
# Dim text that still reaches 3:1 on both the editor and the chrome
# background; the palette "dim" (#5c6773) reaches only 2.97:1 / 2.74:1.
LINENUM = mix(MUTED, BG0, 0.70)                 # #656f7b
# Shadow base: the editor background darkened. Nothing in the palette is
# darker than the surfaces, and pure black is not allowed.
DEEP = scale(BG0, 0.45)                         # #0a0d10
SHADOW = a(DEEP, 0.60)
SHADOW_SOFT = a(DEEP, 0.45)
# Status tints for opaque popups and chips.
TINT_ERROR = mix(RED, BG1, 0.16)
TINT_WARNING = mix(AMBER, BG1, 0.16)
TINT_INFO = mix(BLUE, BG1, 0.16)
CHIP_ERROR_DIM = mix(RED, BG1, 0.35)
CHIP_ERROR_DIM_HOVER = mix(RED, BG1, 0.45)
FIND_OPAQUE = mix(AMBER, BG0, 0.30)             # terminal needs an opaque match colour
TEAL_DEEP = mix(TEAL, BG0, 0.50)
UNCOVERED_BRANCH = mix(RED, BG0, 0.30)
# Tab strip of the Modern UI "connected" tabs. That layout draws no accent
# line on the active tab, so the strip has to sit a step above the chrome for
# the active (editor-coloured) tab to read. Same value as the desktop
# scheme's alternate window background (34,42,52).
STRIP = mix(BG2, BG1, 0.50)                     # #222a34

DERIVED = OrderedDict([
    (LINENUM, "line numbers: muted text mixed 70% into the editor background"),
    (DEEP, "shadow base: editor background at 45% brightness (always used with alpha)"),
    (TINT_ERROR, "error popup background: red mixed 16% into the chrome background"),
    (TINT_WARNING, "warning popup background: amber mixed 16% into the chrome background"),
    (TINT_INFO, "info popup background: blue mixed 16% into the chrome background"),
    (CHIP_ERROR_DIM, "offline / exception chip: red mixed 35% into the chrome background"),
    (CHIP_ERROR_DIM_HOVER, "offline chip hover: red mixed 45% into the chrome background"),
    (FIND_OPAQUE, "terminal current find match: amber mixed 30% into the terminal background"),
    (TEAL_DEEP, "working-border gradient stop: teal mixed 50% into the editor background"),
    (UNCOVERED_BRANCH, "uncovered-branch badge: red mixed 30% into the editor background"),
    (STRIP, "Modern UI connected tab strip: raised tone mixed 50% into the chrome background"),
])

# --------------------------------------------------------------------------
# Translucent layers (exact palette RGB plus alpha, so they stack)
# --------------------------------------------------------------------------
SEL = a(TEAL, 0.20)            # over #171c23 this composites to #224043 (target #223f44)
SEL_INACTIVE = a(TEAL, 0.12)
SEL_MATCH = a(TEAL, 0.10)
FIND = a(AMBER, 0.30)
FIND_OTHER = a(AMBER, 0.18)
WORD = a(MUTED, 0.18)
WORD_WRITE = a(BLUE, 0.20)
NEUTRAL_05 = a(MUTED, 0.05)
NEUTRAL_08 = a(MUTED, 0.08)
NEUTRAL_10 = a(MUTED, 0.10)
NEUTRAL_15 = a(MUTED, 0.15)
HOVER_ROW = a(BG2, 0.60)       # list hover: lighter touch than a selection
HOVER_ICON = a(MUTED, 0.18)    # toolbar buttons: must lighten any surface
ACTIVE_ICON = a(MUTED, 0.28)
DROP = a(TEAL, 0.12)
CLEAR = a(BG1, 0.0)            # fully transparent, without resorting to black

C = OrderedDict()


def put(group, entries):
    """Add a group of workbench colours, refusing duplicates."""
    for key, value in entries:
        if key in C:
            raise SystemExit("duplicate colour key in generator: %s (group %s)" % (key, group))
        C[key] = value


# ==========================================================================
# WORKBENCH COLOURS
# ==========================================================================
put("base", [
    ("foreground", FG),
    ("strongForeground", BRIGHT),
    ("disabledForeground", COMMENT),
    ("descriptionForeground", MUTED),
    ("errorForeground", RED),
    ("icon.foreground", MUTED),
    ("focusBorder", TEAL),
    ("selection.background", a(TEAL, 0.30)),
    ("widget.border", FRAME),
    ("widget.shadow", SHADOW),
    ("sash.hoverBorder", TEAL),
])

put("text", [
    ("textLink.foreground", TEAL),
    ("textLink.activeForeground", TEAL_B),
    ("textBlockQuote.background", a(BG2, 0.60)),
    ("textBlockQuote.border", FRAME),
    ("textCodeBlock.background", a(BG2, 0.60)),
    ("textPreformat.foreground", FG),
    ("textPreformat.background", a(BG2, 0.80)),
    ("textPreformat.border", a(FRAME, 0.60)),
    ("textSeparator.foreground", LINE),
])

put("buttons", [
    ("button.background", TEAL),
    ("button.foreground", ON_ACCENT),
    ("button.hoverBackground", TEAL_B),
    ("button.separator", a(ON_ACCENT, 0.35)),
    ("button.secondaryBackground", BG2),
    ("button.secondaryForeground", FG),
    ("button.secondaryHoverBackground", BG3),
    ("button.secondaryBorder", FRAME),
    ("extensionButton.background", BG2),
    ("extensionButton.foreground", FG),
    ("extensionButton.hoverBackground", BG3),
    ("extensionButton.border", FRAME),
    ("extensionButton.separator", a(FG, 0.25)),
    ("extensionButton.prominentBackground", TEAL),
    ("extensionButton.prominentForeground", ON_ACCENT),
    ("extensionButton.prominentHoverBackground", TEAL_B),
])

put("form controls", [
    ("input.background", BG2),
    ("input.foreground", FG),
    ("input.border", FRAME),
    ("input.placeholderForeground", MUTED),
    ("inputOption.activeBackground", a(TEAL, 0.20)),
    ("inputOption.activeBorder", a(TEAL, 0.60)),
    ("inputOption.activeForeground", BRIGHT),
    ("inputOption.hoverBackground", BG3),
    ("inputValidation.infoBackground", TINT_INFO),
    ("inputValidation.infoBorder", BLUE),
    ("inputValidation.infoForeground", FG),
    ("inputValidation.warningBackground", TINT_WARNING),
    ("inputValidation.warningBorder", AMBER),
    ("inputValidation.warningForeground", FG),
    ("inputValidation.errorBackground", TINT_ERROR),
    ("inputValidation.errorBorder", RED),
    ("inputValidation.errorForeground", FG),
    ("dropdown.background", BG2),
    ("dropdown.listBackground", BG1),
    ("dropdown.foreground", FG),
    ("dropdown.border", FRAME),
    ("checkbox.background", BG2),
    ("checkbox.foreground", TEAL),
    ("checkbox.border", FRAME),
    ("checkbox.selectBackground", BG1),
    ("checkbox.selectBorder", MUTED),
    ("checkbox.disabled.background", a(BG2, 0.50)),
    ("checkbox.disabled.foreground", COMMENT),
    ("radio.activeBackground", BG3),
    ("radio.activeForeground", BRIGHT),
    ("radio.activeBorder", TEAL),
    ("radio.inactiveBackground", BG1),
    ("radio.inactiveForeground", MUTED),
    ("radio.inactiveBorder", FRAME),
    ("radio.inactiveHoverBackground", BG2),
    ("actionBar.toggledBackground", a(TEAL, 0.20)),
    ("toolbar.hoverBackground", HOVER_ICON),
    ("toolbar.activeBackground", ACTIVE_ICON),
])

put("badges, progress, scrollbars", [
    ("badge.background", FRAME),
    ("badge.foreground", FG),
    ("progressBar.background", TEAL),
    ("scrollbar.shadow", SHADOW_SOFT),
    ("scrollbarSlider.background", a(MUTED, 0.20)),
    ("scrollbarSlider.hoverBackground", a(MUTED, 0.35)),
    ("scrollbarSlider.activeBackground", a(MUTED, 0.50)),
])

put("lists and trees", [
    ("list.hoverBackground", HOVER_ROW),
    ("list.hoverForeground", FG),
    ("list.activeSelectionBackground", BG3),
    ("list.activeSelectionForeground", BRIGHT),
    ("list.activeSelectionIconForeground", BRIGHT),
    ("list.inactiveSelectionBackground", BG2),
    ("list.inactiveSelectionForeground", FG),
    ("list.inactiveSelectionIconForeground", FG),
    ("list.focusBackground", BG2),
    ("list.focusForeground", FG),
    ("list.focusOutline", TEAL),
    ("list.focusAndSelectionOutline", a(TEAL, 0.50)),
    ("list.inactiveFocusOutline", FRAME),
    ("list.highlightForeground", TEAL),
    ("list.focusHighlightForeground", TEAL_B),
    ("list.dropBackground", a(TEAL, 0.15)),
    ("list.dropBetweenBackground", TEAL),
    ("list.deemphasizedForeground", MUTED),
    ("list.invalidItemForeground", RED),
    ("list.errorForeground", RED),
    ("list.warningForeground", AMBER),
    ("list.filterMatchBackground", a(AMBER, 0.25)),
    ("listFilterWidget.background", BG2),
    ("listFilterWidget.outline", a(TEAL, 0.0)),
    ("listFilterWidget.noMatchesOutline", RED),
    ("listFilterWidget.shadow", SHADOW),
    ("tree.indentGuidesStroke", FRAME),
    ("tree.inactiveIndentGuidesStroke", LINE),
    ("tree.tableColumnsBorder", LINE),
    ("tree.tableOddRowsBackground", NEUTRAL_05),
    ("keybindingTable.headerBackground", NEUTRAL_08),
    ("keybindingTable.rowsBackground", NEUTRAL_05),
])

put("activity bar", [
    ("activityBar.background", BG1),
    ("activityBar.foreground", FG),
    ("activityBar.inactiveForeground", MUTED),
    ("activityBar.border", BG1),
    ("activityBar.activeBorder", TEAL),
    ("activityBar.activeFocusBorder", TEAL),
    ("activityBar.dropBorder", TEAL),
    ("activityBarBadge.background", TEAL),
    ("activityBarBadge.foreground", ON_ACCENT),
    ("activityBarTop.background", BG1),
    ("activityBarTop.foreground", FG),
    ("activityBarTop.inactiveForeground", MUTED),
    ("activityBarTop.activeBorder", TEAL),
    ("activityBarTop.dropBorder", TEAL),
    ("activityWarningBadge.background", AMBER),
    ("activityWarningBadge.foreground", ON_ACCENT),
    ("activityErrorBadge.background", RED),
    ("activityErrorBadge.foreground", ON_ACCENT),
])

put("side bar", [
    ("sideBar.background", BG1),
    ("sideBar.foreground", FG),
    ("sideBar.border", LINE),
    ("sideBar.dropBackground", DROP),
    ("sideBarTitle.background", BG1),
    ("sideBarTitle.foreground", MUTED),
    ("sideBarSectionHeader.background", BG1),
    ("sideBarSectionHeader.foreground", FG),
    ("sideBarSectionHeader.border", LINE),
    ("sideBarActivityBarTop.border", LINE),
    ("sideBarStickyScroll.background", BG1),
    ("sideBarStickyScroll.border", LINE),
    ("sideBarStickyScroll.shadow", SHADOW_SOFT),
])

put("editor groups and tabs", [
    ("editorGroup.border", LINE),
    ("editorGroup.dropBackground", DROP),
    ("editorGroup.dropIntoPromptBackground", BG1),
    ("editorGroup.dropIntoPromptForeground", FG),
    ("editorGroup.dropIntoPromptBorder", FRAME),
    ("editorGroup.emptyBackground", BG0),
    ("editorGroup.focusedEmptyBorder", a(TEAL, 0.50)),
    ("editorGroupHeader.tabsBackground", BG1),
    ("editorGroupHeader.connectedTabsBackground", STRIP),
    ("editorGroupHeader.tabsBorder", LINE),
    ("editorGroupHeader.noTabsBackground", BG0),
    ("editorPane.background", BG0),
    ("sideBySideEditor.horizontalBorder", LINE),
    ("sideBySideEditor.verticalBorder", LINE),
    ("tab.activeBackground", BG0),
    ("tab.activeForeground", BRIGHT),
    ("tab.activeBorder", BG0),
    ("tab.activeBorderTop", TEAL),
    ("tab.inactiveBackground", BG1),
    ("tab.inactiveForeground", MUTED),
    ("tab.border", BG1),
    ("tab.lastPinnedBorder", LINE),
    ("tab.hoverBackground", BG2),
    ("tab.hoverForeground", FG),
    ("tab.unfocusedActiveBackground", BG0),
    ("tab.unfocusedActiveForeground", SOFT),
    ("tab.unfocusedActiveBorder", BG0),
    ("tab.unfocusedActiveBorderTop", FRAME),
    ("tab.unfocusedInactiveBackground", BG1),
    ("tab.unfocusedInactiveForeground", MUTED),
    ("tab.unfocusedHoverBackground", BG2),
    ("tab.unfocusedHoverForeground", FG),
    ("tab.activeModifiedBorder", AMBER),
    ("tab.inactiveModifiedBorder", a(AMBER, 0.50)),
    ("tab.unfocusedActiveModifiedBorder", a(AMBER, 0.50)),
    ("tab.unfocusedInactiveModifiedBorder", a(AMBER, 0.25)),
    ("tab.selectedBackground", BG0),
    ("tab.selectedForeground", FG),
    ("tab.selectedBorderTop", a(TEAL, 0.50)),
    ("tab.dragAndDropBorder", TEAL),
    ("tab.worktreeBorder", a(AMBER, 0.40)),
    ("browser.border", LINE),
])

put("breadcrumbs", [
    ("breadcrumb.background", BG0),
    ("breadcrumb.foreground", MUTED),
    ("breadcrumb.focusForeground", FG),
    ("breadcrumb.activeSelectionForeground", BRIGHT),
    ("breadcrumbPicker.background", BG1),
])

put("editor", [
    ("editor.background", BG0),
    ("editor.foreground", FG),
    ("editorLineNumber.foreground", LINENUM),
    ("editorLineNumber.activeForeground", FG),
    ("editorLineNumber.dimmedForeground", FRAME),
    ("editorCursor.foreground", TEAL),
    ("editorCursor.background", ON_ACCENT),
    ("editorMultiCursor.primary.foreground", TEAL),
    ("editorMultiCursor.primary.background", ON_ACCENT),
    ("editorMultiCursor.secondary.foreground", TEAL_B),
    ("editorMultiCursor.secondary.background", ON_ACCENT),
    ("editor.compositionBorder", TEAL),
    ("editor.placeholder.foreground", COMMENT),
    ("editorWatermark.foreground", COMMENT),
    # selection family (teal)
    ("editor.selectionBackground", SEL),
    ("editor.inactiveSelectionBackground", SEL_INACTIVE),
    ("editor.selectionHighlightBackground", SEL_MATCH),
    # current line
    ("editor.lineHighlightBackground", BG1),
    ("editor.inactiveLineHighlightBackground", a(BG1, 0.60)),
    # find family (amber)
    ("editor.findMatchBackground", FIND),
    ("editor.findMatchBorder", AMBER),
    ("editor.findMatchHighlightBackground", FIND_OTHER),
    ("editor.findRangeHighlightBackground", NEUTRAL_10),
    # occurrences
    ("editor.wordHighlightBackground", WORD),
    ("editor.wordHighlightStrongBackground", WORD_WRITE),
    ("editor.wordHighlightTextBackground", WORD),
    # ranges, hover, symbols
    ("editor.hoverHighlightBackground", NEUTRAL_15),
    ("editor.rangeHighlightBackground", NEUTRAL_10),
    ("editor.symbolHighlightBackground", a(AMBER, 0.15)),
    ("editor.linkedEditingBackground", a(PURPLE, 0.18)),
    ("editor.foldBackground", NEUTRAL_08),
    ("editor.foldPlaceholderForeground", COMMENT),
    ("editor.snippetTabstopHighlightBackground", a(MUTED, 0.20)),
    ("editor.snippetFinalTabstopHighlightBorder", FRAME),
    # debugging lines and inline values
    ("editor.stackFrameHighlightBackground", a(AMBER, 0.18)),
    ("editor.focusedStackFrameHighlightBackground", a(GREEN, 0.18)),
    ("editor.inlineValuesBackground", a(AMBER, 0.12)),
    ("editor.inlineValuesForeground", AMBER_B),
    # links, whitespace, guides, rulers
    ("editorLink.activeForeground", TEAL_B),
    ("editorWhitespace.foreground", a(DIM, 0.60)),
    ("editorWordWrapIndicator.foreground", a(DIM, 0.60)),
    ("editorRuler.foreground", LINE),
    ("editorCodeLens.foreground", COMMENT),
    ("editorGhostText.foreground", COMMENT),
    ("editorLightBulb.foreground", AMBER),
    ("editorLightBulbAutoFix.foreground", BLUE),
    ("editorLightBulbAi.foreground", PURPLE),
    ("editorUnnecessaryCode.opacity", a(BG0, 0.67)),
    ("editorUnicodeHighlight.border", AMBER),
    ("editorUnicodeHighlight.background", a(AMBER, 0.12)),
])

put("indent guides", [("editorIndentGuide.background%d" % i, LINE) for i in range(1, 7)]
    + [("editorIndentGuide.activeBackground%d" % i, FRAME) for i in range(1, 7)])

# Bracket pairs: cool to warm as nesting deepens.
BRACKETS = [BLUE, PURPLE, TEAL, GREEN, AMBER, RED_B]
put("brackets", [
    ("editorBracketMatch.background", a(TEAL, 0.14)),
    ("editorBracketMatch.border", a(TEAL, 0.55)),
] + [("editorBracketHighlight.foreground%d" % (i + 1), c) for i, c in enumerate(BRACKETS)]
  + [("editorBracketHighlight.unexpectedBracket.foreground", RED)]
  + [("editorBracketPairGuide.background%d" % (i + 1), a(c, 0.25)) for i, c in enumerate(BRACKETS)]
  + [("editorBracketPairGuide.activeBackground%d" % (i + 1), a(c, 0.65)) for i, c in enumerate(BRACKETS)])

put("inlay hints", [
    ("editorInlayHint.background", a(BG2, 0.60)),
    ("editorInlayHint.foreground", COMMENT),
    ("editorInlayHint.typeBackground", a(BG2, 0.60)),
    ("editorInlayHint.typeForeground", COMMENT),
    ("editorInlayHint.parameterBackground", a(BG2, 0.60)),
    ("editorInlayHint.parameterForeground", COMMENT),
])

put("diagnostics", [
    ("editorError.foreground", RED),
    ("editorWarning.foreground", AMBER),
    ("editorInfo.foreground", BLUE),
    ("editorHint.foreground", MUTED),
    ("problemsErrorIcon.foreground", RED),
    ("problemsWarningIcon.foreground", AMBER),
    ("problemsInfoIcon.foreground", BLUE),
    ("editorMarkerNavigation.background", BG1),
    ("editorMarkerNavigationError.background", RED),
    ("editorMarkerNavigationError.headerBackground", a(RED, 0.12)),
    ("editorMarkerNavigationWarning.background", AMBER),
    ("editorMarkerNavigationWarning.headerBackground", a(AMBER, 0.12)),
    ("editorMarkerNavigationInfo.background", BLUE),
    ("editorMarkerNavigationInfo.headerBackground", a(BLUE, 0.12)),
])

put("gutter", [
    ("editorGutter.background", BG0),
    ("editorGutter.addedBackground", GREEN),
    ("editorGutter.modifiedBackground", AMBER),
    ("editorGutter.deletedBackground", RED),
    ("editorGutter.addedSecondaryBackground", a(GREEN, 0.50)),
    ("editorGutter.modifiedSecondaryBackground", a(AMBER, 0.50)),
    ("editorGutter.deletedSecondaryBackground", a(RED, 0.50)),
    ("editorGutter.foldingControlForeground", MUTED),
    ("editorGutter.itemBackground", BG2),
    ("editorGutter.itemGlyphForeground", FG),
    ("editorGutter.commentRangeForeground", FRAME),
    ("editorGutter.commentGlyphForeground", FG),
    ("editorGutter.commentUnresolvedGlyphForeground", BLUE),
    ("editorGutter.commentDraftGlyphForeground", AMBER),
    ("git.blame.editorDecorationForeground", COMMENT),
])

put("overview ruler", [
    ("editorOverviewRuler.border", BG0),
    ("editorOverviewRuler.findMatchForeground", a(AMBER, 0.70)),
    ("editorOverviewRuler.rangeHighlightForeground", a(MUTED, 0.40)),
    ("editorOverviewRuler.selectionHighlightForeground", a(TEAL, 0.50)),
    ("editorOverviewRuler.wordHighlightForeground", a(MUTED, 0.60)),
    ("editorOverviewRuler.wordHighlightStrongForeground", a(BLUE, 0.60)),
    ("editorOverviewRuler.wordHighlightTextForeground", a(MUTED, 0.60)),
    ("editorOverviewRuler.bracketMatchForeground", a(MUTED, 0.50)),
    ("editorOverviewRuler.errorForeground", RED),
    ("editorOverviewRuler.warningForeground", AMBER),
    ("editorOverviewRuler.infoForeground", BLUE),
    ("editorOverviewRuler.addedForeground", a(GREEN, 0.80)),
    ("editorOverviewRuler.modifiedForeground", a(AMBER, 0.80)),
    ("editorOverviewRuler.deletedForeground", a(RED, 0.80)),
    ("editorOverviewRuler.currentContentForeground", a(TEAL, 0.60)),
    ("editorOverviewRuler.incomingContentForeground", a(BLUE, 0.60)),
    ("editorOverviewRuler.commonContentForeground", a(MUTED, 0.60)),
    ("editorOverviewRuler.commentForeground", a(BLUE, 0.50)),
    ("editorOverviewRuler.commentUnresolvedForeground", a(BLUE, 0.80)),
    ("editorOverviewRuler.commentDraftForeground", a(AMBER, 0.80)),
    ("editorOverviewRuler.inlineChatInserted", a(GREEN, 0.50)),
    ("editorOverviewRuler.inlineChatRemoved", a(RED, 0.50)),
    ("editorOverviewRuler.agentFeedbackForeground", PURPLE),
])

put("minimap", [
    ("minimap.background", BG0),
    ("minimap.foregroundOpacity", a(BG0, 0.85)),
    ("minimap.selectionHighlight", a(TEAL, 0.60)),
    ("minimap.selectionOccurrenceHighlight", a(TEAL, 0.35)),
    ("minimap.findMatchHighlight", a(AMBER, 0.70)),
    ("minimap.errorHighlight", RED),
    ("minimap.warningHighlight", AMBER),
    ("minimap.infoHighlight", BLUE),
    ("minimap.chatEditHighlight", a(BG0, 0.60)),
    ("minimapSlider.background", a(MUTED, 0.15)),
    ("minimapSlider.hoverBackground", a(MUTED, 0.25)),
    ("minimapSlider.activeBackground", a(MUTED, 0.35)),
    ("minimapGutter.addedBackground", GREEN),
    ("minimapGutter.modifiedBackground", AMBER),
    ("minimapGutter.deletedBackground", RED),
    ("editorMinimap.inlineChatInserted", a(GREEN, 0.40)),
])

put("editor widgets", [
    ("editorWidget.background", BG1),
    ("editorWidget.foreground", FG),
    ("editorWidget.border", FRAME),
    ("editorWidget.resizeBorder", TEAL),
    ("editorSuggestWidget.background", BG1),
    ("editorSuggestWidget.foreground", FG),
    ("editorSuggestWidget.border", FRAME),
    ("editorSuggestWidget.highlightForeground", TEAL),
    ("editorSuggestWidget.focusHighlightForeground", TEAL_B),
    ("editorSuggestWidget.selectedBackground", BG3),
    ("editorSuggestWidget.selectedForeground", BRIGHT),
    ("editorSuggestWidget.selectedIconForeground", BRIGHT),
    ("editorSuggestWidgetStatus.foreground", MUTED),
    ("editorHoverWidget.background", BG1),
    ("editorHoverWidget.foreground", FG),
    ("editorHoverWidget.border", FRAME),
    ("editorHoverWidget.highlightForeground", TEAL),
    ("editorHoverWidget.statusBarBackground", BG2),
    ("editorActionList.background", BG1),
    ("editorActionList.foreground", FG),
    ("editorActionList.focusBackground", BG3),
    ("editorActionList.focusForeground", BRIGHT),
    ("simpleFindWidget.sashBorder", FRAME),
])

put("sticky scroll", [
    ("editorStickyScroll.background", BG0),
    ("editorStickyScroll.border", LINE),
    ("editorStickyScroll.shadow", SHADOW_SOFT),
    ("editorStickyScrollHover.background", BG1),
    ("editorStickyScrollGutter.background", BG0),
])

put("peek view", [
    ("peekView.border", FRAME),
    ("peekViewTitle.background", BG2),
    ("peekViewTitleLabel.foreground", BRIGHT),
    ("peekViewTitleDescription.foreground", SOFT),
    ("peekViewEditor.background", BG1),
    ("peekViewEditorGutter.background", BG1),
    ("peekViewEditorStickyScroll.background", BG1),
    ("peekViewEditorStickyScrollGutter.background", BG1),
    ("peekViewEditor.matchHighlightBackground", a(AMBER, 0.25)),
    ("peekViewResult.background", BG1),
    ("peekViewResult.fileForeground", FG),
    ("peekViewResult.lineForeground", MUTED),
    ("peekViewResult.matchHighlightBackground", a(AMBER, 0.25)),
    ("peekViewResult.selectionBackground", BG3),
    ("peekViewResult.selectionForeground", BRIGHT),
])

put("diff editor", [
    ("diffEditor.insertedTextBackground", a(GREEN, 0.22)),
    ("diffEditor.removedTextBackground", a(RED, 0.22)),
    ("diffEditor.insertedLineBackground", a(GREEN, 0.12)),
    ("diffEditor.removedLineBackground", a(RED, 0.12)),
    ("diffEditorGutter.insertedLineBackground", a(GREEN, 0.18)),
    ("diffEditorGutter.removedLineBackground", a(RED, 0.18)),
    ("diffEditorOverview.insertedForeground", a(GREEN, 0.60)),
    ("diffEditorOverview.removedForeground", a(RED, 0.60)),
    ("diffEditor.border", LINE),
    ("diffEditor.diagonalFill", a(FRAME, 0.60)),
    ("diffEditor.unchangedRegionBackground", BG1),
    ("diffEditor.unchangedRegionForeground", MUTED),
    ("diffEditor.unchangedRegionShadow", SHADOW_SOFT),
    ("diffEditor.unchangedCodeBackground", NEUTRAL_08),
    ("diffEditor.move.border", a(MUTED, 0.50)),
    ("diffEditor.moveActive.border", AMBER),
    ("multiDiffEditor.background", BG0),
    ("multiDiffEditor.headerBackground", BG1),
    ("multiDiffEditor.border", LINE),
])

put("merge conflicts", [
    ("merge.currentHeaderBackground", a(TEAL, 0.35)),
    ("merge.currentContentBackground", a(TEAL, 0.14)),
    ("merge.incomingHeaderBackground", a(BLUE, 0.35)),
    ("merge.incomingContentBackground", a(BLUE, 0.14)),
    ("merge.commonHeaderBackground", a(MUTED, 0.30)),
    ("merge.commonContentBackground", a(MUTED, 0.12)),
    ("mergeEditor.change.background", a(GREEN, 0.12)),
    ("mergeEditor.change.word.background", a(GREEN, 0.22)),
    ("mergeEditor.changeBase.background", a(RED, 0.12)),
    ("mergeEditor.changeBase.word.background", a(RED, 0.22)),
    ("mergeEditor.conflict.unhandledUnfocused.border", a(AMBER, 0.50)),
    ("mergeEditor.conflict.unhandledFocused.border", AMBER),
    ("mergeEditor.conflict.handledUnfocused.border", a(MUTED, 0.30)),
    ("mergeEditor.conflict.handledFocused.border", a(MUTED, 0.80)),
    ("mergeEditor.conflict.handled.minimapOverViewRuler", a(MUTED, 0.90)),
    ("mergeEditor.conflict.unhandled.minimapOverViewRuler", AMBER),
    ("mergeEditor.conflictingLines.background", a(AMBER, 0.22)),
    ("mergeEditor.conflict.input1.background", a(TEAL, 0.20)),
    ("mergeEditor.conflict.input2.background", a(BLUE, 0.20)),
])

put("title bar and menus", [
    ("titleBar.activeBackground", BG1),
    ("titleBar.activeForeground", FG),
    ("titleBar.inactiveBackground", BG1),
    ("titleBar.inactiveForeground", MUTED),
    ("titleBar.border", LINE),
    ("menubar.selectionBackground", BG2),
    ("menubar.selectionForeground", FG),
    ("menu.background", BG1),
    ("menu.foreground", FG),
    ("menu.selectionBackground", BG3),
    ("menu.selectionForeground", BRIGHT),
    ("menu.separatorBackground", LINE),
    ("menu.border", FRAME),
    ("commandCenter.background", BG0),
    ("commandCenter.foreground", MUTED),
    ("commandCenter.border", LINE),
    ("commandCenter.activeBackground", BG2),
    ("commandCenter.activeForeground", FG),
    ("commandCenter.activeBorder", FRAME),
    ("commandCenter.inactiveForeground", COMMENT),
    ("commandCenter.inactiveBorder", LINE),
    ("commandCenter.debuggingBackground", a(AMBER, 0.15)),
    ("banner.background", BG2),
    ("banner.foreground", FG),
    ("banner.iconForeground", BLUE),
])

put("notifications", [
    ("notifications.background", BG1),
    ("notifications.foreground", FG),
    ("notifications.border", LINE),
    ("notificationCenter.border", FRAME),
    ("notificationToast.border", FRAME),
    ("notificationCenterHeader.background", BG2),
    ("notificationCenterHeader.foreground", FG),
    ("notificationLink.foreground", TEAL),
    ("notificationsErrorIcon.foreground", RED),
    ("notificationsWarningIcon.foreground", AMBER),
    ("notificationsInfoIcon.foreground", BLUE),
])

put("quick input", [
    ("quickInput.background", BG1),
    ("quickInput.foreground", FG),
    ("quickInputTitle.background", BG2),
    ("quickInputList.focusBackground", BG3),
    ("quickInputList.focusForeground", BRIGHT),
    ("quickInputList.focusIconForeground", BRIGHT),
    ("quickInputList.focusHighlightForeground", TEAL_B),
    ("pickerGroup.border", LINE),
    ("pickerGroup.foreground", TEAL),
    ("keybindingLabel.background", a(MUTED, 0.16)),
    ("keybindingLabel.foreground", FG),
    ("keybindingLabel.border", FRAME),
    ("keybindingLabel.bottomBorder", DIM),
])

put("panel", [
    ("panel.background", BG1),
    ("panel.border", LINE),
    ("panel.dropBorder", TEAL),
    ("panelTitle.activeForeground", FG),
    ("panelTitle.inactiveForeground", MUTED),
    ("panelTitle.activeBorder", TEAL),
    ("panelTitle.border", LINE),
    ("panelTitleBadge.background", FRAME),
    ("panelTitleBadge.foreground", FG),
    ("panelInput.border", FRAME),
    ("panelSection.border", LINE),
    ("panelSection.dropBackground", DROP),
    ("panelSectionHeader.background", BG1),
    ("panelSectionHeader.foreground", FG),
    ("panelSectionHeader.border", LINE),
    ("panelStickyScroll.background", BG1),
    ("panelStickyScroll.border", LINE),
    ("panelStickyScroll.shadow", SHADOW_SOFT),
    ("outputView.background", BG1),
    ("outputViewStickyScroll.background", BG1),
])

put("status bar", [
    ("statusBar.background", BG1),
    ("statusBar.foreground", MUTED),
    ("statusBar.border", LINE),
    ("statusBar.focusBorder", TEAL),
    ("statusBar.noFolderBackground", BG1),
    ("statusBar.noFolderForeground", MUTED),
    ("statusBar.noFolderBorder", LINE),
    ("statusBar.debuggingBackground", BG1),
    ("statusBar.debuggingForeground", AMBER),
    ("statusBar.debuggingBorder", AMBER),
    ("statusBarItem.hoverBackground", BG2),
    ("statusBarItem.hoverForeground", FG),
    ("statusBarItem.activeBackground", BG3),
    ("statusBarItem.compactHoverBackground", BG3),
    ("statusBarItem.focusBorder", TEAL),
    ("statusBarItem.prominentBackground", BG2),
    ("statusBarItem.prominentForeground", FG),
    ("statusBarItem.prominentHoverBackground", BG3),
    ("statusBarItem.prominentHoverForeground", BRIGHT),
    ("statusBarItem.remoteBackground", TEAL),
    ("statusBarItem.remoteForeground", ON_ACCENT),
    ("statusBarItem.remoteHoverBackground", TEAL_B),
    ("statusBarItem.remoteHoverForeground", ON_ACCENT),
    ("statusBarItem.errorBackground", RED),
    ("statusBarItem.errorForeground", ON_ACCENT),
    ("statusBarItem.errorHoverBackground", RED_B),
    ("statusBarItem.errorHoverForeground", ON_ACCENT),
    ("statusBarItem.warningBackground", AMBER),
    ("statusBarItem.warningForeground", ON_ACCENT),
    ("statusBarItem.warningHoverBackground", AMBER_B),
    ("statusBarItem.warningHoverForeground", ON_ACCENT),
    ("statusBarItem.offlineBackground", CHIP_ERROR_DIM),
    ("statusBarItem.offlineForeground", BRIGHT),
    ("statusBarItem.offlineHoverBackground", CHIP_ERROR_DIM_HOVER),
    ("statusBarItem.offlineHoverForeground", BRIGHT),
])

ANSI = [
    ("Black", BG2), ("Red", RED), ("Green", GREEN), ("Yellow", AMBER),
    ("Blue", BLUE), ("Magenta", PURPLE), ("Cyan", TEAL), ("White", SOFT),
    ("BrightBlack", DIM), ("BrightRed", RED_B), ("BrightGreen", GREEN_B),
    ("BrightYellow", AMBER_B), ("BrightBlue", BLUE_B), ("BrightMagenta", PURPLE_B),
    ("BrightCyan", TEAL_B), ("BrightWhite", BRIGHT),
]
put("terminal", [
    ("terminal.background", BG0),
    ("terminal.foreground", FG),
    ("terminal.border", LINE),
    ("terminal.selectionBackground", SEL),
    ("terminal.inactiveSelectionBackground", SEL_INACTIVE),
    ("terminal.findMatchBackground", FIND_OPAQUE),
    ("terminal.findMatchBorder", AMBER),
    ("terminal.findMatchHighlightBackground", FIND_OTHER),
    ("terminal.hoverHighlightBackground", NEUTRAL_15),
    ("terminal.dropBackground", DROP),
    ("terminal.initialHintForeground", COMMENT),
    ("terminal.tab.activeBorder", TEAL),
    ("terminalCursor.foreground", TEAL),
    ("terminalCursor.background", ON_ACCENT),
] + [("terminal.ansi%s" % name, value) for name, value in ANSI] + [
    ("terminalCommandDecoration.defaultBackground", COMMENT),
    ("terminalCommandDecoration.successBackground", GREEN),
    ("terminalCommandDecoration.errorBackground", RED),
    ("terminalCommandGuide.foreground", FRAME),
    ("terminalOverviewRuler.border", BG0),
    ("terminalOverviewRuler.cursorForeground", a(MUTED, 0.80)),
    ("terminalOverviewRuler.findMatchForeground", a(AMBER, 0.70)),
    ("terminalStickyScroll.background", BG0),
    ("terminalStickyScroll.border", LINE),
    ("terminalStickyScrollHover.background", BG1),
    ("terminalSymbolIcon.aliasForeground", BLUE),
    ("terminalSymbolIcon.methodForeground", BLUE),
    ("terminalSymbolIcon.argumentForeground", SOFT),
    ("terminalSymbolIcon.optionForeground", AMBER),
    ("terminalSymbolIcon.optionValueForeground", GREEN),
    ("terminalSymbolIcon.flagForeground", AMBER),
    ("terminalSymbolIcon.fileForeground", SOFT),
    ("terminalSymbolIcon.folderForeground", BLUE),
    ("terminalSymbolIcon.symbolicLinkFileForeground", TEAL_B),
    ("terminalSymbolIcon.symbolicLinkFolderForeground", TEAL_B),
    ("terminalSymbolIcon.inlineSuggestionForeground", TEAL),
    ("terminalSymbolIcon.symbolText", FG),
    ("terminalSymbolIcon.branchForeground", PURPLE),
    ("terminalSymbolIcon.commitForeground", AMBER),
    ("terminalSymbolIcon.remoteForeground", TEAL),
    ("terminalSymbolIcon.stashForeground", MUTED),
    ("terminalSymbolIcon.tagForeground", AMBER),
    ("terminalSymbolIcon.pullRequestForeground", GREEN),
    ("terminalSymbolIcon.pullRequestDoneForeground", PURPLE),
])

put("debug", [
    ("debugToolBar.background", BG1),
    ("debugToolBar.border", FRAME),
    ("debugIcon.breakpointForeground", RED),
    ("debugIcon.breakpointDisabledForeground", COMMENT),
    ("debugIcon.breakpointUnverifiedForeground", MUTED),
    ("debugIcon.breakpointCurrentStackframeForeground", AMBER),
    ("debugIcon.breakpointStackframeForeground", GREEN),
    ("debugIcon.startForeground", GREEN),
    ("debugIcon.continueForeground", BLUE),
    ("debugIcon.pauseForeground", BLUE),
    ("debugIcon.stopForeground", RED),
    ("debugIcon.disconnectForeground", RED),
    ("debugIcon.restartForeground", GREEN),
    ("debugIcon.stepOverForeground", BLUE),
    ("debugIcon.stepIntoForeground", BLUE),
    ("debugIcon.stepOutForeground", BLUE),
    ("debugIcon.stepBackForeground", BLUE),
    ("debugConsole.infoForeground", BLUE),
    ("debugConsole.warningForeground", AMBER),
    ("debugConsole.errorForeground", RED),
    ("debugConsole.sourceForeground", MUTED),
    ("debugConsoleInputIcon.foreground", TEAL),
    ("debugExceptionWidget.background", TINT_ERROR),
    ("debugExceptionWidget.border", RED),
    ("debugTokenExpression.name", SOFT),
    ("debugTokenExpression.type", TEAL),
    ("debugTokenExpression.value", FG),
    ("debugTokenExpression.string", GREEN),
    ("debugTokenExpression.number", AMBER),
    ("debugTokenExpression.boolean", AMBER),
    ("debugTokenExpression.error", RED),
    ("debugView.exceptionLabelBackground", CHIP_ERROR_DIM),
    ("debugView.exceptionLabelForeground", BRIGHT),
    ("debugView.stateLabelBackground", a(MUTED, 0.25)),
    ("debugView.stateLabelForeground", FG),
    ("debugView.valueChangedHighlight", a(BLUE, 0.35)),
])

put("testing", [
    ("testing.iconPassed", GREEN),
    ("testing.iconFailed", RED),
    ("testing.iconErrored", RED),
    ("testing.iconQueued", AMBER),
    ("testing.iconSkipped", MUTED),
    ("testing.iconUnset", MUTED),
    ("testing.iconPassed.retired", a(GREEN, 0.70)),
    ("testing.iconFailed.retired", a(RED, 0.70)),
    ("testing.iconErrored.retired", a(RED, 0.70)),
    ("testing.iconQueued.retired", a(AMBER, 0.70)),
    ("testing.iconSkipped.retired", a(MUTED, 0.70)),
    ("testing.iconUnset.retired", a(MUTED, 0.70)),
    ("testing.runAction", GREEN),
    ("testing.peekBorder", RED),
    ("testing.peekHeaderBackground", a(RED, 0.12)),
    ("testing.messagePeekBorder", BLUE),
    ("testing.messagePeekHeaderBackground", a(BLUE, 0.12)),
    ("testing.message.error.badgeBackground", RED),
    ("testing.message.error.badgeBorder", RED),
    ("testing.message.error.badgeForeground", ON_ACCENT),
    ("testing.message.error.lineBackground", a(RED, 0.10)),
    ("testing.message.info.decorationForeground", COMMENT),
    ("testing.coveredBackground", a(GREEN, 0.14)),
    ("testing.coveredBorder", a(GREEN, 0.35)),
    ("testing.coveredGutterBackground", a(GREEN, 0.50)),
    ("testing.coveredMinimapBackground", a(GREEN, 0.50)),
    ("testing.uncoveredBackground", a(RED, 0.14)),
    ("testing.uncoveredBorder", a(RED, 0.35)),
    ("testing.uncoveredGutterBackground", a(RED, 0.50)),
    ("testing.uncoveredMinimapBackground", a(RED, 0.50)),
    ("testing.uncoveredBranchBackground", UNCOVERED_BRANCH),
    ("testing.coverCountBadgeBackground", FRAME),
    ("testing.coverCountBadgeForeground", FG),
])

put("git decorations", [
    ("gitDecoration.addedResourceForeground", GREEN),
    ("gitDecoration.untrackedResourceForeground", GREEN),
    ("gitDecoration.modifiedResourceForeground", AMBER),
    ("gitDecoration.stageModifiedResourceForeground", AMBER),
    ("gitDecoration.deletedResourceForeground", RED),
    ("gitDecoration.stageDeletedResourceForeground", RED),
    ("gitDecoration.renamedResourceForeground", BLUE),
    ("gitDecoration.conflictingResourceForeground", PURPLE),
    ("gitDecoration.ignoredResourceForeground", COMMENT),
    ("gitDecoration.submoduleResourceForeground", BLUE_B),
])

put("source control graph", [
    ("scmGraph.historyItemRefColor", BLUE),
    ("scmGraph.historyItemRemoteRefColor", PURPLE),
    ("scmGraph.historyItemBaseRefColor", AMBER),
    ("scmGraph.foreground1", TEAL),
    ("scmGraph.foreground2", GREEN),
    ("scmGraph.foreground3", RED),
    ("scmGraph.foreground4", PURPLE_B),
    ("scmGraph.foreground5", BLUE_B),
    ("scmGraph.historyItemHoverLabelForeground", ON_ACCENT),
    ("scmGraph.historyItemHoverDefaultLabelBackground", FRAME),
    ("scmGraph.historyItemHoverDefaultLabelForeground", FG),
    ("scmGraph.historyItemHoverAdditionsForeground", GREEN),
    ("scmGraph.historyItemHoverDeletionsForeground", RED),
])

put("settings editor", [
    ("settings.headerForeground", BRIGHT),
    ("settings.settingsHeaderHoverForeground", FG),
    ("settings.modifiedItemIndicator", AMBER),
    ("settings.headerBorder", LINE),
    ("settings.sashBorder", LINE),
    ("settings.dropdownBackground", BG2),
    ("settings.dropdownForeground", FG),
    ("settings.dropdownBorder", FRAME),
    ("settings.dropdownListBorder", FRAME),
    ("settings.checkboxBackground", BG2),
    ("settings.checkboxForeground", TEAL),
    ("settings.checkboxBorder", FRAME),
    ("settings.textInputBackground", BG2),
    ("settings.textInputForeground", FG),
    ("settings.textInputBorder", FRAME),
    ("settings.numberInputBackground", BG2),
    ("settings.numberInputForeground", FG),
    ("settings.numberInputBorder", FRAME),
    ("settings.rowHoverBackground", NEUTRAL_05),
    ("settings.focusedRowBackground", NEUTRAL_08),
    ("settings.focusedRowBorder", a(TEAL, 0.50)),
])

put("welcome page and walkthroughs", [
    ("welcomePage.background", BG0),
    ("welcomePage.tileBackground", BG1),
    ("welcomePage.tileHoverBackground", BG2),
    ("welcomePage.tileBorder", LINE),
    ("welcomePage.progress.background", BG2),
    ("welcomePage.progress.foreground", TEAL),
    ("walkThrough.embeddedEditorBackground", BG1),
    ("walkthrough.stepTitle.foreground", BRIGHT),
])

put("charts", [
    ("charts.foreground", FG),
    ("charts.lines", a(MUTED, 0.50)),
    ("charts.red", RED),
    ("charts.orange", AMBER_B),
    ("charts.yellow", AMBER),
    ("charts.green", GREEN),
    ("charts.blue", BLUE),
    ("charts.purple", PURPLE),
    ("chart.line", BLUE),
    ("chart.axis", a(MUTED, 0.50)),
    ("chart.guide", a(MUTED, 0.25)),
    ("gauge.background", a(TEAL, 0.25)),
    ("gauge.foreground", TEAL),
    ("gauge.warningBackground", a(AMBER, 0.25)),
    ("gauge.warningForeground", AMBER),
    ("gauge.errorBackground", a(RED, 0.25)),
    ("gauge.errorForeground", RED),
])

put("symbol icons", [
    ("symbolIcon.arrayForeground", FG),
    ("symbolIcon.booleanForeground", AMBER),
    ("symbolIcon.classForeground", TEAL),
    ("symbolIcon.colorForeground", FG),
    ("symbolIcon.constantForeground", AMBER),
    ("symbolIcon.constructorForeground", BLUE),
    ("symbolIcon.enumeratorForeground", TEAL),
    ("symbolIcon.enumeratorMemberForeground", AMBER),
    ("symbolIcon.eventForeground", AMBER),
    ("symbolIcon.fieldForeground", SOFT),
    ("symbolIcon.fileForeground", FG),
    ("symbolIcon.folderForeground", FG),
    ("symbolIcon.functionForeground", BLUE),
    ("symbolIcon.interfaceForeground", TEAL),
    ("symbolIcon.keyForeground", BLUE),
    ("symbolIcon.keywordForeground", PURPLE),
    ("symbolIcon.methodForeground", BLUE),
    ("symbolIcon.moduleForeground", TEAL),
    ("symbolIcon.namespaceForeground", TEAL),
    ("symbolIcon.nullForeground", AMBER),
    ("symbolIcon.numberForeground", AMBER),
    ("symbolIcon.objectForeground", FG),
    ("symbolIcon.operatorForeground", MUTED),
    ("symbolIcon.packageForeground", TEAL),
    ("symbolIcon.propertyForeground", SOFT),
    ("symbolIcon.referenceForeground", FG),
    ("symbolIcon.snippetForeground", MUTED),
    ("symbolIcon.stringForeground", GREEN),
    ("symbolIcon.structForeground", TEAL),
    ("symbolIcon.textForeground", FG),
    ("symbolIcon.typeParameterForeground", TEAL),
    ("symbolIcon.unitForeground", PURPLE),
    ("symbolIcon.variableForeground", FG),
])

put("notebooks", [
    ("notebook.editorBackground", BG0),
    ("notebook.cellEditorBackground", BG1),
    ("notebook.cellBorderColor", LINE),
    ("notebook.cellHoverBackground", a(BG1, 0.60)),
    ("notebook.focusedCellBackground", a(BG1, 0.60)),
    ("notebook.selectedCellBackground", a(BG2, 0.40)),
    ("notebook.focusedCellBorder", TEAL),
    ("notebook.focusedEditorBorder", TEAL),
    ("notebook.inactiveFocusedCellBorder", FRAME),
    ("notebook.selectedCellBorder", FRAME),
    ("notebook.inactiveSelectedCellBorder", LINE),
    ("notebook.cellInsertionIndicator", TEAL),
    ("notebook.cellStatusBarItemHoverBackground", HOVER_ICON),
    ("notebook.cellToolbarSeparator", LINE),
    ("notebook.symbolHighlightBackground", NEUTRAL_08),
    ("notebookStatusSuccessIcon.foreground", GREEN),
    ("notebookStatusErrorIcon.foreground", RED),
    ("notebookStatusRunningIcon.foreground", FG),
    ("notebookScrollbarSlider.background", a(MUTED, 0.20)),
    ("notebookScrollbarSlider.hoverBackground", a(MUTED, 0.35)),
    ("notebookScrollbarSlider.activeBackground", a(MUTED, 0.50)),
    ("notebookEditorOverviewRuler.runningCellForeground", GREEN),
    ("interactive.activeCodeBorder", a(TEAL, 0.60)),
    ("interactive.inactiveCodeBorder", FRAME),
])

put("comments", [
    ("commentsView.resolvedIcon", COMMENT),
    ("commentsView.unresolvedIcon", BLUE),
    ("editorCommentsWidget.resolvedBorder", FRAME),
    ("editorCommentsWidget.unresolvedBorder", BLUE),
    ("editorCommentsWidget.rangeBackground", a(BLUE, 0.10)),
    ("editorCommentsWidget.rangeActiveBackground", a(BLUE, 0.18)),
    ("editorCommentsWidget.replyInputBackground", BG2),
])

put("chat", [
    ("chat.requestBackground", a(BG0, 0.62)),
    ("chat.requestBorder", LINE),
    # translucent on purpose: over the chat surface these land on the raised / active tones
    ("chat.requestBubbleBackground", NEUTRAL_10),
    ("chat.requestBubbleHoverBackground", a(MUTED, 0.20)),
    ("chat.requestCodeBorder", a(MUTED, 0.30)),
    ("chat.slashCommandBackground", a(TEAL, 0.15)),
    ("chat.slashCommandForeground", TEAL_B),
    ("chat.avatarBackground", BG2),
    ("chat.avatarForeground", FG),
    ("chat.editedFileForeground", AMBER),
    ("chat.linesAddedForeground", GREEN),
    ("chat.linesRemovedForeground", RED),
    ("chat.checkpointSeparator", FRAME),
    ("chat.statusBackground", BG2),
    ("chat.thinkingShimmer", BRIGHT),
    ("chat.inputWorkingBorderColor1", TEAL),
    ("chat.inputWorkingBorderColor2", TEAL_B),
    ("chat.inputWorkingBorderColor3", TEAL_DEEP),
    ("chat.findMatchBackground", FIND),
    ("chat.findMatchHighlightBackground", FIND_OTHER),
    ("chat.mcpCompatibilityWarningForeground", AMBER),
    ("chat.sessionStateIndicator.inProgressBorder", AMBER),
    ("chat.sessionStateIndicator.needsInputBorder", RED),
    ("chat.sessionStateIndicator.unvisitedBorder", GREEN),
    ("chat.workingProgressStableIconForeground", TEAL),
    ("chat.workingProgressInsidersIconForeground", TEAL),
    ("chat.voiceGlowBaseColor", TEAL),
    ("chat.dictationActiveMicGlow", TEAL),
    ("inlineChat.background", BG1),
    ("inlineChat.foreground", FG),
    ("inlineChat.border", FRAME),
    ("inlineChat.shadow", SHADOW),
    ("inlineChatInput.background", BG2),
    ("inlineChatInput.border", FRAME),
    ("inlineChatInput.focusBorder", TEAL),
    ("inlineChatInput.placeholderForeground", MUTED),
    ("inlineChatDiff.inserted", a(GREEN, 0.15)),
    ("inlineChatDiff.removed", a(RED, 0.15)),
])

put("inline edits", [
    ("inlineEdit.gutterIndicator.background", a(BG1, 0.50)),
    ("inlineEdit.gutterIndicator.primaryBackground", a(TEAL, 0.40)),
    ("inlineEdit.gutterIndicator.primaryBorder", TEAL),
    ("inlineEdit.gutterIndicator.primaryForeground", BRIGHT),
    ("inlineEdit.gutterIndicator.secondaryBackground", BG2),
    ("inlineEdit.gutterIndicator.secondaryBorder", FRAME),
    ("inlineEdit.gutterIndicator.secondaryForeground", FG),
    ("inlineEdit.gutterIndicator.successfulBackground", GREEN),
    ("inlineEdit.gutterIndicator.successfulBorder", GREEN),
    ("inlineEdit.gutterIndicator.successfulForeground", ON_ACCENT),
    ("inlineEdit.modifiedBackground", a(GREEN, 0.08)),
    ("inlineEdit.modifiedBorder", a(GREEN, 0.30)),
    ("inlineEdit.modifiedChangedLineBackground", a(GREEN, 0.10)),
    ("inlineEdit.modifiedChangedTextBackground", a(GREEN, 0.22)),
    ("inlineEdit.originalBackground", a(RED, 0.08)),
    ("inlineEdit.originalBorder", a(RED, 0.30)),
    ("inlineEdit.originalChangedLineBackground", a(RED, 0.10)),
    ("inlineEdit.originalChangedTextBackground", a(RED, 0.22)),
    ("inlineEdit.tabWillAcceptModifiedBorder", a(GREEN, 0.50)),
    ("inlineEdit.tabWillAcceptOriginalBorder", a(RED, 0.50)),
])

put("extensions and profiles", [
    ("extensionBadge.remoteBackground", TEAL),
    ("extensionBadge.remoteForeground", ON_ACCENT),
    ("extensionIcon.starForeground", AMBER),
    ("extensionIcon.verifiedForeground", BLUE),
    ("extensionIcon.preReleaseForeground", TEAL),
    ("extensionIcon.sponsorForeground", RED),
    ("extensionIcon.privateForeground", MUTED),
    ("mcpIcon.starForeground", AMBER),
    ("profileBadge.background", FRAME),
    ("profileBadge.foreground", FG),
    ("profiles.sashBorder", LINE),
    ("ports.iconRunningProcessForeground", GREEN),
])

put("search", [
    ("search.resultsInfoForeground", MUTED),
    ("searchEditor.findMatchBackground", FIND_OTHER),
    ("searchEditor.findMatchBorder", a(AMBER, 0.40)),
    ("searchEditor.textInputBorder", FRAME),
])

put("markdown alerts", [
    ("markdownAlert.note.foreground", BLUE),
    ("markdownAlert.tip.foreground", GREEN),
    ("markdownAlert.important.foreground", PURPLE),
    ("markdownAlert.warning.foreground", AMBER),
    ("markdownAlert.caution.foreground", RED),
])

# --- VS Code 1.14x "Modern UI" (workbench.experimental.modernUI, on by default) ---
# Shell = title bar colour; side bar / panel / editor float on it as cards.
# This layout replaces the accent lines of the classic layout (tab top border,
# activity bar bar, panel underline) with pills, so the active pill carries
# the accent instead: the palette's teal-tinted selection tone.
put("modern ui", [
    ("modernUI.shellBackground", BG1),
    ("modernUI.inactiveShellBackground", BG1),
    ("surface.background", BG1),
    ("surface.foreground", FG),
    ("surface.border", LINE),
    ("editor.border", LINE),
    ("modernPanel.border", LINE),
    ("modernSash.gripForeground", DIM),
    ("modernTab.activeBackground", SELECTION),
    ("modernTab.activeForeground", BRIGHT),
    ("modernTab.hoverBackground", BG2),
    ("modernTab.hoverForeground", FG),
    ("modernEditorTab.activeBackground", SELECTION),
    ("modernEditorTab.activeForeground", BRIGHT),
    ("modernEditorTab.inactiveBackground", a(BG0, 0.0)),
    ("modernEditorTab.hoverBackground", BG2),
    ("modernEditorTab.hoverForeground", FG),
    ("modernEditorTab.activeHoverBackground", SELECTION),
    ("modernEditorTab.activeActionBackground", SELECTION),
    ("modernEditorTab.hoverActionBackground", BG2),
    ("modernEditorTab.activeHoverActionBackground", SELECTION),
    ("modernEditorTab.selectedActionBackground", BG0),
    ("modernActivityBar.background", BG1),
    ("modernActivityBar.inactiveBackground", BG1),
    ("modernActivityBar.border", LINE),
    ("modernActivityBarItem.activeBackground", SELECTION),
    ("modernActivityBarItem.activeForeground", BRIGHT),
    ("modernActivityBarItem.hoverBackground", BG2),
    ("modernActivityBarItem.hoverForeground", FG),
])

put("agents", [
    ("agents.background", BG0),
    ("agentsDetail.background", BG0),
    ("agentsPanel.background", BG1),
    ("agentsPanel.foreground", FG),
    ("agentsPanel.border", LINE),
    ("agentsCard.border", LINE),
    ("agentsBottomPanel.border", LINE),
    ("agentsChatInput.background", BG2),
    ("agentsChatInput.foreground", FG),
    ("agentsChatInput.border", FRAME),
    ("agentsChatInput.focusBorder", TEAL),
    ("agentsChatInput.placeholderForeground", MUTED),
    ("agentsBadge.background", TEAL),
    ("agentsBadge.foreground", ON_ACCENT),
    ("agentsUnreadBadge.background", TEAL),
    ("agentsUnreadBadge.foreground", ON_ACCENT),
    ("agentsGradient.tintColor", TEAL),
    ("agentsNewSessionButton.background", CLEAR),
    ("agentsNewSessionButton.foreground", FG),
    ("agentsNewSessionButton.border", FRAME),
    ("agentsNewSessionButton.hoverBackground", BG2),
    ("agentsUpdateButton.downloadedBackground", a(TEAL, 0.70)),
    ("agentsUpdateButton.downloadingBackground", a(TEAL, 0.40)),
    ("agentsVoice.speakingBackground", a(PURPLE, 0.08)),
    ("agentsVoice.speakingForeground", PURPLE),
    ("agentsMobileDiff.addedForeground", GREEN),
    ("agentsMobileDiff.modifiedForeground", AMBER),
    ("agentsMobileDiff.deletedForeground", RED),
    ("agentSessionReadIndicator.foreground", DIM),
    ("agentSessionSelectedBadge.border", a(BRIGHT, 0.30)),
    ("agentSessionSelectedUnfocusedBadge.border", a(FG, 0.30)),
    ("agentStatusIndicator.background", BG2),
    ("agentFeedbackEditorWidget.background", BG2),
    ("agentFeedbackEditorWidget.border", FRAME),
    ("agentFeedbackInputWidget.border", FRAME),
    ("activeSessionView.background", BG1),
    ("activeSessionView.foreground", FG),
    ("inactiveSessionView.background", BG0),
    ("inactiveSessionView.foreground", FG),
])

# ==========================================================================
# SYNTAX: one role table drives both TextMate rules and semantic tokens
# ==========================================================================
ROLE = OrderedDict([
    ("text", FG), ("comment", COMMENT), ("keyword", PURPLE), ("function", BLUE),
    ("type", TEAL), ("string", GREEN), ("escape", TEAL_B), ("constant", AMBER),
    ("variable", FG), ("parameter", FG), ("property", SOFT), ("punctuation", MUTED),
    ("tag", RED), ("attribute", AMBER), ("decorator", AMBER), ("key", BLUE),
    ("heading", BLUE), ("link", TEAL), ("invalid", RED), ("inserted", GREEN),
    ("deleted", RED), ("changed", AMBER),
])

T = []       # TextMate rules
_seen_scopes = {}


def tm(name, scopes, foreground=None, style=None):
    for s in scopes:
        if s in _seen_scopes:
            raise SystemExit("duplicate TextMate scope %r in %r and %r" % (s, _seen_scopes[s], name))
        _seen_scopes[s] = name
    settings = OrderedDict()
    if foreground is not None:
        settings["foreground"] = foreground
    if style is not None:
        settings["fontStyle"] = style
    T.append(OrderedDict([("name", name), ("scope", list(scopes)), ("settings", settings)]))


# --- text ------------------------------------------------------------------
tm("Embedded source falls back to plain text", [
    "meta.embedded",
    "source.groovy.embedded",
    "meta.template.expression",
    "string meta.image.inline.markdown",
    "variable.legacy.builtin.python",
], ROLE["text"], "")

# --- comments --------------------------------------------------------------
tm("Comments", [
    "comment",
    "punctuation.definition.comment",
    "string.comment",
], ROLE["comment"], "italic")
tm("Docstrings read as documentation", [
    "string.quoted.docstring",
    "string.quoted.docstring punctuation.definition.string",
], ROLE["comment"], "italic")
tm("Doc comment tags", [
    "storage.type.class.jsdoc",
    "punctuation.definition.block.tag.jsdoc",
    "comment keyword.other.documentation",
    "comment storage.type.class",
], ROLE["keyword"])
tm("Doc comment types", [
    "entity.name.type.instance.jsdoc",
    "comment.block.documentation entity.name.type",
], ROLE["type"])
tm("Doc comment parameter names", [
    "variable.other.jsdoc",
    "comment.block.documentation variable.parameter",
], MUTED)

# --- keywords, storage, modifiers -----------------------------------------
tm("Keywords, storage, control flow, import and export, modifiers", [
    "keyword",
    "storage",
    "punctuation.definition.keyword",
], ROLE["keyword"])
tm("Preprocessor directives (as in the bat, Kate and Neovim themes)", [
    "keyword.control.directive",
    "punctuation.definition.directive",
], AMBER)
tm("Word operators are keywords", [
    "keyword.operator.new",
    "keyword.operator.delete",
    "keyword.operator.expression",
    "keyword.operator.instanceof",
    "keyword.operator.type.asserts",
    "keyword.operator.sizeof",
    "keyword.operator.alignof",
    "keyword.operator.alignas",
    "keyword.operator.typeid",
    "keyword.operator.noexcept",
    "keyword.operator.cast",
    "keyword.operator.wordlike",
    "keyword.operator.functionlike",
    "keyword.operator.logical.python",
    "source.css keyword.operator.logical",
    "source.css keyword.operator.gradient",
    "source.css keyword.operator.shape",
    "source.css.scss keyword.operator.logical",
    "source.css.less keyword.operator.logical",
], ROLE["keyword"])
tm("Language variables (this, self, super)", [
    "variable.language",
    "variable.language punctuation.definition.variable",
    "variable.parameter.function.language.special",
], ROLE["keyword"], "italic")

# --- operators and punctuation --------------------------------------------
tm("Operators", [
    "keyword.operator",
    "storage.modifier.pointer",
    "storage.modifier.reference",
], ROLE["punctuation"])
tm("Punctuation", [
    "punctuation",
    "meta.brace",
    "meta.delimiter",
    "entity.other.document.begin.yaml",
    "entity.other.document.end.yaml",
], ROLE["punctuation"])
tm("Glob quantifiers", [
    "variable.language.special.quantifier",
], ROLE["punctuation"], "")
tm("Interpolation delimiters", [
    "punctuation.definition.template-expression",
    "punctuation.section.embedded",
    "punctuation.definition.interpolation",
    "punctuation.section.interpolation",
], ROLE["keyword"])

# --- functions -------------------------------------------------------------
tm("Functions, methods, calls", [
    "entity.name.function",
    "entity.name.method",
    "entity.name.operator",
    "support.function",
    "variable.function",
    "meta.function-call.generic",
    "entity.name.function-call",
    "entity.name.command",
], ROLE["function"])

# --- types -----------------------------------------------------------------
tm("Types, classes, interfaces, enums, namespaces, components", [
    "entity.name.type",
    "entity.name.class",
    "entity.name.struct",
    "entity.name.enum",
    "entity.name.interface",
    "entity.name.namespace",
    "entity.name.scope-resolution",
    "entity.other.inherited-class",
    "support.class",
    "support.type",
    "new.expr entity.name.function",
], ROLE["type"])
tm("Built-in types", [
    "storage.type.built-in",
    "storage.type.primitive",
    "storage.type.integral",
    "storage.type.numeric.go",
    "storage.type.string.go",
    "storage.type.boolean.go",
    "storage.type.byte.go",
    "storage.type.rune.go",
    "storage.type.uintptr.go",
    "storage.type.error.go",
    "storage.type.sql",
    "storage.type.java",
    "storage.type.generic.java",
    "storage.type.object.array.java",
    "source.cs keyword.type",
    "keyword.other.type.php",
], ROLE["type"])

# --- strings ---------------------------------------------------------------
tm("Strings", [
    "string",
    "punctuation.definition.string",
    "string.other.link.description.title",
], ROLE["string"])
tm("Unquoted URLs", [
    "variable.parameter.url",
], ROLE["string"], "")
tm("Escapes, placeholders, regular expressions", [
    "constant.character.escape",
    "constant.other.placeholder",
    "constant.character.format.placeholder",
    "storage.type.format",
    "constant.character.entity",
    "constant.character.entity punctuation.definition.entity",
    "string.regexp",
    "source.regexp",
    "string.regexp punctuation.definition.string",
    "string.regexp punctuation",
    "string.regexp keyword",
    "string.regexp keyword.operator",
    "string.regexp constant",
    "string.regexp support",
    "string.regexp variable",
    "string.regexp entity",
], ROLE["escape"])

# --- constants -------------------------------------------------------------
tm("Numbers, booleans, null, language constants, enum members", [
    "constant",
    "support.constant",
    "variable.other.enummember",
    "meta.delimiter.decimal",
    "punctuation.definition.constant",
    "storage.type.number",
    "storage.type.imaginary",
    "source.c keyword.other.unit",
    "source.cpp keyword.other.unit",
    "source.cuda-cpp keyword.other.unit",
    "source.objc keyword.other.unit",
    "source.objcpp keyword.other.unit",
], ROLE["constant"])

# --- variables, parameters, properties ------------------------------------
tm("Variables", [
    "variable",
    "constant.other.caps",
    "support.variable",
    "punctuation.definition.variable",
    "entity.name.label",
    "entity.name.variable",
    "support.constant.math",
    "support.constant.json",
    "support.class.console",
    "support.type.object.module",
    "storage.modifier.import",
    "storage.modifier.package",
    "string.unquoted.argument",
    "string.unquoted.shell",
    "constant.other.table-name",
    "constant.other.database-name",
], ROLE["variable"])
tm("Parameters", [
    "variable.parameter",
    "entity.name.variable.parameter",
], ROLE["parameter"], "italic")
tm("Stylesheet identifiers are not parameters", [
    "source.css variable.parameter",
    "source.css.scss variable.parameter",
    "source.css.less variable.parameter",
], ROLE["variable"], "")
tm("Object properties and fields", [
    "variable.other.property",
    "variable.other.object.property",
    "variable.other.constant.property",
    "variable.other.member",
    "variable.other.field",
    "variable.object.property",
    "support.variable.property",
    "meta.object-literal.key",
    "meta.attribute.python",
    "entity.name.variable.field",
    "entity.name.variable.property",
    "entity.name.function.call.initializer",
], ROLE["property"])

# --- markup tags and attributes -------------------------------------------
tm("HTML, XML and JSX tag names", [
    "entity.name.tag",
], ROLE["tag"])
tm("HTML, XML and JSX attribute names", [
    "entity.other.attribute-name",
], ROLE["attribute"])

# --- decorators ------------------------------------------------------------
tm("Decorators and annotations", [
    "meta.decorator entity.name.function",
    "punctuation.decorator",
    "punctuation.definition.decorator",
    "entity.name.function.decorator",
    "meta.function.decorator support.type",
    "meta.function.decorator support.function",
    "storage.type.annotation",
    "punctuation.definition.annotation",
    "meta.annotation entity.name.function",
    "meta.attribute.rust",
    "support.other.attribute",
], ROLE["decorator"])
tm("Types inside decorator arguments", [
    "meta.function.decorator meta.function-call.arguments support.type",
], ROLE["type"])
tm("Calls inside decorator arguments", [
    "meta.function.decorator meta.function-call.arguments support.function",
], ROLE["function"])

# --- CSS family ------------------------------------------------------------
tm("CSS selectors", [
    "entity.name.tag.css",
    "entity.name.tag.scss",
    "entity.name.tag.less",
    "meta.selector entity.name.tag",
    "meta.selector entity.other.attribute-name",
    "source.css entity.other.attribute-name",
    "source.css.scss entity.other.attribute-name",
    "source.css.less entity.other.attribute-name",
    "source.css punctuation.definition.entity",
    "source.css.scss punctuation.definition.entity",
    "source.css.less punctuation.definition.entity",
    "entity.name.tag.reference",
    "entity.name.tag.wildcard",
    "entity.other.keyframe-offset",
], ROLE["type"])
tm("CSS property names", [
    "support.type.property-name",
    "support.type.vendored.property-name",
    "meta.property-name",
], ROLE["key"])
tm("CSS values", [
    "meta.property-value.css",
    "meta.property-value.scss",
    "meta.property-value.less",
], ROLE["constant"])
tm("CSS units", [
    "keyword.other.unit",
], PURPLE)

# --- data formats ----------------------------------------------------------
tm("JSON, YAML, TOML, INI and env keys", [
    "punctuation.support.type.property-name",
    "entity.name.tag.yaml",
    "source.toml entity.name.tag",
    "source.toml entity.other.attribute-name",
    "keyword.key.toml",
    "variable.other.key.toml",
    "entity.name.section.group-title",
    "keyword.other.definition.ini",
    "variable.other.env",
    "variable.key.dotenv",
], ROLE["key"])
tm("YAML anchors and aliases", [
    "entity.name.type.anchor.yaml",
    "variable.other.anchor.yaml",
    "variable.other.alias.yaml",
    "punctuation.definition.anchor.yaml",
    "punctuation.definition.alias.yaml",
], ROLE["type"])

# --- markdown --------------------------------------------------------------
tm("Markdown headings", [
    "markup.heading",
    "markup.heading entity.name",
    "entity.name.section.markdown",
    "punctuation.definition.heading.markdown",
], ROLE["heading"], "bold")
tm("Markdown bold", [
    "markup.bold",
    "punctuation.definition.bold.markdown",
], BRIGHT, "bold")
tm("Markdown italic", [
    "markup.italic",
    "punctuation.definition.italic.markdown",
], ROLE["text"], "italic")
tm("Markdown bold italic", [
    "markup.bold markup.italic",
    "markup.italic markup.bold",
    "markup.bold punctuation.definition.italic.markdown",
    "markup.italic punctuation.definition.bold.markdown",
], BRIGHT, "bold italic")
tm("Markdown strikethrough", [
    "markup.strikethrough",
], MUTED, "strikethrough")
tm("Markdown underline", [
    "markup.underline",
], None, "underline")
tm("Markdown links", [
    "markup.underline.link",
    "string.other.link",
    "constant.other.reference.link",
    "meta.link.reference",
], ROLE["link"])
tm("Markdown inline code and fences", [
    "markup.inline.raw",
    "markup.raw",
    "markup.fenced_code.block.markdown",
    "markup.fenced_code.block.markdown punctuation.definition.markdown",
    "fenced_code.block.language",
    "punctuation.definition.raw.markdown",
], ROLE["string"])
tm("Markdown quotes", [
    "markup.quote",
    "punctuation.definition.quote.begin.markdown",
], MUTED, "italic")
tm("Markdown list markers", [
    "punctuation.definition.list.begin.markdown",
    "beginning.punctuation.definition.list.markdown",
    "punctuation.definition.list.markdown",
], PURPLE)
tm("Markdown rules and table borders", [
    "meta.separator.markdown",
    "punctuation.definition.table",
], MUTED)

# --- diff ------------------------------------------------------------------
tm("Diff inserted", [
    "markup.inserted",
    "punctuation.definition.inserted",
    "meta.diff.header.to-file",
    "punctuation.definition.to-file",
], ROLE["inserted"])
tm("Diff deleted", [
    "markup.deleted",
    "punctuation.definition.deleted",
    "meta.diff.header.from-file",
    "punctuation.definition.from-file",
], ROLE["deleted"])
tm("Diff changed", [
    "markup.changed",
    "punctuation.definition.changed",
], ROLE["changed"])
tm("Diff headers and ranges", [
    "meta.diff.range",
    "meta.diff.header",
    "punctuation.definition.range.diff",
], PURPLE)
tm("Diff index lines", [
    "meta.diff.index",
    "markup.ignored",
    "markup.untracked",
], MUTED)

# --- invalid ---------------------------------------------------------------
tm("Invalid", [
    "invalid",
], ROLE["invalid"])

# --- log / output tokens ---------------------------------------------------
# The bundled log grammar tags levels with borrowed scopes (errors as
# "string.regexp,", warnings as "markup.deleted"), so they are pinned here.
tm("Log info", ["token.info-token", "log.info"], BLUE)
tm("Log warning", ["token.warn-token", "log.warning"], AMBER)
tm("Log error", ["token.error-token", "log.error", "log.exceptiontype"], RED)
tm("Log debug", ["token.debug-token", "log.debug"], PURPLE)
tm("Log dates and trace output", ["log.date", "log.verbose"], ROLE["comment"], "")
tm("Log stack frames", ["log.exception"], MUTED)

# ==========================================================================
# SEMANTIC TOKENS (same role table)
# ==========================================================================
def st(foreground=None, style=None, **flags):
    o = OrderedDict()
    if foreground is not None:
        o["foreground"] = foreground
    if style is not None:
        o["fontStyle"] = style
    for k, v in flags.items():
        o[k] = v
    return o


SEM = OrderedDict([
    # types
    ("namespace", st(ROLE["type"])),
    ("module", st(ROLE["type"])),
    ("class", st(ROLE["type"])),
    ("interface", st(ROLE["type"])),
    ("enum", st(ROLE["type"])),
    ("struct", st(ROLE["type"])),
    ("type", st(ROLE["type"])),
    ("typeParameter", st(ROLE["type"])),
    ("typeAlias", st(ROLE["type"])),
    ("concept", st(ROLE["type"])),
    ("builtinType", st(ROLE["type"])),
    ("class.defaultLibrary", st(ROLE["type"])),
    ("type.defaultLibrary", st(ROLE["type"])),
    ("interface.defaultLibrary", st(ROLE["type"])),
    # functions
    ("function", st(ROLE["function"])),
    ("method", st(ROLE["function"])),
    ("macro", st(ROLE["function"])),
    ("function.defaultLibrary", st(ROLE["function"])),
    ("method.defaultLibrary", st(ROLE["function"])),
    ("magicFunction", st(ROLE["function"])),
    # variables, parameters, properties
    ("variable", st(ROLE["variable"])),
    ("variable.readonly", st(ROLE["variable"])),
    ("variable.defaultLibrary", st(ROLE["variable"])),
    ("variable.readonly.defaultLibrary", st(ROLE["constant"])),
    ("parameter", st(ROLE["parameter"], "italic")),
    ("selfParameter", st(ROLE["keyword"], "italic")),
    ("clsParameter", st(ROLE["keyword"], "italic")),
    ("selfKeyword", st(ROLE["keyword"], "italic")),
    ("property", st(ROLE["property"])),
    ("property.readonly", st(ROLE["property"])),
    ("property.defaultLibrary", st(ROLE["property"])),
    ("event", st(ROLE["property"])),
    ("label", st(ROLE["variable"])),
    # constants
    ("enumMember", st(ROLE["constant"])),
    ("number", st(ROLE["constant"])),
    ("boolean", st(ROLE["constant"])),
    ("builtinConstant", st(ROLE["constant"])),
    # keywords
    ("keyword", st(ROLE["keyword"])),
    ("modifier", st(ROLE["keyword"])),
    # strings
    ("string", st(ROLE["string"])),
    ("regexp", st(ROLE["escape"])),
    ("escapeSequence", st(ROLE["escape"])),
    ("formatSpecifier", st(ROLE["escape"])),
    # the rest
    ("comment", st(ROLE["comment"], "italic")),
    ("operator", st(ROLE["punctuation"])),
    ("punctuation", st(ROLE["punctuation"])),
    ("decorator", st(ROLE["decorator"])),
    ("annotation", st(ROLE["decorator"])),
    ("attribute", st(ROLE["decorator"])),
    ("*.deprecated", st(None, None, strikethrough=True)),
])

# ==========================================================================
# WRITE
# ==========================================================================
def build_theme():
    return OrderedDict([
        ("$schema", "vscode://schemas/color-theme"),
        ("name", "Summit"),
        ("type", "dark"),
        ("semanticHighlighting", True),
        ("colors", C),
        ("tokenColors", T),
        ("semanticTokenColors", SEM),
    ])


PACKAGE = OrderedDict([
    ("name", "summit-theme"),
    ("displayName", "Summit"),
    ("description", "Dark slate theme with a glacier-teal accent, matched to the Summit desktop colour scheme."),
    ("version", "1.0.0"),
    ("publisher", "summit"),
    ("engines", OrderedDict([("vscode", "^1.90.0")])),
    ("categories", ["Themes"]),
    ("keywords", ["theme", "dark", "summit", "slate", "teal"]),
    ("contributes", OrderedDict([
        ("themes", [OrderedDict([
            ("label", "Summit"),
            ("uiTheme", "vs-dark"),
            ("path", "./themes/summit-color-theme.json"),
        ])]),
    ])),
])


def write_json(path, obj):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    text = json.dumps(obj, indent=2, ensure_ascii=False) + "\n"
    with open(path, "w", encoding="utf-8", newline="\n") as fh:
        fh.write(text)
    return text


if __name__ == "__main__":
    theme = build_theme()
    write_json(THEME_PATH, theme)
    write_json(PKG_PATH, PACKAGE)
    print("wrote %s" % THEME_PATH)
    print("wrote %s" % PKG_PATH)
    print("colour keys: %d   TextMate rules: %d (%d scope selectors)   semantic rules: %d"
          % (len(C), len(T), sum(len(r["scope"]) for r in T), len(SEM)))

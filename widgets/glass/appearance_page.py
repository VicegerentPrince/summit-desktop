#!/usr/bin/env python3
"""The form of a card's Appearance page, rebuilt in the order people reach for things: the style,
the glass, then the main dials as sliders. The fine controls wait behind Advanced, and a Solid card
shows only what applies to it. The page's logic (its settings aliases, Copy and Paste, Use on every
card) stays as it is; only the form below it changes."""

TOP = """    Kirigami.FormLayout {
        Layout.fillWidth: true
        Layout.topMargin: Kirigami.Units.largeSpacing * 2

        ComboBox {
            id: styleCombo
            Kirigami.FormData.label: i18n("Style:")
            model: [i18n("Glass"), i18n("Solid")]
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Glass:")
            visible: root.isGlass
            spacing: Kirigami.Units.smallSpacing
            ComboBox {
                id: glassCombo
                model: [i18n("Liquid"), i18n("Frosted")]
                onActivated: blurRadiusSpin.value = currentIndex === 0 ? 4 : @FROSTED@
            }
            // the hidden twin holds the width, so the form does not shift when the text changes
            Button { id: glassButtonWidth; visible: false; text: i18n("Use on every card") }
            Button {
                Layout.minimumWidth: glassButtonWidth.implicitWidth
                text: root.glassNote || glassButtonWidth.text
                onClicked: root.useGlassEverywhere()
            }
        }

        // only solid cards have a light and a dark look
        ComboBox {
            id: appearanceCombo
            Kirigami.FormData.label: i18n("Colours:")
            visible: !root.isGlass
            model: [i18n("Dark"), i18n("Light"), i18n("Follow system")]
        }
"""

ADVANCED = """
        Button {
            flat: true
            text: i18n("Advanced")
            icon.name: root.advanced ? "arrow-down" : "arrow-right"
            onClicked: root.advanced = !root.advanced
        }
"""

COPY = """
        RowLayout {
            Kirigami.FormData.label: i18n("Look:")
            visible: root.advanced
            spacing: Kirigami.Units.smallSpacing
            Button {
                icon.name: "edit-copy"
                text: i18n("Copy")
                onClicked: {
                    _hiddenField.text = root._serialize()
                    _hiddenField.selectAll()
                    _hiddenField.copy()
                    pasteStatus.text = i18n("Copied!")
                    pasteStatus.visible = true
                    statusTimer.restart()
                }
            }
            Button {
                icon.name: "edit-paste"
                text: i18n("Paste")
                onClicked: {
                    _hiddenField.text = ""
                    _hiddenField.paste()
                    root._deserialize(_hiddenField.text)
                }
            }
            Label {
                id: pasteStatus
                visible: false
                font.italic: true
                opacity: 0.7
            }
        }

        TextField {
            id: _hiddenField
            visible: false
        }
    }
"""

END = "\n    Item { Layout.fillHeight: true }\n}\n"
ADVANCED_GLASS = "root.advanced && root.isGlass"


def section(name, cond):
    return f"""
        Kirigami.Separator {{
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("{name}")
            visible: {cond}
        }}
"""


def slider(id_, label, lo, hi, unit, cond="root.isGlass"):
    return f"""
        RowLayout {{
            Kirigami.FormData.label: i18n("{label}:")
            visible: {cond}
            spacing: Kirigami.Units.largeSpacing
            Slider {{
                id: {id_}
                Layout.preferredWidth: Kirigami.Units.gridUnit * 13
                from: {lo}; to: {hi}; stepSize: 1
                snapMode: Slider.SnapAlways
                Kirigami.StyleHints.tickMarkStepSize: -1      // whole numbers, without a ruler under them
            }}
            Label {{
                Layout.preferredWidth: Kirigami.Units.gridUnit * 3
                text: {id_}.value.toFixed(0) + "{unit}"
                opacity: 0.7
            }}
        }}
"""


def spin(id_, label, lo, hi, step, fmt, parse, cond=ADVANCED_GLASS):
    return f"""
        SpinBox {{
            id: {id_}
            Kirigami.FormData.label: i18n("{label}:")
            visible: {cond}
            from: {lo}; to: {hi}; stepSize: {step}
            textFromValue: v => {fmt}
            valueFromText: t => {parse}
        }}
"""


REALTIME = f"""
        CheckBox {{
            id: realtimeCheck
            Kirigami.FormData.label: i18n("Moving wallpaper:")
            visible: {ADVANCED_GLASS}
            text: i18n("Keep the glass in step (uses more power)")
        }}
"""

FORM = (TOP
        + section("Adjust", "root.isGlass")
        + slider("blurRadiusSpin", "Frost", 0, 40, " px")
        + slider("tintSpin", "Darkness", 0, 100, " %")
        + slider("scaleSpin", "Lens", 0, 150, "")
        + slider("specStrengthSpin", "Rim light", 0, 100, " %")
        + slider("radiusSpin", "Corners", 0, 100, " px", cond="true")
        + ADVANCED
        + spin("thicknessSpin", "Rim width", 1, 80, 1, 'v + " px"', "parseInt(t)")
        + spin("iorSpin", "Bend", 100, 400, 5, "(v / 100).toFixed(2)", "Math.round(parseFloat(t) * 100)")
        + spin("chromaSpin", "Colour fringe", 0, 100, 1, 'v + " %"', "parseInt(t)")
        + spin("roundnessSpin", "Corner smoothness", 20, 100, 1, "(v / 10).toFixed(1)",
               "Math.round(parseFloat(t) * 10)", cond="root.advanced")
        + REALTIME
        + COPY)


def rebuild(page, frosted):
    head = page[:page.index("    Kirigami.FormLayout {")]
    spacing = "    spacing: Kirigami.Units.largeSpacing\n"
    assert head.count(spacing) == 1
    head = head.replace(spacing, spacing + "    property bool advanced: false\n"
                        "    readonly property bool isGlass: styleCombo.currentIndex === 0\n")
    return head + FORM.replace("@FROSTED@", frosted) + END

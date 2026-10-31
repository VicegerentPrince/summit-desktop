#!/usr/bin/env python3
"""credits.py CONTENTS: names the Summit version on a Liquid Glass card, on its Credits page and in
its About details. Jack Faith's own credits stay as they are: the cards are his, under the GPL."""
import json
import os
import sys

c = sys.argv[1]
p = c + "/ui/config/ConfigAbout.qml"
s = open(p).read()
a = """    ColumnLayout {
        spacing: Kirigami.Units.gridUnit

"""
assert s.count(a) == 1, "ConfigAbout"
s = s.replace(a, a + """        ColumnLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            Kirigami.Heading { Layout.fillWidth: true; level: 1; text: "Summit version" }
            QQC2.Label {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                text: "This version is by Muhammad Muneeb, for Summit, a glass desktop and terminal setup "
                    + "for Plasma 6. Its layouts, settings and transitions are built on Liquid Glass by "
                    + "Jack Faith (jaxparrow07), whose credits follow."
            }
            Kirigami.UrlButton { url: "https://github.com/VicegerentPrince/summit-desktop" }
        }
        Kirigami.Separator { Layout.fillWidth: true }

""")
if os.path.islink(p):       # never write through to the shared vendor copy
    os.remove(p)
open(p, "w").write(s)

p = c + "/../metadata.json"
d = json.load(open(p))
d["KPlugin"]["Authors"].append({"Name": "Muhammad Muneeb, Summit version", "Website": "https://github.com/VicegerentPrince"})
if os.path.islink(p):
    os.remove(p)
json.dump(d, open(p, "w"), indent=4, ensure_ascii=False)

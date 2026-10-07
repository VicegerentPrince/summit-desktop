#!/usr/bin/env python3
"""Packages summit-theme/ as summit-theme-1.0.0.vsix with the standard VSIX layout.

  extension.vsixmanifest
  [Content_Types].xml
  extension/package.json
  extension/themes/summit-color-theme.json

Uses only the Python standard library (zipfile); no npm, no network. The
archive is deterministic (fixed timestamps and modes) and is read back and
compared byte for byte with the source files after it is written.

Run:  python3 tools/build_vsix.py
"""
import hashlib
import json
import os
import sys
import zipfile
from xml.sax.saxutils import escape

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
EXT = os.path.join(ROOT, "summit-theme")
STAMP = (2026, 10, 5, 0, 0, 0)

CONTENT_TYPES = {
    ".json": "application/json",
    ".vsixmanifest": "text/xml",
    ".md": "text/markdown",
    ".png": "image/png",
    ".txt": "text/plain",
}


def manifest_xml(pkg):
    tags = ["theme", "color-theme"] + [k for k in pkg.get("keywords", []) if k not in ("theme", "color-theme")] + ["__web_extension"]
    return """<?xml version="1.0" encoding="utf-8"?>
<PackageManifest Version="2.0.0" xmlns="http://schemas.microsoft.com/developer/vsx-schema/2011" xmlns:d="http://schemas.microsoft.com/developer/vsx-schema-design/2011">
  <Metadata>
    <Identity Language="en-US" Id="{name}" Version="{version}" Publisher="{publisher}" />
    <DisplayName>{display}</DisplayName>
    <Description xml:space="preserve">{description}</Description>
    <Tags>{tags}</Tags>
    <Categories>{categories}</Categories>
    <GalleryFlags>Public</GalleryFlags>
    <Properties>
      <Property Id="Microsoft.VisualStudio.Code.Engine" Value="{engine}" />
      <Property Id="Microsoft.VisualStudio.Code.ExtensionDependencies" Value="" />
      <Property Id="Microsoft.VisualStudio.Code.ExtensionPack" Value="" />
      <Property Id="Microsoft.VisualStudio.Code.ExtensionKind" Value="ui,workspace,web" />
      <Property Id="Microsoft.VisualStudio.Code.LocalizedLanguages" Value="" />
      <Property Id="Microsoft.VisualStudio.Services.GitHubFlavoredMarkdown" Value="true" />
      <Property Id="Microsoft.VisualStudio.Services.Content.Pricing" Value="Free" />
    </Properties>
  </Metadata>
  <Installation>
    <InstallationTarget Id="Microsoft.VisualStudio.Code" />
  </Installation>
  <Dependencies />
  <Assets>
    <Asset Type="Microsoft.VisualStudio.Code.Manifest" Path="extension/package.json" Addressable="true" />
  </Assets>
</PackageManifest>
""".format(
        name=escape(pkg["name"]), version=escape(pkg["version"]), publisher=escape(pkg["publisher"]),
        display=escape(pkg.get("displayName", pkg["name"])), description=escape(pkg.get("description", "")),
        tags=escape(",".join(tags)), categories=escape(",".join(pkg.get("categories", []))),
        engine=escape(pkg["engines"]["vscode"]),
    )


def content_types_xml(extensions):
    rows = "".join('<Default Extension="%s" ContentType="%s"/>' % (e, CONTENT_TYPES[e]) for e in sorted(extensions))
    return ('<?xml version="1.0" encoding="utf-8"?>\n'
            '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">%s</Types>\n' % rows)


def add(zf, name, data):
    info = zipfile.ZipInfo(name, date_time=STAMP)
    info.compress_type = zipfile.ZIP_DEFLATED
    info.create_system = 3                      # unix
    info.external_attr = (0o100644 & 0xFFFF) << 16
    zf.writestr(info, data, compresslevel=9)


def main():
    with open(os.path.join(EXT, "package.json"), "rb") as fh:
        pkg = json.loads(fh.read().decode("utf-8"))
    out = os.path.join(ROOT, "%s-%s.vsix" % (pkg["name"], pkg["version"]))

    files = []
    for base, dirs, names in os.walk(EXT):
        dirs.sort()
        for n in sorted(names):
            full = os.path.join(base, n)
            rel = os.path.relpath(full, EXT).replace(os.sep, "/")
            with open(full, "rb") as fh:
                files.append(("extension/" + rel, fh.read()))
    exts = {os.path.splitext(name)[1] for name, _ in files} | {".vsixmanifest"}
    unknown = [e for e in exts if e not in CONTENT_TYPES]
    if unknown:
        sys.exit("no content type known for %s" % ", ".join(unknown))

    entries = [
        ("extension.vsixmanifest", manifest_xml(pkg).encode("utf-8")),
        ("[Content_Types].xml", content_types_xml(exts).encode("utf-8")),
    ] + files

    tmp = out + ".tmp"
    with zipfile.ZipFile(tmp, "w", zipfile.ZIP_DEFLATED) as zf:
        for name, data in entries:
            add(zf, name, data)
    os.replace(tmp, out)

    # read back and verify
    with zipfile.ZipFile(out) as zf:
        bad = zf.testzip()
        if bad:
            sys.exit("CRC failure in %s" % bad)
        listed = zf.namelist()
        if listed != [n for n, _ in entries]:
            sys.exit("archive listing differs from what was written")
        for name, data in entries:
            if zf.read(name) != data:
                sys.exit("content mismatch for %s" % name)
        manifest = json.loads(zf.read("extension/package.json").decode("utf-8"))
        theme_path = "extension/" + manifest["contributes"]["themes"][0]["path"].lstrip("./")
        json.loads(zf.read(theme_path).decode("utf-8"))
    with open(out, "rb") as fh:
        blob = fh.read()
    print("wrote %s (%d bytes, sha256 %s)" % (os.path.relpath(out, ROOT), len(blob), hashlib.sha256(blob).hexdigest()))
    for name, data in entries:
        print("  %-48s %7d bytes" % (name, len(data)))
    print("verified: CRCs ok, %d entries identical to the source files, manifest and theme parse" % len(entries))


if __name__ == "__main__":
    main()

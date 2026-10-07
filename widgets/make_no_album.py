"""Music widget: a "no album" placeholder that adapts to the wallpaper.
The stock one is an opaque grey square. This keeps its note shape but makes the square a
translucent white tint, so the glass card's colour (taken from the wallpaper) shows through.
usage: make_no_album.py ORIGINAL.png OUT.png"""
import sys
from PIL import Image
src, out = sys.argv[1], sys.argv[2]
im = Image.open(src).convert("RGBA")
lum = im.convert("L")
note = lum.point(lambda v: max(0, min(255, (v - 185) * 255 // 50)))        # the white note, anti-aliased
alpha = note.point(lambda v: 38 + v * (235 - 38) // 255)                     # 15% tint, 92% note
res = Image.new("RGBA", im.size, (255, 255, 255, 0)); res.putalpha(alpha)
res.save(out, optimize=True)

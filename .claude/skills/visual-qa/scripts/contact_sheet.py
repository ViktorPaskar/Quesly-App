#!/usr/bin/env python3
"""Build contact sheets (grids) from a folder of screenshots for fast visual review.

Usage: python3 contact_sheet.py <dir> [--per-row 5] [--width 393] [--only feed,profile]
Writes <dir>/sheet-1.jpg, sheet-2.jpg, ... (filenames are printed). Requires Pillow.
"""
import argparse, glob, os, sys
from PIL import Image, ImageDraw

ap = argparse.ArgumentParser()
ap.add_argument("dir")
ap.add_argument("--per-row", type=int, default=5)
ap.add_argument("--width", type=int, default=393, help="tile width in px (393 = iPhone points)")
ap.add_argument("--only", default="", help="comma-separated substrings to include")
a = ap.parse_args()

files = sorted(glob.glob(os.path.join(a.dir, "*.png")))
if a.only:
    keys = [k.strip() for k in a.only.split(",") if k.strip()]
    files = [f for f in files if any(k in os.path.basename(f) for k in keys)]
if not files:
    sys.exit("no screenshots found")

label_h, gap = 28, 10
tiles = []
for f in files:
    im = Image.open(f).convert("RGB")
    h = round(im.height * a.width / im.width)
    tiles.append((os.path.splitext(os.path.basename(f))[0], im.resize((a.width, h))))

tile_h = max(t[1].height for t in tiles)
for n, start in enumerate(range(0, len(tiles), a.per_row), 1):
    row = tiles[start:start + a.per_row]
    sheet = Image.new("RGB", (len(row) * (a.width + gap) + gap, tile_h + label_h + gap * 2), "#202020")
    draw = ImageDraw.Draw(sheet)
    for i, (name, im) in enumerate(row):
        x = gap + i * (a.width + gap)
        draw.text((x, gap), name, fill="#FFFFFF")
        sheet.paste(im, (x, gap + label_h))
    out = os.path.join(a.dir, f"sheet-{n}.jpg")
    sheet.save(out, quality=88)
    print(out)

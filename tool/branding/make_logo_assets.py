"""Derives every app icon and in-app logo image from the supplied logo,
assets/images/logosheekh.jpeg. The original is only read (its SHA-256 is
checked first) and never modified.

Outputs:
  assets/images/logo_portrait_512.jpg       in-app medallion (head and shoulders)
  android/app/src/main/res/mipmap-*/ic_launcher.png            legacy icons
  android/app/src/main/res/mipmap-*/ic_launcher_foreground.png adaptive layer
  android/app/src/main/res/drawable-*/launch_logo.png          launch screen
  ios/Runner/Assets.xcassets/AppIcon.appiconset/*.png          iOS (opaque)
  web/favicon.png, web/icons/*.png

Needs Pillow:  python -I tool/branding/make_logo_assets.py   (from the repo root)
"""

import hashlib
import json
import os
import sys

from PIL import Image, ImageDraw

ORIGINAL = "assets/images/logosheekh.jpeg"
ORIGINAL_SHA256 = "92355b9f91156bc16a2ffa104cd0473763decb90e77a482e3f5adff27ca17aa9"

# Head-and-shoulders square inside the 640 x 640 photo: the face sits in the
# upper middle, so a plain centre crop would cut the head at small sizes.
PORTRAIT_BOX = (100, 0, 580, 480)

GOLD_LIGHT = (0xE9, 0xC7, 0x66)
GOLD_DARK = (0xB9, 0x8D, 0x2C)
GREEN = (0x2B, 0x50, 0x39)  # LogoMedallion inner colour on dark surfaces
RING = 0.06  # ring width as a fraction of the diameter (as LogoMedallion)


def portrait(src):
    return src.crop(PORTRAIT_BOX)


def gold_disc(size):
    """A diagonal gold gradient disc, like the medallion ring."""
    grad = Image.new("RGB", (size, size))
    px = grad.load()
    for y in range(size):
        for x in range(size):
            t = (x + y) / (2 * (size - 1))
            px[x, y] = tuple(round(a + (b - a) * t) for a, b in zip(GOLD_LIGHT, GOLD_DARK))
    return grad


def circle_mask(size, inset=0):
    m = Image.new("L", (size, size), 0)
    ImageDraw.Draw(m).ellipse((inset, inset, size - 1 - inset, size - 1 - inset), fill=255)
    return m


def medallion(photo, size, supersample=4):
    """Gold ring + circular photo on transparency, rendered large then scaled."""
    big = size * supersample
    out = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    out.paste(gold_disc(big), (0, 0), circle_mask(big))
    ring = round(big * RING)
    inner = big - 2 * ring
    face = photo.resize((inner, inner), Image.LANCZOS)
    out.paste(face, (ring, ring), circle_mask(inner))
    return out.resize((size, size), Image.LANCZOS)


def save_png(img, path):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(path, "PNG", optimize=True)


def main():
    with open(ORIGINAL, "rb") as f:
        data = f.read()
    if hashlib.sha256(data).hexdigest() != ORIGINAL_SHA256:
        sys.exit(f"{ORIGINAL} is not the supplied logo (checksum differs)")
    src = Image.open(ORIGINAL).convert("RGB")
    if src.size != (640, 640):
        sys.exit(f"unexpected logo size {src.size}")
    photo = portrait(src)

    # In-app medallion photo (the ring is drawn by LogoMedallion).
    photo.resize((512, 512), Image.LANCZOS).save(
        "assets/images/logo_portrait_512.jpg", "JPEG", quality=92, optimize=True)

    res = "android/app/src/main/res"
    densities = {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}
    for name, scale in densities.items():
        # Legacy launcher icon (48 dp).
        save_png(medallion(photo, round(48 * scale)), f"{res}/mipmap-{name}/ic_launcher.png")
        # Adaptive foreground (108 dp canvas; the medallion fills the 66 dp
        # safe zone, so no launcher mask can cut into it).
        canvas = round(108 * scale)
        fg = Image.new("RGBA", (canvas, canvas), (0, 0, 0, 0))
        m = medallion(photo, round(66 * scale))
        off = (canvas - m.size[0]) // 2
        fg.paste(m, (off, off), m)
        save_png(fg, f"{res}/mipmap-{name}/ic_launcher_foreground.png")
        # Launch screen logo (120 dp) for Android before 12.
        save_png(medallion(photo, round(120 * scale)), f"{res}/drawable-{name}/launch_logo.png")

    # iOS: opaque squares (the system rounds the corners), from Contents.json.
    ios = "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    with open(f"{ios}/Contents.json") as f:
        contents = json.load(f)
    for entry in contents["images"]:
        pts = float(entry["size"].split("x")[0])
        px = round(pts * int(entry["scale"].rstrip("x")))
        photo.resize((px, px), Image.LANCZOS).save(f"{ios}/{entry['filename']}", "PNG", optimize=True)

    # Web.
    save_png(medallion(photo, 32), "web/favicon.png")
    for size in (192, 512):
        save_png(medallion(photo, size), f"web/icons/Icon-{size}.png")
        mask = Image.new("RGBA", (size, size), GREEN + (255,))
        m = medallion(photo, round(size * 0.8))
        off = (size - m.size[0]) // 2
        mask.paste(m, (off, off), m)
        save_png(mask, f"web/icons/Icon-maskable-{size}.png")

    with open(ORIGINAL, "rb") as f:
        assert hashlib.sha256(f.read()).hexdigest() == ORIGINAL_SHA256
    print("OK: logo assets written; original unchanged")


if __name__ == "__main__":
    main()

"""Side-by-side comparison of the reference screenshots and Flutter goldens.

Usage (from the repo root, after `flutter test test/goldens --update-goldens`):
    python3 -I tool/compare_with_references.py

Writes docs/design/comparison/<name>.png:
reference | Flutter | 50% overlay (ghosting shows misalignment).
The status and navigation bars are system UI, so they are blank in the goldens.
"""
import pathlib
import sys

from PIL import Image, ImageDraw

ROOT = pathlib.Path(__file__).resolve().parent.parent
REF = ROOT / "docs/design/reference"
GOLD = ROOT / "test/goldens/screens"
OUT = ROOT / "docs/design/comparison"

PAIRS = [
    ("01-home.jpg", "01_home_en.png", "01_home"),
    ("02-drawer.jpg", "02_drawer_en.png", "02_drawer"),
    ("03-mushaf-reader.jpg", "03_reader_en.png", "03_reader"),
    ("04-mushaf-ayah-selected.jpg", "04_ayah_selected_en.png", "04_ayah_selected"),
    ("05-ayah-action-sheet.jpg", "05_ayah_sheet_en.png", "05_ayah_sheet"),
    ("06-reader-overflow-menu.jpg", "06_menu_en.png", "06_menu"),
]


def main() -> int:
    OUT.mkdir(parents=True, exist_ok=True)
    for ref_name, gold_name, out_name in PAIRS:
        ref = Image.open(REF / ref_name).convert("RGB")
        gold = Image.open(GOLD / gold_name).convert("RGB")
        if gold.size != ref.size:
            gold = gold.resize(ref.size)
        overlay = Image.blend(ref, gold, 0.5)
        w, h = ref.size
        canvas = Image.new("RGB", (w * 3 + 40, h + 40), (245, 245, 243))
        draw = ImageDraw.Draw(canvas)
        for i, (img, label) in enumerate(
            [(ref, "Reference"), (gold, "Flutter (golden)"), (overlay, "Overlay 50%")]
        ):
            x = i * (w + 20)
            canvas.paste(img, (x, 40))
            draw.text((x + 4, 12), label, fill=(20, 20, 20))
        canvas.save(OUT / f"{out_name}.png", optimize=True)
        print("wrote", OUT / f"{out_name}.png")
    return 0


if __name__ == "__main__":
    sys.exit(main())

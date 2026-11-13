"""Export item art from the original generated RGBA masters (Pillow)."""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "art/source/prayers-v1"
OUTPUT = ROOT / "art/items/prayers-v1"
ITEMS = ["tome_light","tome_bind","tome_watch","votive_candle"]

for name in ITEMS:
    original = Image.open(SOURCE / f"{name}.png").convert("RGBA")
    alpha = original.getchannel("A").point(lambda value: 255 if value >= 128 else 0)
    assert alpha.getextrema() == (0, 255), name
    original = original.crop(alpha.getbbox())
    for size in (128, 64):
        item = original.copy()
        item.thumbnail((size * 7 // 8, size * 7 // 8), Image.Resampling.LANCZOS)
        alpha = item.getchannel("A").point(lambda value: 255 if value >= 128 else 0)
        item = item.convert("RGB").quantize(colors=64, dither=Image.Dither.NONE).convert("RGBA")
        item.putalpha(alpha)
        canvas = Image.new("RGBA", (size, size))
        canvas.paste(item, ((size-item.width)//2, (size-item.height)//2))
        assert set(canvas.getchannel("A").getdata()) == {0, 255}
        assert len({pixel for pixel in canvas.getdata() if pixel[3]}) <= 64
        suffix = "" if size == 128 else "-64"
        canvas.save(OUTPUT / f"{name}{suffix}.png", optimize=True)

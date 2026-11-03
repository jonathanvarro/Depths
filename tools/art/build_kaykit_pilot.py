"""Recolours KayKit Dungeon Remastered's shared gradient texture (CC0) to
the game's floor 1 palette for the #224 pilot.

The palette is sampled from the live floor 1 art: the cave-v1 wall and
floor textures and the cave-v1 dressing drawings. Each texel is muted
(less saturation, a little darker; lifted again for the grain) and then snapped to the nearest
palette colour, so the props share the painted art's colours and its
banded, hand-made look. The result is 256 square, small enough for a
phone, and is shared by every KayKit piece.

It also writes grain-floor1.png: the light and dark of floor 1's wall
texture, as a grey multiply layer. The pilot lays it over every piece in
world space at the walls' own density (64 pixels to a 2 m cell), so the
props get the walls' chunky grit.

Usage: python tools/art/build_kaykit_pilot.py <kaykit dungeon_texture.png>
Writes art/third-party/kaykit-dungeon-remastered/texture-floor1.png, the
grain and a palette swatch beside them. Deterministic: the same inputs
give the same bytes.
"""

import colorsys
import os
import sys

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "art", "third-party", "kaykit-dungeon-remastered")
SOURCES = [os.path.join(ROOT, "art", "textures", "cave-v1", name) for name in ("wall.png", "floor.png")]
DRESSING = os.path.join(ROOT, "art", "dressing", "cave-v1")
COLOURS = 32
SIZE = 256
SATURATION = 0.55  # keep this much of the pack's saturation
VALUE = 0.78  # and this much of its brightness
GRAIN = 0.55  # how strongly the walls' light and dark show on the props
LIFT = 1.12  # brightens the colours a little to make up for the grain's darkening


def palette() -> list:
    """The floor 1 art's main colours, by median cut over all opaque pixels."""
    pixels = []
    files = SOURCES + sorted(os.path.join(DRESSING, f) for f in os.listdir(DRESSING) if f.endswith(".png"))
    for path in files:
        image = Image.open(path).convert("RGBA")
        image.thumbnail((128, 128), Image.NEAREST)
        pixels += [p[:3] for p in image.getdata() if p[3] > 200]
    strip = Image.new("RGB", (len(pixels), 1))
    strip.putdata(pixels)
    quantised = strip.quantize(colors=COLOURS, method=Image.MEDIANCUT, dither=Image.NONE)
    flat = quantised.getpalette()[: COLOURS * 3]
    return [tuple(flat[i : i + 3]) for i in range(0, len(flat), 3)]


def nearest(colour: tuple, colours: list) -> tuple:
    r, g, b = colour
    # Weighted RGB distance: close enough to perceptual for snapping.
    return min(colours, key=lambda c: 2 * (c[0] - r) ** 2 + 4 * (c[1] - g) ** 2 + 3 * (c[2] - b) ** 2)


def mute(colour: tuple) -> tuple:
    h, s, v = colorsys.rgb_to_hsv(*(x / 255.0 for x in colour))
    r, g, b = colorsys.hsv_to_rgb(h, s * SATURATION, min(1.0, v * VALUE * LIFT))
    return (round(r * 255), round(g * 255), round(b * 255))


def grain() -> Image.Image:
    """The wall's brightness as a multiply layer: 1.0 where it's brightest,
    darker in its cracks, eased by GRAIN."""
    wall = Image.open(SOURCES[0]).convert("L")
    values = sorted(wall.getdata())
    top = values[int(len(values) * 0.9)] or 1
    out = [round(255 * (1.0 - GRAIN * (1.0 - min(1.0, v / top)))) for v in wall.getdata()]
    image = Image.new("L", wall.size)
    image.putdata(out)
    return image


def main() -> None:
    source = Image.open(sys.argv[1]).convert("RGB").resize((SIZE, SIZE), Image.BOX)
    colours = palette()
    cache = {}
    out = Image.new("RGB", source.size)
    out.putdata([cache.setdefault(p, nearest(mute(p), colours)) for p in source.getdata()])
    os.makedirs(OUT, exist_ok=True)
    out.save(os.path.join(OUT, "texture-floor1.png"), optimize=True)
    grain().save(os.path.join(OUT, "grain-floor1.png"), optimize=True)
    swatch = Image.new("RGB", (len(colours), 1))
    swatch.putdata(colours)
    swatch.resize((len(colours) * 16, 16), Image.NEAREST).save(os.path.join(OUT, "palette-floor1.png"), optimize=True)
    print("palette", len(colours), "colours; wrote texture-floor1.png")


if __name__ == "__main__":
    main()

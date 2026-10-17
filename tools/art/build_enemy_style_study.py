"""Export the generated lower-detail study; no image generation required."""
from pathlib import Path
import hashlib
import json
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'art/enemies/style-study-v1'
OUT.mkdir(parents=True, exist_ok=True)


def register(path, limited=False):
    im = Image.open(path).convert('RGBA').resize((128, 128), Image.Resampling.NEAREST)
    pixels = list(im.getdata())
    # Remove saturated matte specks, then use crisp binary-alpha pixel edges.
    clean = [(r, g, b, 255) if a >= 128 and not (
        (r > 225 and g < 65 and b < 65) or (r > 220 and g > 200 and b < 105)
    ) else (0, 0, 0, 0) for r, g, b, a in pixels]
    im.putdata(clean)
    box = im.getbbox()
    offset = (64 - (box[0] + box[2]) // 2, 121 - box[3])
    aligned = Image.new('RGBA', (128, 128))
    aligned.paste(im, offset)
    assert sum(p[3] > 0 for p in aligned.getdata()) == sum(p[3] > 0 for p in im.getdata())
    if limited:
        alpha = aligned.getchannel('A')
        aligned = aligned.convert('RGB').quantize(
            colors=24, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE
        ).convert('RGBA')
        aligned.putalpha(alpha)
        aligned.putdata([p if p[3] else (0, 0, 0, 0) for p in aligned.getdata()])
    return aligned, offset


report = {}
images = []
for label, source, filename, limited in [
    ('Detailed concept', 'art/enemies/cave-v1/goblin/idle.png', 'goblin-detailed-128.png', False),
    ('Simpler study', 'art/source/enemy-style-v1/goblin-simple.png', 'goblin-simple-128.png', True),
]:
    im, offset = register(ROOT / source, limited)
    path = OUT / filename
    im.save(path)
    colors = len({p[:3] for p in im.getdata() if p[3]})
    assert im.size == (128, 128) and im.mode == 'RGBA'
    assert set(im.getchannel('A').getdata()) == {0, 255}
    assert im.getbbox()[3] - 1 == 120
    if limited:
        assert colors <= 24
    report[filename] = dict(size=list(im.size), visible_colors=colors, alpha_values=[0, 255],
                            ground_y=120, pivot=[64, 120], translation=list(offset),
                            sha256=hashlib.sha256(path.read_bytes()).hexdigest())
    images.append((label, im))

sheet = Image.new('RGB', (640, 460), '#1d2422')
draw = ImageDraw.Draw(sheet)
for i, (label, im) in enumerate(images):
    x = i * 320
    draw.text((x + 24, 15), label + ' - same 128px canvas', fill='#efe4cb')
    sheet.paste(im.resize((256, 256), Image.Resampling.NEAREST), (x + 32, 40), im.resize((256, 256), Image.Resampling.NEAREST))
    draw.text((x + 24, 306), '2x nearest above / native below', fill='#b7c4ba')
    sheet.paste(im, (x + 24, 324), im)
    # A bright backing exposes accidental opaque backgrounds/dark fringes.
    draw.rectangle((x + 170, 324, x + 297, 451), fill='#aab6aa')
    sheet.paste(im, (x + 170, 324), im)
sheet.save(OUT / 'comparison.png')
(OUT / 'validation.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
print(json.dumps(report, indent=2))

"""Copy real Godot renders and models. Overview only crops/scales/labels captures."""
from pathlib import Path
import hashlib
import json
import shutil
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / 'build/lowpoly-review'
DEST = ROOT / 'art/concepts/character-lowpoly-v1'
DEST.mkdir(parents=True, exist_ok=True)
files = {}
for item in sorted(SOURCE.iterdir()):
    if item.suffix not in {'.png', '.tscn', '.glb'} and item.name != 'report.json':
        continue
    shutil.copyfile(item, DEST / item.name)
    digest = hashlib.sha256(item.read_bytes()).hexdigest()
    assert hashlib.sha256((DEST / item.name).read_bytes()).hexdigest() == digest
    files[item.name] = {'sha256': digest, 'bytes': item.stat().st_size}
    if item.suffix == '.png':
        with Image.open(item) as image:
            image.verify()

font = ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf', 30)
small = ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf', 21)
tiny = ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf', 17)
sheet = Image.new('RGB', (1600, 1050), '#11191e')
draw = ImageDraw.Draw(sheet)
draw.text((28, 18), 'DEPTHS / LOW-POLY TRAVELLER', font=font, fill='#e9dec7')
draw.text((28, 63), 'One identity · three fitted outfits · shared weighted rig · actual Godot model renders', font=small, fill='#aebcc1')

def tile(name, crop, rect, label):
    image = Image.open(DEST / name).convert('RGB').crop(crop)
    image.thumbnail((rect[2], rect[3]), Image.Resampling.LANCZOS)
    sheet.paste(image, (rect[0] + (rect[2] - image.width)//2, rect[1]))
    draw.text((rect[0]+8, rect[1]+rect[3]+8), label, font=tiny, fill='#c9cbc2')

tile('figure-0.png', (435, 5, 970, 725), (20, 120, 520, 730), 'Burgundy coat / travel kit')
tile('portrait-0.png', (340, 85, 1065, 720), (550, 120, 620, 515), 'Angular face / inset eyes / silver streak')
tile('reading-0.png', (470, 70, 1020, 590), (650, 680, 400, 265), 'Weighted elbows & knees / reading pose')
tile('figure-1.png', (475, 20, 935, 710), (1190, 120, 190, 295), 'Quilted coat')
tile('figure-2.png', (465, 20, 945, 710), (1390, 120, 190, 295), 'Salvaged plate')
tile('utility-0.png', (435, 20, 965, 710), (1190, 515, 190, 295), 'Shield')
tile('utility-back-2.png', (460, 20, 945, 710), (1390, 515, 190, 295), 'Frame pack / back')
draw.text((28, 998), 'Style study for review. No approved likeness, live portrait replacement or physical-phone performance claim.', font=small, fill='#aebcc1')
sheet.save(DEST / 'overview.png')
(DEST / '.gdignore').write_text('', encoding='utf-8')
manifest = {
    'issue': 205, 'date': '2026-11-01', 'origin': 'Original authored cross-sections, planar meshes and vertex-colour materials; no external models or generated illustrations.',
    'renderer': 'Godot 4.7.2 / Mobile / D3D12 / AMD Radeon RX 9070 XT',
    'files': files,
    'source_sha256': {p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in Path(__file__).parent.glob('*.gd')},
    'overview': 'Cropped/resized actual captures with labels; no model retouch or synthesized imagery.',
    'limits': ['Owner style/likeness review pending', 'One body size', 'Flat-shaded palette, no texture UVs', 'Rigid armour and fingers', 'Pose clips, not a locomotion library', 'Cape bends with spine/hips; no cloth or collision simulation', 'GLBs export one visible outfit and cape each, no hidden reading prop', 'Portable GLBs use extra palette-material surfaces for reliable colour on import; native project has fewer surfaces', 'Native scene retains all variants; caller controls visibility', 'No physical iPhone benchmark or live integration'],
    'environment_warning': 'Restricted editor preferences and user://vulkan shader-cache directory unavailable; renderer continued without caching, exit 0.'
}
(DEST / 'manifest.json').write_text(json.dumps(manifest, indent=2), encoding='utf-8')
print(f'Packaged {len(files)} real capture/model/report files')

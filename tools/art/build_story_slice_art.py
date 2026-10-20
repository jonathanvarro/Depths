"""Export the first story slice's commissioned art from preserved ImageGen masters.

No painting, background removal or upscaling. Paired prop states share one
registration transform. The .tres files and authored scene hooks are separate.
"""
from pathlib import Path
import hashlib
import json
import re
import sys
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / 'art/source/story-slice-v1'
REVIEW = ROOT / 'art/concepts/story-slice-v1'
CATALOG = ROOT / 'art/props/story-slice-v1/catalog.json'
PORTRAITS = ('commander-edric', 'hask-miner')
ITEMS = ('companion-short-sword', 'companion-mace', 'camp-forged-blade', 'iron-ore')
PAIRS = {'three-knocks': 'three-knocks-used', 'iron-seam': 'iron-seam-used'}
PROPS = ('three-knocks', 'iron-seam', 'lower-water-gate')


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def master(ident):
    return SOURCE / (ident + '-master.png')


def cutout(image):
    alpha = image.getchannel('A').point(lambda a: 255 if a >= 128 else 0)
    image = image.convert('RGB').quantize(64, dither=Image.Dither.NONE).convert('RGBA')
    image.putalpha(alpha)
    return image


def registered(ident, size, area, bounds=None, bottom=False):
    raw = Image.open(master(ident)).convert('RGBA')
    assert raw.getchannel('A').getextrema()[0] == 0, (ident, 'missing transparency')
    bounds = bounds or raw.getchannel('A').point(lambda a: 255 if a >= 128 else 0).getbbox()
    cropped = raw.crop(bounds)
    ratio = min(area[0] / cropped.width, area[1] / cropped.height)
    assert ratio < 1, 'Only reduce original masters'
    small = cropped.resize((round(cropped.width * ratio), round(cropped.height * ratio)), Image.Resampling.LANCZOS)
    dest = Image.new('RGBA', (size, size))
    y = size - 12 - small.height if bottom else (size - small.height) // 2
    dest.alpha_composite(small, ((size - small.width) // 2, y))
    return cutout(dest), {'source_bounds': list(bounds), 'scale': ratio, 'offset': [(size - small.width) // 2, y]}


def save(image, path):
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path)
    return 'res://' + path.relative_to(ROOT).as_posix()


def main():
    REVIEW.mkdir(parents=True, exist_ok=True)
    (REVIEW / '.gdignore').write_text('', encoding='utf-8')
    source_meta = json.loads((SOURCE / 'generation.json').read_text(encoding='utf-8'))
    entries = []
    for entry in source_meta['assets']:
        path = ROOT / entry['source']
        actual = digest(path)
        if 'sha256' in entry:
            assert entry['sha256'] == actual, ('Source changed', entry['id'])
        entry['sha256'] = actual
    (SOURCE / 'generation.json').write_text(json.dumps(source_meta, indent=2) + '\n', encoding='utf-8')

    for ident in PORTRAITS:
        raw = Image.open(master(ident)).convert('RGBA')
        assert raw.width == raw.height
        base = cutout(raw.resize((192, 192), Image.Resampling.LANCZOS))
        texture = save(base, ROOT / 'art/portraits/story-slice-v1' / (ident + '.png'))
        entries.append({'id': ident, 'kind': 'static-neutral-portrait', 'texture': texture,
                        'canvas': [192, 192], 'animation': 'None: authored face is whole; never overlay borrowed eyes/mouth.'})

    for ident in ITEMS:
        icon, transform = registered(ident, 128, (112, 112))
        texture = save(icon, ROOT / 'art/items/story-slice-v1' / (ident + '.png'))
        entries.append({'id': ident, 'kind': 'inventory-icon', 'texture': texture, 'canvas': [128, 128], **transform})

    for ident in PROPS:
        states = [ident] + ([PAIRS[ident]] if ident in PAIRS else [])
        raws = [Image.open(master(state)).convert('RGBA') for state in states]
        assert len(set(raw.size for raw in raws)) == 1, (ident, 'state canvas changed')
        boxes = [raw.getchannel('A').point(lambda a: 255 if a >= 128 else 0).getbbox() for raw in raws]
        bounds = (min(b[0] for b in boxes), min(b[1] for b in boxes), max(b[2] for b in boxes), max(b[3] for b in boxes))
        for state in states:
            sprite, transform = registered(state, 192, (168, 168), bounds, bottom=True)
            texture = save(sprite, ROOT / 'art/props/story-slice-v1' / (state + '.png'))
            entries.append({'id': state, 'kind': 'room-prop', 'texture': texture, 'canvas': [192, 192], 'pivot': [96, 180], **transform})

    raw = Image.open(master('commander-backdrop')).convert('RGB')
    # Fit/crop the wide illustration to landscape without stretching it.
    from PIL import ImageOps
    backdrop = ImageOps.fit(raw, (960, 540), Image.Resampling.LANCZOS).quantize(96, dither=Image.Dither.NONE).convert('RGB')
    texture = save(backdrop, ROOT / 'art/portraits/story-slice-v1/commander-backdrop.png')
    entries.append({'id': 'commander-backdrop', 'kind': 'conversation-backdrop', 'texture': texture, 'canvas': [960, 540]})

    for entry in entries:
        entry['source'] = 'res://' + master(entry['id']).relative_to(ROOT).as_posix()
        entry['sha256'] = digest(ROOT / entry['texture'].removeprefix('res://'))
    CATALOG.parent.mkdir(parents=True, exist_ok=True)
    CATALOG.write_text(json.dumps({'issue': 127, 'date': '2026-10-20', 'colour_limit': 64, 'assets': entries}, indent=2) + '\n', encoding='utf-8')
    board(entries)
    if '--wire' in sys.argv:
        wire()
    print(f'Exported {len(entries)} textures. Source hashes and shared prop transforms recorded.')


def wire():
    descriptions = {
        'companion_short_sword': 'A narrow fullered blade above a worn leather grip. Small nicks near the guard leave the quick, keen point intact.',
        'companion_mace': 'Six compact iron flanges on a slender haft. Rust gathers at their roots; the leather grip is rubbed almost black.',
        'camp_forged_blade': "The apprentice's first good blade: dark hammer scale along the spine, a bright ground edge and two rivets through an ash grip. Light in the hand, and it holds an edge.",
    }
    for ident, description in descriptions.items():
        path = ROOT / 'data/gear' / (ident + '.tres')
        text = path.read_text(encoding='utf-8')
        text, count = re.subn(r'(\[ext_resource type="Texture2D" path=")[^"]+(" id="2"\])',
                             lambda m: m[1] + 'res://art/items/story-slice-v1/' + ident.replace('_', '-') + '.png' + m[2], text)
        assert count == 1
        text = re.sub(r'^description = ".*"$', 'description = ' + json.dumps(description), text, flags=re.M)
        path.write_text(text, encoding='utf-8')
    for path in (ROOT / 'data/conversations').glob('*.tres'):
        text = path.read_text(encoding='utf-8')
        if path.stem.startswith('commander_'):
            text = text.replace('res://art/portraits/recruit-silhouettes-v1/warden.png', 'res://art/portraits/story-slice-v1/commander-edric.png')
        elif path.stem == 'miner_thanks':
            text = text.replace('res://art/portraits/recruit-silhouettes-v1/brawler.png', 'res://art/portraits/story-slice-v1/hask-miner.png')
        else:
            continue
        if path.stem == 'commander_first' and 'backdrop = ' not in text:
            text = text.replace('\n[sub_resource', '\n[ext_resource type="Texture2D" path="res://art/portraits/story-slice-v1/commander-backdrop.png" id="slice_backdrop"]\n\n[sub_resource', 1)
            text += 'backdrop = ExtResource("slice_backdrop")\n'
        path.write_text(text, encoding='utf-8')
    for ident in PROPS:
        path = ROOT / 'data/events' / ('quest_' + ident.replace('-', '_').replace('lower_water_gate', 'lower_gate') + '.tres')
        text = path.read_text(encoding='utf-8')
        if 'prop = ' not in text:
            resource = '[ext_resource type="PackedScene" path="res://art/props/story-slice-v1/' + ident + '.tscn" id="slice_prop"]'
            text = text.replace('\n[sub_resource', '\n' + resource + '\n\n[sub_resource', 1)
            text += 'prop = ExtResource("slice_prop")\n'
        path.write_text(text, encoding='utf-8')


def board(entries):
    font_path = next((ROOT / 'art/fonts/source-sans-3').glob('*.ttf'))
    font = ImageFont.truetype(str(font_path), 19)
    small = ImageFont.truetype(str(font_path), 15)
    sheet = Image.new('RGB', (1100, 940), '#151a19')
    d = ImageDraw.Draw(sheet)
    d.text((22, 12), 'Depths / first story slice / live art and phone-size review', font=font, fill='#e6dac1')
    for i, ident in enumerate(PORTRAITS):
        art = Image.open(ROOT / 'art/portraits/story-slice-v1' / (ident + '.png')).convert('RGBA')
        x = 24 + i * 262
        sheet.paste(art, (x, 52), art)
        miniature = art.resize((96, 96), Image.Resampling.NEAREST)
        sheet.paste(miniature, (x + 156, 165), miniature)
        d.text((x, 266), ident.replace('-', ' ').title(), font=font, fill='#e6dac1')
    for i, ident in enumerate(ITEMS):
        art = Image.open(ROOT / 'art/items/story-slice-v1' / (ident + '.png')).convert('RGBA')
        x = 24 + i * 262
        sheet.paste(art, (x, 310), art)
        miniature = art.resize((40, 40), Image.Resampling.LANCZOS)
        sheet.paste(miniature, (x + 158, 370), miniature)
        d.text((x, 442), ident.replace('-', ' '), font=small, fill='#e6dac1')
    for i, ident in enumerate(('three-knocks', 'three-knocks-used', 'iron-seam', 'iron-seam-used')):
        art = Image.open(ROOT / 'art/props/story-slice-v1' / (ident + '.png')).convert('RGBA')
        x = 24 + i * 262
        sheet.paste(art, (x, 490), art)
        d.text((x, 690), ident, font=small, fill='#e6dac1')
    gate = Image.open(ROOT / 'art/props/story-slice-v1/lower-water-gate.png').convert('RGBA')
    sheet.paste(gate, (24, 726), gate)
    d.text((238, 780), 'Lower water gate / bars remain closed after inspection', font=font, fill='#e6dac1')
    d.text((238, 814), 'Neutral faces are static. No borrowed animation layers.', font=font, fill='#b3ac9c')
    d.text((238, 846), 'Used rubble marks a dealt-with site; it does not open the passage.', font=font, fill='#b3ac9c')
    sheet.save(REVIEW / 'overview.png')


if __name__ == '__main__':
    main()

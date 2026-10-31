"""#194/#195: mechanical candidate exports and review, never live bindings.

ImageGen authors every new drawing. Masters stay immutable; this exporter only
fits/quantizes them using the existing inventory pipeline. Existing 128px icons
keep their visible pixels; transparent RGB is zeroed in review copies only.
Shape selection precedes runtime promotion.
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import hashlib
import json
import os
import sys
import textwrap
import numpy as np
sys.dont_write_bytecode = True
from build_field_kit_art import fitted

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / 'art/source/early-equipment-v1'
REVIEW = ROOT / 'art/concepts/early-equipment-v1'
REGIONS = {'cave-mine': 'Cave & Mine', 'goblin-territory': 'Goblin Territory'}


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def write_json(path, value):
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')


def sheet(entries, region, background, treatment='colour'):
    bg, fg, muted = ('#1b2420', '#e6dac1', '#aeb5a4') if background == 'dark' else ('#d7c5a3', '#302d25', '#655a48')
    board = Image.new('RGB', (1280, 820), bg)
    draw = ImageDraw.Draw(board)
    font_file = next((ROOT / 'art/fonts/source-sans-3').glob('*.ttf'))
    title = ImageFont.truetype(str(font_file), 27)
    font = ImageFont.truetype(str(font_file), 19)
    small = ImageFont.truetype(str(font_file), 16)
    draw.text((24, 16), REGIONS[region] + ' | Ordinary equipment bases', font=title, fill=fg)
    draw.text((24, 53), 'Shape review | 128 / 64 / 32 px | No runtime assignment', font=small, fill=muted)
    groups = [entries[:5], entries[5:8], entries[8:]]
    for row, group in enumerate(groups):
        y = 90 + row * 240
        for col, entry in enumerate(group):
            x = 14 + col * 254
            icon = Image.open(REVIEW / entry['candidate_icon']).convert('RGBA')
            if treatment == 'greyscale':
                alpha = icon.getchannel('A')
                icon = icon.convert('L').convert('RGBA')
                icon.putalpha(alpha)
            elif treatment == 'silhouette':
                alpha = icon.getchannel('A')
                icon = Image.new('RGBA', icon.size, fg)
                icon.putalpha(alpha)
            for size, offset in [(128, (0, 0)), (64, (142, 8)), (32, (158, 88))]:
                scaled = icon.resize((size, size), Image.Resampling.NEAREST)
                board.paste(scaled, (x + offset[0], y + offset[1]), scaled)
            for line, text in enumerate(textwrap.wrap(entry['name'], 25)):
                draw.text((x, y + 136 + line * 22), text, font=font, fill=fg)
            draw.text((x, y + 184), entry['family'], font=small, fill=muted)
            draw.text((x, y + 206), 'Retained art' if entry['source_kind'] == 'retained_existing_art' else 'New drawing', font=small, fill=muted)
    board.save(REVIEW / f'{region}-{background}-{treatment}.png')


def main():
    brief = json.loads((SOURCE / 'brief.json').read_text(encoding='utf-8'))
    generated = json.loads((SOURCE / 'generation.json').read_text(encoding='utf-8'))
    (REVIEW / 'candidates128').mkdir(parents=True, exist_ok=True)
    checks, failures, items = 0, [], []

    def check(ok, message):
        nonlocal checks
        checks += 1
        if not ok:
            failures.append(message)

    check(len(brief['assets']) == 22, '22 designs')
    check(len({e['id'] for e in brief['assets']}) == 22, 'Unique art IDs')
    for asset in brief['assets']:
        entry = dict(asset)
        source = ROOT / entry['source']
        check(source.exists(), entry['id'] + ': source exists')
        raw = Image.open(source).convert('RGBA')
        entry['source_canvas'] = list(raw.size)
        entry['source_sha256'] = sha(source)
        entry['source_url'] = os.path.relpath(source, REVIEW).replace('\\', '/')
        icon_path = REVIEW / 'candidates128' / (entry['id'] + '.png')
        if entry.get('reuse_icon'):
            original = ROOT / entry['reuse_icon']
            old_pixels = np.array(Image.open(original).convert('RGBA'))
            copy_pixels = old_pixels.copy()
            copy_pixels[copy_pixels[:, :, 3] == 0] = 0
            Image.fromarray(copy_pixels).save(icon_path)
            entry['registration'] = {'method': 'existing 128px visible RGBA unchanged; invisible RGB zeroed in candidate only', 'source_icon': entry['reuse_icon'], 'source_icon_sha256': sha(original)}
            check(np.array_equal(old_pixels[old_pixels[:, :, 3] > 0], copy_pixels[old_pixels[:, :, 3] > 0]), entry['id'] + ': approved visible pixels unchanged')
        else:
            icon, registration = fitted(raw, 128, 64)
            icon.save(icon_path)
            entry['registration'] = {'method': 'existing fitted(): direct source crop, Lanczos reduction, hard alpha, no-dither 64-colour quantization', **registration}
            check(registration['scale'] < 1, entry['id'] + ': no upscaling')
        icon = Image.open(icon_path)
        rgba = np.array(icon.convert('RGBA'))
        visible = rgba[:, :, 3] > 0
        bounds = icon.getchannel('A').getbbox()
        colours = len(np.unique(rgba[:, :, :3][visible], axis=0))
        check(icon.mode == 'RGBA' and icon.size == (128, 128), entry['id'] + ': native RGBA128')
        check(set(np.unique(rgba[:, :, 3])).issubset({0, 255}), entry['id'] + ': binary alpha')
        check(bounds is not None and min(bounds[0], bounds[1], 128-bounds[2], 128-bounds[3]) >= 8, entry['id'] + ': 8px padding')
        check(colours <= 64, entry['id'] + ': at most 64 visible colours')
        check(not rgba[~visible].any(), entry['id'] + ': clean invisible RGB')
        check((ROOT / entry['source_provenance']).exists(), entry['id'] + ': prompt provenance exists')
        check(entry['runtime_binding'] is None, entry['id'] + ': no live assignment')
        entry.update(candidate_icon='candidates128/' + icon_path.name, icon_sha256=sha(icon_path), alpha_bounds=list(bounds), visible_colours=colours)
        items.append(entry)
    for region in REGIONS:
        regional = [e for e in items if e['region'] == region]
        check(len(regional) == 11, region + ': eleven designs')
        check([e['category'] for e in regional].count('body') == 3, region + ': three armour weights')
        check([e['category'] for e in regional].count('back') == 3, region + ': three back-slot choices')
        for background, treatment in [('dark', 'colour'), ('parchment', 'colour'), ('dark', 'greyscale'), ('parchment', 'silhouette')]:
            sheet(regional, region, background, treatment)
    for entry in generated['assets']:
        path = ROOT / entry['source']
        check(not entry.get('sha256') or entry['sha256'] == sha(path), entry['id'] + ': immutable generated master')
        entry.update(sha256=sha(path), canvas=list(Image.open(path).size))
    write_json(SOURCE / 'generation.json', generated)
    catalog = {'issues': [194, 195], 'date': brief['date'], 'stage': brief['stage'], 'runtime_bindings_changed': False, 'canvas': [128, 128], 'padding_minimum': 8, 'colour_limit': 64, 'items': items}
    write_json(REVIEW / 'catalog.json', catalog)
    write_json(REVIEW / 'validation.json', {'checks': checks, 'failures': failures, 'new_drawings': 16, 'retained_designs': 6, 'candidate_icons': len(items), 'owner_selected': [], 'physical_iPhone': False, 'live_bindings': False})
    template = (Path(__file__).with_name('early_equipment_review.html')).read_text(encoding='utf-8')
    (REVIEW / 'inspector.html').write_text(template.replace('/* CATALOG_DATA */[]', json.dumps(items, ensure_ascii=False)), encoding='utf-8')
    print(f'EARLY_EQUIPMENT: {len(items)} candidates, {checks} checks, {len(failures)} failures')
    if failures:
        raise SystemExit('\n'.join(failures))


if __name__ == '__main__':
    main()

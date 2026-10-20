"""Check source provenance, export registration and cosmetic-only resource changes."""
from pathlib import Path
import hashlib
import json
import re
import subprocess
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def visual_neutral(text, kind):
    if kind == 'gear':
        text = re.sub(r'^description = .*$', '<description>', text, flags=re.M)
    if kind in ('gear', 'conversation'):
        text = re.sub(r'(\[ext_resource type="Texture2D" path=")[^"]+(" id=")', r'\1<texture>\2', text)
    text = re.sub(r'^\[ext_resource .* id="slice_(prop|backdrop)"\]\n?', '', text, flags=re.M)
    text = re.sub(r'^(prop|backdrop) = ExtResource\("slice_[^"]+"\)\n?', '', text, flags=re.M)
    return '\n'.join(line for line in text.splitlines() if line.strip())


def main():
    source_dir = ROOT / 'art/source/story-slice-v1'
    sources = json.loads((source_dir / 'generation.json').read_text(encoding='utf-8'))
    catalogue = json.loads((ROOT / 'art/props/story-slice-v1/catalog.json').read_text(encoding='utf-8'))
    originals = 0
    for entry in sources['assets']:
        path = ROOT / entry['source']
        assert digest(path) == entry['sha256'], ('Master changed', path)
        original = Path(entry['original'])
        if original.exists():
            assert digest(original) == entry['sha256'], ('Not a byte-exact source copy', path)
            originals += 1
    textures = {entry['id']: entry for entry in catalogue['assets']}
    for entry in textures.values():
        path = ROOT / entry['texture'].removeprefix('res://')
        assert digest(path) == entry['sha256']
        image = Image.open(path).convert('RGBA')
        assert list(image.size) == entry['canvas']
        opaque = {rgb[:3] for rgb in image.get_flattened_data() if rgb[3]}
        assert len(opaque) <= (96 if entry['kind'] == 'conversation-backdrop' else 64)
        if entry['kind'] != 'conversation-backdrop':
            assert set(image.getchannel('A').get_flattened_data()) == {0, 255}
        if entry['kind'] == 'inventory-icon':
            x0, y0, x1, y1 = image.getchannel('A').getbbox()
            assert min(x0, y0) >= 8 and max(x1, y1) <= 120
        if entry['kind'] == 'room-prop':
            assert image.getchannel('A').getbbox()[3] <= 180
    for base in ('three-knocks', 'iron-seam'):
        used = textures[base + '-used']
        for key in ('source_bounds', 'scale', 'offset', 'pivot', 'canvas'):
            assert textures[base][key] == used[key], ('Registration differs', base, key)
    resources = []
    for kind, paths in (
        ('gear', ['data/gear/' + ident + '.tres' for ident in ('companion_short_sword', 'companion_mace', 'camp_forged_blade')]),
        ('event', ['data/events/quest_' + ident + '.tres' for ident in ('three_knocks', 'iron_seam', 'lower_gate')]),
        ('conversation', ['data/conversations/' + ident + '.tres' for ident in ('commander_first', 'commander_report', 'commander_waiting', 'miner_thanks')]),
    ):
        for relative in paths:
            original = subprocess.check_output(['git', 'show', sources['baseline_commit'] + ':' + relative], cwd=ROOT, text=True)
            current = (ROOT / relative).read_text(encoding='utf-8')
            assert visual_neutral(current, kind) == visual_neutral(original, kind), ('Nonvisual content changed', relative)
            resources.append(relative)
    report = {'masters': len(sources['assets']), 'byte_exact_originals_present': originals, 'exports': len(textures),
              'shared_prop_state_transforms': 2, 'unchanged_nonvisual_resources': resources,
              'baseline': sources['baseline_commit'], 'failures': []}
    (ROOT / 'art/concepts/story-slice-v1/export-validation.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
    print(f"Validated {len(textures)} exports, {len(resources)} unchanged rule/dialogue resources, and {originals} byte-exact source copies.")


if __name__ == '__main__':
    main()

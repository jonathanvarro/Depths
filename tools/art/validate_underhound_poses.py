"""Independent source/PNG/approval contract checks for the three-pose family."""
from pathlib import Path
from PIL import Image
import hashlib, json, sys

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'art/enemies/underhound-v1'
REVIEW = ROOT / 'art/concepts/underhound-poses-v1'
SOURCE = ROOT / 'art/source/underhound-v1'
results = []

def check(ok, label):
    results.append({'check': label, 'ok': bool(ok)})
    if not ok:
        print('FAIL', label)

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

approval = json.loads((OUT / 'approval.json').read_text())
manifest = json.loads((SOURCE / 'poses.json').read_text())
catalog = json.loads((OUT / 'catalog.json').read_text())
palette = {tuple(rgb) for rgb in json.loads((OUT / 'palette.json').read_text())['rgb']}
check(sha(OUT / 'idle.png') == approval['native_png_sha256'], 'Approved idle PNG unchanged')
check(sha(SOURCE / 'idle-master.png') == approval['master_sha256'], 'Approved source master unchanged')
check(set(catalog['animations']) == {'idle', 'attack', 'hurt'}, 'All three states advertised')
check(catalog['shared_registration']['per_pose_fit_or_grounding'] is False, 'Common registration, no per-pose fit')
check(catalog['shared_registration']['source_canvas'] == list(Image.open(SOURCE / 'idle-master.png').size), 'Actual source canvas recorded')
for ref in manifest['references']:
    check(sha(ROOT / ref['path']) == ref['sha256'], 'Preserved reference '+ref['path'])
for pose in manifest['poses']:
    source = ROOT / pose['source']
    check(sha(source) == pose['sha256'], 'Immutable master '+pose['id'])
    original = Path(pose['original_path'])
    if original.exists():
        check(original.read_bytes() == source.read_bytes(), 'Exact built-in copy '+pose['id'])
    check(len(pose['prompt']) > 100 and manifest['tool'] == 'built-in image_gen', 'Exact prompt/tool '+pose['id'])
union, hashes = set(), set()
for name in ('idle', 'attack', 'hurt'):
    path = OUT / (name + '.png')
    image = Image.open(path)
    check(image.mode == 'RGBA' and image.size == (128, 128), 'Native128 RGBA '+name)
    pixels = list(image.get_flattened_data())
    colors = {p[:3] for p in pixels if p[3]}
    union |= colors
    check(colors <= palette, 'Approved palette only '+name)
    check({p[3] for p in pixels} == {0, 255}, 'Binary alpha '+name)
    check(all(p[:3] == (0, 0, 0) for p in pixels if not p[3]), 'Invisible RGB cleared '+name)
    box = image.getbbox()
    check(box[0] >= 4 and box[2] <= 124 and box[1] >= 8 and box[3] <= 124, 'No clipped body/tail/jaw '+name)
    check(sha(path) == catalog['poses'][name]['sha256'], 'Recorded export hash '+name)
    hashes.add(sha(path))
check(len(hashes) == 3 and len(union) <= 32, 'Three distinct drawings, at most 32 colours in the whole family')
check(Image.open(OUT / 'attack.png').getbbox()[3] == 121, 'Attack keeps planted contact y120')
check(Image.open(OUT / 'hurt.png').getbbox()[3] < 121, 'Raised hurt paw is not snapped down to idle baseline')
godot = json.loads((REVIEW / 'godot-validation.json').read_text())
check(not godot['failures'], 'Actual combat UI review passes')
check(len(godot['captures']) == 12 and all((REVIEW / name).exists() for name in godot['captures']), 'All twelve combat captures retained')
for folder in (SOURCE, REVIEW):
    check((folder / '.gdignore').exists(), 'Sources/review excluded from runtime '+folder.name)
failed = sum(not r['ok'] for r in results)
(REVIEW / 'source-validation.json').write_text(json.dumps({'checks': len(results), 'failed': failed, 'results': results}, indent=2) + '\n', encoding='utf-8', newline='\n')
print(f'UNDERHOUND_SOURCE: {len(results)} checks, {failed} failed')
sys.exit(1 if failed else 0)

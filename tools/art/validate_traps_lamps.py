"""Independent native/source preservation and visual-only resource checks."""
from pathlib import Path
from PIL import Image
import hashlib, json, re, subprocess

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / 'art/source/traps-lamps-v1'
OUT = ROOT / 'art/props/traps-lamps-v1'
REVIEW = ROOT / 'art/concepts/traps-lamps-v1'
results = []

def check(ok, label):
    results.append({'ok': bool(ok), 'label': label})
    if not ok:
        print('FAIL:', label)

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

m = json.loads((SOURCE / 'generation.json').read_text())
c = json.loads((OUT / 'catalog.json').read_text())
check(len(m['assets']) == 9 and m['tool'] == 'built-in image_gen', 'Nine authored textures with built-in source records')
for ref in m['references']:
    check(sha(ROOT / ref['path']) == ref['sha256'], 'Unchanged existing reference ' + ref['path'])
for entry in m['assets']:
    id = entry['id']
    path = SOURCE / (id + '.png')
    check(sha(path) == entry['sha256'] and len(entry['prompt']) > 100, 'Pinned master and exact prompt ' + id)
    original = Path(entry['original_path'])
    if original.exists():
        check(original.read_bytes() == path.read_bytes(), 'Unaltered original copy ' + id)
    image = Image.open(OUT / (id + '.png'))
    pixels = list(image.get_flattened_data())
    check(image.mode == 'RGBA' and image.size == (128, 128), 'Native128 RGBA ' + id)
    check({p[3] for p in pixels} == {0, 255} and all(p[:3] == (0, 0, 0) for p in pixels if not p[3]), 'Hard alpha, clear invisible RGB ' + id)
    check(sha(OUT / (id + '.png')) == c['records'][id]['sha256'], 'Export hash ' + id)
    box = image.getbbox()
    check(box[0] > 0 and box[1] > 0 and box[2] < 128 and box[3] < 128, 'Silhouette has transparent margins ' + id)
for name in ['snare', 'dart', 'bell', 'lamp']:
    paths = [OUT / (name + '-' + state + '.png') for state in ['closed', 'used']]
    colors = {p[:3] for path in paths for p in Image.open(path).get_flattened_data() if p[3]}
    check(len(colors) <= 32 and paths[0].read_bytes() != paths[1].read_bytes(), 'Distinct pair and shared <=32 colors ' + name)
    sizes = [Image.open(SOURCE / (name + '-' + state + '.png')).size for state in ['closed', 'used']]
    check(sizes[0] == sizes[1] and sizes[0][0] == sizes[0][1], 'Shared full source canvas ' + name)
ports = Image.open(OUT / 'dart-ports.png')
check(sum(1 for r, g, b, a in ports.get_flattened_data() if a == 255 and max(r, g, b) < 12) >= 40, 'Dart holes contain opaque darkness, not transparent cutouts')
for event in ['trap_snare', 'trap_dart', 'trap_bell_wire', 'territory_lamp_eaters']:
    path = 'data/events/' + event + '.tres'
    old = subprocess.check_output(['git', 'show', 'HEAD:' + path], cwd=ROOT).decode()
    current = (ROOT / path).read_text()
    def without_art(value):
        return re.sub(r'(type="PackedScene" path=")[^"]+', r'\1<art>', value).replace('\r\n', '\n')
    check(without_art(old) == without_art(current), 'Only art reference changed; all event rules preserved ' + event)
package = 'data/packages/territory_lamp_eaters.tres'
check(subprocess.check_output(['git', 'show', 'HEAD:' + package], cwd=ROOT).decode().replace('\r\n', '\n') == (ROOT / package).read_text(), 'Territory placement/chance preserved')
for folder in [SOURCE, REVIEW]:
    check((folder / '.gdignore').exists(), 'Source/review excluded ' + folder.name)
report = {'checks': len(results), 'failures': [r for r in results if not r['ok']], 'results': results}
(REVIEW / 'source-validation.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8', newline='\n')
print('TRAPS_LAMPS_SOURCE:', len(results), 'checks,', len(report['failures']), 'failures')
raise SystemExit(1 if report['failures'] else 0)

"""Review the live fungal set, retaining hashes of unchanged reused art."""
from pathlib import Path
import hashlib, json, re, subprocess

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'art/concepts/fungal-caverns-v1'

shots = [
    ('main-1278-normal', 'Live floor two · phone'),
    ('main-phone-before', 'Previous cave set · same phone position'),
    ('main-1278-larger', 'Live floor two · phone Larger'),
    ('main-1280-normal', 'Live floor two · desktop'),
    ('main-1280-larger', 'Live floor two · desktop Larger'),
    ('main-phone-out', 'Live floor two · carried light Out'),
    ('hall-neutral-review', 'Neutral material inspection · brighter than live light'),
]
for width in (1280, 1278):
    shots.extend((f'{view}-{width}-lantern', f'{view.title()} · {width}px · carried lantern')
                 for view in ('hall', 'roots', 'crossing', 'wall'))
shots.extend((f'hall-phone-{mode}', f'Isolated hall · phone · {mode}')
             for mode in ('dim', 'out', 'still'))
assert all((OUT / (name + '.png')).exists() for name, _ in shots)

script = (ROOT / 'scripts/fungal_dressing.gd').read_text(encoding='utf-8')
stems = set(re.findall(r'"((?:cave-v[12]|landmarks-v1)/[^"\n]+)"', script))
stems.update(('cave-v2/moss-curtain-lit', 'cave-v2/floor-fungus-lit'))
queue = [f'art/dressing/{stem}.tscn' for stem in stems]
queue.extend(('themes/cave.tres', 'themes/fortress.tres',
              'art/textures/descent-walls-v1/fungal-stone.tres',
              'art/textures/descent-surfaces-v1/fungal-stone-floor.tres',
              'art/textures/descent-surfaces-v1/fungal-stone-ceiling.tres',
              'art/effects/ambient-v1/fungus-pulse.tres',
              'art/effects/ambient-v1/drip.tres'))
files = set()
while queue:
    name = queue.pop()
    if Path(name).suffix == '.gd':
        continue  # integration scripts are intentionally changed, not reused art
    if name in files:
        continue
    files.add(name)
    path = ROOT / name
    assert path.is_file(), name
    if path.suffix in ('.tres', '.tscn'):
        queue.extend(re.findall(r'path="res://([^"\n]+)"', path.read_text(encoding='utf-8-sig')))
# Reused art/themes must remain identical to tracked inputs, allowing Git's
# ordinary text newline normalization.
subprocess.run(['git', 'diff', '--quiet', 'HEAD', '--', *sorted(files)], cwd=ROOT, check=True)
(OUT / 'reused-assets.json').write_text(json.dumps({
    'date': '2026-10-25', 'new_raster_art': False,
    'files': [{'path': name, 'sha256': hashlib.sha256((ROOT / name).read_bytes()).hexdigest()}
              for name in sorted(files)],
}, indent=2) + '\n', encoding='utf-8', newline='\n')

runs = []
for name in ('dressing_check', 'save_check', 'fortress_check'):
    log = ROOT / 'build/fungal-review' / (name + '.log')
    text = log.read_text(encoding='utf-8-sig')
    assert not re.search(r'^FAIL |SCRIPT ERROR', text, re.M), name
    runs.append({'name': name, 'passes': len(re.findall(r'^PASS ', text, re.M)),
                 'failures': 0, 'private_save': True,
                 'log_sha256': hashlib.sha256(log.read_bytes()).hexdigest()})
(OUT / 'regressions.json').write_text(json.dumps({
    'date': '2026-10-25', 'runs': runs,
    'timing': 'Continue initially failed in parallel runs; unchanged HEAD and current Main pass alone. Legacy fixed-delay Main fixtures should run sequentially.',
    'shutdown': 'Existing full-game teardown RID/object/resource warnings remain; isolated fungal fixture is clean.',
    'physical_iPhone': False,
}, indent=2) + '\n', encoding='utf-8', newline='\n')

html = '''<!doctype html><html lang="en"><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Depths · Fungal Caverns</title><style>
body{margin:0;background:#10140f;color:#e6dac1;font:17px system-ui}
header{padding:20px 24px;max-width:1280px;margin:auto}h1{font:30px Georgia;margin:8px 0}
p{color:#b3a78f;max-width:85ch;line-height:1.5}nav{display:flex;gap:10px;flex-wrap:wrap}
select,button{font:inherit;background:#22271e;color:#e6dac1;border:1px solid #776343;padding:10px;min-height:44px;max-width:100%}
figure{margin:0 auto;max-width:1440px}img{width:100%;height:auto;display:block}
figcaption{padding:14px 24px;color:#b3a78f}a{color:#dbb477}
</style><header><small>LIVE ENVIRONMENT · DEPTH TWO</small><h1>Fungal Caverns</h1>
<p>Matched stone, floor and ceiling; sparse roots, moss, fungi and drips. Compare the previous cave set from the same phone position, or inspect the materials under neutral review light. These are actual Godot captures.</p>
<nav><select id="shot" aria-label="Review capture"></select><button id="before">Before</button><button id="after">After</button><button id="neutral">Materials</button></nav>
<p><a href="../../../docs/fungal-caverns.md">Handoff and checks</a> · <a href="../../../docs/underhound-production.md">First deeper horror: Underhound</a></p></header>
<figure><img id="image" alt=""><figcaption id="caption"></figcaption></figure><script>
const shots=__SHOTS__,select=document.querySelector('#shot'),img=document.querySelector('#image'),caption=document.querySelector('#caption');
shots.forEach(([file,label],i)=>select.add(new Option(label,i)));
function show(i){select.selectedIndex=i;const[file,label]=shots[i];img.src=file+'.png';img.alt=label;caption.textContent=label+' · Windows renderer; physical iPhone appearance/performance remains untested.';}
select.onchange=()=>show(select.selectedIndex);document.querySelector('#before').onclick=()=>show(1);document.querySelector('#after').onclick=()=>show(0);document.querySelector('#neutral').onclick=()=>show(6);show(0);
</script></html>'''
(OUT / 'inspector.html').write_text(html.replace('__SHOTS__', json.dumps(shots)), encoding='utf-8', newline='\n')
print(f'FUNGAL_REVIEW: {len(shots)} captures, {len(files)} unchanged reused inputs, {sum(r["passes"] for r in runs)} regression assertions')

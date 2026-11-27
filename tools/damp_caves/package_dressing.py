"""Build the local native-capture review; never launch a visible browser."""
import argparse
import html
import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
parser=argparse.ArgumentParser();parser.add_argument('--workspace',type=Path,required=True);args=parser.parse_args()
ART=ROOT/'art/dressing/damp-dressing-v1';REVIEW=args.workspace/'build/local-damp-dressing-v1'
catalog=json.loads((ART/'catalog.json').read_text());report=json.loads((REVIEW/'native/validation.json').read_text())
assert not report['failures'],report['failures']
for file in report['captures']:assert (REVIEW/'native'/file).is_file(),file
cards=[]
for row in catalog['assets']:
    name=html.escape(row['id']);mount=html.escape(row['mount'])
    cards.append(f'<article data-id="{name}"><h3>{name}</h3><a class="image" href="native/{name}-neutral.png"><img loading="lazy" src="native/{name}-neutral.png" data-neutral="native/{name}-neutral.png" data-phone="native/{name}-phone.png" alt="Native {name}"></a><p>{mount} · {row["triangles"]:,} triangles · 1 draw</p><p><a href="masters/{name}.blend">Editable master</a></p></article>')
rooms=[]
for mode in ['wet-room','fungal-exit-room','lost-cache','mine-conversions']:
    for width in [1280,1278,844]:
        file=f'{mode}-{width}.png'
        rooms.append(f'<figure><a href="native/{file}"><img loading="lazy" src="native/{file}" alt="{mode} {width}"></a><figcaption>{mode} · {width}px</figcaption></figure>')
effects=[]
for mode in ['drip','drip-stalactite-effect']:
    for sample in ['fall','impact']:
        file=f'{mode}-{sample}.png'
        effects.append(f'<figure><a href="native/{file}"><img loading="lazy" src="native/{file}" alt="{mode} {sample}"></a><figcaption>{mode} · {sample} paused sample</figcaption></figure>')
page='''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Depths · Damp Caves dressing</title>
<style>body{margin:0;background:#10191b;color:#d6d2bd;font:16px/1.55 system-ui}main{max-width:1440px;margin:auto;padding:36px}h1,h2,h3{font-family:Georgia,serif;color:#d4b67c}h1{font-size:38px;margin-bottom:8px}h2{margin-top:40px}h3{margin:12px 16px}a{color:#d4b67c}header{border-bottom:1px solid #736345;padding-bottom:24px}button,input{padding:12px 18px;background:#222b29;color:#eee4cb;border:1px solid #8e784c;font:inherit;margin:6px}button{cursor:pointer}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(320px,1fr));gap:18px}article,figure{margin:0;background:#152023;border:1px solid #47524b}img{width:100%;display:block}article p,figcaption{margin:8px 16px}article a.image{display:block}small{color:#adb6ad}.tools{position:sticky;top:0;padding:10px;background:#10191bf5;z-index:2}input{width:250px}.status{color:#b9ccad}</style>
<main><header><small>DEPTHS · #302 C/D · ORIGINAL PROJECT GEOMETRY</small><h1>Damp Caves dressing & early 3D conversions</h1>
<p>45 solid models, 21 dry mine counterparts, 29 old-id dispositions. All images are actual Godot 4.7.2 Mobile/D3D12 renders. This is an art library, awaiting Claude’s live placement and theme hookup.</p>
<p class="status">CHECK_COUNT checks passed · CAPTURE_COUNT native captures · private desktop, isolated profile · physical iPhone and owner review remain.</p>
<p>Wet limestone, restrained mineral sheen, fibrous roof roots, shallow opaque water, mud/gravel/marks, worn cache supplies, and registered fresh/resolved event geometry. The separate mushroom/mold pieces belong in the Fungal Hollows exit room; decorative glow is not party light.</p>
<p><a href="native/validation.json">Native validation & measured budgets</a> · <a href="native-launch/launch.json">Isolated desktop record</a></p></header>
<h2>Room-scale examples</h2><p>Metric presentation fixtures, not seeded live placements. Desktop and both landscape phone shapes.</p><div class="grid">ROOMS</div>
<h2>Individual pieces & registered states</h2><div class="tools"><button data-mode="neutral">Neutral inspection</button><button data-mode="phone">Phone / torch</button><input id="filter" aria-label="Filter assets" placeholder="Filter models…"></div><div id="assets" class="grid">CARDS</div>
<h2>Falling drip & ripple</h2><p>One opaque bead and one expanding ring; no particles or extra light. Motion is off by default. set_motion(false) resets the exact pose and stops processing. Roof and stalactite hooks land at floor level.</p><div class="grid">EFFECTS</div>
<h2>Hookup boundaries</h2><p>+Z faces out of a real wall; ceiling pieces start at the roof; floor/edge pieces use y=0. Floor relief sits only millimetres above the caller’s floor. Existing mist and verified bone/mine libraries are reused. State wrappers accept the old closed/empty container property, and expose fresh/empty or fresh/used explicitly. No collision, travel, water, poison, quests or RNG belongs to these assets.</p>
<p>Editable separate-piece Blender masters remain local in masters/. Sources, hashes, exact engine envelopes and every replacement path are recorded in art/dressing/damp-dressing-v1/catalog.json in the delivery branch.</p>
</main><script>document.querySelectorAll('button[data-mode]').forEach(b=>b.onclick=()=>document.querySelectorAll('#assets img').forEach(img=>{img.src=img.dataset[b.dataset.mode];img.parentElement.href=img.src}));document.querySelector('#filter').oninput=e=>document.querySelectorAll('article[data-id]').forEach(a=>a.hidden=!a.dataset.id.includes(e.target.value.toLowerCase()));</script></html>'''
page=page.replace('CHECK_COUNT',str(report['checks'])).replace('CAPTURE_COUNT',str(len(report['captures'])))
page=page.replace('ROOMS','\n'.join(rooms)).replace('CARDS','\n'.join(cards)).replace('EFFECTS','\n'.join(effects))
(REVIEW/'inspector.html').write_text(page,encoding='utf-8')
print('Packaged native review:',REVIEW/'inspector.html')

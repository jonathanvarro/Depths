"""Local native gallery for E/F. No visible browser or owner data access."""
import argparse
import html
import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
p=argparse.ArgumentParser();p.add_argument('--workspace',type=Path,required=True);args=p.parse_args()
out=args.workspace/'build/local-damp-sites-v1'
catalog=json.loads((ROOT/'art/props/damp-sites-v1/catalog.json').read_text())
report=json.loads((out/'native/validation.json').read_text());assert not report['failures'],report['failures']
for file in report['captures']:assert (out/'native'/file).is_file(),file
landmarks=[]
for row in catalog['landmarks']:
    name=row['id'];cost=report['scene_counts'][name]
    attrs=' '.join(f'data-{mode}="native/{name}-{suffix}.png"' for mode,suffix in [('desktop','1280'),('phone','844'),('wide','1278'),('overview','overview')])
    landmarks.append(f'<article><h3>{html.escape(name.removeprefix("landmark-").replace("-"," "))}</h3><a class="shot" href="native/{name}-1280.png"><img loading="lazy" src="native/{name}-1280.png" {attrs} alt="Native {name}"></a><p>{cost["triangles"]:,} triangles · {cost["draws"]} draws · {row["room_cells"]} cells</p><p>{html.escape(row["layout"])}</p></article>')
events=[]
for row in catalog['events']:
    for state in row['states']:
        name=row['id']+'-'+state;cost=report['scene_counts'][name]
        events.append(f'<article><h3>{row["id"]} · {state}</h3><a class="shot" href="native/{name}-neutral.png"><img loading="lazy" src="native/{name}-neutral.png" data-neutral="native/{name}-neutral.png" data-phone="native/{name}-phone.png" alt="Native {name}"></a><p>{cost["triangles"]:,} triangles · {cost["draws"]} draws</p></article>')
pieces=[]
for row in catalog['assets']:
    name=row['id'];pieces.append(f'<article><h3>{name}</h3><a href="native/raw-{name}-neutral.png"><img loading="lazy" src="native/raw-{name}-neutral.png" alt="Solid {name}"></a><p>{row["triangles"]:,} triangles · 1 draw · <a href="masters/{name}.blend">Editable master</a></p></article>')
page='''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Depths · Damp Caves landmarks & props</title>
<style>body{margin:0;background:#10191b;color:#d6d2bd;font:16px/1.55 system-ui}main{max-width:1440px;margin:auto;padding:36px}h1,h2,h3{font-family:Georgia,serif;color:#d4b67c}h1{font-size:38px;margin-bottom:8px}h2{margin-top:40px}h3{margin:12px 16px}a{color:#d4b67c}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(350px,1fr));gap:18px}article{background:#152023;border:1px solid #47524b}article p{margin:8px 16px}img{width:100%;display:block}.tools{position:sticky;top:0;padding:10px;background:#10191bf5;z-index:2}button{padding:10px 16px;background:#222b29;color:#eee4cb;border:1px solid #8e784c;font:inherit;margin:4px;cursor:pointer}header{border-bottom:1px solid #736345;padding-bottom:24px}small{color:#adb6ad}</style>
<main><header><small>DEPTHS · #302 E/F · ACTUAL NATIVE MOBILE CAPTURES</small><h1>Damp Caves landmarks & interactive appearances</h1><p>Six reusable landmark compositions, five event prop sets and fourteen solid exports. These are visual assets awaiting Claude’s live placement, event choices and rules.</p><p>CHECKS checks passed · SHOTS real captures · desktop and both landscape phone shapes · isolated Windows desktop, no owner saves or active-window changes.</p><p><a href="native/validation.json">Measured budgets & native report</a> · <a href="native-launch/launch.json">Isolated desktop record</a></p></header>
<h2>Landmarks</h2><div class="tools" data-target="landmarks"><button data-view="desktop">Desktop / torch</button><button data-view="wide">1278×590</button><button data-view="phone">844×390</button><button data-view="overview">Neutral layout</button></div><div class="grid" id="landmarks">LANDMARKS</div>
<h2>Interactive props and resolved states</h2><p>Appearance swaps are immediate and restorable. The ledge deliberately requires an explicit slipped/passed outcome; generic “empty” is rejected. The seep keeps its natural water. Fish bodies remain opaque; only their small viewing-water surface uses alpha.</p><div class="tools" data-target="events"><button data-view="neutral">Neutral inspection</button><button data-view="phone">Phone / torch</button></div><div class="grid" id="events">EVENTS</div>
<h2>Solid detail exports</h2><div class="grid">PIECES</div>
<h2>Integration boundaries</h2><p>Room scenes include scenery, caller interaction/approach markers and metric footprint notes. The rooms’ surrounding walls/floor in these captures are review fixtures. Fit real map walls and preserve dry-route/quest authority. Most landmarks use 3×3 cells; drowned drift uses 1×3. The slick ledge supplies an actual recessed tile and requires the caller floor omitted. Other water is decorative, not map.water.</p><p>The minecart derives from Kio Kurashi’s <a href="https://kiokurashi.itch.io/3d-static-minecart">CC0 Static Minecart</a>. Existing verified KayKit bones, the project pack, rails and dressing are reused. Sources and changes are recorded in the repository catalogue and credits. Separate-piece Blender masters stay local. No new private model or external animation clips.</p><p>Motion defaults off. Fresh fish and explicitly enabled child drips support exact reset and stop processing in still mode. Owner style review, physical iPhone performance, live seeded placement and exported-game hookup remain.</p></main>
<script>document.querySelectorAll('.tools').forEach(t=>t.querySelectorAll('button').forEach(b=>b.onclick=()=>document.querySelectorAll('#'+t.dataset.target+' img').forEach(i=>{i.src=i.dataset[b.dataset.view];i.parentElement.href=i.src})));</script></html>'''
page=page.replace('CHECKS',str(report['checks'])).replace('SHOTS',str(len(report['captures'])))
page=page.replace('LANDMARKS','\n'.join(landmarks)).replace('EVENTS','\n'.join(events)).replace('PIECES','\n'.join(pieces))
(out/'inspector.html').write_text(page,encoding='utf-8');print(out/'inspector.html')

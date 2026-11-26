"""Assemble untouched native review captures; no image processing or uploads."""
import argparse
from html import escape
from pathlib import Path
import shutil

parser=argparse.ArgumentParser()
parser.add_argument('--review',type=Path,required=True)
parser.add_argument('--baseline',type=Path,required=True)
parser.add_argument('--follow-up',action='store_true',help='Compare #294 against the retained #293 captures')
args=parser.parse_args()
out=args.review;old=out/'baseline';old.mkdir(parents=True,exist_ok=True)
for path in (args.baseline/'captures').glob('*.png'):
    shutil.copyfile(path,old/path.name)

def picture(path,label):
    return f'<figure><a href="{escape(path)}"><img loading="lazy" src="{escape(path)}" alt="{escape(label)}"></a><figcaption>{escape(label)}</figcaption></figure>'

body='''<h1>Rats &amp; cave bat — six review refinements</h1>
<p>Native Godot Mobile captures. Click any image for original resolution.
Left: retained baseline. Right: revised model. Studio lighting is deliberately
plain; field images show the actual game. No physical iPhone review yet.</p>'''
pairs=[
    ('Rat muzzle, paws & curved tail','rat-idle-0-40','rat-idle-0-40'),
    ('Great rat shoulders & bristles','great-rat-idle-0-40','great-rat-idle-0-40'),
    ('Bat wing depth and head','bat-idle-0-0','bat-idle-0-0'),
    ('Folded grounded bat','bat-landed-0-40','bat-landed-0-40')]
if args.follow_up:
    body='''<h1>Rat revision — owner / Claude feedback #294</h1>
    <p>Left: merged #293 baseline. Right: revised candidate. Native Mobile-renderer
    captures, original resolutions. The approved bat flight and first-person camera
    logic are retained. Compare the front view and actual phone fights first.</p>'''
    pairs=[('Rat: visible red eyes, tucked legs, smaller rear-set ears','rat-idle-0-0','rat-idle-0-0'),
           ('Rat: longer tapered snout and lower silhouette','rat-idle-0-90','rat-idle-0-90'),
           ('Great rat: front threat and prominent incisors','great-rat-idle-0-0','great-rat-idle-0-0'),
           ('Great rat: lower bulk, bristles and matte coat','great-rat-idle-0-40','great-rat-idle-0-40'),
           ('Grounded bat: broader wing outline','bat-landed-0-40','bat-landed-0-40')]
for title,before,after in pairs:
    body+=f'<h2>{title}</h2><div class="pair">'+picture('baseline/'+before+'.png','Before')+picture('captures/'+after+'.png','After')+'</div>'
body+='<h2>First-person phone view</h2><p>Camera framing keeps low models above combat actions. Model origins stay on the floor.</p>'
body+='<div class="pair">'+picture('baseline/live-rat-844.png','Earlier rat framing')+picture('live-check/field-rat-idle-844.png','Revised rat framing')+'</div>'
body+='<div class="pair">'+picture('baseline/live-cave_bat-landed-844.png','Earlier grounded bat framing')+picture('live-check/field-cave_bat-landed-844.png','Revised grounded bat framing')+'</div>'
body+='<h2>Additional poses and angles</h2><div class="pair">'
for name in ['rat-attack-29-40','rat-idle-0-90','great-rat-idle-0-90','whisker-idle-0-40','bat-idle-25-0','bat-idle-50-0','bat-swoop-29-40','bat-bite-29-40','bat-hurt-ground-13-40','bat-fall-ground-100-40']:
    body+=picture('captures/'+name+'.png',name)
body+='</div><h2>Phone layouts</h2><div class="pair">'
for name in ['field-great_rat-idle-667','field-rat-attack-844','field-cave_bat-idle-844','field-cave_bat-bite-667']:
    body+=picture('live-check/'+name+'.png',name)
body+='</div><p><a href="live-check/validation.json">Geometry / framing results</a> · Editable Blender files: masters/ · Source and limits: docs/rat-bat-refinement.md</p>'
if args.follow_up:body=body.replace('docs/rat-bat-refinement.md','docs/rat-predatory-revision.md')
html='''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width"><title>Depths — creature refinement review</title><style>
body{background:#141916;color:#ddd3bb;font:17px/1.6 Georgia,serif;max-width:1500px;margin:40px auto;padding:0 24px}h1,h2{color:#d0ad6f}h2{border-top:1px solid #665638;padding-top:24px}.pair{display:grid;grid-template-columns:1fr 1fr;gap:20px}figure{margin:0 0 20px;background:#202723;padding:10px;border:1px solid #655536}img{display:block;width:100%;height:auto}a{color:#d0ad6f}figcaption{font:14px/1.5 system-ui;margin-top:8px}@media(max-width:700px){.pair{grid-template-columns:1fr}}</style>'''+body+'</html>'
(out/'inspector.html').write_text(html,encoding='utf-8')
print(out/'inspector.html')

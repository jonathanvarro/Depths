"""Promote live-shape regional adaptations; preserve all nonvisual game fields."""
from pathlib import Path
import hashlib
import html
import json
import sys
sys.dont_write_bytecode=True
from PIL import Image
from build_field_kit_art import fitted
from build_regional_equipment_icons import validate_icon, DECISIONS

ROOT=Path(__file__).resolve().parents[2]
SOURCE=ROOT/'art/source/regional-equipment-v2'
OUT=ROOT/'art/items/regional-equipment-v2'
REVIEW=ROOT/'art/concepts/regional-equipment-v2'
NAMES={'quilted_coat':'Quilted coat','studded_jerkin':'Studded jerkin',
       'goblin_scale':'Goblin scale shirt','goblin_shield':'Goblin round shield'}
MAP={'quilted-work-coat':'quilted_coat','riveted-guard-coat':'studded_jerkin',
     'garrison-scale-coat':'goblin_scale','gate-guards-shield':'goblin_shield'}
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def main():
    generation=json.loads((SOURCE/'generation.json').read_text(encoding='utf-8'))
    (OUT/'compact64').mkdir(parents=True,exist_ok=True);REVIEW.mkdir(parents=True,exist_ok=True)
    (REVIEW/'.gdignore').touch()
    bases_path=ROOT/'data/equipment/bases.json';data=json.loads(bases_path.read_text(encoding='utf-8'))
    before=json.loads(json.dumps(data));items=[]
    for a in generation['assets']:
        path=SOURCE/a['file'];assert sha(path)==a['sha256'] and sha(ROOT/a['reference'])==a['reference_sha256']
        raw=Image.open(path).convert('RGBA');assert raw.getchannel('A').getextrema()[0]==0
        id=a['id'];row=next(b for b in data['bases'] if b['id']==id)
        old=row.get('icon','res://art/items/refined-v2/padded-coat.png')
        for size in [128,64]:
            icon,_=fitted(raw,size,64);validate_icon(icon,size)
            target=OUT/(id+'.png') if size==128 else OUT/'compact64'/(id+'.png')
            icon.save(target)
        row['icon']='res://'+(OUT/(id+'.png')).relative_to(ROOT).as_posix()
        items.append({'id':id,'name':NAMES[id],'old_icon':old,'icon':row['icon'],
            'source':path.relative_to(ROOT).as_posix(),'source_sha256':a['sha256'],
            'icon_sha256':sha(OUT/(id+'.png'))})
    for prior,current in zip(before['bases'],data['bases']):
        assert {k:v for k,v in prior.items() if k!='icon'}=={k:v for k,v in current.items() if k!='icon'}
    bases_path.write_text(json.dumps(data,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
    gear=ROOT/'data/gear/padded_coat.tres';text=gear.read_text(encoding='utf-8')
    text=text.replace('res://art/items/refined-v2/padded-coat.png','res://art/items/regional-equipment-v2/quilted_coat.png')
    gear.write_text(text,encoding='utf-8')
    ledger=dict(DECISIONS)
    for candidate,id in MAP.items():ledger[candidate]='Adapted to the current '+NAMES[id]+'; new production icon, unchanged item rules.'
    ledger.update({'miners-sling':'Use the newer Leather sling production design (ranged-focus-v1).',
        'hazel-walking-staff':'Use the newer Oak Staff production design (ranged-focus-v1); this remains an alternative concept.',
        'sentry-shortbow':'Use the newer Short Bow production design (ranged-focus-v1).',
        'cinderwood-baton':'Use the newer Prayer Wand production design (ranged-focus-v1); no new regional base.',
        'raiders-leather-vest':'The live Studded jerkin now has its own asymmetric vest adaptation.',
        'survey-cape':'Keep the live full Oilcloth cloak; the short hooded cape remains an unused alternative.',
        'riveted-mining-coat':'Retained concept with no live base; no new gear ID or stats introduced.',
        'surveyors-shortsword':'Keep the founder sword and current ordinary sword pictures; unused alternative retained.'})
    (OUT/'catalog.json').write_text(json.dumps({'items':items,'candidate_audit':ledger,'nonvisual_fields_preserved':True},indent=2)+'\n',encoding='utf-8')
    cards=[]
    for a in items:
        cards.append('<article><h2>'+a['name']+'</h2><p>Previous · revised · compact</p>'+''.join(
            f'<img width="{s}" height="{s}" src="../../../{p[6:]}" alt="{html.escape(a["name"])}">'
            for s,p in [(64,a['old_icon']),(128,a['icon']),(64,a['icon'].replace('/'+a['id']+'.png','/compact64/'+a['id']+'.png'))])+'</article>')
    rows=''.join('<tr><th>'+html.escape(k.replace('-',' '))+'</th><td>'+html.escape(v)+'</td></tr>' for k,v in ledger.items())
    page='''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Depths · Regional equipment finish</title><style>body{background:#141a17;color:#e2d9c1;font:16px/1.5 Georgia,serif;max-width:1100px;margin:auto;padding:22px}main{display:grid;grid-template-columns:repeat(auto-fit,minmax(min(100%,320px),1fr));gap:16px}article,table{background:#252b23;border:1px solid #826f47;padding:18px}img{object-fit:contain;image-rendering:pixelated;max-width:100%}th,td{text-align:left;padding:10px;border-bottom:1px solid #514c38}table{width:100%;border-collapse:collapse}a{color:#d9ba7e}</style><h1>Regional equipment · production adaptations</h1><p>Worn, handmade materials fitted to the actual live item shapes. Original concepts remain preserved; no new equipment rules or base IDs.</p><main>'''+''.join(cards)+'</main><h2>All 22 regional concepts accounted for</h2><table>'+rows+'</table><p><a href="../../../docs/companion-polish-and-regional-equipment.md">Sources, validation and handoff</a></p></html>'
    (REVIEW/'inspector.html').write_text(page,encoding='utf-8')
    print('Four production icons exported at 128/64; all 22 concepts reconciled; nonvisual fields unchanged')
if __name__=='__main__':main()

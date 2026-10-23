"""Verify original drafts, reference integrity and complete concept coverage."""
from pathlib import Path
from PIL import Image
import json,hashlib,re,sys
ROOT=Path(__file__).resolve().parents[2];SOURCE=ROOT/'art/source/descent-horror-v1';OUT=ROOT/'art/concepts/descent-horror-v1'
manifest=json.loads((SOURCE/'generation.json').read_text());cat=json.loads((OUT/'catalog.json').read_text());results=[]
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def check(ok,name):
    results.append({'check':name,'ok':bool(ok)})
    if not ok:print('FAIL',name)
check(len(manifest['assets'])==13,'Eleven preserved earlier masters and two owner-requested revisions')
check(len(cat['entries'])==10,'Ten requested beings')
check([(n,len([e for e in cat['entries'] if e['issue']==n])) for n in [150,151,152]]==[(150,3),(151,4),(152,3)],'All three batches complete as drafts')
for e in manifest['assets']:
    source=ROOT/e['source'];review=ROOT/e['review'];original=Path(e['original_path'])
    check(sha(source)==e['sha256'],'Immutable generated master '+e['id'])
    check(review.read_bytes()==source.read_bytes(),'Unaltered review copy '+e['id'])
    if original.exists():check(original.read_bytes()==source.read_bytes(),'Exact built-in output copy '+e['id'])
    image=Image.open(source);image.verify()
    with Image.open(source) as im:check(im.size==(1536,1024),'Full landscape sheet '+e['id'])
    record=json.loads((SOURCE/'records'/(e['id']+'.json')).read_text())
    check(record['prompt']==e['prompt'] and e['tool']=='built-in image_gen','Exact prompt/tool retained '+e['id'])
    for ref in e['reference_images']:
        check((ROOT/ref['path']).is_file() and sha(ROOT/ref['path'])==ref['sha256'],'Reference role/hash '+e['id']+'/'+ref['role'])
for e in cat['entries']:
    x,y,mid=e['split'];w,h=e['size']
    check(0<x<w and 0<mid<y<h,'Valid review regions '+e['id'])
    check(e['owner_selection'] is None,'Owner choice explicitly pending '+e['id'])
    check(e['id'] in (ROOT/'docs/descent-horror-concepts.md').read_text(),'Handoff covers '+e['id'])
    master=next(m for m in manifest['assets'] if m['id']==e['master_id'])
    check(e['sha256']==master['sha256'] and sha(OUT/e['file'])==master['sha256'],'Active gallery uses recorded master '+e['id'])
    if e['id'] in ['drowned-bell','sleeper-beyond']:
        check(e['master_id']==e['id']+'-revised','Current owner revision selected '+e['id'])
        check(sha(OUT/e['previous']['file'])==e['previous']['sha256'],'Previous draft preserved '+e['id'])
for p in [OUT,SOURCE]:check((p/'.gdignore').exists(),'Concepts stay outside game imports '+p.name)
for p in [ROOT/'docs/descent-horror-concepts.md']:
    for target in re.findall(r'\]\(([^)]+)\)',p.read_text()):
        if '://' in target or target.startswith('#'):continue
        check((p.parent/target.split('#')[0]).exists(),'Handoff link '+target)
failed=sum(not e['ok'] for e in results)
(OUT/'source-validation.json').write_text(json.dumps({'issues':[150,151,152],'checks':len(results),'failed':failed,'scope':'Draft sheets and source integrity; not production art or live game validation','results':results},indent=2)+'\n',encoding='utf-8',newline='\n')
print('HORROR_CONCEPT_SOURCE:',len(results),'checks,',failed,'failed');sys.exit(1 if failed else 0)

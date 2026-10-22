"""Source, visual-only binding, mobile export and builder guards for #142."""
from pathlib import Path
from PIL import Image
import hashlib,json,re,sys
sys.dont_write_bytecode=True
from build_event_trinket_art import ROOT,SOURCE,ICONS,PROPS,REVIEW,normalize
results=[]
def check(ok,name):
    results.append({'check':name,'ok':bool(ok)})
    if not ok:print('FAIL: '+name)
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
manifest=json.loads((SOURCE/'generation.json').read_text())
check(len(manifest['assets'])==15,'Fifteen distinct requested masters')
for a in manifest['assets']:
    p=ROOT/a['source'];check(sha(p)==a['sha256'],'Immutable master '+a['id'])
    origin=Path(a['original_path'])
    if origin.exists():check(origin.read_bytes()==p.read_bytes(),'Byte-exact original '+a['id'])
    check(a['tool']=='built-in image_gen' and len(a['prompt'])>500,'Tool and exact prompt '+a['id'])
    check(Image.open(p).mode=='RGBA','Generated alpha '+a['id'])
cat=json.loads((ICONS/'catalog.json').read_text());memory=0
for e in cat['items']:
    for key,size,limit in [('icon',128,64),('compact_icon',64,32)]:
        p=ROOT/e[key][6:];im=Image.open(p).convert('RGBA');data=list(im.get_flattened_data());opaque=[x for x in data if x[3]]
        check(im.size==(size,size),'Native canvas '+e['id']+key)
        check(set(p[3] for p in data)=={0,255},'Binary transparent export '+e['id']+key)
        check(len({p[:3] for p in opaque})<=limit,'Palette '+e['id']+key)
        check(all(p==(0,0,0,0) for p in data if p[3]==0),'No invisible RGB '+e['id']+key)
        box=im.getbbox();check(box[0]>=3 and box[1]>=3 and box[2]<=size-3 and box[3]<=size-3,'Consistent padding '+e['id']+key)
        memory+=size*size*4
    check(e['scale']<1,'No upscale '+e['id'])
    for r in e['resources']:
        check(e['icon'] in (ROOT/r[6:]).read_text(),'Connected icon '+r)
    if len(e['resources'])==2:
        paths=[re.search(r'\[ext_resource type="Texture2D" path="([^"]+)',(ROOT/r[6:]).read_text())[1] for r in e['resources']]
        check(paths[0]==paths[1],'Hidden curse keeps same image '+e['id'])
for e in cat['props']:
    check(e['shared_scale']<1,'No upscale '+e['id'])
    union=set()
    for t in e['textures']:
        im=Image.open(ROOT/t[6:]).convert('RGBA');data=list(im.get_flattened_data());union.update(p[:3] for p in data if p[3])
        check(im.size==(128,128),'Prop canvas '+t)
        check(set(p[3] for p in data)=={0,255},'Prop alpha '+t)
        check(all(p==(0,0,0,0) for p in data if p[3]==0),'Prop invisible RGB '+t)
        box=im.getbbox();check(box[0]>1 and box[1]>1 and box[2]<127 and box[3]<127,'Prop margin '+t)
        memory+=128*128*4
    check(len(union)<=64,'Shared paired palette '+e['id'])
    check((ROOT/e['textures'][0][6:]).read_bytes()!=(ROOT/e['textures'][1][6:]).read_bytes(),'Distinct resolved state '+e['id'])
    event=(ROOT/e['event'][6:]).read_text()
    check(e['scene'] in event,'Live event binding '+e['id'])
    check(('prop_on_wall = true' in event)==(e['mount']=='wall'),'Existing mount rule '+e['id'])
for rel,entry in json.loads((SOURCE/'bindings-before.json').read_text()).items():
    if entry['kind']=='builder':continue
    check(normalize((ROOT/rel).read_text(),entry['kind'])==normalize(entry['text'],entry['kind']),'All gameplay fields preserved '+rel)
for rel,h in json.loads((SOURCE/'preserved-art.json').read_text()).items():check(sha(ROOT/rel)==h,'Existing artwork untouched '+rel)
seal=(ROOT/'art/symbols/crest-v1/forked-seal.svg').read_text()
paths=re.findall(r'<path d="([^"]+)"',seal)
for p in (SOURCE/'native').glob('*.svg'):check(all(d in p.read_text() for d in paths),'Exact canonical seal contours '+p.name)
builder=(ROOT/'tools/story/build_trinkets.gd').read_text()
check('id.trim_suffix("_cursed")' in builder and 'trinkets-v1/' in builder,'Trinket builder retains shared art')
builder=(ROOT/'tools/story/build_shrines.gd').read_text()
check('DEFILED_SHRINE, 2, true)' in builder and all(e['scene'] in builder for e in cat['props']),'Event builder retains all three scenes and wall flag')
for p in list(ICONS.rglob('*.png'))+list(PROPS.glob('*.png')):
    settings=p.with_suffix('.png.import').read_text()
    check('compress/mode=0' in settings,'Lossless import '+p.name)
    check('mipmaps/generate=false' in settings,'No mipmaps '+p.name)
report={'issue':142,'checks':len(results),'failed':sum(not e['ok'] for e in results),'runtime_rgba_bytes':memory,'results':results}
(REVIEW/'source-validation.json').write_text(json.dumps(report,indent=2)+'\n')
print('EVENT_TRINKET_VALIDATION: %d checks, %d failed, %.3f MiB RGBA'%(report['checks'],report['failed'],memory/1048576))
sys.exit(1 if report['failed'] else 0)

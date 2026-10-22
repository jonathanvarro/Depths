"""Independent #141 source, palette, alpha, pose, binding and effect audit."""
from pathlib import Path
from PIL import Image
import numpy as np
import json,hashlib,re
ROOT=Path(__file__).resolve().parents[2]
SOURCE=ROOT/'art/source/monsters-v1'
OUT=ROOT/'art/concepts/monsters-v1'
checks=[]
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def path(p):return ROOT/p.removeprefix('res://')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def check(ok,label):checks.append({'check':label,'ok':bool(ok)})
master=read(SOURCE/'generation.json')
check(len(master['assets'])==23,'All 23 built-in originals retained, including horn correction')
for entry in master['assets']:
    p=ROOT/entry['source'];origin=Path(entry['original_path'])
    check(sha(p)==entry['sha256'],'Immutable master hash: '+entry['id'])
    if origin.exists():check(origin.read_bytes()==p.read_bytes(),'Byte-exact original: '+entry['id'])
    check(entry['tool']=='built-in image_gen' and len(entry['prompt'])>100,'Exact built-in prompt: '+entry['id'])
    check(all((ROOT/p).exists() for p in entry['reference_images']),'Retained references: '+entry['id'])
catalog=read(ROOT/'art/enemies/monsters-v1/catalog.json')
check(len(catalog['assets'])==11,'Eleven complete monster families')
drawings=0
for entry in catalog['assets']:
    id=entry['id'];size=entry['canvas'][0];palette=set();scales=set()
    check(size==(192 if id=='broodmother' else 128),'Deliberate native canvas: '+id)
    check(entry['pivot']==([96,180] if id=='broodmother' else [64,120]),'Shared bottom-centre origin: '+id)
    for pose,uri in entry['poses'].items():
        drawings+=1;im=Image.open(path(uri)).convert('RGBA');a=np.array(im);visible=a[:,:,3]>0
        palette|=set(map(tuple,a[:,:,:3][visible]));b=im.getbbox()
        check(im.size==(size,size) and np.any(visible),'Complete nonempty native drawing: '+id+'/'+pose)
        check(set(np.unique(a[:,:,3]))=={0,255} and np.all(a[~visible]==0),'Binary clean transparency: '+id+'/'+pose)
        check(b[0]>=7 and b[1]>=7 and b[2]<=size-7 and b[3]<=size-7,'Unclipped content with padding: '+id+'/'+pose)
        check(sha(path(uri))==entry['pose_sha256'][pose],'Export hash: '+id+'/'+pose)
    for reg in entry['registration']:scales.add(reg['scale'])
    check(len(scales)==1,'One raw-pixel scale for every pose: '+id)
    check(len(palette)<=32 and palette==set(map(tuple,entry['palette'])),'One <=32-colour family palette: '+id)
    check(all(p in entry['animations'] for p in ['idle','attack','hurt']),'Required combat animations: '+id)
    im=Image.open(path(entry['poses']['idle']));b=im.getbbox()
    check(abs((b[3]-b[1])*entry['pixel_size']-entry['visual_height_metres'])<1e-6,'Measured idle world height: '+id)
    if id=='gate-captain':
        check(entry['registration'][1]['source'].endswith('rally-fix-master.png') and all(not e['source'].endswith('rally-fix-master.png') for i,e in enumerate(entry['registration']) if i!=1),'Corrected rally only; other poses retain originals')
check(drawings==46,'All 46 registered pose drawings')
check(next(e for e in catalog['assets'] if e['id']=='gas-bloat')['animations']['burst']==['burst-1','burst-2'],'Two-frame gas-bloat rupture')

glyphs=read(ROOT/'art/ui/monsters-v1/catalog.json')
for group,entries in glyphs['groups'].items():
    for id,uri in entries.items():
        im=Image.open(path(uri))
        check(im.size==(32,32) and im.convert('RGBA').getchannel('A').getbbox()!=None,'Native readable glyph canvas: '+group+'/'+id)
        if id!='wind-up':check((SOURCE/'glyphs'/group/(id+'.svg')).exists(),'Original SVG source: '+id)
check(glyphs['groups']['intent']['wind-up']=='res://art/ui/backlog96-v1/intent/heavy.png','Heavy blow reused instead of duplicate wind-up symbol')
effects=read(ROOT/'art/effects/monsters-v1/catalog.json')
for effect in effects['effects']:
    im=Image.open(path(effect['texture'])).convert('RGBA');w,h=effect['frame_size']
    check(im.size==(w*effect['frame_count'],h) and max(im.size)<=512,'Compact effect atlas: '+effect['id'])
    if 'frames' in effect:
        last=np.array(im.crop(((effect['frame_count']-1)*w,0,effect['frame_count']*w,h)))
        check(not np.any(last),'One-shot clears on final frame: '+effect['id'])
    if effect['id']=='gas-burst':check(np.array(im)[:,:,3].max()<=144,'Gas burst has no opaque white flash')

baseline=read(SOURCE/'bindings-before.json')
def nonvisual(s):
    s=re.sub(r'^\[ext_resource type="PackedScene".*\]\n','',s,flags=re.M)
    return re.sub(r'^(tint|sprite_scale) = .*\n','',s,flags=re.M)
for name,before in baseline['resources'].items():
    s=(ROOT/name).read_text(encoding='utf-8');id=Path(name).stem.replace('_','-')
    check(nonvisual(s)==nonvisual(before),'All nonvisual resource values retained: '+id)
    check('res://art/enemies/monsters-v1/'+id+'/scene.tscn' in s and 'tint = ' not in s and 'sprite_scale = ' not in s,'Live scene without placeholder tint/scale: '+id)
def builder_rules(s):
    s=re.sub(r'^##.*\n','',s,flags=re.M)
    s=re.sub(r'"scene": load\("[^"]+"\)','"scene": ART',s)
    s=re.sub(r'"tint": (Color\([^\n]+?\)|Color.WHITE), "sprite_scale": [^,]+,','ART',s)
    return s
check(builder_rules((ROOT/'tools/story/build_monsters.gd').read_text())==builder_rules(baseline['builder']),'Resource builder retains every gameplay value')
for uri,h in read(SOURCE/'preserved-art.json').items():check(sha(path(uri))==h,'Preserved earlier art: '+uri)
runtime=list((ROOT/'art/enemies/monsters-v1').rglob('*.png'))+list((ROOT/'art/ui/monsters-v1').rglob('*.png'))+list((ROOT/'art/effects/monsters-v1').glob('*.png'))
rgba=sum(Image.open(p).width*Image.open(p).height*4 for p in runtime)
report={'issue':141,'checks':len(checks),'failures':[e['check'] for e in checks if not e['ok']],'masters':23,'families':11,'drawings':drawings,'runtime_pngs':len(runtime),'rgba_canvas_bytes':rgba,'rgba_canvas_mib':round(rgba/2**20,3),'limits':'Common transforms and shared palettes are checked; anatomical continuity also requires visual inspection. Canvas memory excludes engine overhead, not physical iPhone profiling.','results':checks}
(OUT/'source-validation.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8',newline='\n')
print('MONSTER_SOURCE checks=%d failures=%d runtime=%.3fMiB'%(len(checks),len(report['failures']),rgba/2**20))
for failure in report['failures']:print('FAIL: '+failure)
raise SystemExit(1 if report['failures'] else 0)

"""Independent source, palette, preservation and registration audit for #139."""
from pathlib import Path
import hashlib,json,re,subprocess
import numpy as np
from PIL import Image

ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'art/concepts/descent-finish-v1'
checks=[]
def check(ok,label):
    checks.append({'check':label,'ok':bool(ok)})
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def path(uri):return ROOT/uri.removeprefix('res://')
def read(p):return json.loads(p.read_text(encoding='utf-8'))

masters=0
for directory in ['descent-surfaces-v1','cave-dressing-v2']:
    manifest=read(ROOT/'art/source'/directory/'generation.json')
    for entry in manifest['assets']:
        masters+=1;p=ROOT/entry['source']
        check(sha(p)==entry['sha256'],'Original source hash: '+entry['id'])
        check(len(entry['prompt'])>100 and entry['tool']=='built-in image_gen','Exact built-in prompt: '+entry['id'])
        original=Path(entry['original_path'])
        if original.exists():check(p.read_bytes()==original.read_bytes(),'Byte-exact generated copy: '+entry['id'])
check(masters==28,'All 28 masters retained, including rejected peg candidate')

surfaces=read(ROOT/'art/textures/descent-surfaces-v1/catalog.json')
check(len(surfaces['assets'])==12 and len(surfaces['families'])==6,'Six complete surface families')
for entry in surfaces['assets']:
    p=path(entry['texture']);im=Image.open(p).convert('RGBA');a=np.array(im)
    wall=np.array(Image.open(path(entry['palette_source'])).convert('RGB'))
    colours=set(map(tuple,a[:,:,:3].reshape(-1,3)));wall_colours=set(map(tuple,wall.reshape(-1,3)))
    check(im.size==(128,128) and np.all(a[:,:,3]==255),'Opaque native surface: '+entry['id'])
    check(len(colours)<=32 and colours<=wall_colours,'Exact wall-palette subset: '+entry['id'])
    check(np.array_equal(a[0],a[-1]) and np.array_equal(a[:,0],a[:,-1]),'Opposite edge pixels match: '+entry['id'])
    check(sha(p)==entry['sha256'] and sha(path(entry['source']))==entry['source_sha256'],'Surface provenance: '+entry['id'])

dressing=read(ROOT/'art/dressing/cave-v2/catalog.json')
check(len(dressing['assets'])==20,'Twenty dressing entries including reuse and composite')
for entry in dressing['assets']:
    p=path(entry['texture']);im=Image.open(p).convert('RGBA');a=np.array(im);visible=a[:,:,3]>0
    colours=set(map(tuple,a[:,:,:3][visible]))
    check(im.size==(128,128) and set(np.unique(a[:,:,3]))=={0,255},'Native binary alpha: '+entry['id'])
    check(len(colours)<=64,'Visible colour budget: '+entry['id'])
    if entry['id']!='floor-fungus':
        check(np.all(a[~visible]==0),'Clean transparent RGB: '+entry['id'])
    check(sha(p)==entry['sha256'] and sha(path(entry['source']))==entry['source_sha256'],'Dressing provenance: '+entry['id'])
    b=im.getbbox();measure=b[3]-b[1] if entry['measured_axis']=='height' else b[2]-b[0]
    check(abs(measure*entry['pixel_size']-entry['metres'])<1e-6,'Measured real size: '+entry['id'])
    check(not entry['interactive'] and not entry['collision'],'Scenery classification: '+entry['id'])
    if entry['mount']=='ceiling':check(entry['pivot'][1]==b[1],'Hanging top anchor: '+entry['id'])
    if entry['mount']=='floor-edge':check(entry['pivot'][1]==b[3],'Standing foot anchor: '+entry['id'])
    if 'glow_frames' in entry:
        mask=np.array(Image.open(path(entry['emission_mask'])).convert('RGBA'))
        atlas=np.array(Image.open(path(entry['glow_frames']).with_suffix('.png')).convert('RGBA'))
        check(mask.shape==a.shape and atlas.shape==(256,512,4),'Registered mask and atlas: '+entry['id'])
        check(np.all((mask[:,:,3]>0)<=visible) and np.count_nonzero(mask[:,:,3])>50,'Emission remains inside base: '+entry['id'])
        bounds=[]
        for i in range(8):
            frame=atlas[i//4*128:(i//4+1)*128,i%4*128:(i%4+1)*128]
            check(np.all((frame[:,:,3]>0)<=visible),'Frame %d registered: %s'%(i,entry['id']))
            bounds.append(Image.fromarray(frame).getbbox())
        check(len(set(bounds))==1,'Pulse changes opacity without moving drawings: '+entry['id'])
        if entry['id']=='floor-fungus':check(np.all(mask[88:,:,3]==0),'Fungus emission excludes stems/feet')

check(path('res://art/dressing/cave-v2/floor-fungus.png').read_bytes()==path('res://art/dressing/cave-v1/pale-mushrooms.png').read_bytes(),'Neutral floor fungus reused byte-exact')
spikes=next(e for e in dressing['assets'] if e['id']=='wall-spikes')
check(spikes['source'].endswith('wall-spikes-pointed-master.png'),'Pointed spike replacement selected')
for name in ['stranger-mark','inscription-band','seal-ornament']:
    svg=ROOT/'art/source/cave-dressing-v2/native'/(name+'.svg')
    check(svg.exists() and '<path' in svg.read_text(),'Original native drawing: '+name)
svg=(ROOT/'art/source/cave-dressing-v2/native/stranger-mark.svg').read_text()
ink=(ROOT/'art/source/cave-dressing-v2/native/stranger-mark-ink.svg').read_text()
check(re.findall(r'<path d="([^"]+)"',svg)[0]==re.findall(r'<path d="([^"]+)"',ink)[0],'Scratch and future map ink share exact motif')
check(Image.open(ROOT/'art/dressing/cave-v2/stranger-mark-ink.png').size==(32,32),'Native route-clue ink dimensions')

preserved=read(ROOT/'art/source/cave-dressing-v2/reused-inputs.json')
for uri,h in preserved.items():
    p=path(uri)
    check(sha(p)==h,'Preserved input: '+uri)
    original=subprocess.run(['git','show','HEAD:'+p.relative_to(ROOT).as_posix()],cwd=ROOT,capture_output=True,check=True).stdout
    tracked_equal=original==p.read_bytes()
    if p.suffix in ['.gd','.tres']:
        tracked_equal=original.replace(b'\r\n',b'\n')==p.read_bytes().replace(b'\r\n',b'\n')
    check(tracked_equal,'Preserved tracked content: '+uri)

runtime_pngs=list((ROOT/'art/textures/descent-surfaces-v1').glob('*.png'))+list((ROOT/'art/dressing/cave-v2').glob('*.png'))
rgba_bytes=sum(Image.open(p).width*Image.open(p).height*4 for p in runtime_pngs)
report={'issue':139,'checks':len(checks),'failures':[c['check'] for c in checks if not c['ok']],
        'generated_masters':masters,'surface_textures':12,'dressing_entries':20,'runtime_pngs':len(runtime_pngs),
        'rgba_canvas_bytes':rgba_bytes,'rgba_canvas_mib':round(rgba_bytes/2**20,3),
        'limits':'Canvas memory before engine overhead, not physical iPhone profiling. Matching edge colours do not prove structural continuity.',
        'results':checks}
(OUT/'source-validation.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print('DESCENT_FINISH_SOURCE checks=%d failures=%d runtime=%.3fMiB'%(len(checks),len(report['failures']),rgba_bytes/2**20))
for failure in report['failures']:print('FAIL: '+failure)
raise SystemExit(1 if report['failures'] else 0)

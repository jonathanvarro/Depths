"""#166 verify originals, native budgets, tiling and state registration."""
from pathlib import Path
from PIL import Image
import hashlib,json,numpy as np
ROOT=Path(__file__).resolve().parents[2]
SOURCE=ROOT/'art/source/drowned-water-v1';REVIEW=ROOT/'art/concepts/drowned-water-v1'
manifest=json.loads((SOURCE/'generation.json').read_text(encoding='utf-8'))
prompts=json.loads((SOURCE/'prompts.json').read_text(encoding='utf-8'))
checks=0
def check(ok,label):
 global checks
 checks+=1
 assert ok,label
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def local(p):return ROOT/p.removeprefix('res://')
for id,entry in manifest['masters'].items():
 p=local(entry['path']);check(sha(p)==entry['sha256'],id+' preserved master hash')
 original=Path(entry['original_path'])
 if original.exists():check(p.read_bytes()==original.read_bytes(),id+' byte-identical original copy')
 check(Image.open(p).size==tuple(entry['size']),id+' original size recorded')
 check(len(prompts['prompts'][id])>500,id+' exact built-in prompt retained')
for path,h in manifest['references'].items():check(sha(ROOT/path)==h,path+' existing style reference unchanged')
tiles={}
for id in ['shallow','deep']:
 entry=manifest['exports'][id];p=local(entry['path']);im=Image.open(p).convert('RGB');a=np.asarray(im)
 tiles[id]=a
 check(sha(p)==entry['sha256'],id+' export hash')
 check(im.size==(128,128),id+' native128')
 check(len(im.getcolors())<=32,id+' <=32 colours')
 check(np.array_equal(a[0],a[-1]),id+' top/bottom exact periodic edge')
 check(np.array_equal(a[:,0],a[:,-1]),id+' left/right exact periodic edge')
 check(Image.open(REVIEW/(id+'-tiled.png')).size==(384,384),id+' 3x3 tiling review')
check(tiles['deep'].mean()<tiles['shallow'].mean()*.65,'Deep water remains visibly darker than submerged stone')
pal=set();frames={}
for id in ['sluice-closed','sluice-open']:
 entry=manifest['exports'][id];im=Image.open(local(entry['path'])).convert('RGBA');a=np.asarray(im);frames[id]=a
 check(im.size==(192,192),id+' native192 full canvas')
 check(sha(local(entry['path']))==entry['sha256'],id+' export hash')
 check(set(np.unique(a[:,:,3]))=={0,255},id+' hard alpha')
 check(not a[0,:,3].any() and not a[-1,:,3].any(),id+' top/bottom transparent margins')
 check(not a[:,0,3].any() and not a[:,-1,3].any(),id+' side transparent margins')
 check(not a[a[:,:,3]==0,:3].any(),id+' zero invisible RGB')
 pal.update(map(tuple,a[a[:,:,3]>0,:3]))
check(len(pal)<=48,'Sluice pair shares <=48 visible colours')
check(np.max(np.abs(np.array(manifest['exports']['sluice-closed']['bounds'])-np.array(manifest['exports']['sluice-open']['bounds'])))<=1,'Fixed outer assembly registration within one native pixel')
closed=frames['sluice-closed'][90:140,100:145];opened=frames['sluice-open'][90:140,100:145]
check(opened[:,:,3].min()==255,'Open aperture is opaque all through its interior')
check(opened[:,:,:3].mean()<closed[:,:,:3].mean()*.5,'Raised gate reveals a clearly dark open channel')
scene=(ROOT/'art/props/drowned-water-v1/sluice.tscn').read_text(encoding='utf-8')
check('container.gd' in scene and 'empty_texture' in scene,'Existing closed/empty state contract')
check('billboard = 0' in scene,'Stable architectural wall mount')
check(manifest['registration']['world_canvas_width']==2.0,'Canvas fits the 2m grid-cell width')
shader=(ROOT/'art/textures/drowned-water-v1/water.gdshader').read_text(encoding='utf-8')
check(shader.count('texture(surface_texture,')==2,'Only two water texture samples')
check('MODEL_MATRIX' in shader and 'motion_enabled ? TIME : 0.0' in shader,'World-space phase and fixed still mode')
check('ALPHA =' not in shader and 'SCREEN_TEXTURE' not in shader and 'DEPTH_TEXTURE' not in shader,'Opaque material without costly screen/depth passes')
report={'checks':checks,'failures':[],'raw_rgba_budget_bytes':2*128*128*4+2*192*192*4,
 'scope':'Asset library only; original gameplay/themes/event data are unchanged. Source math does not certify visual style.'}
(REVIEW/'source-validation.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print(json.dumps(report))

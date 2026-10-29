"""Source and full-component invariants, independent of visual approval."""
from pathlib import Path
from PIL import Image,ImageChops
import hashlib,json
ROOT=Path(__file__).resolve().parents[2];SOURCE=ROOT/'art/source/wounded-keeper-v1'
OUT=ROOT/'art/portraits/wounded-keeper-v1';REVIEW=ROOT/'art/concepts/wounded-keeper-v1'
report=json.loads((SOURCE/'generation.json').read_text(encoding='utf-8'));prompts=json.loads((SOURCE/'prompts.json').read_text(encoding='utf-8'))
checks=0
def check(ok,label):
 global checks
 checks+=1
 assert ok,label
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def load(p):return Image.open(p).convert('RGBA')
def compose(*images):
 result=Image.new('RGBA',(192,192))
 for im in images:result.alpha_composite(im)
 return result
def diffmask(a,b):
 d=ImageChops.difference(a,b)
 return ImageChops.lighter(ImageChops.lighter(d.getchannel('R'),d.getchannel('G')),ImageChops.lighter(d.getchannel('B'),d.getchannel('A')))
for id,master in report['masters'].items():
 p=ROOT/master['file'].removeprefix('res://');check(sha(p)==master['sha256'],id+' exact master hash')
 original=Path(master['original_path'])
 if original.exists():check(p.read_bytes()==original.read_bytes(),id+' byte-identical original copy')
 check(load(p).size==tuple(master['size']),id+' source size')
 check(load(p).getchannel('A').getextrema()[0]==0,id+' true source transparency')
 check(len(prompts['prompts'][id])>500,id+' full exact prompt')
for path,h in report['references'].items():check(sha(ROOT/path)==h,'Existing elf reference unchanged')
base=load(OUT/'neutral/resting.png');expression_mask=Image.open(SOURCE/'expression-mask.png').convert('L')
pal=set();eyes=set();mouths=set()
for entry in report['expressions']:
 emotion=entry['id'];folder=OUT/emotion;source=SOURCE/emotion;rest=load(folder/'resting.png');clean=load(folder/'character-clean.png')
 em=Image.open(source/'eye-mask.png').convert('L');mm=Image.open(source/'mouth-mask.png').convert('L')
 check(not ImageChops.multiply(em,mm).getbbox(),emotion+' separate eye/mouth masks')
 check(compose(clean,load(folder/'eyes-neutral.png'),load(folder/'mouth-neutral.png')).tobytes()==rest.tobytes(),emotion+' exact original reconstruction')
 check(not ImageChops.subtract(diffmask(rest,base),expression_mask).getbbox(),emotion+' silhouette, ears, hair, wound and clothing unchanged')
 if emotion!='neutral':check(rest.tobytes()!=base.tobytes(),emotion+' distinct expression')
 for p in folder.glob('*.png'):
  im=load(p);check(im.size==(192,192),p.name+' full canvas')
  check(im.getpixel((0,0))[3]==0 and im.getpixel((191,191))[3]==0,p.name+' transparent margins')
  check(not any(v[:3]!=(0,0,0) for v in im.get_flattened_data() if v[3]==0),p.name+' zero invisible RGB')
  if p.stem not in ['shadow','highlight']:pal.update(v[:3] for v in im.get_flattened_data() if v[3])
 for kind,states,mask in [('eyes',['neutral','half','closed'],em),('mouth',['neutral','small','open'],mm)]:
  variants=[]
  for state in states:
   part=load(folder/(kind+'-'+state+'.png'))
   check(part.getchannel('A').tobytes()==mask.tobytes(),emotion+' '+kind+' '+state+' replaces full same footprint')
   full=compose(clean,part,load(folder/('mouth-neutral.png' if kind=='eyes' else 'eyes-neutral.png')))
   check(not ImageChops.subtract(diffmask(full,rest),mask).getbbox(),emotion+' '+state+' changes only its own feature')
   variants.append(part.tobytes())
  check(len(set(variants))==3,emotion+' '+kind+' all three distinct drawings')
 eyes.add(sha(folder/'eyes-half.png'));mouths.add(sha(folder/'mouth-open.png'))
 check(Image.open(source/'eyes-half-iris.png').getbbox() is not None,emotion+' halfway blink retains source eye pixels')
 resource=(ROOT/'data/portraits/wounded-keeper-v1'/(emotion+'.tres')).read_text(encoding='utf-8')
 check('rig_kind = "Unique"' in resource and 'face_id = &"wounded-keeper"' in resource,emotion+' identity')
 check(all('/'+emotion+'/'+part+'.png' in resource for part in ['eyes-half','eyes-closed','mouth-small','mouth-open']),emotion+' owns emotion-specific frames')
check(len(eyes)==3 and len(mouths)==3,'No neutral animation images borrowed by other expressions')
check(len(pal)<=64,'Shared <=64-colour character palette')
static=(ROOT/'data/portraits/wounded-keeper-v1/map-reading.tres').read_text(encoding='utf-8')
check('blink_frames' not in static and 'talk_frames' not in static,'Map-reading pose has no borrowed animation')
check(load(OUT/'map-reading/resting.png').tobytes()!=base.tobytes(),'Map pose is a distinct drawing')
catalog=json.loads((OUT/'catalog.json').read_text(encoding='utf-8'))
check(len(catalog['portraits'])==4,'Three expressions plus one map-reading pose')
for entry in catalog['portraits']:
 for field in ['portrait_set','fallback']:check((ROOT/entry[field].removeprefix('res://')).exists(),entry['id']+' '+field+' exists')
result={'checks':checks,'failures':[],'visible_palette':len(pal),'scope':'Native source/registration invariants; visual fit and interpretation remain owner review.'}
(REVIEW/'source-validation.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8');print(json.dumps(result))

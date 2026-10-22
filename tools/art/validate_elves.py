"""#131 immutable sources, exact neutral reconstruction and pose contracts."""
from pathlib import Path
from PIL import Image,ImageChops
import hashlib,json,sys
ROOT=Path(__file__).resolve().parents[2];SOURCE=ROOT/'art/source/elves-v1';OUT=ROOT/'art/portraits/elves-v1';ENEMY=ROOT/'art/enemies/elves-v1/swordswoman';REVIEW=ROOT/'art/concepts/elves-v1'
results=[]
def check(ok,name):
 results.append({'check':name,'ok':bool(ok)})
 if not ok:print('FAIL',name)
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def im(p):return Image.open(p).convert('RGBA')
manifest=json.loads((SOURCE/'generation.json').read_text())
check(len(manifest['assets'])==5,'Five separately generated assets')
for e in manifest['assets']:
 p=ROOT/e['source'];check(sha(p)==e['sha256'],'Immutable source '+e['id'])
 if Path(e['original_path']).exists():check(p.read_bytes()==Path(e['original_path']).read_bytes(),'Original exact bytes '+e['id'])
 check(e['tool']=='built-in image_gen' and len(e['prompt'])>600,'Built-in tool and exact prompt '+e['id'])
for p,h in json.loads((SOURCE/'preserved-art.json').read_text()).items():check(sha(ROOT/p)==h,'Earlier portrait/art unchanged '+p)
for p,h in json.loads((SOURCE/'authoring-helpers.json').read_text()).items():check(sha(ROOT/p)==h,'Accepted native authoring helper unchanged '+p)
memory=0
for e in json.loads((OUT/'catalog.json').read_text())['portraits']:
 folder=OUT/e['id'];base=im(folder/'resting.png');clean=im(folder/'character-clean.png')
 neutral=clean.copy();neutral.alpha_composite(im(folder/'eyes-neutral.png'));neutral.alpha_composite(im(folder/'mouth-neutral.png'))
 check(neutral.tobytes()==base.tobytes(),'Exact neutral reconstruction '+e['id'])
 text=(ROOT/e['resource'][6:]).read_text();check('rig_kind = "Unique"' in text and e['id'] in text,'Unique resource family '+e['id'])
 for p in folder.glob('*.png'):
  image=im(p);check(image.size==(192,192),'Aligned untrimmed canvas '+str(p.relative_to(OUT)))
  if p.stem not in ['shadow','highlight']:
   check(set(x[3] for x in image.get_flattened_data())<={0,255},'Binary feature/base alpha '+p.stem)
   check(len({x[:3] for x in image.get_flattened_data() if x[3]})<=96,'Native portrait palette '+p.stem)
  check(p.name in ['resting.png','character-clean.png'] or 'path="res://art/portraits/elves-v1/'+e['id']+'/'+p.name+'"' in text,'Resource owns every layer '+p.stem)
  settings=p.with_suffix('.png.import').read_text();check('compress/mode=0' in settings and 'mipmaps/generate=false' in settings,'Lossless/no mipmaps '+p.stem)
  memory+=192*192*4
 for kind,names in [('eye',['eyes-neutral','eyes-half','eyes-closed']),('mouth',['mouth-neutral','mouth-small','mouth-open','mouth-round'])]:
  mask=Image.open(SOURCE/e['id']/(kind+'-mask.png')).convert('L')
  for name in names:check(ImageChops.difference(im(folder/(name+'.png')).getchannel('A'),mask).getbbox() is None,'Complete feature replacement '+e['id']+name)
 check(Image.open(SOURCE/e['id']/'eyes-closed-iris.png').getbbox() is None,'Closed frame has no iris '+e['id'])
 check(Image.open(SOURCE/e['id']/'eyes-half-iris.png').getbbox() is not None,'Half frame retains original lower iris '+e['id'])
 spec=e['features'];cx=round((spec['lip'][0][0]+spec['lip'][-1][0])/2)
 round_image=clean.copy();round_image.alpha_composite(im(folder/'mouth-round.png'))
 mask=Image.open(SOURCE/e['id']/'mouth-mask.png').convert('L')
 check(all(round_image.getpixel((x,y))==clean.getpixel((x,y)) for y in range(192) for x in range(192) if abs(x-cx)>5 and mask.getpixel((x,y))),'Round speech removes old lip corners '+e['id'])
registration=json.loads((ENEMY/'registration.json').read_text());colours=set()
for e in registration['poses']:
 p=ENEMY/(e['pose']+'.png');image=im(p);pixels=list(image.get_flattened_data());colours.update(x[:3] for x in pixels if x[3])
 check(image.size==(128,128),'Native combat canvas '+e['pose'])
 check(image.getbbox()[3]==121,'Registered floor pivot '+e['pose'])
 check(set(x[3] for x in pixels)=={0,255} and all(x==(0,0,0,0) for x in pixels if x[3]==0),'Transparent combat gaps '+e['pose'])
 check(sha(p)==e['sha256'],'Pose export hash '+e['pose']);memory+=128*128*4
check(len(colours)<=32,'One shared 32-colour combat palette')
check(registration['common_reduced_canvas']==[112,112] and registration['pivot']==[64,120],'Common pose scale and pivot')
failed=sum(not r['ok'] for r in results)
(REVIEW/'source-validation.json').write_text(json.dumps({'issue':131,'checks':len(results),'failed':failed,'runtime_rgba_bytes':memory,'results':results},indent=2)+'\n')
print('ELF_SOURCE_VALIDATION:',len(results),'checks,',failed,'failed,',round(memory/1048576,3),'MiB RGBA')
sys.exit(1 if failed else 0)

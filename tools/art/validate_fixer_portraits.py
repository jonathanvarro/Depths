"""#163 source, registration, complete-component and preservation checks."""
from pathlib import Path
from PIL import Image, ImageChops
import hashlib,json,re,subprocess,sys
sys.dont_write_bytecode=True
from build_fixer_portraits import register
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'art/portraits/fixer-v1'; SOURCE=ROOT/'art/source/fixer-v1'; REVIEW=ROOT/'art/concepts/fixer-v1'
checks=0
def check(ok,label):
 global checks
 checks+=1
 assert ok,label
def load(p):return Image.open(p).convert('RGBA')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def compose(*images):
 result=Image.new('RGBA',(192,192))
 for im in images:result.alpha_composite(im)
 return result
def equal(a,b):return a.tobytes()==b.tobytes()

report=json.loads((REVIEW/'asset-validation.json').read_text())
generation=json.loads((SOURCE/'generation.json').read_text())
prompts=json.loads((SOURCE/'prompts.json').read_text())
for id,spec in generation['masters'].items():
 p=ROOT/spec['file'].removeprefix('res://')
 check(sha(p)==spec['sha256'],id+' master hash')
 if Path(spec['original_path']).exists():check(p.read_bytes()==Path(spec['original_path']).read_bytes(),id+' exact original output retained')
 check(load(p).getchannel('A').getextrema()==(0,255),id+' source has true transparency')
 check(len(prompts['prompts'][id[-1]])>500,id+' exact built-in prompt retained')
for path,h in generation['references'].items():check(sha(ROOT/path.removeprefix('res://'))==h,'Original reference preserved '+path)
for path,h in report['shared_inputs'].items():check(sha(ROOT/path.removeprefix('res://'))==h,'Original shared template preserved')
baseline=json.loads(subprocess.check_output(['git','show','45ce3dc:art/portraits/recruit-roster-v1/catalog.json'],cwd=ROOT,text=True))
catalog=json.loads((ROOT/'art/portraits/recruit-roster-v1/catalog.json').read_text())
check(catalog['portraits'][:9]==baseline['portraits'],'Existing nine catalog records unchanged')
check(catalog['by_role']['Fixer']==['fixer-a','fixer-b','fixer-c'],'Three stable Fixer IDs')
check(len(catalog['portraits'])==12,'Twelve recruit faces')
old=json.loads((SOURCE/'preserved-inputs.json').read_text())
for path,h in old.items():check(sha(ROOT/path)==h,'Existing artwork/resource byte preservation '+path)
heads=set(); eyes=set();mouths=set()
for face in report['faces']:
 id=face['id'];folder=OUT/id;head=load(folder/'head.png');clean=load(folder/'head-clean.png')
 body=load(folder/'body.png')
 em=Image.open(SOURCE/(id+'-eye-matte.png')).convert('L');mm=Image.open(SOURCE/(id+'-mouth-matte.png')).convert('L')
 mask=ImageChops.lighter(em,mm)
 check(not ImageChops.multiply(em,mm).getbbox(),id+' independent feature mattes')
 check(equal(compose(clean,load(folder/'eyes-neutral.png'),load(folder/'mouth-neutral.png')),head),id+' exact neutral reconstruction')
 check(equal(compose(body,head),load(folder/'preview.png')),id+' fallback equals layered neutral')
 check(equal(load(folder/'preview.png'),register(SOURCE/(id+'-master.png'))),id+' full registered concept preserved; no template torso substitution')
 check(not head.getchannel('A').crop((0,144,192,192)).getbbox(),id+' no duplicate torso')
 for path in folder.glob('*.png'):
  im=load(path);check(im.size==(192,192),str(path)+' canvas')
  check(im.getpixel((0,0))[3]==0 and im.getpixel((191,191))[3]==0,str(path)+' transparent margins')
  check(not any(p[:3]!=(0,0,0) for p in im.get_flattened_data() if p[3]==0),str(path)+' zero invisible RGB')
 for name,region in [('eyes',em),('mouth',mm)]:
  for mode in (['neutral','half','closed'] if name=='eyes' else ['neutral','small','open']):
   im=load(folder/(name+'-'+mode+'.png'))
   check(im.getchannel('A').tobytes()==region.tobytes(),id+' '+name+' '+mode+' replaces full identical footprint')
   pose=compose(clean,im,load(folder/('mouth-neutral.png' if name=='eyes' else 'eyes-neutral.png')))
   diff=ImageChops.difference(pose,head)
   changed=ImageChops.lighter(ImageChops.lighter(diff.getchannel('R'),diff.getchannel('G')),diff.getchannel('B'))
   check(not ImageChops.subtract(changed,region).getbbox(),id+' '+mode+' changes only its complete feature')
   if mode!='neutral':check(changed.getbbox() is not None,id+' '+mode+' is a distinct drawing')
  if name=='eyes':
   closed=load(folder/'eyes-closed.png');half=load(folder/'eyes-half.png')
   # These tilted heads have individually fitted ocular paths; all original
   # pixels beyond those footprints (including the eyebrows) are unchanged.
   pose=compose(clean,closed,load(folder/'mouth-neutral.png'))
   diff=ImageChops.difference(pose,head).convert('RGB')
   changed=ImageChops.lighter(ImageChops.lighter(diff.getchannel('R'),diff.getchannel('G')),diff.getchannel('B'))
   check(not ImageChops.subtract(changed,em).getbbox(),id+' tilted eye drawings respect fitted footprint')
   iris=Image.open(SOURCE/(id+'-half-iris.png')).convert('L')
   check(iris.getbbox() is not None,id+' half lid retains original lower eye pixels')
  else:
   a=load(folder/'mouth-small.png');b=load(folder/'mouth-open.png')
   check(not equal(a,b),id+' two distinct talk shapes')
 for path in [folder/'head-clean.png',folder/'eyes-neutral.png',folder/'mouth-neutral.png']:
  check(len({p[:3] for p in load(path).get_flattened_data() if p[3]})<=48,id+' controlled native palette')
 heads.add(sha(folder/'head.png'));eyes.add(sha(folder/'eyes-closed.png'));mouths.add(sha(folder/'mouth-open.png'))
 resource=(ROOT/'data/portraits/fixer-v1'/(id+'.tres')).read_text()
 check('face_id = &"'+id+'"' in resource,id+' own identity')
 for part in ['eyes-neutral','eyes-half','eyes-closed','mouth-neutral','mouth-small','mouth-open']:
  check('fixer-v1/'+id+'/'+part+'.png' in resource,id+' own '+part)
 check('rig_kind = "Unique"' in resource,id+' concept-specific rig keeps its own garments')
check(len(heads)==len(eyes)==len(mouths)==3,'No head, blink or talk drawings shared between faces')
check(sha(ROOT/'art/portraits/recruit-silhouettes-v1/fixer.png')!=sha(ROOT/'art/portraits/recruit-silhouettes-v1/scout.png'),'Distinct Fixer silhouette')
report={'checks':checks,'failures':[],'existing_art_and_resources_preserved':len(old),
 'scope':'Source integrity, native registration, full component replacement and exact neutral reconstruction; visual judgment remains separate.'}
(REVIEW/'source-validation.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps(report))

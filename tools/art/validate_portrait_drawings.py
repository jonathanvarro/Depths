"""#124: preserve v3 rig invariants and test the actual v4 source components.

Style is reviewed visually at 192/96px; these checks cover independent visible
iris points, Corin's profile/beard/teeth, opacity and unchanged rig/timing data.
"""
from pathlib import Path
from PIL import Image,ImageChops
import json,hashlib,subprocess

ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'art/concepts/portrait-drawings-v4'
manifest=json.loads((OUT/'components.json').read_text(encoding='utf-8'))
v3_path=ROOT/'art/concepts/portrait-components-v3/components.json'
v3=json.loads(v3_path.read_text(encoding='utf-8'))
catalog=json.loads((ROOT/'data/portraits/catalog.json').read_text(encoding='utf-8'))
entries=catalog['portraits']+catalog['supporting_resources'];checks=0;failures=[]
def check(ok,label):
 global checks
 checks+=1
 if not ok:failures.append(label)
def local(p):return ROOT/p.removeprefix('res://')
def load(p):return Image.open(local(p)).convert('RGBA')
def same(a,b):return a.tobytes()==b.tobytes()
def stack(entry,eye=None,mouth=None):
 image=Image.new('RGBA',(192,192))
 for p in entry['layers']:
  if p.endswith('/background.png'):continue
  if p==entry['neutral_eyes']:p=eye or p
  if p==entry['neutral_mouth']:p=mouth or p
  image.alpha_composite(load(p))
 return image
check(hashlib.sha256(v3_path.read_bytes()).hexdigest()==manifest['v3_manifest_sha256'],'v3 manifest unchanged')
for path in ['scripts/portrait_view.gd','scripts/party_card.gd']:
 original=subprocess.check_output(['git','show','551071c:'+path],cwd=ROOT,text=True,encoding='utf-8')
 check((ROOT/path).read_text(encoding='utf-8')==original,path+' timing/filter code unchanged')
IRIS={'mara':[(97,71),(123,72)],'corin':[(93,67),(120,71)],'alwen':[(99,70),(123,70)]}
GLINT={'mara':[(97,70),(124,71)],'corin':[(93,65),(120,69)],'alwen':[(99,68),(123,68)]}
for face in manifest['faces']:
 name=face['face'];baseline=next(f for f in v3['faces'] if f['face']==name)
 original=load(face['original']);clean=load(face['clean']);parts={p['name']:p for p in face['outputs']}
 check(face['eye_mask']==baseline['eye_mask'] and face['mouth_mask']==baseline['mouth_mask'],name+' exact v3 matte references')
 for label in ['clean-character','eyes-neutral','mouth-neutral']:
  part=parts[label];old=next(p for p in baseline['outputs'] if p['name']==label)
  check(part==old and hashlib.sha256(local(part['texture']).read_bytes()).hexdigest()==old['sha256'],name+' unchanged '+label)
 for path,h in face['input_layers'].items():check(hashlib.sha256(local(path).read_bytes()).hexdigest()==h,name+' original source intact')
 palette={p for p in original.get_flattened_data() if p[3]}
 for part in face['outputs']:
  if part['name'] in ['clean-character','eyes-neutral','mouth-neutral']:continue
  image=load(part['texture']);mask=Image.open(local(face['eye_mask'] if part['name'].startswith('eyes') else face['mouth_mask'])).convert('L')
  check(image.size==(192,192) and same(image.getchannel('A'),mask),name+' unchanged canvas/matte '+part['name'])
  check(hashlib.sha256(local(part['texture']).read_bytes()).hexdigest()==part['sha256'],name+' output hash '+part['name'])
  check(all(not p[3] or p in palette for p in image.get_flattened_data()),name+' native palette '+part['name'])
  if 'iris' in part:
   iris=Image.open(local(part['iris']));points=[(x,y) for y in range(192) for x in range(192) if iris.getpixel((x,y))]
   check(all(image.getpixel(p)==original.getpixel(p) for p in points),name+' lower iris is actual original texture '+part['name'])
   if part['name']=='eyes-half':check(len(points)>=30 and sum(image.getpixel(p)!=clean.getpixel(p) for p in points)>=12,name+' half blink retains visible eye detail')
   lash=Image.open(local(part['lash']));bounds=lash.getbbox()
   check(bounds is not None and ImageChops.subtract(lash,mask).getbbox() is None,name+' lash inside original matte')
   if name=='corin':check(all(not lash.getpixel((x,y)) for y in range(192) for x in range(129,192)),name+' lash stays before profile edge')
  else:
   opening=Image.open(local(part['opening']));bounds=opening.getbbox();points=[(x,y) for y in range(192) for x in range(192) if opening.getpixel((x,y))]
   check(bounds is not None and ImageChops.subtract(opening,mask).getbbox() is None,name+' mouth cavity inside matte '+part['name'])
   column_depths=[sum(opening.getpixel((x,y))>0 for y in range(192)) for x in range(bounds[0],bounds[2])]
   check(bounds[2]-bounds[0] < face['drawing_recipe']['lip'][-1][0]-face['drawing_recipe']['lip'][0][0] and max(column_depths)<=3,name+' opening is smaller than full lips '+part['name'])
   mask_points=[(x,y) for y in range(192) for x in range(192) if mask.getpixel((x,y))]
   check(sum(image.getpixel(p)==original.getpixel(p) for p in mask_points)>len(mask_points)*.35,name+' original lip/skin/beard detail retained '+part['name'])
 half=load(parts['eyes-half']['texture']);closed=load(parts['eyes-closed']['texture'])
 stroke=Image.open(local(parts['eyes-closed']['lash']))
 remaining={(x,y) for y in range(192) for x in range(192) if stroke.getpixel((x,y))};groups=[]
 while remaining:
  queue=[remaining.pop()];group=[]
  while queue:
   point=queue.pop();group.append(point)
   for dx,dy in [(a,b) for a in [-1,0,1] for b in [-1,0,1] if a or b]:
    other=(point[0]+dx,point[1]+dy)
    if other in remaining:remaining.remove(other);queue.append(other)
  groups.append(group)
 check(len(groups)==2 and all(max(y for x,y in g)>min(y for x,y in g) for g in groups),name+' two connected curved lash lines')
 check(len({parts[n]['sha256'] for n in parts if n.startswith('mouth')})==sum(n.startswith('mouth') for n in parts),name+' every declared mouth shape is distinct from neutral and each other')
 for point in IRIS.get(name,[]):check(half.getpixel(point)==original.getpixel(point),name+' independent lower iris point '+str(point))
 for point in GLINT.get(name,[]):check(closed.getpixel(point)!=original.getpixel(point),name+' closed removes original glint '+str(point))
 if name=='corin':
  for kind in ['mouth-small','mouth-open','mouth-round']:
   image=load(parts[kind]['texture'])
   check(all(image.getpixel(p)==original.getpixel(p) for p in [(92,87),(98,87),(103,88)]),'Corin beard texture retained '+kind)
  image=load(parts['mouth-open']['texture'])
  gap=image.getpixel((104,92));tooth=image.getpixel((102,91))
  check(sum(gap[:3])<sum(tooth[:3])*.7,'Corin gap darker than neighbouring tooth')
 for resource in face['resources']:
  entry=next(e for e in entries if e['resource']==resource)
  expected=original
  if entry['id']=='underlayer':
   expected=Image.new('RGBA',(192,192))
   for p in face['input_layers']:
    if not p.endswith(('/background.png','/tunic.png')):expected.alpha_composite(load(p))
  check(same(stack(entry),expected),resource+' exact resting reconstruction')
  check(len(entry['frames'])==(6 if name in ['mara','corin','alwen'] else 5),resource+' honest declared shape count')
  for frame in entry['frames'][1:]:
   component=frame['eyes'] if frame['eyes']!=entry['neutral_eyes'] else frame['mouth']
   check(component in [p['texture'] for p in face['outputs']],resource+' live component listed in manifest')
  for eye in ['eyes-neutral','eyes-half','eyes-closed']:
   for mouth in [p for p in parts if p.startswith('mouth')]:
    a=stack(entry,parts[eye]['texture'],parts[mouth]['texture']);b=stack(entry)
    whole=ImageChops.lighter(Image.open(local(face['eye_mask'])),Image.open(local(face['mouth_mask'])))
    b.paste(clean,(0,0),whole);b.alpha_composite(load(parts[eye]['texture']));b.alpha_composite(load(parts[mouth]['texture']))
    check(same(a,b),resource+' simultaneous '+eye+'/'+mouth)
report={'issue':124,'revision':manifest['revision'],'faces':12,'checks':checks,'failures':failures,
 'neutral_clean_mattes_timing':'unchanged from v3','review':'192px,96px nearest, held enlarged crops and actual Godot motion; style remains a visual judgment.'}
(OUT/'pixel-validation.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8',newline='\n')
print(json.dumps(report,indent=2))
if failures:raise SystemExit(1)

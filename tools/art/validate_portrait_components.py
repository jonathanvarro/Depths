"""Check real stacked components and the screenshot's duplicate-feature cases.

Tests reconstruction, clean underlayers, full opaque feature coverage, every
blink/talk combination, and independent original iris/lip-corner landmarks.
Visual review of the held native/enlarged drawings remains necessary.
"""
from pathlib import Path
from PIL import Image, ImageChops
import hashlib, json

ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'art/concepts/portrait-components-v3'
manifest=json.loads((OUT/'components.json').read_text(encoding='utf-8'))
catalog=json.loads((ROOT/'data/portraits/catalog.json').read_text(encoding='utf-8'))
entries=catalog['portraits']+catalog['supporting_resources']
checks=0;failures=[]
def check(condition,label):
 global checks
 checks+=1
 if not condition:failures.append(label)
def local(uri):return ROOT/uri.removeprefix('res://')
def load(uri):return Image.open(local(uri)).convert('RGBA')
def equal(a,b):return a.tobytes()==b.tobytes()
def stacked(entry,eyes=None,mouth=None,bare=False):
 image=Image.new('RGBA',(192,192))
 for p in entry['layers']:
  if p.endswith('/background.png'):continue
  if p==entry['neutral_eyes']:
   if bare:continue
   p=eyes or p
  if p==entry['neutral_mouth']:
   if bare:continue
   p=mouth or p
  image.alpha_composite(load(p))
 return image

# Coordinates taken from the original eye highlights and lip corners, rather
# than generated edit masks. The two Mara regressions correspond to owner crops.
LANDMARKS={
 'mara':{'iris':[(97,70),(124,71),(134,68)],'corners':[(96,101),(121,101),(122,102)]},
 'corin':{'iris':[(93,65),(120,69)],'corners':[(90,89),(118,94)]},
 'alwen':{'iris':[(99,68),(123,68)],'corners':[(103,95),(122,95)]},
}

for face in manifest['faces']:
 name=face['face'];original=load(face['original']);clean=load(face['clean'])
 eyes_mask=Image.open(local(face['eye_mask'])).convert('L');mouth_mask=Image.open(local(face['mouth_mask'])).convert('L')
 whole=ImageChops.lighter(eyes_mask,mouth_mask)
 changed=[(x,y) for y in range(192) for x in range(192) if original.getpixel((x,y))!=clean.getpixel((x,y))]
 check(changed and all(whole.getpixel(p) for p in changed),name+' clean plate preserves all pixels outside full feature footprints')
 for path,h in face['input_layers'].items():
  check(hashlib.sha256(local(path).read_bytes()).hexdigest()==h,name+' original untouched '+path)
 outputs={part['name']:part for part in face['outputs']}
 original_palette={p for p in original.get_flattened_data() if p[3]}
 head_source=next(p for p in face['input_layers'] if p.endswith(('/head.png','/base.png')))
 head_palette={p for p in load(head_source).get_flattened_data() if p[3]}
 for part in face['outputs']:
  image=load(part['texture']);check(image.size==(192,192),name+' native canvas '+part['name'])
  # A clean base can include original material hidden by the separate tunic in
  # the clothed reference. Those untouched source colours must remain valid.
  allowed_palette=original_palette|head_palette if part['name']=='clean-character' else original_palette
  check(all(not p[3] or p in allowed_palette for p in image.get_flattened_data()),name+' original native palette '+part['name'])
  check(hashlib.sha256(local(part['texture']).read_bytes()).hexdigest()==part['sha256'],name+' registered output '+part['name'])
  if part['name']=='clean-character':continue
  mask=eyes_mask if part['name'].startswith('eyes') else mouth_mask
  check(equal(image.getchannel('A'),mask),name+' complete opaque feature matte '+part['name'])
  if 'ink' in part:
   ink=Image.open(local(part['ink'])).convert('L')
   clean_pixels=[(x,y) for y in range(192) for x in range(192) if mask.getpixel((x,y)) and not ink.getpixel((x,y))]
   check(all(image.getpixel(p)==clean.getpixel(p) for p in clean_pixels),name+' no resting feature retained outside new drawing '+part['name'])
 for resource in face['resources']:
  entry=next(e for e in entries if e['resource']==resource)
  expected_original=original;expected_clean=clean
  if entry['id']=='underlayer':
   expected_original=Image.new('RGBA',(192,192))
   for path in face['input_layers']:
    if not path.endswith(('/background.png','/tunic.png')):expected_original.alpha_composite(load(path))
   expected_clean=expected_original.copy();expected_clean.paste(clean,(0,0),whole)
  check(equal(stacked(entry),expected_original),resource+' original neutral reconstructed byte-for-byte')
  check(equal(stacked(entry,bare=True),expected_clean),resource+' underlying character actually contains clean face')
  for eye in ['eyes-neutral','eyes-half','eyes-closed']:
   for mouth in [n for n in outputs if n.startswith('mouth')]:
    a=stacked(entry,outputs[eye]['texture'],outputs[mouth]['texture'])
    b=expected_clean.copy();b.alpha_composite(load(outputs[eye]['texture']));b.alpha_composite(load(outputs[mouth]['texture']))
    check(equal(a,b),resource+' exact combined replacement '+eye+' / '+mouth)
 landmarks=LANDMARKS.get(name,{'iris':[(96,68),(122,69)]})
 closed=load(outputs['eyes-closed']['texture'])
 # Two connected strokes, one per eye; no detached old lashes or eye fragments.
 closed_ink=Image.open(local(outputs['eyes-closed']['ink']))
 remaining={(x,y) for y in range(192) for x in range(192) if closed_ink.getpixel((x,y))}
 components=[]
 while remaining:
  pending=[remaining.pop()];count=0
  while pending:
   x,y=pending.pop();count+=1
   for dx,dy in [(a,b) for a in [-1,0,1] for b in [-1,0,1] if a or b]:
    point=(x+dx,y+dy)
    if point in remaining:remaining.remove(point);pending.append(point)
  components.append(count)
 check(len(components)==2 and min(components)>20,name+' closed lids each form one connected drawing')
 for p in landmarks['iris']:
  check(eyes_mask.getpixel(p)==255 and closed.getpixel(p)==clean.getpixel(p) and original.getpixel(p)!=closed.getpixel(p),name+' original iris/lash absent at '+str(p))
 if 'mouth-round' in outputs:
  rounded=load(outputs['mouth-round']['texture'])
  for p in landmarks.get('corners',[]):
   check(mouth_mask.getpixel(p)==255 and rounded.getpixel(p)==clean.getpixel(p) and original.getpixel(p)!=rounded.getpixel(p),name+' old resting lip corner absent at '+str(p))

report={'revision':manifest['revision'],'faces':len(manifest['faces']),'checks':checks,'failures':failures,
 'neutral_reconstruction':'exact original RGBA','combined_blink_and_talk':'all combinations',
 'visual_review':'Held native and enlarged drawings; separately inspect clean plate and outer corners.'}
(OUT/'pixel-validation.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8',newline='\n')
print(json.dumps(report,indent=2))
if failures:raise SystemExit(1)

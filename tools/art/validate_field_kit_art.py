"""Independent #138 source/export/binding checks; never changes game resources."""
from pathlib import Path
from PIL import Image
import hashlib,json,re
import numpy as np
ROOT=Path(__file__).resolve().parents[2]
cat=json.loads((ROOT/'art/items/field-kit-v1/catalog.json').read_text())
checks=0;failures=[]
def check(ok,label):
 global checks
 checks+=1
 if not ok:failures.append(label)
def local(uri):return ROOT/uri.removeprefix('res://')
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def rules(text):
 text=re.sub(r'^\[ext_resource type="Texture2D"[^\n]*\n','',text,flags=re.M)
 text=re.sub(r'^icon = [^\n]*\n','',text,flags=re.M)
 return '\n'.join(line.rstrip() for line in text.splitlines() if line.strip())
sources=json.loads((ROOT/'art/source/field-kit-v1/generation.json').read_text())
for a in sources['assets']:
 check(sha(ROOT/a['source'])==a['sha256'],'Source hash '+a['id'])
 check(bool(a['prompt']) and a['tool']=='built-in image_gen','Exact built-in prompt '+a['id'])
 if Path(a['original_path']).exists():check(sha(Path(a['original_path']))==a['sha256'],'Original copy '+a['id'])
total=0
for e in cat['items']:
 for key,size,colours in [('icon',128,64),('compact_icon',64,32)]:
  im=Image.open(local(e[key])).convert('RGBA');a=np.array(im);total+=size*size*4
  check(im.size==(size,size),'Canvas '+e['id']+' '+key)
  check(set(np.unique(a[:,:,3]))=={0,255},'Hard alpha '+e['id']+' '+key)
  check(not np.any(a[:,:,:3][a[:,:,3]==0]),'Transparent RGB '+e['id']+' '+key)
  check(len(set(map(tuple,a[:,:,:3][a[:,:,3]>0])))<=colours,'Palette '+e['id']+' '+key)
  b=im.getbbox();check(min(b[0],b[1],size-b[2],size-b[3])>=size//16,'Padding '+e['id']+' '+key)
 check(sha(local(e['source']))==e['source_sha256'] and sha(local(e['icon']))==e['icon_sha256'],'Catalogue hashes '+e['id'])
signatures=[]
for e in cat['symbols']:
 im=Image.open(local(e['icon'])).convert('RGBA');total+=32*32*4
 check(im.size==(32,32) and im.getchannel('A').getextrema()==(0,255),'32px alpha '+e['id'])
 signature=im.resize((14,14),Image.Resampling.NEAREST).convert('LA').tobytes()
 check(signature not in signatures,'Distinct compact luminance/shape '+e['id']);signatures.append(signature)
 check('<title>'+e['name']+'</title>' in local(e['source']).read_text(encoding='utf-8'),'Native glyph source '+e['id'])
for e in cat['items']+cat['symbols']:
 text=local(e['resource']).read_text()
 check(hashlib.sha256(rules(text).encode()).hexdigest()==e['nonvisual_sha256'],'Every nonvisual field unchanged '+e['id'])
 check('path="'+e['icon']+'" id="field_art"' in text and 'icon = ExtResource("field_art")' in text,'Live binding '+e['id'])
report={'checks':checks,'failures':failures,'items':len(cat['items']),'symbols':len(cat['symbols']),'rgba_texture_bytes':total}
(ROOT/'art/concepts/field-kit-v1/source-validation.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps(report,indent=2));raise SystemExit(bool(failures))

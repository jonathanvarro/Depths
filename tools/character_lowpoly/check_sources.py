"""Verify packaged captures, portable rig data, native cards and gallery assets."""
from pathlib import Path
import hashlib,json,struct,re
from PIL import Image
ROOT=Path(__file__).resolve().parents[2]
DEST=ROOT/'art/concepts/character-lowpoly-v1'
manifest=json.loads((DEST/'manifest.json').read_text())
count=0
def check(ok,label):
 global count
 count+=1
 assert ok,label
for name,info in manifest['files'].items():
 p=DEST/name
 check(hashlib.sha256(p.read_bytes()).hexdigest()==info['sha256'],name+' hash')
 if p.suffix=='.png':
  with Image.open(p) as image:
   image.load()
   check(len(image.getcolors(image.width*image.height))>12,name+' nonblank')
for outfit in range(3):
 for size in [96,192]:
  with Image.open(DEST/f'card-{outfit}-{size}.png') as image:check(image.size==(size,size),'Native card size')
 p=DEST/f'traveller-{outfit}.glb';data=p.read_bytes()
 check(data[:4]==b'glTF','GLB magic')
 length=struct.unpack_from('<I',data,12)[0];gltf=json.loads(data[20:20+length])
 check(len(gltf['skins'])==1 and len(gltf['skins'][0]['joints'])==16,'Portable shared rig')
 check({x['name'] for x in gltf['animations']}=={'standing','seated','reading'},'Portable poses')
 check(all('uri' not in x for x in gltf['buffers']),'Self-contained GLB')
 check(all('JOINTS_0' in p['attributes'] and 'WEIGHTS_0' in p['attributes'] for m in gltf['meshes'] for p in m['primitives']),'All portable surfaces skinned')
 check(any(m['pbrMetallicRoughness']['baseColorFactor'][0]<.5 for m in gltf['materials']),'Palette not all white')
html=(DEST/'inspector.html').read_text()
for link in re.findall(r'(?:src|href)="([^"]+)"',html):check((DEST/link).exists(),'Local asset '+link)
scene=(DEST/'traveller.tscn').read_text()
check('script = ' not in scene and '[ext_resource' not in scene,'Independent script-free scene')
check('type="AnimationPlayer"' in scene,'Native pose library')
report=json.loads((DEST/'report.json').read_text())
check(not report['failures'] and report['combinations']==27,'Renderer combinations passed')
print(f'LOWPOLY SOURCES: {count} checks passed')

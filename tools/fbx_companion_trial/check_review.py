"""Validate the private local gallery, captures, models and unchanged source copies."""
from pathlib import Path
import hashlib,json,re
from PIL import Image
ROOT=Path(__file__).resolve().parents[2]
LOCAL=ROOT/'build/local-fbx-trial'
OUT=LOCAL/'review'
manifest=json.loads((OUT/'manifest.json').read_text())
count=0
def check(ok,label):
 global count
 count+=1
 assert ok,label
for name,record in manifest['files'].items():
 p=OUT/name
 check(hashlib.sha256(p.read_bytes()).hexdigest()==record['sha256'],'Unchanged capture '+name)
 if p.suffix=='.png':
  with Image.open(p) as image:
   image.load()
   check(len(image.getcolors(image.width*image.height))>12,'Nonblank '+name)
for look in [0,1]:
 for dimension in [192,96]:
  with Image.open(OUT/f'appearance-{look}-{dimension}.png') as image:check(image.size==(dimension,dimension),'Native portrait size')
 text=(LOCAL/f'appearance-{look}.tscn').read_text()
 check('[ext_resource' not in text and 'script = ' not in text,'Standalone native model')
 check('expedition/sit_down' not in text and '&"sit_down"' in text,'Animation stored in local library')
with Image.open(OUT/'phone.png') as image:check(image.size==(1278,590),'Actual phone-shaped window size')
with Image.open(OUT/'seated-motion.gif') as image:check(image.n_frames>=64,'Real motion preview frames')
original=json.loads((LOCAL/'original-hashes.json').read_text(encoding='utf-8-sig'))
check(hashlib.sha256((LOCAL/'source/character.fbx').read_bytes()).hexdigest().upper()==original['fbx'],'Original FBX preserved byte-for-byte')
check(hashlib.sha256((LOCAL/'body-texture.png').read_bytes()).hexdigest().upper()==original['texture'],'Original texture preserved byte-for-byte')
html=(OUT/'inspector.html').read_text()
for link in re.findall(r'(?:src|href)="([^"]+)"',html):check((OUT/link).exists(),'Local review link '+link)
for name in ['check-report.json','check-report-headless.json']:
 report=json.loads((LOCAL/name).read_text())
 check(not report['failures'],'Passing '+name)
check(len(list((OUT/'frames').glob('*.png')))==66,'Complete renderer frame sequence')
print(f'LOCAL FBX REVIEW: {count} checks passed')

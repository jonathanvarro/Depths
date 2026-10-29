"""Native/source invariants for #166. Visual judgments remain separate."""
from pathlib import Path
from PIL import Image
import json,hashlib
ROOT=Path(__file__).resolve().parents[2];SRC=ROOT/'art/source/waterworks-v1';REVIEW=ROOT/'art/concepts/waterworks-v1'
checks=0;failures=[]
def check(ok,description):
 global checks
 checks+=1
 if not ok:failures.append(description)
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def main():
 m=json.loads((SRC/'generation.json').read_text());p=json.loads((SRC/'prompts.json').read_text())
 check(sha(ROOT/'art/textures/descent-walls-v1/drowned-masonry.png')==m['reference_sha256'],'Existing wall reference unchanged')
 for id,record in m['sources'].items():
  source=SRC/(id+'-master.png');im=Image.open(source)
  check(sha(source)==record['sha256'],id+' source hash')
  original=Path(record['original_path'])
  if original.exists():check(source.read_bytes()==original.read_bytes(),id+' unaltered copy')
  check(bool(p['prompts'][id]),id+' exact prompt retained')
  out=ROOT/m['outputs'][id]['path'].removeprefix('res://');native=Image.open(out).convert('RGBA')
  check(native.size==(128,128),id+' native canvas')
  pixels=list(native.get_flattened_data());check(len({v[:3] for v in pixels if v[3]})<=32,id+' palette')
  check(sha(out)==m['outputs'][id]['sha256'],id+' output hash')
  if id.startswith('wet-'):
   check(all(v[3]==255 for v in pixels),id+' opaque')
   check(all(native.getpixel((x,0))==native.getpixel((x,127)) for x in range(128)),id+' vertical periodicity')
   check(all(native.getpixel((0,y))==native.getpixel((127,y)) for y in range(128)),id+' horizontal periodicity')
   material=out.with_suffix('.tres').read_text();check('emission' not in material and 'roughness = 0.82' in material,id+' no light cost')
  else:
   check(set(v[3] for v in pixels)=={0,255},id+' binary alpha')
   check(all(v==(0,0,0,0) for v in pixels if v[3]==0),id+' clean invisible RGB')
   b=native.getbbox();check(b[0]>0 and b[1]>0 and b[2]<128 and b[3]<128,id+' full silhouette margin')
   scene=out.with_suffix('.tscn').read_text();check('billboard = 0' in scene and 'shaded = true' in scene,id+' mounting and light')
 report={'checks':checks,'failures':failures,'scope':'Source/export invariants; no live placement or physical iPhone claims'}
 (REVIEW/'source-validation.json').write_text(json.dumps(report,indent=2)+'\n');print(report)
 if failures:raise SystemExit(1)
if __name__=='__main__':main()

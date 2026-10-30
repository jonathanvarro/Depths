from pathlib import Path
from PIL import Image
import json,hashlib
ROOT=Path(__file__).resolve().parents[2];SRC=ROOT/'art/source/descent-production-v1';REVIEW=ROOT/'art/concepts/descent-production-v1'
checks=0;failures=[]
def check(ok,label):
 global checks
 checks+=1
 if not ok:failures.append(label)
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def main():
 m=json.loads((SRC/'generation.json').read_text(encoding='utf-8'))
 lineage=json.loads((SRC/'lineage.json').read_text(encoding='utf-8'))
 for name,original_name in lineage['original_filenames'].items():
  original=Path(lineage['original_directory'])/original_name
  if original.exists():check(original.read_bytes()==(SRC/name).read_bytes(),name+' exact original')
 for name,record in m['sources'].items():check(sha(SRC/name)==record['sha256'],name+' retained')
 for path,value in m['preserved'].items():check(sha(ROOT/path.removeprefix('res://'))==value,path+' unchanged')
 for family,folder in [('underhound','underhound-v2'),('borrowed-pack','borrowed-pack-v1')]:
  colours=set();hashes=set()
  for name,record in m['outputs'][family].items():
   p=ROOT/'art/enemies'/folder/(name+'.png');im=Image.open(p).convert('RGBA');pixels=list(im.get_flattened_data())
   check(sha(p)==record['sha256'],family+'/'+name+' hash');hashes.add(sha(p))
   check(im.size==(128,128),family+'/'+name+' native128')
   check({v[3] for v in pixels}=={0,255},family+'/'+name+' hard alpha')
   check(all(v==(0,0,0,0) for v in pixels if not v[3]),family+'/'+name+' no hidden matte')
   b=im.getbbox();check(b[0]>=2 and b[1]>=2 and b[2]<=126 and b[3]<=126,family+'/'+name+' margin')
   colours.update(v[:3] for v in pixels if v[3])
  check(len(colours)<=32,family+' shared32');check(len(hashes)==len(m['outputs'][family]),family+' unique drawings')
  check(m['hound_registration' if family=='underhound' else 'pack_registration']['per_pose_fit']==False,family+' common transform')
 for name in ['idle','attack','hurt']:check(sha(ROOT/'art/enemies/underhound-v2'/f'{name}.png')==sha(ROOT/'art/enemies/underhound-v1'/f'{name}.png'),name+' exact inherited pixels')
 stone=Image.open(ROOT/'art/props/ancient-stonework-v1/stone.png').convert('RGBA');pulse=Image.open(ROOT/'art/props/ancient-stonework-v1/pulse.png').convert('RGBA')
 check(stone.size==pulse.size==(192,192),'Stone and pulse aligned192')
 check(len({p[:3] for p in stone.get_flattened_data() if p[3]})<=48,'Stone palette')
 check(0<m['outputs']['stone']['pulse_pixels']<192*192/8,'Pulse sparse')
 check(all(not p[3] or s[3] for p,s in zip(pulse.get_flattened_data(),stone.get_flattened_data())),'Pulse inside stone')
 report={'checks':checks,'failures':failures,'scope':'Source/export invariants; owner visual review and live hookup remain separate'}
 (REVIEW/'source-validation.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8');print(report)
 if failures:raise SystemExit(1)
if __name__=='__main__':main()

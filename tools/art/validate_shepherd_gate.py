from pathlib import Path
from PIL import Image
import json,hashlib
ROOT=Path(__file__).resolve().parents[2];SRC=ROOT/'art/source/shepherd-gate-v1';OUT=ROOT/'art/concepts/shepherd-gate-v1'
checks=0;failures=[]
def check(ok,label):
 global checks
 checks+=1
 if not ok:failures.append(label)
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def main():
 m=json.loads((SRC/'generation.json').read_text(encoding='utf-8'))
 for id,r in m['sources'].items():
  source=SRC/(id+'-master.png');check(sha(source)==r['sha256'],id+' hash')
  original=Path(r['original_path'])
  if original.exists():check(source.read_bytes()==original.read_bytes(),id+' original copy')
  check(bool((SRC/r['prompt_file']).read_text(encoding='utf-8').strip()),id+' prompt')
 for ref,value in m['references'].items():check(sha(ROOT/ref)==value,ref+' unchanged')
 union=set()
 for id,r in m['families'].items():
  folder=ROOT/Path(r['scene'].removeprefix('res://')).parent;hashes=set()
  for name,record in r['poses'].items():
   p=folder/(name+'.png');im=Image.open(p).convert('RGBA');pixels=list(im.get_flattened_data());hashes.add(sha(p))
   check(sha(p)==record['sha256'],id+'/'+name+' hash');check(im.size==(r['canvas'],r['canvas']),id+'/'+name+' canvas')
   check({p[3] for p in pixels}=={0,255},id+'/'+name+' alpha')
   check(all(v==(0,0,0,0) for v in pixels if not v[3]),id+'/'+name+' invisible RGB')
   b=im.getbbox();check(b[0]>=2 and b[1]>=2 and b[2]<=r['canvas']-2 and b[3]<=r['canvas']-2,id+'/'+name+' margins')
   union.update(v[:3] for v in pixels if v[3])
  check(len(hashes)==len(r['poses']),id+' unique drawings');check(not r['per_pose_fit'],id+' fixed transform')
 check(len(union)<=32,'Shared kinship32 palette')
 folder=ROOT/'art/props/reservoir-flow-gate-v1';a=Image.open(folder/'closed.png').convert('RGBA');b=Image.open(folder/'open.png').convert('RGBA');x0,y0,x1,y1=m['gate']['aperture']
 check(a.size==b.size==(192,192),'Gate native192')
 check(a.tobytes()!=b.tobytes(),'Gate distinct states')
 check(all(a.getpixel((x,y))==b.getpixel((x,y)) for y in range(192) for x in range(192) if not(x0<=x<x1 and y0<=y<y1)),'Frame and chains exact outside aperture')
 check(all(b.getpixel((x,y))[3]==255 for y in range(60,160) for x in range(55,138)),'Open aperture opaque')
 check(len({v[:3] for im in [a,b] for v in im.get_flattened_data() if v[3]})<=48,'Gate48 shared palette')
 check(a.getbbox()==b.getbbox(),'Gate registration bounds')
 report={'checks':checks,'failures':failures,'scope':'Source/native invariants; owner review and live hookup remain separate'}
 (OUT/'source-validation.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8');print(report)
 if failures:raise SystemExit(1)
if __name__=='__main__':main()

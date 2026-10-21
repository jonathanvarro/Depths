"""Verify #132 source provenance, alpha, palette and paired registrations."""
from pathlib import Path
from PIL import Image
import hashlib,json
import numpy as np

ROOT=Path(__file__).resolve().parents[2]
DIR=ROOT/'art/dressing/landmarks-v1'
OUT=ROOT/'art/concepts/landmarks-v1'
checks=0
failures=[]
def check(ok,label):
 global checks
 checks+=1
 if not ok: failures.append(label)
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def local(uri):return ROOT/uri.removeprefix('res://')
cat=json.loads((DIR/'catalog.json').read_text())
sources=json.loads((ROOT/'art/source/landmarks-v1/generation.json').read_text())
for item in sources['assets']:
 path=ROOT/item['source']
 check(sha(path)==item['sha256'],'Immutable master '+item['id'])
 check(bool(item['prompt']) and item['tool']=='built-in image_gen','Exact built-in prompt '+item['id'])
 original=Path(item['original_path'])
 if original.exists():check(sha(original)==sha(path),'Byte-exact original copy '+item['id'])
palette={tuple(c) for c in json.loads((DIR/'palette.json').read_text())}
union=set()
for entry in cat['assets']:
 data=np.array(Image.open(local(entry['texture'])).convert('RGBA'))
 check(data.shape==(128,128,4),'Native size '+entry['id'])
 check(set(np.unique(data[:,:,3]))=={0,255},'Hard alpha '+entry['id'])
 check(not np.any(data[:,:,:3][data[:,:,3]==0]),'No invisible RGB fringe '+entry['id'])
 colours=set(map(tuple,data[:,:,:3][data[:,:,3]>0]))
 union|=colours
 check(colours<=palette,'Shared palette '+entry['id'])
 check(sha(local(entry['source']))==entry['source_sha256'] and sha(local(entry['texture']))==entry['export_sha256'],'Recorded hashes '+entry['id'])
 check(local(entry['scene']).exists() and not entry['collision'],'Mounted scene '+entry['id'])
 check(entry['scale']<=1 and 0<entry['metres']<=1.45,'Downscale and cell scale '+entry['id'])
check(len(palette)<=64 and len(union)<=64,'Whole library shares <=64 colours')
entries={e['id']:e for e in cat['assets']}
for fresh,used in [('miners-shrine','miners-shrine-used'),('shrine-offerings','shrine-offerings-used')]:
 a,b=entries[fresh],entries[used]
 for key in ['source_bounds','scale','offset','pivot','pixel_size']:
  check(a[key]==b[key],'State registration '+fresh+' '+key)
 check(local(a['texture']).read_bytes()!=local(b['texture']).read_bytes(),'Distinct resolved state '+fresh)
for name in ['banner-seal','shrine-candle-glow']:
 data=np.array(Image.open(DIR/(name+'.png')).convert('RGBA'))
 check(set(map(tuple,data[:,:,:3][data[:,:,3]>0]))<=palette,'Native accent shares palette '+name)
glyph=Image.open(ROOT/'art/ui/backlog96-v1/map/landmark.png').convert('RGBA')
check(glyph.size==(32,32) and glyph.getchannel('A').getextrema()==(0,255),'Transparent 32px glyph')
native=json.loads((ROOT/'art/source/landmarks-v1/native-inputs.json').read_text())['canonical_seal']
check(sha(ROOT/native['path'])==native['sha256'],'Canonical forked seal unchanged')
report={'checks':checks,'failures':failures,'selected_assets':len(entries),'retained_masters':len(sources['assets']),'shared_colours':len(union),'rgba_texture_bytes':sum(Image.open(p).width*Image.open(p).height*4 for p in DIR.glob('*.png'))+32*32*4}
(OUT/'source-validation.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps(report,indent=2))
raise SystemExit(bool(failures))

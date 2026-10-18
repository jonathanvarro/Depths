"""Build #62 from its exploration source and the locally adapted #61 panels."""
from pathlib import Path
from PIL import Image
import argparse,base64,hashlib,json
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'art/concepts/interface/navigation-v2'
ASSETS=OUT/'assets';ASSETS.mkdir(exist_ok=True)
prior=ROOT/'art/concepts/interface/pack-heroes-v2'
manifest={'issue':62,'kind':'Code-authored HUD study; no new generated artwork','assets':[]}
fragment=(OUT/'source.fragment.html').read_text(encoding='utf-8').replace('@@heroPanels@@',(OUT/'hero-panels.fragment.html').read_text(encoding='utf-8'))
def uri(data,mime):return 'data:'+mime+';base64,'+base64.b64encode(data).decode('ascii')
for entry in json.loads((prior/'manifest.json').read_text())['assets']:
    p=ROOT/entry['output']
    mime='font/woff' if p.suffix=='.woff' else 'image/jpeg' if p.suffix=='.jpg' else 'image/png'
    fragment=fragment.replace('@@'+entry['id']+'@@',uri(p.read_bytes(),mime))
    manifest['assets'].append({'id':entry['id'],'reused':entry['output'],'sha256':hashlib.sha256(p.read_bytes()).hexdigest()})
for key,source,size in [('cave','art/concepts/interface/navigation-v1/cave-backdrop.png',(960,540)),('map','art/concepts/map/hero-map-v1.png',(640,480))]:
    src=ROOT/source;image=Image.open(src).convert('RGB');image.thumbnail(size,Image.Resampling.LANCZOS)
    dest=ASSETS/(key+'.jpg');image.save(dest,quality=78)
    fragment=fragment.replace('@@'+key+'@@',uri(dest.read_bytes(),'image/jpeg'))
    manifest['assets'].append({'id':key,'source':source,'output':dest.relative_to(ROOT).as_posix(),'source_sha256':hashlib.sha256(src.read_bytes()).hexdigest(),'sha256':hashlib.sha256(dest.read_bytes()).hexdigest(),'size':image.size})
notices=[]
for folder in ['cinzel','source-sans-3']:
    notices.append((ROOT/'art/fonts'/folder/'OFL.txt').read_text(encoding='utf-8'))
fragment+='\n<!-- Bundled font notices: original tables retained in WOFF container.\n'+'\n\n'.join(notices)+'\n-->\n'
assert '@@' not in fragment
assert len(fragment.encode('utf-8'))<1_000_000,len(fragment.encode('utf-8'))
(OUT/'navigation-hud.html').write_text(fragment,encoding='utf-8',newline='\n')
parser=argparse.ArgumentParser();parser.add_argument('--inline-path',type=Path);args=parser.parse_args()
if args.inline_path:args.inline_path.write_text(fragment,encoding='utf-8',newline='\n')
(OUT/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8',newline='\n')
print('Built HUD study:',len(fragment.encode('utf-8')),'bytes')

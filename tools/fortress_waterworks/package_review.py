"""Verify #246 source/build/native lineage, then package the local gallery."""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import struct
from PIL import Image

ROOT=Path(__file__).resolve().parents[2]
ART=ROOT/'art/props/fortress-waterworks-3d-v1'
parser=argparse.ArgumentParser()
parser.add_argument('--workspace',type=Path,required=True)
args=parser.parse_args()
review=args.workspace/'build/local-fortress-waterworks-v1'
catalog_file=ART/'catalog.json'
catalog=json.loads(catalog_file.read_text(encoding='utf-8'))
report=json.loads((review/'validation.json').read_text(encoding='utf-8'))
assert not report['failures'] and report['renderer']=='mobile'
assert not (review/'native-error.log').read_text(encoding='utf-8').strip()
assert hashlib.sha256(catalog_file.read_bytes()).hexdigest()==report['catalog_sha256']
assert hashlib.sha256(Path(__file__).with_name('build_models.py').read_bytes()).hexdigest()==catalog['builder_sha256']
assert hashlib.sha256((ROOT/'tools/mine_props/build_models.py').read_bytes()).hexdigest()==catalog['helpers_sha256']
for entry in catalog['assets']:
    data=(ART/(entry['id']+'.glb')).read_bytes()
    assert hashlib.sha256(data).hexdigest()==entry['sha256']
    length,kind=struct.unpack_from('<II',data,12)
    assert kind==0x4e4f534a
    gltf=json.loads(data[20:20+length])
    assert not gltf.get('images') and not gltf.get('materials') and not gltf.get('animations')
    assert (review/'masters'/(entry['id']+'.blend')).is_file()
for source in catalog['sources']:
    assert hashlib.sha256((ROOT/source['file']).read_bytes()).hexdigest()==source['sha256']
    assert b'CC0' in (ROOT/source['licence']).read_bytes()
assert len(report['captures'])==106
for name in report['captures']:
    with Image.open(review/'captures'/name) as image:
        assert image.width>200 and image.height>190
        assert image.getextrema()[0][0]<image.getextrema()[0][1]
groups={'FORTRESS':'','WATERWORKS':''}
for entry in catalog['recipes']:
    name=entry['id']
    kind='gate' if 'lift' in entry else ('palisade' if name=='palisade' else 'static')
    groups[entry['batch'].upper()]+=(f'<article data-name="{name}" data-kind="{kind}">'
        f'<h3>{name.replace("-"," ").capitalize()}</h3>'
        f'<img src="captures/{name}-cave-0-closed.png" alt="Native {name.replace("-"," ")} preview">'
        f'<p>{entry["mount"].capitalize()} mount · {entry["triangles"]} visible triangles</p></article>\n')
html=Path(__file__).with_name('gallery.html').read_text(encoding='utf-8')
for key,cards in groups.items(): html=html.replace('@@'+key+'@@',cards)
(review/'inspector.html').write_text(html,encoding='utf-8')
shutil.copy2(ROOT/'docs/fortress-and-waterworks-3d.md',review/'START_HERE.md')
result={'verified_models':len(catalog['assets']),'recipes':len(catalog['recipes']),
        'verified_source_files':len(catalog['sources']),'builder_matches_exports':True,
        'native_captures':len(report['captures']),'failures':[]}
(review/'artifact-validation.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
print('FORTRESS_WATERWORKS_ARTIFACTS',result)

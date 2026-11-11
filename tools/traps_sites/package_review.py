"""Verify current model, script, source and native capture lineage, then package."""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import struct
from PIL import Image
ROOT=Path(__file__).resolve().parents[2]
ART=ROOT/'art/props/traps-sites-3d-v1'
parser=argparse.ArgumentParser()
parser.add_argument('--workspace',type=Path,required=True)
args=parser.parse_args()
review=args.workspace/'build/local-traps-sites-mist-v1'
catalog=json.loads((ART/'catalog.json').read_text())
report=json.loads((review/'validation.json').read_text())
assert not report['failures'] and report['renderer']=='mobile'
assert not (review/'native-error.log').read_text().strip()
assert len(report['captures'])==154
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
assert sha(ART/'catalog.json')==report['catalog_sha256']
assert sha(Path(__file__).with_name('build_models.py'))==catalog['builder_sha256']
assert sha(ROOT/'tools/mine_props/build_models.py')==catalog['helpers_sha256']
for path,digest in report['runtime_sha256'].items(): assert sha(ROOT/path.removeprefix('res://'))==digest
for entry in catalog['assets']:
    path=ART/(entry['id']+'.glb')
    assert sha(path)==entry['sha256']
    data=path.read_bytes()
    length,kind=struct.unpack_from('<II',data,12)
    assert kind==0x4e4f534a
    gltf=json.loads(data[20:20+length])
    assert not gltf.get('images') and not gltf.get('materials') and not gltf.get('animations')
    assert (review/'masters'/(entry['id']+'.blend')).exists()
for name in report['captures']:
    with Image.open(review/'captures'/name) as image:
        assert image.width>200 and image.height>190
        assert image.getextrema()[0][0]<image.getextrema()[0][1]
source=ROOT/'art/source/calming-herbs-v1'
generation=json.loads((source/'generation.json').read_text())
assert sha(source/'master.png')==generation['sha256']
for entry in generation['exports']:assert sha(ROOT/entry['file'])==entry['sha256']
for name in ['herbs-validation.json','live-mist-validation.json']:
    assert not json.loads((review/name).read_text())['failures']
assert not (review/'herbs-error.log').read_text().strip()
assert 'ERROR:' not in (review/'live-mist-error.log').read_text()
groups={'TRAPS':'','SITES':''}
descriptions={'tripwire':'Taut / released / sprung rubble', 'bell-alarm':'Set / disconnected / snapped line',
    'snare':'Open noose / coiled / drawn tight','dart-plate':'Raised / wedged / depressed with spent darts',
    'hollow-floor':'Cracked / collapsed','idol-niche':'Present / removed / toppled','still-pool':'Calm / disturbed'}
for entry in catalog['recipes']:
    name=entry['id']
    groups[entry['batch'].upper()]+=(f'<article data-name="{name}"><h3>{name.replace("-"," ").capitalize()}</h3>'
        f'<img src="captures/{name}-cave-0-closed.png" alt="Native {name.replace("-"," ")} preview">'
        f'<p>{descriptions[name]}</p></article>\n')
html=Path(__file__).with_name('gallery.html').read_text(encoding='utf-8')
for key,cards in groups.items():html=html.replace('@@'+key+'@@',cards)
(review/'inspector.html').write_text(html,encoding='utf-8',newline='\n')
frames=[Image.open(review/'captures'/('mist-motion-%02d.png'%i)).convert('RGB') for i in range(12)]
frames[0].save(review/'mist-motion.gif',save_all=True,append_images=frames[1:],duration=600,loop=0)
shutil.copy2(ROOT/'docs/traps-sites-and-mist-3d.md',review/'START_HERE.md')
result={'models':len(catalog['assets']),'recipes':len(catalog['recipes']),'native_captures':len(report['captures']),
    'real_pack_captures':3,'real_dungeon_captures':1,'source_build_runtime_hashes_match':True,'failures':[]}
(review/'artifact-validation.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8',newline='\n')
print('TRAPS_SITES_ARTIFACTS',result)

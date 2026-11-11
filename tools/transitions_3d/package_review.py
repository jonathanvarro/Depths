"""Verify #225/#250 source/export/runtime lineage and package native review."""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import struct
from PIL import Image
ROOT=Path(__file__).resolve().parents[2]
ART=ROOT/'art/features/transitions-3d-v1'
REGIONS=ROOT/'art/materials/regional-props-v1'
parser=argparse.ArgumentParser()
parser.add_argument('--workspace',type=Path,required=True)
args=parser.parse_args()
review=args.workspace/'build/local-transitions-regional-v1'
catalog=json.loads((ART/'catalog.json').read_text())
regions=json.loads((REGIONS/'catalog.json').read_text())
report=json.loads((review/'validation.json').read_text())
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
assert report['renderer']=='mobile' and not report['failures']
assert not (review/'native-error.log').read_text().strip()
assert len(report['captures'])==105
assert sha(ART/'catalog.json')==report['catalog_sha256']
assert sha(Path(__file__).with_name('build_models.py'))==catalog['builder_sha256']
assert sha(ROOT/'tools/mine_props/build_models.py')==catalog['helpers_sha256']
assert sha(Path(__file__).with_name('build_regions.py'))==regions['builder_sha256']
for path,digest in report['runtime_sha256'].items():assert sha(ROOT/path.removeprefix('res://'))==digest
for source in catalog['sources']:assert sha(ROOT/source['file'])==source['sha256']
assert b'CC0' in (ROOT/'art/third-party/kaykit-transitions-v1/LICENSE.txt').read_bytes()
for entry in catalog['assets']:
    data=(ART/(entry['id']+'.glb')).read_bytes()
    assert hashlib.sha256(data).hexdigest()==entry['sha256']
    length,kind=struct.unpack_from('<II',data,12)
    assert kind==0x4e4f534a
    gltf=json.loads(data[20:20+length])
    assert not gltf.get('images') and not gltf.get('materials') and not gltf.get('animations')
    assert (review/'masters'/(entry['id']+'.blend')).exists()
for path,digest in regions['models_unchanged'].items():assert sha(ROOT/path)==digest
assert sha(ROOT/regions['base_atlas']['file'])==regions['base_atlas']['sha256']
for region in regions['regions']:
    name=region['id']
    assert sha(ROOT/region['wall'])==region['wall_sha256']
    assert sha(ROOT/region['floor'])==region['floor_sha256']
    assert sha(REGIONS/(name+'.tres'))==region['material_sha256']
    for suffix,size in [('atlas',256),('grain',64)]:
        path=REGIONS/(name+'-'+suffix+'.png')
        assert sha(path)==region[suffix+'_sha256']
        with Image.open(path) as image:
            assert image.size==(size,size) and len(set(image.get_flattened_data()))<=32
for name in report['captures']:
    with Image.open(review/'captures'/name) as image:
        assert image.width>200 and image.height>200
        assert image.getextrema()[0][0]<image.getextrema()[0][1]
groups={'TRANSITIONS':'','BLOCKERS':'','REGIONS':''}
notes={'stone-up':'Worn CC0 stone flight / upper throat','stone-down':'Recessed stone flight / full cell apron',
       'fortress-up':'Scavenged timber / iron repairs','fortress-down':'Recessed timber flight / crooked rails',
       'cave-ledge-down':'Broken ledge / recessed shaft','root-climb-up':'Roots / ceiling aperture cap','daylight-mouth':'Rock mouth / fixed muted vista',
       'web-intact':'Irregular opaque silk strands','web-torn':'Clear centre / hanging remnants','root-barrier':'Dense crossed roots'}
for entry in catalog['assets']:
    name=entry['id']
    groups[entry['batch'].upper()]+=(f'<article data-name="{name}"><h3>{name.replace("-"," ").capitalize()}</h3>'
        f'<img src="captures/{name}-cave-0.png" alt="Native {name.replace("-"," ")} preview">'
        f'<p>{notes[name]} · {entry["triangles"]} triangles</p></article>\n')
for name,label in [('cave','Original cave'),('fungal','Moss and damp'),('scorched','Smoke and char'),('waterlogged','Water and silt')]:
    groups['REGIONS']+=f'<article data-name="props-{name}"><h3>{label}</h3><img src="captures/props-{name}-cave-0.png" alt="Same three props with {label.lower()} material"><p>Same geometry and UVs / shared material</p></article>\n'
html=Path(__file__).with_name('gallery.html').read_text(encoding='utf-8')
for key,cards in groups.items():html=html.replace('@@'+key+'@@',cards)
(review/'inspector.html').write_text(html,encoding='utf-8',newline='\n')
shutil.copy2(ROOT/'docs/transitions-blockers-and-regional-materials.md',review/'START_HERE.md')
result={'models':10,'regional_materials':3,'native_captures':len(report['captures']),
        'sources_builds_and_captures_match':True,'original_meshes_and_floor1_atlas_unchanged':True,'failures':[]}
(review/'artifact-validation.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8',newline='\n')
print('TRANSITION_ARTIFACTS',result)

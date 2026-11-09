"""Verify current builder/export lineage and native captures, then package review."""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
from PIL import Image

ROOT=Path(__file__).resolve().parents[2]
ART=ROOT/'art/dressing/cave-growth-3d-v1'
parser=argparse.ArgumentParser()
parser.add_argument('--workspace',type=Path,required=True)
args=parser.parse_args()
review=args.workspace/'build/local-cave-growth-v1'
catalog_file=ART/'catalog.json'
catalog=json.loads(catalog_file.read_text(encoding='utf-8'))
report=json.loads((review/'validation.json').read_text(encoding='utf-8'))
assert not report['failures'] and report['renderer']=='mobile'
assert hashlib.sha256(catalog_file.read_bytes()).hexdigest()==report['catalog_sha256']
assert hashlib.sha256(Path(__file__).with_name('build_models.py').read_bytes()).hexdigest()==catalog['builder_sha256']
assert hashlib.sha256((ROOT/'tools/mine_props/build_models.py').read_bytes()).hexdigest()==catalog['helpers_sha256']
for entry in catalog['assets']:
    assert hashlib.sha256((ART/(entry['id']+'.glb')).read_bytes()).hexdigest()==entry['sha256']
for source in catalog['sources']:
    assert hashlib.sha256((ROOT/source['file']).read_bytes()).hexdigest()==source['sha256']
    assert b'CC0' in (ROOT/source['licence']).read_bytes()
assert len(report['captures'])==107
for name in report['captures']:
    with Image.open(review/'captures'/name) as image:
        assert image.width>200 and image.height>190
        assert image.getextrema()[0][0]<image.getextrema()[0][1]
groups={'FORMATIONS':'','GROWTH':''}
for index,entry in enumerate(catalog['assets']):
    name=entry['id']
    group='FORMATIONS' if index<8 else 'GROWTH'
    groups[group]+=(f'<article data-name="{name}" data-glow="{str(entry["optional_glow"]).lower()}">'
                    f'<h3>{name.replace("-"," ").capitalize()}</h3>'
                    f'<img src="captures/{name}-cave-0-plain.png" alt="Native {name.replace("-"," ")} preview">'
                    f'<p>{entry["mount"].capitalize()} mount · {entry["triangles"]} triangles</p></article>\n')
html=Path(__file__).with_name('gallery.html').read_text(encoding='utf-8')
for key,cards in groups.items(): html=html.replace('@@'+key+'@@',cards)
(review/'inspector.html').write_text(html,encoding='utf-8')
shutil.copy2(ROOT/'docs/cave-formations-and-growth-3d.md',review/'START_HERE.md')
result={'verified_models':len(catalog['assets']),'verified_source_files':len(catalog['sources']),
        'builder_matches_exports':True,'native_captures':len(report['captures']),'failures':[]}
(review/'artifact-validation.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
print('GROWTH_ARTIFACTS',result)

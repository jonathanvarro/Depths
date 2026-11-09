"""Verify the selected sources and native captures, then package the art gallery."""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
from PIL import Image

ROOT=Path(__file__).resolve().parents[2]
parser=argparse.ArgumentParser()
parser.add_argument('--workspace',type=Path,required=True)
args=parser.parse_args()
review=args.workspace/'build/local-mine-props-v1'
art=ROOT/'art/dressing/mine-3d-v1'
catalog=json.loads((art/'catalog.json').read_text(encoding='utf-8'))
report=json.loads((review/'validation.json').read_text(encoding='utf-8'))
assert not report['failures'] and report['renderer']=='mobile'
for entry in catalog['assets']:
    assert hashlib.sha256((art/(entry['id']+'.glb')).read_bytes()).hexdigest()==entry['sha256']
source=ROOT/'art/third-party/kaykit-mine-props-v1'
provenance=json.loads((source/'provenance.json').read_text(encoding='utf-8'))
for entry in provenance['files']:
    data=(source/entry['file']).read_bytes()
    assert hashlib.sha256(data).hexdigest()==entry['sha256']
    blob=('blob '+str(len(data))+'\0').encode()+data
    assert hashlib.sha1(blob).hexdigest()==entry['git_blob_sha1']
for name in report['captures']:
    with Image.open(review/'captures'/name) as image:
        assert image.width>200 and image.height>200
        assert image.getextrema()[0][0]<image.getextrema()[0][1]
assert len(report['captures'])==52
(review/'inspector.html').write_text(Path(__file__).with_name('gallery.html').read_text(encoding='utf-8'),encoding='utf-8')
shutil.copy2(ROOT/'docs/mine-props-3d.md',review/'START_HERE.md')
result={'verified_source_files':len(provenance['files']),'verified_models':len(catalog['assets']),
        'native_captures':len(report['captures']),'failures':[]}
(review/'artifact-validation.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
print('MINE_ARTIFACTS',result)

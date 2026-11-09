"""Verify the #242 models and actual renderer captures before packaging review."""
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
ART=ROOT/'art/props/expedition-3d-v1'
review=args.workspace/'build/local-expedition-props-v1'
catalog=json.loads((ART/'catalog.json').read_text(encoding='utf-8'))
report=json.loads((review/'validation.json').read_text(encoding='utf-8'))
assert not report['failures'] and report['renderer']=='mobile'
for entry in catalog['assets']:
    assert hashlib.sha256((ART/(entry['id']+'.glb')).read_bytes()).hexdigest()==entry['sha256']
source=ROOT/'art/third-party/kaykit-containers-rest-v1'
proof=json.loads((source/'provenance.json').read_text(encoding='utf-8'))
for entry in proof['files']:
    data=(source/entry['file']).read_bytes()
    assert hashlib.sha256(data).hexdigest()==entry['sha256']
    blob=('blob '+str(len(data))+'\0').encode()+data
    assert hashlib.sha1(blob).hexdigest()==entry['git_blob_sha1']
assert len(report['captures'])==102
for name in report['captures']:
    with Image.open(review/'captures'/name) as image:
        assert image.width>200 and image.height>190
        assert image.getextrema()[0][0]<image.getextrema()[0][1]
shutil.copy2(Path(__file__).with_name('gallery.html'),review/'inspector.html')
shutil.copy2(ROOT/'docs/containers-rest-workings-3d.md',review/'START_HERE.md')
result={'verified_originals':len(proof['files']),'verified_models':len(catalog['assets']),
        'native_captures':len(report['captures']),'failures':[]}
(review/'artifact-validation.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
print('EXPEDITION_ARTIFACTS',result)

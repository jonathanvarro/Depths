import argparse,hashlib,json,shutil
from pathlib import Path
from PIL import Image
ROOT=Path(__file__).resolve().parents[2]
parser=argparse.ArgumentParser();parser.add_argument('--workspace',type=Path,required=True);args=parser.parse_args()
OUT=args.workspace/'build/local-rat-landmarks-v1'
native=json.loads((OUT/'validation.json').read_text());live=json.loads((OUT/'live/live-validation.json').read_text())
assert native['checks']==951 and not native['failures'] and native['renderer']=='mobile'
assert live['checks']==37 and not live['failures']
assert len(native['captures'])==150 and len(live['captures'])==20
verified=[]
source=ROOT/'art/third-party/oga-rat-v1'
for entry in json.loads((source/'provenance.json').read_text())['files']:
    data=(source/entry['file']).read_bytes()
    assert len(data)==entry['bytes'] and hashlib.sha256(data).hexdigest()==entry['sha256']
    verified.append(entry['file'])
models=[]
for folder in ['art/enemies/rat-3d-v1','art/props/shrine-events-3d-v1']:
    catalog=json.loads((ROOT/folder/'catalog.json').read_text())
    entries=catalog.get('assets',[{'id':'rat','sha256':catalog.get('sha256')}])
    for entry in entries:
        path=ROOT/folder/(entry['id']+'.glb')
        assert hashlib.sha256(path.read_bytes()).hexdigest()==entry['sha256']
        assert path.read_bytes()==(OUT/folder/path.name).read_bytes()
        models.append(str(path.relative_to(ROOT)))
for name in native['captures']:
    with Image.open(OUT/'captures'/name) as image:
        assert image.width>=300 and image.height>=120 and image.getextrema()[0][0]!=image.getextrema()[0][1]
for name in live['captures']:
    with Image.open(OUT/'live'/name) as image:assert image.width>=667 and image.height>=375
for folder in ['art/enemies/rat-3d-v1','art/props/shrine-events-3d-v1']:
    for path in (ROOT/folder).iterdir():
        if path.suffix in ['.gd','.tscn','.tres','.png']:
            assert path.read_bytes()==(OUT/folder/path.name).read_bytes(),path
hide=Image.open(ROOT/'art/enemies/rat-3d-v1/rat.png');assert hide.size==(128,128) and len(hide.getcolors(256))==32
shutil.copy2(Path(__file__).with_name('gallery.html'),OUT/'inspector.html')
shutil.copy2(ROOT/'docs/rat-and-shrine-landmarks-3d.md',OUT/'START_HERE.md')
report={'verified_originals':len(verified),'verified_models':len(models),'native_checks':native['checks'],
        'live_checks':live['checks'],'native_captures':len(native['captures'])+len(live['captures']),
        'runtime_hashes':{str(p.relative_to(ROOT)):hashlib.sha256(p.read_bytes()).hexdigest() for folder in ['art/enemies/rat-3d-v1','art/props/shrine-events-3d-v1'] for p in (ROOT/folder).iterdir() if p.suffix in ['.glb','.gd','.tscn','.tres','.png']},'failures':[]}
(OUT/'artifact-validation.json').write_text(json.dumps(report,indent=2)+'\n')
print('RAT_LANDMARK_ARTIFACTS',{k:v for k,v in report.items() if k!='runtime_hashes'})

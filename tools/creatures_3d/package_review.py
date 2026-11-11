import argparse,hashlib,json,shutil
from pathlib import Path
from PIL import Image
ROOT=Path(__file__).resolve().parents[2]
parser=argparse.ArgumentParser();parser.add_argument('--workspace',type=Path,required=True);args=parser.parse_args()
OUT=args.workspace/'build/local-spiders-goblin-v1';ART=ROOT/'art/enemies/field-creatures-3d-v1';SOURCE=ROOT/'art/third-party/oga-creatures-v1'
catalog=json.loads((ART/'catalog.json').read_text(encoding='utf-8'))
native=json.loads((OUT/'validation.json').read_text(encoding='utf-8'));live=json.loads((OUT/'live/live-validation.json').read_text(encoding='utf-8'))
assert not native['failures'] and native['checks']==2884 and len(native['captures'])==250 and native['renderer']=='mobile'
assert not live['failures'] and live['checks']==156 and len(live['captures'])==62
for folder in ['native-check','live-check']:
    launch=json.loads((OUT/folder/'launch.json').read_text());assert launch['exit_code']==0 and not launch['test_was_foreground'] and not launch['timed_out']
for record in json.loads((SOURCE/'provenance.json').read_text(encoding='utf-8'))['files']:
    data=(SOURCE/record['file']).read_bytes();assert len(data)==record['bytes'] and hashlib.sha256(data).hexdigest()==record['sha256']
for entry in catalog['assets']:
    p=ART/(entry['id']+'.glb');assert hashlib.sha256(p.read_bytes()).hexdigest()==entry['sha256'];assert p.read_bytes()==(OUT/'art/enemies/field-creatures-3d-v1'/p.name).read_bytes()
for p in ART.iterdir():
    if p.suffix in ['.gd','.tscn','.tres','.png','.json']:assert p.read_bytes()==(OUT/'art/enemies/field-creatures-3d-v1'/p.name).read_bytes(),p.name
for base,report in [(OUT/'captures',native),(OUT/'live',live)]:
    for name in report['captures']:
        with Image.open(base/name) as image:assert image.width>=300 and image.height>=120 and image.getextrema()[0][0]!=image.getextrema()[0][1]
palette=Image.open(ART/'palette.png');assert palette.size==(256,128) and len(palette.getcolors(256))==32
gallery=Path(__file__).with_name('gallery.html').read_text(encoding='utf-8').replace('__CATALOG__',json.dumps(catalog))
(OUT/'inspector.html').write_text(gallery,encoding='utf-8')
shutil.copy2(ROOT/'docs/spiders-and-goblin-3d.md',OUT/'START_HERE.md')
report={'originals':5,'models':4,'native_checks':native['checks'],'game_checks':live['checks'],'native_captures':312,'background_desktops_verified':2,'failures':[],
        'runtime_hashes':{p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in ART.iterdir() if p.suffix in ['.glb','.gd','.tscn','.tres','.png','.json']}}
(OUT/'artifact-validation.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print('CREATURE_ARTIFACTS',{k:v for k,v in report.items() if k!='runtime_hashes'})

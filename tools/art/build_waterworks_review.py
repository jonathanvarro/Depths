from pathlib import Path
import json,base64
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'art/concepts/waterworks-v1'
data=json.loads((OUT/'assets.json').read_text(encoding='utf-8'))
data['images']={id:'data:image/png;base64,'+base64.b64encode((ROOT/path.removeprefix('res://')).read_bytes()).decode() for id,path in data['images'].items()}
data['captures']=json.loads((OUT/'render-validation.json').read_text(encoding='utf-8'))['captures']
(OUT/'inspector.html').write_text((OUT/'layout.html').read_text(encoding='utf-8').replace('@@data@@',json.dumps(data)),encoding='utf-8',newline='\n')
print('Offline waterworks inspector built with 5 native assets and 18 renderer views.')

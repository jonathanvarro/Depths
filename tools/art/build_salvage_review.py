from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'art/concepts/salvage-v1'
catalog=json.loads((ROOT/'art/items/salvage-v1/catalog.json').read_text(encoding='utf-8'))
captures=json.loads((OUT/'godot-renderer.json').read_text(encoding='utf-8'))['captures']
template=Path(__file__).with_name('salvage_review.html').read_text(encoding='utf-8')
(OUT/'inspector.html').write_text(template.replace('/* DATA */{}',json.dumps({'items':catalog['items'],'captures':captures})),encoding='utf-8',newline='\n')
print('SALVAGE_REVIEW: seven live icons, before/after and real UI views')

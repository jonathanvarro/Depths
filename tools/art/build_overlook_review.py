"""Build the file-safe Overlook review from its actual production layout."""
from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'art/concepts/overlook-v1'
layout=json.loads((ROOT/'art/camp/overlook-v1/layout.json').read_text(encoding='utf-8'))
renders=json.loads((OUT/'godot-renderer.json').read_text(encoding='utf-8'))
data={'layout':layout,'captures':renders['captures']}
template=Path(__file__).with_name('overlook_review.html').read_text(encoding='utf-8')
(OUT/'inspector.html').write_text(template.replace('/* DATA */{}',json.dumps(data)),encoding='utf-8',newline='\n')
print('OVERLOOK_REVIEW: production layers, party/presence states and native captures')

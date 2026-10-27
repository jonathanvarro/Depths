"""Package actual Godot menu captures and pin the reused visual inputs."""
from pathlib import Path
import hashlib, json, subprocess

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'art/concepts/interface/journal-settings-v1'
reports = [json.loads((OUT / name).read_text()) for name in ['godot-validation.json', 'main-validation.json']]
assert all(not report['failures'] for report in reports)
files = [name for report in reports for name in report['captures']]
preferred = ['main-journal-normal.png', 'main-settings-normal.png', 'main-journal-larger.png', 'main-settings-larger.png']
files = preferred + [name for name in files if name not in preferred]
assert len(files) == len(set(files)) and all((OUT / name).exists() for name in files)
inputs = ['art/ui/map-v1/parchment.png', 'art/ui/controls-v1/journal.svg', 'art/ui/controls-v1/settings.svg', 'art/ui/controls-v1/close.svg']
for name in inputs:
    assert (ROOT / name).read_bytes() == subprocess.check_output(['git', 'show', 'HEAD:' + name], cwd=ROOT), name
record = {'date': '2026-10-26', 'issue': 165, 'new_raster_art': False,
          'reused_inputs': {name: hashlib.sha256((ROOT / name).read_bytes()).hexdigest() for name in inputs},
          'captures': files, 'physical_iPhone': False}
(OUT / 'catalog.json').write_text(json.dumps(record, indent=2) + '\n', encoding='utf-8', newline='\n')
html = '''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Depths · Quest log and Settings</title><style>
body{margin:0;background:#151b16;color:#e6dac1;font:17px system-ui}main{max-width:1280px;margin:auto;padding:20px}h1{font:30px Georgia}p{line-height:1.5;max-width:90ch;color:#b7ab93}a{color:#d7b174}nav{display:flex;gap:10px;flex-wrap:wrap;margin:16px 0}button,select{font:inherit;max-width:100%;min-height:44px;padding:9px;background:#2a2c22;color:#e6dac1;border:1px solid #796746}figure{margin:18px 0}img{display:block;width:100%;height:auto}figcaption{margin-top:12px;color:#b7ab93}</style>
<main><h1>Quest log and Settings</h1><p>Captured from the running Godot screens. The journal uses the existing rough paper, grouped open/completed entries and readable next steps. Settings keeps sound, display and music credits in the shared Field kit frame. The heading and Close stay outside the scroll areas.</p>
<nav><button data-view="main-journal-normal.png">Quest log</button><button data-view="main-settings-normal.png">Settings</button><button data-view="main-journal-larger.png">Journal · Larger</button><button data-view="main-settings-larger.png">Settings · Larger</button></nav>
<select id="view" aria-label="Capture"></select><figure><img id="render" alt=""><figcaption id="caption"></figcaption></figure>
<p>Includes desktop, landscape phone and SE-shaped views at Normal/Larger scale; narrow views, credits, empty/scrolled quests, and actual title/Pack/camp entry points. Screenshots and simulated touch checks do not establish physical iPhone usability.</p>
<p><a href="../../../../docs/journal-and-settings.md">Behavior, checks and handoff</a> · <a href="godot-validation.json">Isolated widget checks</a> · <a href="main-validation.json">Actual caller checks</a></p></main>
<script>const files=__FILES__,select=document.getElementById('view'),image=document.getElementById('render');files.forEach((f,i)=>select.add(new Option(f.replace('.png','').replaceAll('-',' '),i)));function show(){const f=files[select.selectedIndex];image.src=f;image.alt=select.selectedOptions[0].textContent;document.getElementById('caption').textContent=image.alt+' · Windows Godot 4.7.2 Mobile renderer';}select.onchange=show;document.querySelectorAll('[data-view]').forEach(b=>b.onclick=()=>{select.value=String(files.indexOf(b.dataset.view));show();});show();</script></html>'''
(OUT / 'inspector.html').write_text(html.replace('__FILES__', json.dumps(files)), encoding='utf-8', newline='\n')
print('MENU_REVIEW:', len(files), 'actual captures; existing paper and SVG inputs pinned')

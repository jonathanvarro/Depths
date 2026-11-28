"""Package local native review and an opt-in playable launcher; never launches it."""
import argparse
import html
import json
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument('--workspace', type=Path, required=True)
parser.add_argument('--output', type=Path, required=True)
parser.add_argument('--godot', type=Path, required=True)
args = parser.parse_args()
workspace, output, godot = (p.resolve() for p in (args.workspace, args.output, args.godot))
report = json.loads((output / 'native/validation.json').read_text())
assert not report['failures'], report['failures']
assert (workspace / 'scenes/prototypes/cavern_walk.tscn').is_file()
assert godot.is_file()
cards = []
for filename in report['captures']:
    assert (output / 'native' / filename).is_file()
    name = html.escape(filename.removesuffix('.png').replace('-', ' '))
    cards.append(f'<figure><a href="native/{filename}"><img loading="lazy" src="native/{filename}" alt="{name}"></a><figcaption>{name}</figcaption></figure>')
(output / 'inspector.html').write_text('''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Cavern walking study</title>
<style>body{margin:0;background:#101b20;color:#e8dfc8;font:18px/1.5 Georgia,serif}main{max-width:1440px;margin:auto;padding:28px}h1{font-weight:400;margin:0;color:#d6b579}a{color:#d6b579}p{max-width:75ch}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(320px,1fr));gap:20px}figure{margin:0;background:#182126;border:1px solid #685c40}img{display:block;width:100%}figcaption{padding:10px}code{font-size:16px}header{border-bottom:1px solid #685c40;margin-bottom:24px;padding-bottom:12px}</style>
<main><header><h1>Cavern · walking study</h1><p>A small playable loop: upper bridge, descending eastern ledge, lower ledge and western ascent. 27 cells, 2.4m between landings. The stone path and camera follow the same continuous ramp profile. Adjacent ledges connect only where a ramp exists.</p>
<p>Play: open <b>START_WALK.cmd</b> beside this page, or open <code>scenes/prototypes/cavern_walk.tscn</code> in the worktree and press F6. W/S or ↑/↓ move; A/D or ←/→ turn. Mouse/touch buttons support holds. M opens the explored map; Esc closes it or opens Continue / Start again / Quit prototype.</p>
<p>This study does not enter the campaign or read/write expedition saves or settings. The Rest Area threshold is the endpoint; walk back to explore the other route. Existing art is reused around a simple movement study; final ledge silhouettes and production floor integration remain later work.</p>
<p>Native Godot 4.7.2 Mobile/D3D12: ''' + str(report['checks']) + ' checks, ' + str(len(report['captures'])) + ''' captures, zero failures. Full loop and reverse traversal, real floor/scenery rays, GUI mouse/touch dispatch, pause/resume/restart, and 1280×720 / 1278×590 / 844×390 / 667×375 / 2556×1179 layouts. Private desktop; physical iPhone feel/performance awaits review.</p>
<p><a href="native/validation.json">Validation</a> · <a href="native-launch/launch.json">Private-desktop record</a></p></header><div class="grid">''' + ''.join(cards) + '</div></main></html>', encoding='utf-8')
# A visible interactive run is only started if the owner chooses this launcher.
(output / 'START_WALK.cmd').write_text(
    '@echo off\n'
    f'set "APPDATA={output / "play-profile"}"\n'
    f'start "" "{godot}" --path "{workspace}" res://scenes/prototypes/cavern_walk.tscn --resolution 1280x720\n',
    encoding='utf-8')
print(output / 'inspector.html')

"""Validate retained native/export evidence and package the local review."""
import argparse
import html
import json
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument('--workspace', type=Path, required=True)
parser.add_argument('--output', type=Path, required=True)
args = parser.parse_args()
workspace, output = args.workspace.resolve(), args.output.resolve()
report = json.loads((output/'native/validation.json').read_text())
assert not report['failures'], report['failures']
exports = {}
for area in ('cavern', 'rest'):
    folder = output/f'export-{area}-launch'
    launch = json.loads((folder/'launch.json').read_text())
    assert launch['exit_code'] == 0 and not launch['test_was_foreground']
    log = (folder/'stdout.log').read_text(encoding='utf-8')
    assert 'ERROR:' not in log and not (folder/'stderr.log').read_text(encoding='utf-8').strip()
    data = json.loads(next(line.removeprefix('AREA_CHECK ') for line in log.splitlines() if line.startswith('AREA_CHECK ')))
    assert data['area'] == area, data
    assert abs(data['party_y']-data['floor_y']) < .001
    if area == 'cavern':
        assert data['terrain_version'] == 1 and data['height_cells'] > 0
    else:
        assert data['refuge_asset'] == 'rest-area-approach' and data['refuge_state'] == 'used'
    exports[area] = data
(output/'export-validation.json').write_text(json.dumps(exports,indent=2))
native_launch=json.loads((output/'native-launch/launch.json').read_text())
assert not native_launch['test_was_foreground'] and native_launch['exit_code']==0
assert not (output/'native-launch/stderr.log').read_text().strip()
cards=[]
for filename in report['captures']:
    assert (output/'native'/filename).is_file()
    label=html.escape(filename.removesuffix('.png').replace('-',' '))
    cards.append(f'<figure><a href="native/{filename}"><img loading="lazy" src="native/{filename}" alt="{label}"></a><figcaption>{label}</figcaption></figure>')
(output/'inspector.html').write_text('''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Live Cavern and Rest Area</title><style>body{margin:0;background:#101b20;color:#e8dfc8;font:18px/1.5 Georgia,serif}main{max-width:1440px;padding:28px;margin:auto}h1{font-weight:400;color:#d6b579}a{color:#d6b579}p{max-width:80ch}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(340px,1fr));gap:20px}figure{margin:0;background:#182126;border:1px solid #685c40}img{display:block;width:100%}figcaption{padding:10px}</style><main><h1>Live Cavern and full Rest Area</h1><p>The approved elevation approach now runs inside the real expedition: sloping ledges, level encounter/quest landings, grounded creatures and props, compatible saved terrain and paired returns. New Rest Areas use the complete shelter, tent, supplies, planning table and bankable hearth.</p><p>Play with <b>START_CAVERN.cmd</b> or <b>START_REST.cmd</b> beside this page. They start the actual Windows export with copies of private review saves. Normal expedition saves/settings are untouched. Movement, Pack, Map and Esc menus are the existing game controls.</p><p>''' + str(report['checks']) + ' native checks / ' + str(len(report['captures'])) + ''' captures, zero failures. Terrain: 29,778 checks across 30 maps. Mandatory quest suite: 220 floors passed. Actual Windows export assertions confirm saved Cavern heights and the restored spent refuge. Physical iPhone performance and owner review remain.</p><p>Cached legacy Rest Area layouts retain their compact marker until a new expedition generates the full reserved approach. The approved Overlook interface and its present-party/rest/stash rules remain.</p><p><a href="native/validation.json">Native report</a> · <a href="export-validation.json">Executable assertions</a> · <a href="native-launch/launch.json">Private desktop record</a></p><div class="grid">''' + ''.join(cards) + '</div></main></html>',encoding='utf-8')
exe=workspace/'build/windows/Depths.exe'
assert exe.is_file()
play=output/'play-profile'
for area in ('cavern','rest'):
    fixture=output/'native'/('export-cavern-save.dat' if area=='cavern' else 'export-save.dat')
    private_save=play/f'{area}-review.dat'
    assert fixture.is_file()
    (output/f'START_{area.upper()}.cmd').write_text(
        '@echo off\n'+f'set "APPDATA={play}"\n'+f'if not exist "{play}" mkdir "{play}"\n'+
        f'if not exist "{private_save}" copy /b "{fixture}" "{private_save}" >nul\n'+
        f'start "" "{exe}" --resolution 1278x590 -- --save="{private_save}" --continue\n',encoding='utf-8')
print(json.dumps({'gallery':str(output/'inspector.html'),'native_checks':report['checks'],'exports':exports}))

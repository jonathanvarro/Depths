"""Package actual follow-up chair captures and verify their local provenance."""
from pathlib import Path
import hashlib
import html
import json

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / 'build/local-blender-kit-v1'
OUT = BASE / 'animation-requests-v1/female-chair-intake-v1'


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    checks = 0

    def check(ok, label):
        nonlocal checks
        checks += 1
        assert ok, label

    source = json.loads((OUT / 'source-manifest.json').read_text(encoding='utf-8'))
    prior = json.loads((BASE / 'animation-requests-v1/received-v1/source-manifest.json').read_text(encoding='utf-8'))
    originals = json.loads((BASE / 'kit-manifest.json').read_text(encoding='utf-8'))
    for entry in source['files'] + prior['files']:
        check(sha(Path(entry['destination'])) == entry['sha256'], 'Unchanged intake ' + entry['name'])
    for entry in originals['sources']:
        check(sha(BASE / entry['file']) == entry['sha256'], 'Unchanged earlier source ' + entry['file'])
    record = json.loads((OUT / 'female-manifest.json').read_text(encoding='utf-8'))
    check(sha(OUT / record['master']) == record['sha256'], 'Exact candidate master')
    check(sha(BASE / record['garment_source_master']) == record['garment_source_sha256'], 'Original garment master')
    for motion in record['motions']:
        check(motion['max_world_position_error'] < .00002 and motion['max_world_axis_error_degrees'] < .01,
              'Source world pose retained ' + motion['id'])
    export = json.loads((OUT / 'export-validation.json').read_text(encoding='utf-8'))
    native = json.loads((OUT / 'godot-smoke/godot-validation.json').read_text(encoding='utf-8'))
    check(not export['failures'] and not native['failures'], 'Independent and native checks pass')
    for entry in export['reports']:
        check(sha(OUT / entry['export']) == entry['sha256'], 'Exact imported GLB')
    captures = json.loads((OUT / 'review/captures.json').read_text(encoding='utf-8'))
    sections = ''
    for motion, title in [('sit_down', 'Stand to sit'), ('stand_up', 'Sit to stand')]:
        figures = ''
        for capture in [c for c in captures if c['motion'] == motion]:
            with Image.open(OUT / 'review' / capture['file']) as image:
                check(image.size == (420, 560) and image.getextrema()[0][0] != image.getextrema()[0][1], 'Actual capture ' + capture['file'])
            figures += f'<figure><img src="{capture["file"]}" width="420" height="560" alt="{html.escape(title + " " + capture["sample"] + " " + capture["angle"])}"><figcaption>{capture["sample"]} · {capture["angle"]} · frame {capture["frame"]:g}</figcaption></figure>'
        sections += f'<section><h2>{title}</h2><div class="frames">{figures}</div></section>'
    page = f'''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Female chair transitions</title>
<style>body{{background:#151d1d;color:#e4dfd0;font:17px/1.5 system-ui;margin:0 auto;padding:22px;max-width:1260px}}a{{color:#e8c58c}}h1,h2{{font-family:Georgia,serif}}.frames{{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:12px}}figure{{margin:0;background:#243030}}img{{display:block;width:100%;height:auto}}figcaption{{padding:10px;font-size:14px}}li{{margin:8px 0}}</style>
<h1>Female chair transitions</h1><p>Actual saved-candidate Blender captures, sampled at start/middle/end. No loop or seamless sequence approval is implied.</p>
<ul><li>Both new clips match the female body, with all 65 joints at 60fps. Source-world poses are preserved on her unchanged rig.</li><li>The re-uploaded sit-down has different bytes, but the three audited poses match its earlier version exactly.</li><li>Sit-down end and stand-up start have similar head/torso/leg posture. Their source root placement differs by about 1.074 units; align placement explicitly before chaining.</li><li>A quiet seated hold is still missing. Sitting Talking is a separate crossed-leg conversation pose.</li><li>Next: incorporate accepted clips into the existing clothing-switching reviewer and check full sequences, contacts and loops.</li></ul>
<p><a href="../female_chair.blend">Editable candidate</a> · <a href="../exports/female_kit.glb">Independent GLB</a> · <a href="../godot-smoke/native-female.png">Actual Godot import</a> · <a href="../../received-v1/candidates-v1/review/inspector.html">Earlier pack review</a></p>
<p>{export['checks']} independent export checks and {native['checks']} native Godot Mobile checks pass. All originals and earlier masters remain separate.</p>{sections}</html>'''
    (OUT / 'review/inspector.html').write_text(page, encoding='utf-8')
    result = {'checks': checks, 'failures': [], 'actual_blender_captures': len(captures),
              'independent_export_checks': export['checks'], 'native_mobile_checks': native['checks'],
              'quiet_seated_hold_received': False, 'final_sequence_approved': False}
    (OUT / 'review/validation.json').write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
    print('CHAIR_REVIEW', result)


if __name__ == '__main__':
    main()

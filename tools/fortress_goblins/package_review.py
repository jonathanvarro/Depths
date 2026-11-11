"""Package the fortress captures and keep the review tied to verified exports."""
import argparse
import hashlib
import json
from pathlib import Path

ROOT=Path(__file__).resolve().parents[2]
ART=ROOT/"art/enemies/fortress-goblins-3d-v1"
parser=argparse.ArgumentParser()
parser.add_argument("--workspace",type=Path,required=True)
args=parser.parse_args()
out=args.workspace/"build/local-fortress-goblins-3d-v1"
catalog=json.loads((ART/"catalog.json").read_text(encoding="utf-8"))
check=json.loads((out/"validation.json").read_text(encoding="utf-8"))
launch=json.loads((out/"native-check/launch.json").read_text(encoding="utf-8"))
assert not check["failures"] and check["renderer"]=="mobile"
assert launch["exit_code"]==0 and not launch["test_was_foreground"] and launch["foreground_unchanged"]
for asset in catalog["assets"]:
    model=ART/(asset["id"]+".glb")
    contents=model.read_bytes()
    assert hashlib.sha256(contents).hexdigest()==asset["sha256"]
    assert contents==(out/model.relative_to(ROOT)).read_bytes()
    assert (out/"masters"/(asset["id"]+".blend")).is_file()
for filename in check["captures"]:
    assert (out/"captures"/filename).read_bytes()[:8]==b"\x89PNG\r\n\x1a\n"
page='''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Depths · Fortress goblin review</title>
<style>
:root{background:#171b19;color:#e5d6b8;font:16px system-ui}body{max-width:1180px;margin:auto;padding:16px}h1{font:2.5rem Georgia}
figure{margin:12px 0;background:#242824;border:1px solid #615740}figcaption{padding:10px 12px}img{display:block;width:100%;height:auto}
select,button{min-height:44px;background:#292c27;color:inherit;border:1px solid #827455;padding:7px 12px;font:inherit}
#controls{display:flex;gap:8px;flex-wrap:wrap;align-items:center}a{color:#e5bb78}
</style>
<h1>Fortress goblins</h1>
<figure><img src="captures/lineup.png" alt="Common goblin, shield guard, archer and Goblin King">
<figcaption>Common goblin · shield guard · archer · Goblin King</figcaption></figure>
<div id="controls">
<label>Model <select id="asset"></select></label><label>Pose <select id="pose"></select></label>
<label>View <select id="view"><option value="pose">Three-quarter</option><option value="front">Front idle</option>
<option value="first-person">First person</option><option value="native-phone">Phone-size board</option></select></label>
<button id="prev" aria-label="Previous sample">−</button><button id="next" aria-label="Next sample">+</button>
<output id="label" aria-live="polite"></output></div>
<figure><img id="detail" alt=""></figure>
<p><a href="validation.json">Godot validation</a>. Use START_REVIEW.cmd for continuous playback and exact frame stepping.</p>
<script type="application/json" id="data">__CATALOG__</script>
<script>
const get = id => document.getElementById(id);
const assets = JSON.parse(get('data').textContent).assets;
const select = get('asset');
select.replaceChildren(...assets.map(a => new Option(a.label,a.id)));
select.value = 'goblin-king';
let asset, frame;
function choose() {
  asset = assets.find(a => a.id === select.value);
  get('pose').replaceChildren(...Object.keys(asset.clips).map(pose => new Option(pose,pose)));
  get('pose').value = 'idle';
  frame = 0;
  render();
}
function render() {
  const mode = get('view').value;
  const pose = get('pose').value;
  get('pose').disabled = mode !== 'pose';
  get('prev').disabled = mode !== 'pose' || frame === 0;
  get('next').disabled = mode !== 'pose' || frame === 4;
  const suffix = mode === 'pose' ? pose + '-' + frame : mode;
  get('label').value = mode === 'pose' ? 'Frame ' + asset.clips[pose].samples[frame].frame : 'Idle';
  get('detail').src = 'captures/' + asset.id + '-' + suffix + '.png';
  get('detail').alt = asset.label + ' · ' + suffix;
}
select.onchange = choose;
get('pose').onchange = () => { frame = 0; render(); };
get('view').onchange = render;
get('prev').onclick = () => { frame = Math.max(0,frame-1); render(); };
get('next').onclick = () => { frame = Math.min(4,frame+1); render(); };
choose();
</script></html>'''
(out/"inspector.html").write_text(page.replace("__CATALOG__",json.dumps(catalog)),encoding="utf-8")
print("Fortress gallery",len(catalog["assets"]),"models and",len(check["captures"]),"captures.")

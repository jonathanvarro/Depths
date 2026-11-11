"""Verify the native mining captures and write the local state comparison."""
import argparse
import hashlib
import json
from pathlib import Path

from PIL import Image, ImageChops

ROOT=Path(__file__).resolve().parents[2]
ART=ROOT/"art/props/mining-finds-3d-v1"
parser=argparse.ArgumentParser()
parser.add_argument("--workspace",type=Path,required=True)
args=parser.parse_args()
out=args.workspace/"build/local-mining-finds-v1"
validation=json.loads((out/"mobile.json").read_text(encoding="utf-8"))
launch=json.loads((out/"native-check/launch.json").read_text(encoding="utf-8"))
assert not validation["failures"] and validation["renderer"]=="mobile"
assert launch["exit_code"]==0 and launch["foreground_unchanged"] and not launch["test_was_foreground"]
catalog=json.loads((ART/"catalog.json").read_text(encoding="utf-8"))
for asset in catalog["assets"]:
    path=ART/(asset["id"]+".glb")
    assert hashlib.sha256(path.read_bytes()).hexdigest()==asset["sha256"]
    assert (out/"masters"/(asset["id"]+".blend")).is_file()
for id in ("tool-rack","coal-seam"):
    for width in (1278,852):
        with Image.open(out/(f"{id}-fresh-{width}.png")) as fresh, Image.open(out/(f"{id}-searched-{width}.png")) as searched:
            assert fresh.width==searched.width==width
            assert ImageChops.difference(fresh.convert("RGB"),searched.convert("RGB")).getbbox()
parts=[]
for id,label in (("tool-rack","Tool rack"),("coal-seam","Coal seam")):
    cards="".join(f'<figure><img src="{id}-{state}-852.png" alt="{label}, {state}"><figcaption>{state.title()}</figcaption></figure>'
                  for state in ("fresh","searched"))
    parts.append(f'<h2>{label}</h2><section>{cards}</section>')
page='''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Depths · Mining finds</title><style>
:root{background:#181c19;color:#e5d9bf;font:16px system-ui}body{max-width:1050px;margin:auto;padding:16px}
h1,h2{font-family:Georgia,serif}section{display:grid;grid-template-columns:repeat(auto-fit,minmax(min(100%,300px),1fr));gap:10px}
figure{margin:0;background:#262a24;border:1px solid #6c5b45}img{display:block;width:100%;height:auto}figcaption{padding:7px 10px}a{color:#dec18c}
</style><h1>Mining finds</h1>'''+''.join(parts)+'''
<p><a href="../mining-finds-trainer-art-checkout/art/concepts/mining-trainer-v1/inspector.html">Inventory icons and camp trainer</a> · <a href="mobile.json">Godot checks</a></p></html>'''
(out/"inspector.html").write_text(page,encoding="utf-8")
print("Mining gallery verified",validation["checks"],"checks,",len(validation["captures"]),"captures.")

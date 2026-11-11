"""Check local review evidence against the exported roster and package the gallery."""
import argparse
import hashlib
import json
import shutil
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
TOOL = Path(__file__).resolve().parent
parser = argparse.ArgumentParser()
parser.add_argument("--workspace", type=Path, required=True)
args = parser.parse_args()
out = args.workspace/"build/local-combat-roster-v1"
art = "art/enemies/combat-roster-3d-v1"
catalog = json.loads((ROOT/art/"catalog.json").read_text(encoding="utf-8"))
assert len(catalog["assets"]) == 11
assert sum(asset["party"] for asset in catalog["assets"]) == 4
proof = {}
for mode, folder in (("native",out),("live",out/"live")):
    report = json.loads((folder/"validation.json").read_text(encoding="utf-8"))
    launch = json.loads((out/(mode+"-check")/"launch.json").read_text(encoding="utf-8"))
    assert launch["exit_code"] == 0 and not launch["timed_out"], launch
    assert not launch["test_was_foreground"] and launch["foreground_unchanged"], launch
    assert not report["failures"] and report["renderer"] == "mobile", report["failures"]
    files = report["captures"]
    assert len(files) == len(set(files))
    for file in files:
        with Image.open((folder/"captures" if mode=="native" else folder)/file) as image:
            assert image.width>=600 and image.height>=120 and image.getextrema()[0][0] != image.getextrema()[0][1], file
    proof[mode] = {"checks":report["checks"],"captures":len(files),"foreground_unchanged":True}
for asset in catalog["assets"]:
    path = Path(art)/(asset["id"]+".glb")
    data = (ROOT/path).read_bytes()
    assert hashlib.sha256(data).hexdigest() == asset["sha256"]
    assert data == (out/path).read_bytes()
    assert (out/"masters"/(asset["id"]+".blend")).is_file()
for filename in ("palette.png","palette.tres","actor.gd"):
    assert (ROOT/art/filename).read_bytes() == (out/art/filename).read_bytes()
gallery = (TOOL/"gallery.html").read_text(encoding="utf-8")
(out/"inspector.html").write_text(gallery.replace("__CATALOG__",json.dumps(catalog,ensure_ascii=False)),encoding="utf-8")
shutil.copy2(ROOT/"docs/combat-roster-3d.md",out/"START_HERE.md")
(out/"artifact-validation.json").write_text(json.dumps(proof,indent=2)+"\n",encoding="utf-8")
print(proof)

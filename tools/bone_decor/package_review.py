"""Package the actual native bone-scenery captures as a local review gallery."""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
parser = argparse.ArgumentParser()
parser.add_argument("--workspace", type=Path, required=True)
args = parser.parse_args()
review = args.workspace / "build/local-bone-decor-v1"
catalog = json.loads((ROOT / "art/dressing/bone-decor-v1/catalog.json").read_text(encoding="utf-8"))
report = json.loads((review / "validation.json").read_text(encoding="utf-8"))
assert not report["failures"] and report["renderer"] == "mobile"
checks = 2
for entry in catalog["assets"]:
    path = ROOT / "art/dressing/bone-decor-v1" / (entry["name"] + ".glb")
    assert hashlib.sha256(path.read_bytes()).hexdigest() == entry["sha256"]
    checks += 1
for filename in report["captures"]:
    with Image.open(review / "captures" / filename) as image:
        assert image.width > 200 and image.height > 100
        assert image.getextrema()[0][0] < image.getextrema()[0][1]
    checks += 2
source = ROOT / "art/third-party/kaykit-bones-v1"
proof = json.loads((source / "provenance.json").read_text(encoding="utf-8"))
for entry in proof["files"]:
    data = (source / entry["file"]).read_bytes()
    assert hashlib.sha256(data).hexdigest() == entry["sha256"]
    blob = ("blob " + str(len(data)) + "\0").encode() + data
    assert hashlib.sha1(blob).hexdigest() == entry["git_blob_sha1"]
    checks += 2
items = [
    ("scattered-bones", "Scattered bones", "Four loose bones"),
    ("small-remains", "Small remains", "Skull, ribcage and loose limbs"),
    ("fallen-skeleton", "Fallen skeleton study", "Static Death A pose"),
    ("seated-skeleton", "Seated skeleton study", "Static floor-sitting pose"),
]
cards = ""
for name, label, text in items:
    triangles = report["scene_triangles"][name]
    cards += (f'<article data-name="{name}"><h2>{label}</h2>'
              f'<img src="captures/{name}-cave-0.png" alt="Native {label.lower()} preview">'
              f'<p>{text} · {triangles:,} triangles</p></article>\n')
template = Path(__file__).with_name("gallery.html").read_text(encoding="utf-8")
(review / "inspector.html").write_text(template.replace("@@CARDS@@", cards), encoding="utf-8")
(review / "artifact-validation.json").write_text(
    json.dumps({"checks": checks, "failures": [], "verified_originals": len(proof["files"])}, indent=2) + "\n", encoding="utf-8")
shutil.copy2(ROOT / "docs/bone-decor-library.md", review / "START_HERE.md")
print("BONE_ARTIFACTS", checks, "checks")

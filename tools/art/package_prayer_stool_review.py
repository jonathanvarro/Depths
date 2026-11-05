"""Package #216 items/marks and the local #218 stool contact captures."""
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
output = args.workspace / "build/prayer-stool-review-v1"
output.mkdir(parents=True, exist_ok=True)
for folder in ["items", "marks", "captures"]:
    (output / folder).mkdir(exist_ok=True)
items = ["tome_light", "tome_bind", "tome_watch", "votive_candle"]
checks = 0
hashes = {}
for item in items:
    for size in [128, 64]:
        suffix = "" if size == 128 else "-64"
        path = ROOT / "art/items/prayers-v1" / f"{item}{suffix}.png"
        image = Image.open(path).convert("RGBA")
        assert image.size == (size, size)
        assert set(image.getchannel("A").getdata()) == {0, 255}
        assert len({pixel for pixel in image.getdata() if pixel[3]}) <= 64
        checks += 3
        shutil.copy2(path, output / "items" / path.name)
        hashes[path.name] = hashlib.sha256(path.read_bytes()).hexdigest()
for path in (ROOT / "art/ui/prayers-v1").glob("*.svg"):
    shutil.copy2(path, output / "marks" / path.name)
prayers = args.workspace / "build/prayer-art-check-v1"
stool = args.workspace / "build/local-stool-review-v1"
for source, target in [(prayers / "native-prayers.png", "native-prayers.png"),
                       (stool / "seated-side.png", "seated-side.png"),
                       (stool / "sit-approach.png", "sit-approach.png"),
                       (stool / "stand-rise.png", "stand-rise.png")]:
    shutil.copy2(source, output / "captures" / target)
for source, filename in [(prayers, "native-prayers.json"), (stool, "stool-validation.json")]:
    report = json.loads((source / filename).read_text(encoding="utf-8"))
    assert not report["failures"] and report["renderer"] == "mobile"
    checks += 2
    shutil.copy2(source / filename, output / filename)
source_hashes = json.loads((stool / "source-hashes.json").read_text(encoding="utf-8"))
for relative, expected in source_hashes.items():
    for path in [stool / relative, args.workspace / "build/local-padded-jacket-v2" / relative]:
        assert hashlib.sha256(path.read_bytes()).hexdigest() == expected
        checks += 1
template = Path(__file__).with_name("prayer-stool-review.html").read_text(encoding="utf-8")
(output / "inspector.html").write_text(template, encoding="utf-8")
(output / "artifact-validation.json").write_text(
    json.dumps({"checks": checks, "failures": [], "item_sha256": hashes}, indent=2) + "\n", encoding="utf-8")
print("PRAYER_STOOL_ARTIFACTS", checks, "checks passed", output)

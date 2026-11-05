"""Create a private stool-contact review from the checked jacket snapshot."""
import argparse
import hashlib
import json
from pathlib import Path
import shutil

ROOT = Path(__file__).resolve().parents[2]
parser = argparse.ArgumentParser()
parser.add_argument("--workspace", type=Path, required=True)
args = parser.parse_args()
source = args.workspace / "build/local-padded-jacket-v2"
output = args.workspace / "build/local-stool-review-v1"
output.mkdir(parents=True, exist_ok=True)
(output / "assets").mkdir(exist_ok=True)

def copy_file(path, relative):
    target = output / relative
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(path, target)

for filename in ["actor.gd", "actor_base.gd", "review.gd", "review_base.gd",
                 "project.godot", "display_normalization.json", "manifest.json", "START_REVIEW.cmd"]:
    copy_file(source / filename, filename)
for fit in ["female", "male"]:
    copy_file(source / "assets" / f"{fit}.glb", f"assets/{fit}.glb")
manifest = json.loads((output / "manifest.json").read_text(encoding="utf-8"))
manifest["review_footer"] = "Fixed 43 cm stool / chair contact review / #218"
(output / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
copy_file(ROOT / "tools/stool_review/stool_review.gd", "stool_review.gd")
copy_file(ROOT / "tools/stool_review/check_stool.gd", "check_stool.gd")
for filename in ["stool.tscn", "stool.glb"]:
    copy_file(ROOT / "art/dressing/camp-stool-v1" / filename, f"art/dressing/camp-stool-v1/{filename}")
copy_file(ROOT / "art/dressing/camp-stool-v1/stool.tscn", "stool.tscn")
scene = (source / "review.tscn").read_text(encoding="utf-8")
(output / "review.tscn").write_text(scene.replace("res://review.gd", "res://stool_review.gd"), encoding="utf-8")
hashes = {f"assets/{fit}.glb": hashlib.sha256((source / "assets" / f"{fit}.glb").read_bytes()).hexdigest()
          for fit in ["female", "male"]}
(output / "source-hashes.json").write_text(json.dumps(hashes, indent=2) + "\n", encoding="utf-8")
print("STOOL_REVIEW_PREPARED", output)

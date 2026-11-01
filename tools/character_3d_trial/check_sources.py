"""Source/export/link checks for the isolated native 3D review."""
from pathlib import Path
from html.parser import HTMLParser
import hashlib
import json
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
REVIEW = ROOT / "art/concepts/character-3d-trial-v1"
manifest = json.loads((REVIEW / "manifest.json").read_text(encoding="utf-8"))
report = json.loads((REVIEW / "report.json").read_text(encoding="utf-8"))
assert not report["failures"]
checks = 1
for name, record in manifest["files"].items():
    file = REVIEW / name
    assert hashlib.sha256(file.read_bytes()).hexdigest() == record["sha256"], name
    checks += 1
    if name.endswith(".png"):
        with Image.open(file) as image:
            image.load()
            if name.endswith("-96.png") or name.endswith("-192.png"):
                expected = 96 if name.endswith("-96.png") else 192
                assert image.size == (expected, expected), name
                assert len(image.getcolors(maxcolors=1_000_000)) > 8, name
                checks += 2
    if name.endswith(".tscn"):
        text = file.read_text(encoding="utf-8")
        assert "Skeleton3D" in text and "BoneAttachment3D" in text
        assert "script =" not in text and "ext_resource" not in text
        checks += 2

class Links(HTMLParser):
    def handle_starttag(self, tag, attrs):
        global checks
        for key, value in attrs:
            if key in {"href", "src"} and value and not value.startswith(("http", "#")):
                assert (REVIEW / value).exists(), value
                checks += 1

Links().feed((REVIEW / "inspector.html").read_text(encoding="utf-8"))
for view in ["standing", "portrait", "seated", "reading", "back"]:
    for index in range(3):
        assert (REVIEW / f"{view}-{index}.png").exists()
        checks += 1
print(f"CHARACTER3D_SOURCE: {checks} checks passed")

"""Package actual renderer outputs; never synthesizes or retouches model imagery."""
from pathlib import Path
import hashlib
import json
import shutil
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "build/character3d-review"
DEST = ROOT / "art/concepts/character-3d-trial-v1"
DEST.mkdir(parents=True, exist_ok=True)
files = {}
for item in sorted(SOURCE.iterdir()):
    if item.suffix in {".png", ".tscn"} or item.name == "report.json":
        target = DEST / item.name
        shutil.copyfile(item, target)
        digest = hashlib.sha256(item.read_bytes()).hexdigest()
        assert hashlib.sha256(target.read_bytes()).hexdigest() == digest
        files[item.name] = {"sha256": digest, "bytes": item.stat().st_size}
        if item.suffix == ".png":
            with Image.open(target) as image:
                image.verify()

try:
    font = ImageFont.truetype("C:/Windows/Fonts/segoeui.ttf", 23)
    small = ImageFont.truetype("C:/Windows/Fonts/segoeui.ttf", 17)
except OSError:
    font = small = ImageFont.load_default()
sheet = Image.new("RGB", (1440, 1010), "#161d23")
draw = ImageDraw.Draw(sheet)
draw.text((24, 14), "MODULAR 3D COMPANIONS / actual Godot renders", font=font, fill="#e4e7e7")
draw.text((24, 49), "Technical blockout. Shared rig and wardrobe; faces and materials are not production art.", font=small, fill="#bfc6c8")
tiles = [
    ("standing-0-render.png", "Travel cloth / shield"),
    ("standing-1-render.png", "Quilted medium / cape"),
    ("standing-2-render.png", "Heavy plates / pack"),
    ("portrait-0-render.png", "Same faces / portrait camera"),
    ("reading-1-render.png", "Shared reading pose"),
    ("back-2-render.png", "Back view / frame pack"),
]
for i, (filename, label) in enumerate(tiles):
    x, y = (i % 3) * 480, 96 + (i // 3) * 370
    draw.text((x + 20, y), label, font=small, fill="#e4e7e7")
    image = Image.open(DEST / filename).convert("RGB")
    image.thumbnail((456, 330), Image.Resampling.LANCZOS)
    sheet.paste(image, (x + (480 - image.width) // 2, y + 33))
draw.text((24, 850), "Native 96px portrait renders / cloth, medium, heavy", font=small, fill="#e4e7e7")
for person_index, person in enumerate(["rook", "branna"]):
    for outfit in range(3):
        image = Image.open(DEST / f"{person}-{outfit}-96.png").convert("RGB")
        sheet.paste(image, (24 + outfit * 116 + person_index * 510, 887))
sheet.save(DEST / "overview.png")

manifest = {
    "date": "2026-11-01", "issue": 203,
    "source": "Original procedural meshes in tools/character_3d_trial/character.gd",
    "inputs": "No external models, image references or generated image masters",
    "renderer": "Godot 4.7.2 Mobile / D3D12 / Radeon RX 9070 XT",
    "limits": "Rigid-part technical prototype; not production skinning, likeness approval or phone benchmark",
    "renderer_warning": "Sandbox prevents user://vulkan shader-cache directory creation; renderer continues without cache and exits 0.",
    "files": files,
    "source_files": {name: hashlib.sha256((ROOT / "tools/character_3d_trial" / name).read_bytes()).hexdigest() for name in ["character.gd", "review.gd", "check.gd", "project.godot"]},
}
(DEST / "manifest.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")
print(f"Packaged {len(files)} original capture/model/report files plus overview and manifest")

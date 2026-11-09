"""Muted 256px atlases for the owner's CC0 KayKit bone scenery."""
import hashlib
import json
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "art/third-party/kaykit-bones-v1"
OUTPUT = ROOT / "art/dressing/bone-decor-v1"
OUTPUT.mkdir(parents=True, exist_ok=True)
inputs = {"halloween": SOURCE / "halloween/halloweenbits_texture.png",
          "skeletons": SOURCE / "skeletons/skeleton_texture.png"}
for family, path in inputs.items():
    image = Image.open(path).convert("RGB").resize((256, 256), Image.Resampling.BILINEAR)
    colours = []
    for red, green, blue in image.getdata():
        grey = .25 * red + .60 * green + .15 * blue
        colours.append((round((grey * .70 + red * .30) * .94),
                        round((grey * .70 + green * .30) * .88),
                        round((grey * .70 + blue * .30) * .73)))
    image.putdata(colours)
    image = image.quantize(colors=64, dither=Image.Dither.NONE).convert("RGB")
    image.save(OUTPUT / ("texture-" + family + ".png"), optimize=True)
record = {str(path.relative_to(SOURCE)).replace("\\", "/"): hashlib.sha256(path.read_bytes()).hexdigest()
          for path in sorted(SOURCE.rglob("*")) if path.is_file() and path.parent.name in inputs}
(OUTPUT / "source-hashes.json").write_text(json.dumps(record, indent=2) + "\n", encoding="utf-8")
print("BONE_ATLASES_READY")

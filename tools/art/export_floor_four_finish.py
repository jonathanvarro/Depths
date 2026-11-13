"""Fit the new tome and named-cast studies to the game's review sizes."""
from pathlib import Path
import hashlib
import json
import sys

from PIL import Image

sys.dont_write_bytecode = True
from build_field_kit_art import fitted


ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "art/source/floor-four-finish-v1"


def export(record, key, directory, sizes, colours):
    path = SOURCE / f"{key}.png"
    entry = record[key]
    assert hashlib.sha256(path.read_bytes()).hexdigest() == entry["sha256"], key
    image = Image.open(path).convert("RGBA")
    assert image.getchannel("A").getextrema() == (0, 255), key
    directory.mkdir(parents=True, exist_ok=True)
    for size in sizes:
        result, _ = fitted(image, size, colours)
        result.save(directory / f"{key}-{size}.png", optimize=True)


if __name__ == "__main__":
    record = json.loads((SOURCE / "generation.json").read_text(encoding="utf-8"))["assets"]
    export(record, "tome-discern", ROOT / "art/items/discern-v1", (64, 128), 64)
    for name in ("branna", "nessa", "maelin"):
        export(record, name, ROOT / "art/concepts/named-cast-v1", (96, 192), 64)

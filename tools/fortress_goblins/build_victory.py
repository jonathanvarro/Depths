"""Fit the original Goblin King victory card to the existing story UI canvas."""
import hashlib
import json
from pathlib import Path

from PIL import Image, ImageOps

ROOT=Path(__file__).resolve().parents[2]
SOURCE=ROOT/"art/source/fortress-king-v1"
entry=json.loads((SOURCE/"generation.json").read_text(encoding="utf-8"))["assets"][0]
source=SOURCE/entry["master"]
assert hashlib.sha256(source.read_bytes()).hexdigest()==entry["sha256"]
destination=ROOT/"art/illustrations/fortress-king-v1/victory.png"
destination.parent.mkdir(parents=True,exist_ok=True)
with Image.open(source) as image:
    card=ImageOps.fit(image.convert("RGB"),(640,360),Image.Resampling.LANCZOS)
assert card.size==(640,360)
card.save(destination)

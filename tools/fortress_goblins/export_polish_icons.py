"""Export the bestiary mask and the two item sizes from native model renders."""
import argparse
from pathlib import Path
import sys

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
sys.dont_write_bytecode = True
sys.path.insert(0, str(ROOT / "tools/art"))
from build_field_kit_art import fitted


def silhouette(path):
    mask = Image.open(path).convert("RGBA").getchannel("A")
    mask = mask.point(lambda opacity: 255 if opacity >= 128 else 0)
    mask = mask.crop(mask.getbbox())
    mask.thumbnail((56, 56), Image.Resampling.NEAREST)
    result = Image.new("RGBA", (64, 64))
    result.paste((48, 45, 37, 255),
                 ((64-mask.width)//2, (64-mask.height)//2,
                  (64+mask.width)//2, (64+mask.height)//2), mask)
    return result


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--review-output", type=Path, required=True)
    args = parser.parse_args()
    renders = args.review_output / "polish"
    journal = ROOT / "art/ui/expedition-v1/thumbnails/goblin_king.png"
    silhouette(renders / "king-profile.png").save(journal, optimize=True)
    raw = Image.open(renders / "treatment.png").convert("RGBA")
    items = ROOT / "art/items/treatment-supplies-v1"
    items.mkdir(parents=True, exist_ok=True)
    for size in (64, 128):
        image, _ = fitted(raw, size, 64)
        image.save(items / f"bundle-{size}.png", optimize=True)


if __name__ == "__main__":
    main()

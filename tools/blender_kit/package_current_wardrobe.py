"""Package/check assembly-v2 without touching the earlier review or sources."""
from pathlib import Path
import sys

sys.dont_write_bytecode = True
import package_wardrobe
import validate_wardrobe

OUT = Path(__file__).resolve().parents[2] / 'build/local-blender-kit-v1/assembly-v2'

if __name__ == '__main__':
    package_wardrobe.OUT = OUT
    package_wardrobe.REVIEW = OUT / 'review'
    package_wardrobe.main()
    validate_wardrobe.OUT = OUT
    validate_wardrobe.main()

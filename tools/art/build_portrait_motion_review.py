"""Package unedited Godot viewport captures as a looping review animation."""
from pathlib import Path
from PIL import Image
import sys

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / (sys.argv[1] if len(sys.argv)>1 else 'art/concepts/portrait-coherence-v1')
frames = [Image.open(path).convert('RGB') for path in sorted(OUT.glob('motion-*.png'))]
assert len(frames) == 18 and all(image.size == (512, 448) for image in frames)
# One display palette prevents GIF re-quantisation from making skin colours
# flicker between frames. Native PNGs remain the exact-pixel review source.
palette = frames[0].quantize(colors=256, dither=Image.Dither.NONE)
frames = [frame.quantize(palette=palette, dither=Image.Dither.NONE) for frame in frames]
frames[0].save(OUT / 'motion.gif', save_all=True, append_images=frames[1:],
               duration=[80] * 17 + [700], loop=0, disposal=2)
print('Packaged 18 unedited runtime captures into motion.gif')

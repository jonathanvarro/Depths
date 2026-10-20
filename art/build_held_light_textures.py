"""Small pixel textures for the 3D held torch and lantern (owner request,
2026-10-20). Deterministic; rerun after tweaking.

    python art/build_held_light_textures.py
"""
import random
from pathlib import Path
from PIL import Image

OUT = Path(__file__).parent / "props" / "held-3d-v1"
OUT.mkdir(parents=True, exist_ok=True)
rng = random.Random(7)


def clamp(v):
    return max(0, min(255, int(v)))


def wood():
    """Dark, oiled ash with long vertical grain."""
    w, h = 16, 64
    img = Image.new("RGB", (w, h))
    px = img.load()
    lines = [rng.uniform(-0.5, 0.5) for _ in range(w)]
    for x in range(w):
        for y in range(h):
            base = 62 + 14 * lines[x] + rng.uniform(-5, 5)
            if (x + y // 9) % 5 == 0:
                base -= 14  # grain line
            px[x, y] = (clamp(base * 1.25), clamp(base * 0.86), clamp(base * 0.55))
    img.save(OUT / "wood.png")


def cloth():
    """Pitch-soaked rag wrapping: diagonal bands, charred toward the top."""
    w, h = 32, 32
    img = Image.new("RGB", (w, h))
    px = img.load()
    for x in range(w):
        for y in range(h):
            band = ((x + y * 2) // 5) % 2
            v = 118 if band else 92
            v += rng.uniform(-10, 10)
            char = max(0.0, 1.0 - y / 11.0)  # top rows burnt black
            r, g, b = v * 1.1, v * 0.86, v * 0.55
            r, g, b = (c * (1 - 0.8 * char) for c in (r, g, b))
            if y < 3 and rng.random() < 0.35:
                r, g, b = 160, 70, 20  # glowing embers in the char
            px[x, y] = (clamp(r), clamp(g), clamp(b))
    img.save(OUT / "cloth.png")


def leather():
    """Dark grip binding."""
    w, h = 16, 16
    img = Image.new("RGB", (w, h))
    px = img.load()
    for x in range(w):
        for y in range(h):
            v = 46 + rng.uniform(-6, 6) + (8 if (x + y) % 6 == 0 else 0)
            px[x, y] = (clamp(v * 1.3), clamp(v * 0.95), clamp(v * 0.7))
    img.save(OUT / "leather.png")


def metal(name, rgb, spots):
    """Aged brass or blackened iron with pitting."""
    w, h = 16, 16
    img = Image.new("RGB", (w, h))
    px = img.load()
    for x in range(w):
        for y in range(h):
            k = 1.0 + rng.uniform(-0.12, 0.12)
            if rng.random() < spots:
                k *= 0.55  # tarnish / pitting
            if y in (0, 15):
                k *= 1.25  # worn edge
            px[x, y] = tuple(clamp(c * k) for c in rgb)
    img.save(OUT / f"{name}.png")


wood()
cloth()
leather()
metal("brass", (128, 96, 54), 0.18)
metal("iron", (58, 52, 46), 0.22)
print("wrote", OUT)

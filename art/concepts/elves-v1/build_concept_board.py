"""Elves and dark elves: first concept board (owner direction, 2026-10-20).

A designer's board, not final art. It shows:
- build and height against a human;
- the face direction (big brows, sharp male chins, softer female faces, long ears);
- the armour language and the palettes.

ChatGPT paints the real portraits and sprites from it; see
docs/elves-concept.md.

    python art/concepts/elves-v1/build_concept_board.py
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

HERE = Path(__file__).parent
ROOT = HERE.parents[2]
SS = 2  # supersample, then shrink for clean edges
W, H = 2400, 1700
BG = (24, 22, 21)
INK = (18, 15, 14)
TEXT = (232, 220, 192)
MUTED = (165, 152, 128)

PALETTES = {
    "Human (reference)": {"skin": [(201, 160, 128), (170, 128, 98)], "hair": [(84, 60, 44)], "metal": [(110, 100, 86)], "cloth": [(96, 78, 60)]},
    "Elf": {
        "skin": [(244, 216, 192), (226, 190, 162), (196, 156, 128)],
        "hair": [(246, 226, 160), (222, 190, 110), (176, 140, 70)],
        "metal": [(236, 241, 246), (196, 206, 216), (146, 158, 172), (92, 102, 116)],
        "cloth": [(52, 96, 80), (34, 66, 56), (204, 176, 98)],
    },
    "Dark elf": {
        "skin": [(152, 170, 204), (118, 136, 174), (82, 96, 132)],
        "hair": [(236, 238, 244), (186, 190, 204), (30, 30, 38), (14, 14, 18)],
        "metal": [(78, 78, 92), (44, 44, 54), (26, 26, 32), (14, 14, 18)],
        "cloth": [(96, 30, 56), (58, 18, 36), (150, 152, 168), (36, 34, 38)],
    },
}


def font(size, display=False):
    path = ROOT / ("art/fonts/cinzel/Cinzel-Variable.ttf" if display else "art/fonts/source-sans-3/SourceSans3-Variable.ttf")
    return ImageFont.truetype(str(path), size * SS)


def P(points):
    return [(x * SS, y * SS) for x, y in points]


def poly(d, pts, fill, outline=INK, width=2):
    d.polygon(P(pts), fill=fill, outline=outline, width=width * SS)


def line(d, pts, fill, width=2):
    d.line(P(pts), fill=fill, width=width * SS, joint="curve")


def ellipse(d, box, fill, outline=INK, width=2):
    x0, y0, x1, y1 = box
    d.ellipse([x0 * SS, y0 * SS, x1 * SS, y1 * SS], fill=fill, outline=outline, width=width * SS)


def text(d, xy, s, size=20, fill=TEXT, display=False, anchor="la"):
    d.text((xy[0] * SS, xy[1] * SS), s, font=font(size, display), fill=fill, anchor=anchor)


# --- Full figures ----------------------------------------------------------

def figure(d, cx, ground, height, kind, sex):
    """A front-view costume silhouette. `kind`: human, elf, dark."""
    heads = 7.4 if kind == "human" else 8.4  # elves: longer legs and neck
    h = height / heads
    top = ground - height
    male = sex == "m"
    pal = PALETTES["Human (reference)" if kind == "human" else ("Elf" if kind == "elf" else "Dark elf")]
    skin, hair, metal, cloth = pal["skin"], pal["hair"], pal["metal"], pal["cloth"]
    slim = 0.88 if kind != "human" else 1.0
    sh = (1.05 if male else 0.88) * h * slim  # half shoulder width
    wa = (0.62 if male else 0.48) * h * slim  # half waist
    hi = (0.7 if male else 0.78) * h * slim  # half hips
    neck_y = top + h * 1.05
    sh_y = top + h * 1.45
    waist_y = top + h * 3.1
    hip_y = top + h * 3.7
    knee_y = top + h * 5.9
    if kind == "dark":
        hair_col = hair[0] if male else hair[2]  # he white-haired, she black
    else:
        hair_col = hair[0] if kind == "elf" else hair[0]

    # Cloak or cape behind.
    if kind == "elf":
        poly(d, [(cx - sh * 1.05, sh_y), (cx + sh * 1.05, sh_y), (cx + sh * 1.45, knee_y + h * 0.8), (cx - sh * 1.45, knee_y + h * 0.8)], cloth[1])
    elif kind == "dark":
        poly(d, [(cx - sh * 1.1, sh_y), (cx + sh * 1.1, sh_y), (cx + sh * 1.6, ground - h * 0.25), (cx + sh * 0.6, ground - h * 0.1), (cx, ground - h * 0.4), (cx - sh * 0.6, ground - h * 0.1), (cx - sh * 1.6, ground - h * 0.25)], cloth[1])
    # Long hair behind the shoulders.
    if kind != "human" and not male:
        poly(d, [(cx - h * 0.42, top + h * 0.4), (cx + h * 0.42, top + h * 0.4), (cx + h * 0.62, sh_y + h * 1.5), (cx - h * 0.62, sh_y + h * 1.5)], hair_col)
    elif kind != "human":
        poly(d, [(cx - h * 0.38, top + h * 0.4), (cx + h * 0.38, top + h * 0.4), (cx + h * 0.5, sh_y + h * 0.35), (cx - h * 0.5, sh_y + h * 0.35)], hair_col)

    leg_col = metal[1] if kind != "human" else cloth[0]
    # Legs.
    for side in (-1, 1):
        x_hip = cx + side * hi * 0.5
        poly(d, [(x_hip - h * 0.24, hip_y), (x_hip + h * 0.24, hip_y), (cx + side * h * 0.34 + h * 0.13, ground - h * 0.12), (cx + side * h * 0.34 - h * 0.13, ground - h * 0.12)], leg_col)
        # Boots.
        poly(d, [(cx + side * h * 0.34 - h * 0.15, knee_y + h * 0.9), (cx + side * h * 0.34 + h * 0.15, knee_y + h * 0.9), (cx + side * h * 0.34 + h * 0.18, ground), (cx + side * h * 0.34 - h * 0.18, ground)], metal[2] if kind != "human" else (60, 46, 36))
        if kind == "elf":  # banded greaves
            for i in range(4):
                y = knee_y + h * (0.1 + i * 0.25)
                line(d, [(cx + side * h * 0.34 - h * 0.16, y), (cx + side * h * 0.34 + h * 0.16, y + h * 0.04)], metal[3], 2)
            ellipse(d, (cx + side * h * 0.34 - h * 0.14, knee_y - h * 0.14, cx + side * h * 0.34 + h * 0.14, knee_y + h * 0.14), metal[0])
        elif kind == "dark":  # spiked knee cops
            poly(d, [(cx + side * h * 0.34 - h * 0.15, knee_y), (cx + side * h * 0.34, knee_y - h * 0.35), (cx + side * h * 0.34 + h * 0.15, knee_y), (cx + side * h * 0.34, knee_y + h * 0.18)], metal[1])
    # Arms.
    for side in (-1, 1):
        sx = cx + side * sh
        hand_y = hip_y + h * 0.55
        poly(d, [(sx - h * 0.17, sh_y + h * 0.1), (sx + h * 0.17, sh_y + h * 0.1), (sx + side * h * 0.12 + h * 0.12, hand_y), (sx + side * h * 0.12 - h * 0.12, hand_y)], metal[1] if kind != "human" else cloth[0])
        ellipse(d, (sx + side * h * 0.12 - h * 0.11, hand_y - h * 0.02, sx + side * h * 0.12 + h * 0.11, hand_y + h * 0.22), skin[1] if kind == "human" else metal[2])
        if kind == "elf":  # layered vambrace bands
            for i in range(4):
                y = sh_y + h * (1.35 + i * 0.22)
                line(d, [(sx + side * h * 0.05 - h * 0.15, y), (sx + side * h * 0.05 + h * 0.15, y)], metal[3], 2)
    # Torso.
    body = metal[0] if kind == "elf" else (metal[2] if kind == "dark" else cloth[0])
    torso = [(cx - sh, sh_y), (cx + sh, sh_y), (cx + wa, waist_y), (cx + hi, hip_y), (cx - hi, hip_y), (cx - wa, waist_y)]
    poly(d, torso, body)
    if kind == "elf":
        # Banded mithril cuirass: overlapping curved lames.
        for i in range(7):
            t = i / 7
            y = sh_y + h * 0.45 + t * (hip_y - sh_y - h * 0.45)
            half = sh + (wa - sh) * min(1, t * 1.6) if t < 0.62 else wa + (hi - wa) * (t - 0.62) / 0.38
            line(d, [(cx - half * 0.92, y), (cx, y + h * 0.12), (cx + half * 0.92, y)], metal[2], 3)
        # Leaf tassets.
        for side in (-1, 1):
            for k in range(2):
                x = cx + side * (hi * 0.35 + k * hi * 0.42)
                poly(d, [(x - h * 0.2, hip_y - h * 0.05), (x + h * 0.2, hip_y - h * 0.05), (x, hip_y + h * 0.85)], metal[1])
        # Green tabard panel with gold edge.
        poly(d, [(cx - h * 0.22, waist_y), (cx + h * 0.22, waist_y), (cx + h * 0.18, knee_y + h * 0.3), (cx, knee_y + h * 0.55), (cx - h * 0.18, knee_y + h * 0.3)], cloth[0], outline=cloth[2])
    elif kind == "dark":
        # Gothic plate: central ridge, fluting, pointed waist.
        line(d, [(cx, sh_y + h * 0.3), (cx, waist_y + h * 0.3)], metal[0], 3)
        for k in (-2, -1, 1, 2):
            line(d, [(cx + k * h * 0.2, sh_y + h * 0.5), (cx + k * h * 0.14, waist_y)], metal[0], 2)
        poly(d, [(cx - wa, waist_y), (cx + wa, waist_y), (cx, waist_y + h * 0.55)], metal[1])
        for side in (-1, 1):  # pointed tassets
            for k in range(2):
                x = cx + side * (hi * 0.4 + k * hi * 0.45)
                poly(d, [(x - h * 0.2, hip_y - h * 0.1), (x + h * 0.2, hip_y - h * 0.1), (x + side * h * 0.05, hip_y + h * 0.95)], metal[2])
        # Crimson tabard.
        poly(d, [(cx - h * 0.18, hip_y), (cx + h * 0.18, hip_y), (cx + h * 0.12, knee_y + h * 0.6), (cx, knee_y + h * 0.9), (cx - h * 0.12, knee_y + h * 0.6)], cloth[0], outline=cloth[2])
    # Shoulders.
    for side in (-1, 1):
        sx = cx + side * sh
        if kind == "elf":
            for i in range(3):  # three stacked crescent lames
                r = h * (0.52 - i * 0.09)
                y = sh_y + h * (0.05 + i * 0.22)
                d.chord([(sx - r) * SS, (y - r * 0.7) * SS, (sx + r) * SS, (y + r * 0.7) * SS], 180, 360, fill=metal[i % 2], outline=INK, width=2 * SS)
        elif kind == "dark":
            poly(d, [(sx - side * h * 0.25, sh_y + h * 0.35), (sx + side * h * 0.55, sh_y + h * 0.3), (sx + side * h * 0.3, sh_y - h * 0.95), (sx, sh_y - h * 0.1)], metal[1])
    # Black fur mantle.
    if kind == "dark":
        pts = []
        n = 14
        for i in range(n + 1):
            t = i / n
            x = cx - sh * 1.15 + t * sh * 2.3
            y = sh_y + h * (0.05 if i % 2 else 0.4) - h * 0.15 * (1 - abs(t - 0.5) * 2)
            pts.append((x, y))
        pts += [(cx + sh * 0.8, sh_y - h * 0.3), (cx + h * 0.3, neck_y - h * 0.05), (cx - h * 0.3, neck_y - h * 0.05), (cx - sh * 0.8, sh_y - h * 0.3)]
        poly(d, pts, cloth[3])
    # Neck, head, ears, face.
    poly(d, [(cx - h * 0.15, top + h * 0.85), (cx + h * 0.15, top + h * 0.85), (cx + h * 0.17, sh_y), (cx - h * 0.17, sh_y)], skin[1])
    if kind == "dark":  # tall gorget
        poly(d, [(cx - h * 0.26, neck_y - h * 0.05), (cx + h * 0.26, neck_y - h * 0.05), (cx + h * 0.32, sh_y + h * 0.1), (cx - h * 0.32, sh_y + h * 0.1)], metal[1])
    head_w = h * (0.33 if kind != "human" else 0.36)
    chin = h * (1.0 if male else 0.95)
    if kind != "human":
        for side in (-1, 1):  # long pointed ears, swept up and back
            poly(d, [(cx + side * head_w * 0.92, top + h * 0.42), (cx + side * head_w * 2.1, top + h * 0.02), (cx + side * head_w * 0.95, top + h * 0.62)], skin[0])
    jaw = [(cx - head_w, top + h * 0.35), (cx - head_w * 0.95, top + h * 0.62),
           (cx - head_w * (0.45 if male else 0.6), top + h * 0.86), (cx, top + chin),
           (cx + head_w * (0.45 if male else 0.6), top + h * 0.86), (cx + head_w * 0.95, top + h * 0.62), (cx + head_w, top + h * 0.35)]
    d.pieslice([(cx - head_w) * SS, (top) * SS, (cx + head_w) * SS, (top + h * 0.75) * SS], 180, 360, fill=skin[0], outline=INK, width=2 * SS)
    poly(d, jaw, skin[0])
    # Hairline / fringe.
    if kind != "human":
        poly(d, [(cx - head_w * 1.05, top + h * 0.38), (cx - head_w * 0.6, top - h * 0.04), (cx + head_w * 0.6, top - h * 0.04), (cx + head_w * 1.05, top + h * 0.38), (cx + head_w * 0.2, top + h * 0.16)], hair_col)
    else:
        poly(d, [(cx - head_w * 1.02, top + h * 0.4), (cx - head_w * 0.5, top - h * 0.02), (cx + head_w * 0.5, top - h * 0.02), (cx + head_w * 1.02, top + h * 0.4), (cx, top + h * 0.18)], hair_col)
    # Brows and eyes: bold, upswept brows for elves.
    brow = 4 if kind != "human" else 2
    for side in (-1, 1):
        ex = cx + side * head_w * 0.42
        line(d, [(ex - side * head_w * 0.28, top + h * 0.47), (ex + side * head_w * 0.32, top + h * (0.4 if kind != "human" else 0.45))], INK, brow)
        eye_col = (90, 140, 120) if kind == "elf" else ((200, 190, 230) if kind == "dark" else (70, 55, 45))
        ellipse(d, (ex - head_w * 0.17, top + h * 0.5, ex + head_w * 0.17, top + h * 0.57), eye_col, width=1)
    line(d, [(cx - head_w * 0.18, top + h * 0.78), (cx + head_w * 0.18, top + h * 0.78)], (120, 70, 70) if not male else INK, 2)
    # Circlet / crown.
    if kind == "elf":
        line(d, [(cx - head_w * 0.95, top + h * 0.3), (cx, top + h * 0.22), (cx + head_w * 0.95, top + h * 0.3)], cloth[2], 3)
    elif kind == "dark" and not male:
        for k in (-1, 0, 1):
            poly(d, [(cx + k * head_w * 0.5 - h * 0.06, top + h * 0.12), (cx + k * head_w * 0.5 + h * 0.06, top + h * 0.12), (cx + k * head_w * 0.5, top - h * (0.35 if k == 0 else 0.2))], metal[1])


# --- Head studies ------------------------------------------------------------

def head_outline(cx, cy, w, up, down, taper, steps=40):
    """A head: round crown, cheeks, then a jaw drawn in to the chin.
    Higher `taper` makes a sharper chin."""
    import math
    pts = []
    for i in range(steps + 1):
        a = math.pi + math.pi * i / steps  # over the crown, left to right
        pts.append((cx + math.cos(a) * w, cy + math.sin(a) * up))
    for i in range(1, steps):
        a = math.pi * i / steps  # down the right jaw, round the chin, up the left
        s = math.sin(a)
        x = math.cos(a) * w * (1 - taper * s ** 1.6)
        pts.append((cx + x, cy + s * down))
    return pts


def head_study(d, cx, cy, s, kind, sex):
    """A bigger head and shoulders: brows, ears, chin, hair and collar."""
    male = sex == "m"
    pal = PALETTES["Elf" if kind == "elf" else "Dark elf"]
    skin, hair, metal, cloth = pal["skin"], pal["hair"], pal["metal"], pal["cloth"]
    hair_col = hair[0] if kind == "elf" else (hair[0] if male else hair[3])
    hair_shade = hair[1] if kind == "elf" else (hair[1] if male else hair[2])
    w = s * 0.3
    up, down = s * 0.42, s * (0.62 if male else 0.55)
    # Shoulders and armour collar.
    if kind == "elf":
        poly(d, [(cx - s * 0.75, cy + s * 1.0), (cx - s * 0.6, cy + s * 0.7), (cx + s * 0.6, cy + s * 0.7), (cx + s * 0.75, cy + s * 1.0)], metal[1])
        for i in range(3):
            y = cy + s * (0.72 + i * 0.09)
            line(d, [(cx - s * (0.6 + i * 0.05), y), (cx, y + s * 0.06), (cx + s * (0.6 + i * 0.05), y)], metal[3], 3)
        poly(d, [(cx - s * 0.2, cy + s * 0.55), (cx + s * 0.2, cy + s * 0.55), (cx + s * 0.26, cy + s * 0.74), (cx - s * 0.26, cy + s * 0.74)], metal[0])
    else:
        poly(d, [(cx - s * 0.75, cy + s * 1.0), (cx - s * 0.6, cy + s * 0.72), (cx + s * 0.6, cy + s * 0.72), (cx + s * 0.75, cy + s * 1.0)], metal[2])
        fur = []
        tufts = [0.6, 0.74, 0.55, 0.7, 0.5, 0.66, 0.47, 0.62, 0.45, 0.6, 0.48, 0.64, 0.52, 0.69, 0.56, 0.73, 0.6, 0.76, 0.62]
        for i, depth in enumerate(tufts):  # a ragged black fur collar, fullest at the neck
            t = i / (len(tufts) - 1)
            fur.append((cx - s * 0.8 + t * s * 1.6 + (s * 0.02 if i % 2 else 0), cy + s * depth))
        fur += [(cx + s * 0.78, cy + s * 1.0), (cx - s * 0.78, cy + s * 1.0)]
        poly(d, fur, cloth[3])
        poly(d, [(cx - s * 0.2, cy + s * 0.45), (cx + s * 0.2, cy + s * 0.45), (cx + s * 0.28, cy + s * 0.72), (cx - s * 0.28, cy + s * 0.72)], metal[1])  # high gorget
    # Neck.
    poly(d, [(cx - w * 0.45, cy + s * 0.3), (cx + w * 0.45, cy + s * 0.3), (cx + w * 0.5, cy + s * 0.62), (cx - w * 0.5, cy + s * 0.62)], skin[1])
    # Hair behind the head.
    if not male:
        poly(d, head_outline(cx, cy + s * 0.05, w * 1.35, up * 1.18, s * 1.0, -0.15), hair_col)
    else:
        poly(d, head_outline(cx, cy - s * 0.02, w * 1.18, up * 1.12, s * 0.5, 0.25), hair_col)
    # Ears: long, swept up and back, with an inner fold.
    for side in (-1, 1):
        poly(d, [(cx + side * w * 0.92, cy - s * 0.02), (cx + side * w * 2.3, cy - s * 0.55), (cx + side * w * 1.0, cy + s * 0.2)], skin[0])
        line(d, [(cx + side * w * 1.08, cy + s * 0.04), (cx + side * w * 1.85, cy - s * 0.4)], skin[2], 2)
    # Face: high cheekbones; a sharp chin for him, a soft one for her.
    poly(d, head_outline(cx, cy, w, up, down, 0.62 if male else 0.48), skin[0])
    for side in (-1, 1):
        line(d, [(cx + side * w * 0.92, cy + s * 0.14), (cx + side * w * 0.5, cy + s * 0.3)], skin[2], 3)
    # Brows: large and bold, sweeping up toward the temples.
    for side in (-1, 1):
        bx = cx + side * w * 0.42
        thick = 0.05 if male else 0.035
        poly(d, [(bx - side * w * 0.32, cy - s * 0.03), (bx + side * w * 0.5, cy - s * 0.17), (bx + side * w * 0.46, cy - s * (0.17 - thick)), (bx - side * w * 0.3, cy - s * (0.03 - thick))],
             hair_shade, outline=INK, width=1)
        # Almond eyes, a little larger and lashed for her.
        eh = s * (0.035 if male else 0.045)
        ey = cy + s * 0.05
        eye = [(bx - w * 0.24, ey), (bx - w * 0.05, ey - eh), (bx + w * 0.2, ey - eh * 0.6), (bx + w * 0.27, ey), (bx + w * 0.05, ey + eh * 0.8), (bx - w * 0.15, ey + eh * 0.6)]
        if side < 0:
            eye = [(2 * bx - x, y) for x, y in eye]
        poly(d, eye, (240, 236, 226), width=2)
        iris = (88, 150, 124) if kind == "elf" else (206, 196, 236)
        ellipse(d, (bx - eh * 0.75, ey - eh * 0.75, bx + eh * 0.75, ey + eh * 0.75), iris, width=1)
        if not male:
            for k in range(3):
                ox = bx + side * (w * 0.12 + k * w * 0.06)
                line(d, [(ox, ey - eh * 0.9), (ox + side * w * 0.05, ey - eh * 1.5)], INK, 2)
    # Nose, mouth and chin.
    line(d, [(cx - w * 0.02, cy + s * 0.08), (cx + w * 0.07, cy + s * 0.28), (cx - w * 0.07, cy + s * 0.3)], skin[2], 2)
    if male:
        line(d, [(cx - w * 0.3, cy + s * 0.42), (cx, cy + s * 0.435), (cx + w * 0.3, cy + s * 0.42)], (110, 70, 64), 3)
        line(d, [(cx - w * 0.1, cy + s * 0.56), (cx + w * 0.1, cy + s * 0.56)], skin[2], 2)  # chin shadow
    else:
        lip = (176, 92, 96) if kind == "elf" else (112, 76, 128)
        poly(d, [(cx - w * 0.3, cy + s * 0.41), (cx - w * 0.08, cy + s * 0.385), (cx, cy + s * 0.395), (cx + w * 0.08, cy + s * 0.385), (cx + w * 0.3, cy + s * 0.41), (cx, cy + s * 0.46)], lip, width=1)
    # Front of the hair: a side-swept fringe for her, swept back for him.
    if not male:
        poly(d, [(cx - w * 1.15, cy + s * 0.05), (cx - w * 1.0, cy - s * 0.32), (cx - w * 0.3, cy - s * 0.46), (cx + w * 0.6, cy - s * 0.42), (cx + w * 1.12, cy - s * 0.1),
                 (cx + w * 0.95, cy - s * 0.18), (cx + w * 0.2, cy - s * 0.28), (cx - w * 0.75, cy - s * 0.12), (cx - w * 0.95, cy + s * 0.1)], hair_col)
        for k in range(4):
            line(d, [(cx - w * (0.8 - k * 0.45), cy - s * 0.4), (cx - w * (0.6 - k * 0.5), cy - s * 0.2)], hair_shade, 2)
    else:
        poly(d, [(cx - w * 1.05, cy - s * 0.05), (cx - w * 0.85, cy - s * 0.36), (cx, cy - s * 0.47), (cx + w * 0.85, cy - s * 0.36), (cx + w * 1.05, cy - s * 0.05),
                 (cx + w * 0.9, cy - s * 0.2), (cx, cy - s * 0.33), (cx - w * 0.9, cy - s * 0.2)], hair_col)
        for k in range(5):
            line(d, [(cx - w * 0.7 + k * w * 0.35, cy - s * 0.34), (cx - w * 0.6 + k * w * 0.3, cy - s * 0.45)], hair_shade, 2)
    # Circlets.
    if kind == "elf":
        line(d, [(cx - w * 1.0, cy - s * 0.2), (cx, cy - s * 0.3), (cx + w * 1.0, cy - s * 0.2)], cloth[2], 3)
        ellipse(d, (cx - w * 0.07, cy - s * 0.35, cx + w * 0.07, cy - s * 0.26), (130, 200, 170), width=1)
    elif not male:
        for k in (-1, 0, 1):
            poly(d, [(cx + k * w * 0.5 - s * 0.03, cy - s * 0.4), (cx + k * w * 0.5 + s * 0.03, cy - s * 0.4), (cx + k * w * 0.5, cy - s * (0.68 if k == 0 else 0.56))], metal[1])


# --- Board ---------------------------------------------------------------------

def main():
    img = Image.new("RGB", (W * SS, H * SS), BG)
    d = ImageDraw.Draw(img)
    text(d, (60, 40), "Elves and dark elves", 54, display=True)
    text(d, (60, 112), "First concept board · owner direction 2026-10-20 · not final art: ChatGPT paints from this (docs/elves-concept.md)", 22, MUTED)

    # Lineup with a height scale.
    ground = 1000
    base = 560  # human height in px
    lineup = [("Human (Mara)", "human", "f", 1.0), ("Elf · man", "elf", "m", 1.12), ("Elf · woman", "elf", "f", 1.07),
              ("Dark elf · man", "dark", "m", 1.11), ("Dark elf · woman", "dark", "f", 1.06)]
    for k in range(7):
        y = ground - base * (k / 6) * 1.15
        line(d, [(60, y), (1500, y)], (44, 40, 38), 1)
    line(d, [(60, ground), (1500, ground)], (90, 80, 70), 2)
    x = 200
    for label, kind, sex, scale in lineup:
        figure(d, x, ground, base * scale, kind, sex)
        text(d, (x, ground + 26), label, 22, anchor="ma")
        text(d, (x, ground + 56), "%d%% of human height" % round(scale * 100) if kind != "human" else "reference", 18, MUTED, anchor="ma")
        x += 285

    # Head studies.
    text(d, (1560, 150), "Faces", 34, display=True)
    studies = [("Elf · man", "elf", "m"), ("Elf · woman", "elf", "f"), ("Dark elf · man", "dark", "m"), ("Dark elf · woman", "dark", "f")]
    for i, (label, kind, sex) in enumerate(studies):
        cx = 1720 + (i % 2) * 380
        cy = 360 + (i // 2) * 420
        head_study(d, cx, cy, 210, kind, sex)
        text(d, (cx, cy + 222), label, 20, anchor="ma")

    # Palettes.
    y = 1110
    text(d, (60, y), "Palettes", 34, display=True)
    y += 60
    for name in ["Elf", "Dark elf"]:
        text(d, (60, y + 8), name, 22)
        x = 200
        for group in ["skin", "hair", "metal", "cloth"]:
            text(d, (x, y - 20), group, 16, MUTED)
            for c in PALETTES[name][group]:
                d.rectangle([x * SS, y * SS, (x + 46) * SS, (y + 46) * SS], fill=c, outline=INK, width=2 * SS)
                x += 50
            x += 30
        y += 110

    # Armour notes.
    notes_x = 1100
    text(d, (notes_x, 1110), "Armour language", 34, display=True)
    notes = [
        ("Elves: silver mithril, banded and layered", [
            "Curved overlapping lames on chest, pauldrons and greaves (like a lobster tail, but slim)",
            "Leaf-shaped tassets; etched vine filigree; small gold edging only",
            "Deep green cloak and tabard; a gold circlet; light, quiet, elegant",
        ]),
        ("Dark elves: gothic black plate with black fur", [
            "Fluted, ridged black plate with pointed waists, cops and tassets",
            "Tall swept pauldrons; a heavy black fur mantle over the shoulders",
            "High gorget; crimson or violet cloth; grey-silver filigree; spired circlets",
        ]),
    ]
    y = 1170
    for title, lines in notes:
        text(d, (notes_x, y), title, 22)
        y += 34
        for s in lines:
            text(d, (notes_x + 18, y), "·  " + s, 18, MUTED)
            y += 28
        y += 18

    img = img.resize((W, H), Image.LANCZOS)
    img.save(HERE / "concept-board.png")
    print("wrote", HERE / "concept-board.png")


if __name__ == "__main__":
    main()

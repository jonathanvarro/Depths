"""Placeholder 32px glyphs for #105 (show, don't tell), in the style of the
#96 set: flat colours with a dark outline. ChatGPT will replace them.

    python art/build_visual_glyphs.py
"""
from pathlib import Path
from PIL import Image, ImageDraw

OUT = Path(__file__).parent / "ui" / "visual105-v1"
INK = (24, 18, 14, 255)
S = 32


def canvas():
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    return img, ImageDraw.Draw(img)


def outline(img):
    """Adds a 1px dark outline around everything drawn."""
    src = img.copy()
    px = src.load()
    out = img.load()
    for y in range(S):
        for x in range(S):
            if px[x, y][3] > 0:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < S and 0 <= ny < S and px[nx, ny][3] > 0 and px[nx, ny][:3] != INK[:3]:
                    out[x, y] = INK
                    break
    return img


def save(name, img):
    OUT.mkdir(parents=True, exist_ok=True)
    outline(img).save(OUT / (name + ".png"))


def rush():
    img, d = canvas()
    col = (230, 150, 60, 255)
    for ox in (4, 14):
        d.polygon([(ox, 8), (ox + 10, 16), (ox, 24), (ox + 4, 16)], fill=col)
    return img


def recover():
    img, d = canvas()
    col = (150, 180, 210, 255)
    d.ellipse((6, 16, 14, 24), fill=col)
    d.ellipse((14, 9, 21, 16), fill=col)
    d.ellipse((21, 4, 26, 9), fill=col)
    return img


def beat():
    img, d = canvas()
    d.rectangle((7, 12, 25, 24), fill=(150, 90, 50, 255))
    d.ellipse((7, 8, 25, 16), fill=(220, 200, 160, 255))
    d.line((4, 4, 13, 11), fill=(200, 170, 120, 255), width=2)
    d.line((28, 4, 19, 11), fill=(200, 170, 120, 255), width=2)
    return img


def webbed():
    img, d = canvas()
    col = (225, 225, 215, 255)
    c = (16, 16)
    for a, b in (((3, 3), (29, 29)), ((29, 3), (3, 29)), ((16, 2), (16, 30)), ((2, 16), (30, 16))):
        d.line((a, b), fill=col, width=1)
    for r in (5, 10):
        d.polygon([(c[0], c[1] - r), (c[0] + r, c[1]), (c[0], c[1] + r), (c[0] - r, c[1])], outline=col)
    return img


def venom():
    img, d = canvas()
    col = (110, 190, 70, 255)
    d.polygon([(16, 4), (24, 18), (8, 18)], fill=col)
    d.ellipse((8, 12, 24, 28), fill=col)
    d.ellipse((12, 17, 16, 21), fill=(200, 240, 160, 255))
    return img


def guard():
    img, d = canvas()
    d.polygon([(6, 5), (26, 5), (26, 16), (16, 28), (6, 16)], fill=(90, 130, 190, 255))
    d.polygon([(10, 9), (22, 9), (22, 16), (16, 23), (10, 16)], fill=(150, 185, 230, 255))
    return img


def armour():
    img, d = canvas()
    col = (160, 120, 80, 255)
    d.polygon([(6, 6), (12, 4), (16, 8), (20, 4), (26, 6), (24, 14), (24, 27), (8, 27), (8, 14)], fill=col)
    d.line((16, 9, 16, 26), fill=(110, 80, 50, 255), width=1)
    return img


def drummed():
    img, d = canvas()
    col = (220, 90, 60, 255)
    d.polygon([(16, 3), (27, 16), (20, 16), (20, 28), (12, 28), (12, 16), (5, 16)], fill=col)
    return img


def miss():
    img, d = canvas()
    d.arc((3, 6, 29, 32), 200, 340, fill=(200, 200, 200, 255), width=3)
    return img


def heart():
    img, d = canvas()
    col = (200, 50, 45, 255)
    d.ellipse((4, 6, 17, 19), fill=col)
    d.ellipse((15, 6, 28, 19), fill=col)
    d.polygon([(5, 15), (27, 15), (16, 28)], fill=col)
    d.ellipse((8, 9, 12, 13), fill=(240, 140, 130, 255))
    return img


def nerves():
    img, d = canvas()
    col = (150, 115, 200, 255)
    d.line((6, 10, 11, 6, 16, 10, 21, 6, 26, 10), fill=col, width=3)
    d.line((6, 18, 11, 14, 16, 18, 21, 14, 26, 18), fill=col, width=3)
    d.line((6, 26, 11, 22, 16, 26, 21, 22, 26, 26), fill=col, width=3)
    return img


def rest():
    img, d = canvas()
    d.line((6, 26, 26, 20), fill=(120, 80, 50, 255), width=3)
    d.line((6, 20, 26, 26), fill=(120, 80, 50, 255), width=3)
    d.polygon([(16, 4), (23, 20), (9, 20)], fill=(235, 140, 50, 255))
    d.polygon([(16, 10), (20, 20), (12, 20)], fill=(250, 220, 110, 255))
    return img


for name, fn in [("heart", heart), ("nerves", nerves), ("rest", rest), ("rush", rush), ("recover", recover), ("beat", beat), ("webbed", webbed),
                 ("venom", venom), ("guard", guard), ("armour", armour), ("drummed", drummed),
                 ("miss", miss)]:
    save(name, fn())
print("wrote", OUT)

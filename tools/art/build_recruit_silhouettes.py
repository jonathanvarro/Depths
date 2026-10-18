"""Placeholder recruit portraits (#41): one plain silhouette per role, until
ChatGPT's recruit portraits land (#82). 192 x 192 like Mara's portrait.

    python tools/art/build_recruit_silhouettes.py
"""
from pathlib import Path
from PIL import Image, ImageDraw

OUT = Path(__file__).resolve().parents[2] / "art" / "portraits" / "recruit-silhouettes-v1"
SIZE = 192
BACKGROUNDS = {"warden": (38, 44, 52), "scout": (36, 48, 38), "brawler": (56, 38, 34)}
SHAPE = (14, 13, 12)
RIM = (120, 104, 82)


def base(role):
    im = Image.new("RGB", (SIZE, SIZE), BACKGROUNDS[role])
    d = ImageDraw.Draw(im)
    for r in range(90, 0, -6):  # a soft vignette glow behind the head
        shade = tuple(min(255, c + (90 - r) // 6) for c in BACKGROUNDS[role])
        d.ellipse([96 - r, 80 - r, 96 + r, 80 + r], fill=shade)
    return im, d


def warden():
    im, d = base("warden")
    d.polygon([(30, 192), (44, 128), (96, 112), (148, 128), (162, 192)], fill=SHAPE)  # heavy cloak
    d.ellipse([66, 46, 126, 112], fill=SHAPE)  # head
    d.rectangle([60, 40, 132, 62], fill=SHAPE)  # helm brim
    d.polygon([(118, 130), (176, 130), (176, 170), (147, 192), (118, 170)], fill=(24, 26, 30), outline=RIM)  # shield
    return im


def scout():
    im, d = base("scout")
    d.polygon([(48, 192), (60, 134), (96, 120), (132, 134), (144, 192)], fill=SHAPE)  # light coat
    d.polygon([(60, 112), (96, 30), (132, 112), (118, 120), (74, 120)], fill=SHAPE)  # pointed hood
    d.ellipse([74, 62, 118, 110], fill=(22, 21, 19))  # face in shadow
    d.line([(150, 70), (126, 190)], fill=RIM, width=3)  # bow stave
    return im


def brawler():
    im, d = base("brawler")
    d.polygon([(10, 192), (26, 130), (96, 116), (166, 130), (182, 192)], fill=SHAPE)  # broad shoulders
    d.ellipse([62, 44, 130, 118], fill=SHAPE)  # big head
    d.line([(78, 66), (92, 84)], fill=RIM, width=3)  # scar
    return im


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    for name, make in [("warden", warden), ("scout", scout), ("brawler", brawler)]:
        make().save(OUT / f"{name}.png")
        print(name)


if __name__ == "__main__":
    main()

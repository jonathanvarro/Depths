"""Build distinct 192 px facial layers from approved, registered masters."""
from pathlib import Path
import sys

from PIL import Image, ImageChops, ImageDraw

sys.dont_write_bytecode = True
import build_fixer_portraits as fixer

ROOT = Path(__file__).resolve().parents[2]
REVIEW = ROOT / "art/concepts/named-cast-v1"
fixer.OUT = ROOT / "art/portraits/named-cast-v1"
fixer.DATA = ROOT / "data/portraits/named-cast-v1"
kit, components, drawings = fixer.kit, fixer.components, fixer.drawings

# Complete eye shapes and lip seams measured on the approved native pixels.
FACES = {
    "branna": (
        "branna", ((80,97,(61,61,62,63),(65,65,65,64)),
                    (107,125,(64,62,62,64),(67,67,67,66))),
        [(89,90),(95,88),(102,89),(110,89),(116,91)], (104,46)),
    "nessa": (
        "nessa", ((87,104,(60,57,57,59),(64,63,62,61)),
                   (115,131,(60,59,58,61),(64,64,63,63))),
        [(97,86),(103,85),(109,85),(117,85),(123,88)], (108,47)),
    "maelin": (
        "maelin-v3", ((79,97,(64,63,62,62),(68,68,67,65)),
                       (107,124,(62,60,60,61),(65,65,64,63))),
        [(93,92),(100,90),(108,89),(116,89),(121,89)], (103,49)),
}


def eye_curve(left, right, top, bottom):
    xs = [left, left+round((right-left)/3), right-round((right-left)/3), right]
    upper = list(zip(xs, top, strict=True))
    lower = list(zip(xs, bottom, strict=True))
    half = [(x, y + (1 if i in (0,3) else 2)) for i,(x,y) in enumerate(upper)]
    return {
        "footprint": [(x,y-2) for x,y in upper] + [(x,y+2) for x,y in lower[::-1]],
        "half": half,
        "lower": lower,
        "closed": [(x, y-1) for x,y in lower],
    }


def condition_layers(base, folder, bandage_at, lip):
    alpha = base.getchannel("A")
    reference = ROOT/"art/portraits/recruit-roster-v1/warden-b"
    for name in ("blood", "dirt", "bandage"):
        original = fixer.load(reference/(name+".png"))
        overlay = kit.blank()
        if name == "bandage":
            dressing = original.crop(original.getbbox())
            dressing.thumbnail((20,7),Image.Resampling.NEAREST)
            overlay.paste(dressing,bandage_at)
        else:
            overlay.paste(original,(0,-7))
        overlay.putalpha(ImageChops.multiply(overlay.getchannel("A"),alpha))
        fixer.save(overlay,folder/(name+".png"))

    for name in ("pallor","shadow-left","highlight-left"):
        overlay = kit.blank()
        for y in range(192):
            for x in range(192):
                r,g,b,a = base.getpixel((x,y))
                if not a:
                    continue
                if name == "pallor":
                    if 54<=x<=135 and 49<=y<=lip[2][1]+21 and r-b>20 and 1.06<r/max(1,g)<1.7:
                        overlay.putpixel((x,y),(168,178,153,65))
                else:
                    coverage = (x*.8+y*.2)/191
                    shade,amount = (0,180*coverage) if name == "shadow-left" else (255,190*(1-coverage))
                    overlay.putpixel((x,y),(shade,shade,shade,round(amount)))
        fixer.save(overlay,folder/(name+".png"))


def build(name, entry):
    source, eyes, lip, bandage = entry
    base = fixer.load(REVIEW/(source+"-192.png"))
    assert base.size == (192,192)
    folder = fixer.OUT/name
    body, head = kit.blank(), kit.blank()
    body.paste(base.crop((0,134,192,192)),(0,134))
    head.paste(base.crop((0,0,192,134)))
    fixer.save(body,folder/"body.png")
    ocular = [eye_curve(*eye) for eye in eyes]
    eye_mask = ImageChops.multiply(ImageChops.lighter(*(components.polygon(e["footprint"]) for e in ocular)),head.getchannel("A"))
    left, right = lip[0][0]-3, lip[-1][0]+3
    top, bottom = min(y for _,y in lip)-4,max(y for _,y in lip)+6
    mouth_mask = components.polygon([(left,top+2),(left+4,top),(right-4,top),(right,top+2),
                                    (right,bottom-2),(right-4,bottom),(left+4,bottom),(left,bottom-2)])
    mouth_mask = ImageChops.multiply(mouth_mask,head.getchannel("A"))
    assert not ImageChops.multiply(eye_mask,mouth_mask).getbbox()
    drawings.EYES[name] = ocular
    drawings.FACES[name] = {"lip":lip}
    palette = sorted({pixel for pixel in head.get_flattened_data() if pixel[3]})
    clean = components.clean_feature(head,eye_mask,"eyes",palette)
    clean = components.clean_feature(clean,mouth_mask,"mouth",palette)
    clean = fixer.save(clean,folder/"head-clean.png")
    layers = {"eyes-neutral":components.full_patch(head,eye_mask),
              "mouth-neutral":components.full_patch(head,mouth_mask)}
    for mode in ("half","closed"):
        art, _, _ = drawings.eyes(name,head,clean,eye_mask,mode,palette)
        layers["eyes-"+mode] = components.full_patch(art,eye_mask)
    for mode in ("small","open"):
        art, opening, _ = drawings.mouth(name,head,mouth_mask,mode,palette)
        assert opening.getbbox(), (name,mode)
        layers["mouth-"+mode] = components.full_patch(art,mouth_mask)
    for layer, art in layers.items():
        layers[layer] = fixer.save(art,folder/(layer+".png"))
        expected = eye_mask if layer.startswith("eyes-") else mouth_mask
        assert layers[layer].getchannel("A").tobytes() == expected.tobytes(), (name,layer)
    assert kit.composite([body,clean,layers["eyes-neutral"],layers["mouth-neutral"]]).tobytes() == base.tobytes()
    condition_layers(base,folder,bandage,lip)
    fixer.resource(name)
    frames = [("eyes-neutral","mouth-neutral"),("eyes-half","mouth-neutral"),
              ("eyes-closed","mouth-neutral"),("eyes-neutral","mouth-small"),
              ("eyes-neutral","mouth-open"),("eyes-closed","mouth-open")]
    return [kit.composite([body,clean,layers[eye],layers[mouth]]) for eye,mouth in frames]


def main():
    rows = [build(name, entry) for name, entry in FACES.items()]
    for size in (96,192):
        sheet = Image.new("RGBA",(size*6,(size+23)*3),"#22241f")
        draw = ImageDraw.Draw(sheet)
        for row,(name,poses) in enumerate(zip(FACES,rows,strict=True)):
            for col,(caption,im) in enumerate(zip(("Neutral","Half blink","Closed","Speak small","Speak open","Blink and speak"),poses,strict=True)):
                x,y = col*size,row*(size+23)
                draw.text((x+3,y+2),name.title() if col==0 else caption,fill="#e5d8bf")
                sheet.alpha_composite(im.resize((size,size),Image.Resampling.NEAREST),(x,y+22))
        sheet.save(REVIEW/f"animation-{size}.png")


if __name__ == "__main__":
    main()

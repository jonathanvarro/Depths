"""Export four direct-source icons with the existing item palette contract."""
from pathlib import Path
import argparse
import hashlib
import json
import sys

from PIL import Image, ImageDraw

sys.dont_write_bytecode = True
from build_field_kit_art import fitted, nonvisual

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT/"art/source/ranged-focus-v2"
OUT = ROOT/"art/items/ranged-focus-v2"
REVIEW = ROOT/"art/concepts/ranged-focus-v2"
RESOURCES = {"sling":"sling","short-bow":"short_bow","wand":"wand","oak-staff":"oak_staff"}
LABELS = {"sling":"Leather sling","short-bow":"Short bow","wand":"Prayer wand","oak-staff":"Oak staff"}


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--wire", action="store_true")
    options = parser.parse_args()
    OUT.mkdir(parents=True,exist_ok=True)
    REVIEW.mkdir(parents=True,exist_ok=True)
    (REVIEW/".gdignore").write_text("",encoding="utf-8")
    manifest = json.loads((SOURCE/"generation.json").read_text(encoding="utf-8"))
    bases_path = ROOT/"data/equipment/bases.json"
    original_bases = bases_path.read_text(encoding="utf-8")
    new_bases = original_bases
    for name,entry in manifest["assets"].items():
        source = SOURCE/entry["file"]
        digest = sha(source)
        assert entry.get("sha256",digest) == digest, name
        entry["sha256"] = digest
        master = Image.open(source).convert("RGBA")
        assert master.getchannel("A").getextrema() == (0,255), name
        for size in (128,64):
            icon,fit = fitted(master,size,64)
            output = OUT/f"{name}-{size}.png"
            icon.save(output,optimize=True)
            assert set(icon.getchannel("A").get_flattened_data()) == {0,255}
            assert icon.getbbox()[0]>=size//16 and icon.getbbox()[1]>=size//16
            assert len({p[:3] for p in icon.get_flattened_data() if p[3]})<=64
            entry[str(size)] = {"file":str(output.relative_to(ROOT)).replace("\\","/"),
                                "sha256":sha(output),"fit":fit}
        if options.wire:
            path=ROOT/"data/gear"/(RESOURCES[name]+".tres")
            before=path.read_text(encoding="utf-8")
            after=before.replace(f"res://art/items/ranged-focus-v1/{name}.png",
                                 f"res://art/items/ranged-focus-v2/{name}-128.png")
            assert f"res://art/items/ranged-focus-v2/{name}-128.png" in after, name
            assert nonvisual(before)==nonvisual(after),name
            path.write_text(after,encoding="utf-8",newline="\n")
            new_bases = new_bases.replace(f"res://art/items/ranged-focus-v1/{name}.png",
                                         f"res://art/items/ranged-focus-v2/{name}-128.png")

    if options.wire:
        original_data = json.loads(original_bases)
        new_data = json.loads(new_bases)
        for data in (original_data, new_data):
            for entry in data["bases"]:
                entry.pop("icon", None)
        assert original_data == new_data, "Equipment base rules changed"
        bases_path.write_text(new_bases,encoding="utf-8",newline="\n")

    # Native icon, compact icon, and a 40 px nearest-neighbour phone example.
    sheet = Image.new("RGB",(560,376),"#171d19")
    draw = ImageDraw.Draw(sheet)
    for col,(name,label) in enumerate(LABELS.items()):
        x=col*140
        draw.text((x+7,6),label,fill="#e1d6bf")
        for size,y in ((128,28),(64,179),(40,270)):
            icon=Image.open(OUT/f"{name}-{64 if size==40 else size}.png")
            if size==40:
                icon=icon.resize((40,40),Image.Resampling.NEAREST)
            sheet.paste(icon,(x+(140-size)//2,y),icon)
    draw.text((8,351),"128 px / 64 px / 40 px phone example",fill="#b7ad96")
    sheet.save(REVIEW/"comparison.png")
    (SOURCE/"generation.json").write_text(json.dumps(manifest,indent=2)+"\n",encoding="utf-8")
    print("Four source hashes, eight exports, hard alpha, 64-colour palettes and resource invariants passed.")


if __name__ == "__main__":
    main()

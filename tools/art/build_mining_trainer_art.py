"""Prepare mining icons and trainer art from the checked original rasters."""
import hashlib
import json
from pathlib import Path
import sys

sys.dont_write_bytecode=True
import numpy as np
from PIL import Image, ImageOps
from build_field_kit_art import fitted

ROOT=Path(__file__).resolve().parents[2]
ITEMS=ROOT/"art/items/mining-finds-v1"
CAMP=ROOT/"art/camp/skills-trainer-v1"
REVIEW=ROOT/"art/concepts/mining-trainer-v1"


def masters(folder):
    source=ROOT/"art/source"/folder
    entries=json.loads((source/"generation.json").read_text(encoding="utf-8"))["assets"]
    for entry in entries:
        path=source/entry["master"]
        assert hashlib.sha256(path.read_bytes()).hexdigest()==entry["sha256"]
        for ref in entry["reference_images"]:
            assert (ROOT/ref).is_file(),ref
        with Image.open(path) as image:
            image.verify()
        with Image.open(path) as image:
            yield entry["id"],image.convert("RGBA")


def icons():
    (ITEMS/"compact64").mkdir(parents=True,exist_ok=True)
    for name,original in masters("mining-finds-v1"):
        for size in (128,64):
            icon,_=fitted(original,size,64)
            data=np.asarray(icon)
            alpha=data[:,:,3]
            assert icon.size==(size,size)
            assert set(np.unique(alpha))=={0,255}
            assert not data[alpha==0,:3].any()
            assert len(np.unique(data[alpha>0,:3],axis=0))<=64
            left,top,right,bottom=icon.getchannel("A").getbbox()
            assert min(left,top,size-right,size-bottom)>=size//16
            dest=ITEMS if size==128 else ITEMS/"compact64"
            icon.save(dest/(name+".png"))


def remove_faint_alpha(image, threshold):
    pixels=np.array(image)
    pixels[pixels[:,:,3]<threshold]=0
    return Image.fromarray(pixels)


def trainer():
    CAMP.mkdir(parents=True,exist_ok=True)
    images=dict(masters("skills-trainer-v1"))
    portrait=images["trainer"]
    assert portrait.width==portrait.height
    portrait=remove_faint_alpha(portrait.resize((192,192),Image.Resampling.LANCZOS),18)
    assert portrait.getchannel("A").getextrema()==(0,255)
    portrait.save(CAMP/"trainer.png")
    shelter=images["shelter"]
    bounds=shelter.getchannel("A").point(lambda alpha:255 if alpha>=96 else 0).getbbox()
    assert bounds
    sprite=ImageOps.contain(shelter.crop(bounds),(500,250),Image.Resampling.LANCZOS)
    sprite=remove_faint_alpha(sprite,26)
    assert sprite.getchannel("A").getextrema()==(0,255)
    canvas=Image.new("RGBA",(512,256))
    canvas.alpha_composite(sprite,((512-sprite.width)//2,250-sprite.height))
    canvas.save(CAMP/"shelter.png")
    (CAMP/"shelter.tscn").write_text(
        '[gd_scene load_steps=2 format=3]\n'
        '[ext_resource type="Texture2D" path="res://art/camp/skills-trainer-v1/shelter.png" id="1"]\n'
        '[node name="SkillsTrainerShelter" type="Node2D"]\ntexture_filter = 2\n'
        '[node name="Base" type="Sprite2D" parent="."]\ncentered = false\n'
        'position = Vector2(-92.16, -90)\nscale = Vector2(0.36, 0.36)\n'
        'texture = ExtResource("1")\nlight_mask = 2\n',encoding="utf-8")


def gallery():
    REVIEW.mkdir(parents=True,exist_ok=True)
    (REVIEW/".gdignore").touch()
    page='''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Depths · Mining finds and camp trainer</title>
<style>
:root{background:#151a18;color:#e2d7bf;font:16px system-ui}body{margin:auto;max-width:880px;padding:18px}
h1,h2{font-family:Georgia,serif}section{display:flex;gap:12px;flex-wrap:wrap}
figure{margin:0;display:grid;align-content:center;justify-items:center;background:#262d27;border:1px solid #59533d;padding:10px;max-width:100%;box-sizing:border-box}
img{display:block;max-width:100%;height:auto;object-fit:contain;image-rendering:pixelated}figcaption{margin-top:8px}a{color:#dabb84}
</style><h1>Mining finds and camp trainer</h1><h2>Inventory at 40 px</h2><section>
<figure><img src="../../items/mining-finds-v1/compact64/mattock.png" width="40" alt=""><figcaption>Mattock</figcaption></figure>
<figure><img src="../../items/regional-equipment-v1/compact64/miners_sledge.png" width="40" alt=""><figcaption>Miner’s sledge</figcaption></figure>
<figure><img src="../../items/mining-finds-v1/compact64/coal.png" width="40" alt=""><figcaption>Coal</figcaption></figure>
<figure><img src="../../items/salvage-v1/black-ore.png" width="40" alt=""><figcaption>Black ore</figcaption></figure>
</section><h2>Camp skills trainer</h2><section>
<figure><img src="../../camp/skills-trainer-v1/trainer.png" width="192" alt="Grey-haired veteran in a patched vest"><figcaption>Dialogue portrait</figcaption></figure>
<figure><img src="../../camp/skills-trainer-v1/shelter.png" width="330" alt="Canvas shelter with straw post and bench"><figcaption>Training shelter</figcaption></figure>
</section><p><a href="../../../docs/mining-finds-and-trainer-art.md">Handoff and asset paths</a></p></html>'''
    (REVIEW/"inspector.html").write_text(page,encoding="utf-8")


if __name__=="__main__":
    icons()
    trainer()
    gallery()
    print("Mining icon registration and trainer cutouts verified.")

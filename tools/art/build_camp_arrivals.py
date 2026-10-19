"""Export the unloading wagon against the existing camp palette/registration."""
from pathlib import Path
from PIL import Image
import hashlib,json
from build_layered_camp import register
from build_treasure_art import palette,quantize

ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'art/camp/arrivals-v1'
SOURCE=ROOT/'art/source/camp-arrivals-v1'
REVIEW=ROOT/'art/concepts/camp-arrivals-v1'

def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()

def main():
    OUT.mkdir(parents=True,exist_ok=True);REVIEW.mkdir(parents=True,exist_ok=True)
    (REVIEW/'.gdignore').touch()
    master=Image.open(SOURCE/'caravan-unloading.png').convert('RGBA')
    im,pos,registration=register(master,[53,95,245,116])
    terrain=Image.open(ROOT/'art/camp/organic-v3/terrain.png').convert('RGBA')
    raw_alpha=im.getchannel('A');im=quantize(im,palette([terrain],64))
    im.putalpha(raw_alpha.point(lambda a:255 if a>=224 else 0))
    path=OUT/'caravan-unloading.png';im.save(path)
    assert set(im.getchannel('A').get_flattened_data())<={0,255}
    allowed={p[:3] for p in terrain.get_flattened_data()}
    assert all(p[:3] in allowed for p in im.get_flattened_data() if p[3])
    scene='[gd_scene load_steps=2 format=3]\n[ext_resource type="Texture2D" path="res://art/camp/arrivals-v1/caravan-unloading.png" id="texture"]\n\n[node name="Unloading" type="Sprite2D"]\nposition = Vector2('+str(pos[0])+', '+str(pos[1])+')\ncentered = false\ntexture = ExtResource("texture")\ntexture_filter = 1\nlight_mask = 2\nvisible = false\n'
    (OUT/'caravan-unloading.tscn').write_text(scene,encoding='utf-8',newline='\n')
    report={'issue':80,'bounds':[53,95,245,116],'registration':registration,
        'master_sha256':sha(SOURCE/'caravan-unloading.png'),'export_sha256':sha(path),
        'palette':'Existing organic-v3 terrain colours only; no original artwork changed',
        'alpha':'Binary, threshold 224','new_game':'tent/fire/nurse, unloading merchant, no smith; cave remains',
        'triggers':'First post-tutorial return opens trading; first rest brings smith'}
    (REVIEW/'export-validation.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8',newline='\n')
    print('PASS: registered unloading wagon, transparent alpha and exact existing camp palette.')

if __name__=='__main__':main()

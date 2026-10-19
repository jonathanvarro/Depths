"""Export independently registered camp layers; no story schedule is authored."""
from pathlib import Path
from PIL import Image
import hashlib,json
from build_treasure_art import mask,palette,quantize

ROOT=Path(__file__).resolve().parents[2]
SOURCE=ROOT/'art/source/camp-layered-v3'
OUT=ROOT/'art/camp/organic-v3'
REVIEW=ROOT/'art/concepts/camp-layered-v3'
SITES=[
 {'id':'treatment','label':'Nurse','npc':'nurse','bounds':[184,48,188,77],'rect':[178,40,192,80]},
 {'id':'cave','label':'Cave path','npc':'','source':'cave-post','bounds':[508,33,27,70],'rect':[485,24,146,106],'lights':[[529,74,.32,.58,2,4]]},
 {'id':'supplies','label':'Merchant','npc':'merchant','bounds':[53,95,245,116],'rect':[45,120,245,89],'lights':[[103,158,.30,.62,2,4]]},
 {'id':'smith','label':'Apprentice smith','npc':'apprentice','bounds':[443,129,189,122],'rect':[466,133,166,122],'lights':[[575,214,.33,.82,6,1]]},
 {'id':'rest','label':'Your tent','npc':'','bounds':[26,200,192,112],'rect':[24,214,198,101],'lights':[[157,249,.30,.55,2,4]]},
 {'id':'fire','label':'Recruitment fire','npc':'','source':'fire-corrected','bounds':[303,190,191,91],'rect':[294,197,160,92]},
]

def write(path,text):
    path.parent.mkdir(parents=True,exist_ok=True);path.write_text(text,encoding='utf-8',newline='\n')
def uri(path):return 'res://'+path.relative_to(ROOT).as_posix()
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def load(name):return Image.open(SOURCE/(name+'.png')).convert('RGBA')

def register(im,box):
    assert im.getchannel('A').getextrema()[0]==0,'Cutouts must be genuinely transparent'
    crop=im.crop(mask(im).getbbox())
    scale=min(box[2]/crop.width,box[3]/crop.height)
    crop=crop.resize((max(1,round(crop.width*scale)),max(1,round(crop.height*scale))),Image.Resampling.NEAREST)
    x=box[0]+(box[2]-crop.width)//2;y=box[1]+box[3]-crop.height
    output=Image.new('RGBA',(crop.width+4,crop.height+4));output.paste(crop,(2,2))
    return output,[x-2,y-2],{'source_bounds':mask(im).getbbox(),'scale':scale,'position':[x-2,y-2],'canvas':list(output.size)}

def site_scene(site,pos):
    id=site['id']
    ext='[ext_resource type="Script" path="res://art/camp/organic-v3/site.gd" id="script"]\n'
    ext+='[ext_resource type="Texture2D" path="'+uri(OUT/(id+'.png'))+'" id="texture"]\n'
    count=3
    extra=''
    if site.get('lights'):
        ext+='[ext_resource type="Script" path="res://art/camp/organic-v3/warm_light.gd" id="light"]\n';count+=1
        for i,(x,y,energy,scale,w,h) in enumerate(site['lights']):
            extra+='[node name="Lantern'+str(i)+'" type="PointLight2D" parent="."]\nscript = ExtResource("light")\nposition = Vector2('+str(x)+', '+str(y)+')\nbase_energy = '+str(energy)+'\ntexture_scale = '+str(scale)+'\nphase = '+str(.7+SITES.index(site)*1.9)+'\ncore_size = Vector2('+str(w)+', '+str(h)+')\n'
    if id=='treatment':
        ext+='[ext_resource type="Texture2D" path="'+uri(OUT/'occupied-cot.png')+'" id="cot"]\n';count+=1
        extra+='[node name="OccupiedCot" type="Sprite2D" parent="."]\nposition = Vector2(245, 84)\ncentered = false\ntexture = ExtResource("cot")\nlight_mask = 2\nvisible = false\n'
    if id=='cave':
        ext+='[ext_resource type="Texture2D" path="'+uri(OUT/'notice.png')+'" id="notice"]\n';count+=1
        extra+='[node name="Notice" type="Sprite2D" parent="."]\nposition = Vector2(517, 65)\ncentered = false\ntexture = ExtResource("notice")\nlight_mask = 2\nvisible = false\n'
    if id=='fire':
        ext+='[ext_resource type="SpriteFrames" path="res://art/features/campfire-v1/frames.tres" id="flames"]\n';count+=1
        extra+='[node name="FlameAnchor" type="Node2D" parent="."]\nposition = Vector2(399, 248)\nscale = Vector2(0.34, 0.34)\n[node name="Flames" type="AnimatedSprite2D" parent="FlameAnchor"]\nposition = Vector2(-64, -102)\ncentered = false\nsprite_frames = ExtResource("flames")\nanimation = &"burn"\nlight_mask = 1\n'
    scene='[gd_scene load_steps='+str(count)+' format=3]\n'+ext+'\n[node name="'+id+'" type="Node2D"]\nscript = ExtResource("script")\ntexture_filter = 1\n'
    scene+='[node name="Base" type="Sprite2D" parent="."]\nposition = Vector2('+str(pos[0])+', '+str(pos[1])+')\ncentered = false\ntexture = ExtResource("texture")\nlight_mask = 2\n'+extra
    write(OUT/(id+'.tscn'),scene)

def main():
    for folder in [SOURCE,REVIEW]:write(folder/'.gdignore','')
    terrain=load('terrain').convert('RGB').resize((640,360),Image.Resampling.NEAREST).convert('RGBA')
    layers={};positions={};registration={}
    for site in SITES:
        id=site['id'];layers[id],positions[id],registration[id]=register(load(site.get('source',id)),site['bounds'])
    cot,_,registration['occupied-cot']=register(load('occupied-cot'),[0,0,43,24])
    # Reuse the authored paper region; this is a small registered crop export.
    notice=Image.open(ROOT/'art/camp/cave-camp-variants-v1/contract-notice-patch.png').convert('RGBA').crop((68,99,82,123)).resize((8,14),Image.Resampling.NEAREST)
    layers['occupied-cot']=cot;layers['notice']=notice
    pal=palette([terrain]+list(layers.values()),64)
    terrain=quantize(terrain,pal);terrain.putalpha(255);terrain.save(OUT/'terrain.png')
    for id,im in layers.items():
        raw_alpha=im.getchannel('A')
        im=quantize(im,pal)
        # Crisp pixel cutouts drop soft extraction halos; opaque structure stays.
        im.putalpha(raw_alpha.point(lambda a:255 if a>=224 else 0))
        im.save(OUT/(id+'.png'));layers[id]=im
    for site in SITES:site_scene(site,positions[site['id']])
    layout={'canvas':[640,360],'sites':SITES,'registration':registration,'story':'No arrival schedule. Missing site_presence keys default to present.'}
    write(OUT/'layout.json',json.dumps(layout,indent=2)+'\n')
    composite=terrain.copy()
    for site in SITES:composite.alpha_composite(layers[site['id']],tuple(positions[site['id']]))
    composite.convert('RGB').save(REVIEW/'assembled-unlit.png')
    terrain.convert('RGB').save(REVIEW/'terrain-only.png')
    report={'issue':108,'source_masters':9,'native_canvas':[640,360],'shared_palette_limit':64,'cutout_alpha_threshold':224,
      'registration':registration,'sha256':{p.relative_to(ROOT).as_posix():sha(p) for p in OUT.glob('*.png')},
      'source_sha256':{p.name:sha(p) for p in SOURCE.glob('*.png')}}
    write(REVIEW/'export-validation.json',json.dumps(report,indent=2)+'\n')
    print('Exported terrain, six independent sites, recovery/notice layers and registered scenes.')

if __name__=='__main__':main()

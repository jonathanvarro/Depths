"""Small original pixel cloud/light-pop FX, independent of combat outcomes."""
from pathlib import Path
from PIL import Image,ImageDraw
import json,math
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'art/effects/monsters-v1'
def uri(p):return 'res://'+p.relative_to(ROOT).as_posix()
def write(p,s):p.write_text(s,encoding='utf-8',newline='\n')
def frames(id,images,speed):
    w,h=images[0].size;atlas=Image.new('RGBA',(w*len(images),h))
    for i,im in enumerate(images):atlas.paste(im,(w*i,0))
    atlas.save(OUT/(id+'.png'))
    text='[gd_resource type="SpriteFrames" load_steps='+str(len(images)+2)+' format=3]\n[ext_resource type="Texture2D" path="'+uri(OUT/(id+'.png'))+'" id="sheet"]\n'
    for i in range(len(images)):text+='\n[sub_resource type="AtlasTexture" id="f'+str(i)+'"]\natlas = ExtResource("sheet")\nregion = Rect2('+str(i*w)+', 0, '+str(w)+', '+str(h)+')\n'
    text+='\n[resource]\nanimations = [{"frames":['+','.join('{"duration":1.0,"texture":SubResource("f'+str(i)+'")}' for i in range(len(images)))+'],"loop":false,"name":&"once","speed":'+str(float(speed))+'}]\n'
    write(OUT/(id+'.tres'),text)
    return {'id':id,'texture':uri(OUT/(id+'.png')),'frames':uri(OUT/(id+'.tres')),'frame_count':len(images),'frame_size':[w,h],'fps':speed,'animation':'once'}
def main():
    OUT.mkdir(parents=True,exist_ok=True)
    # Author on a 64px pixel grid, enlarge by nearest; broad irregular lobes.
    clouds=[]
    clusters=[(-14,2,10),(-6,-9,12),(8,-8,10),(16,3,9),(7,12,10),(-8,10,9),(0,2,13)]
    for i in range(4):
        im=Image.new('RGBA',(64,64));d=ImageDraw.Draw(im)
        for j,(dx,dy,r) in enumerate(clusters):
            spread=.50+i*.24;cx=32+dx*spread;cy=32+dy*spread-i*2
            rr=r*(.70+i*.18);alpha=[128,104,64,0][i]
            d.ellipse((round(cx-rr),round(cy-rr),round(cx+rr),round(cy+rr)),fill=(78,89,59,alpha))
            d.ellipse((round(cx-rr*.8),round(cy-rr*.9),round(cx+rr*.6),round(cy+rr*.5)),fill=(119,130,76,alpha))
            d.ellipse((round(cx-rr*.55),round(cy-rr*.6),round(cx),round(cy)),fill=(153,157,91,round(alpha*.8)))
        if i==3:im=Image.new('RGBA',(64,64))
        clouds.append(im.resize((128,128),Image.Resampling.NEAREST))
    effects=[frames('gas-burst',clouds,8)]
    haze=Image.new('RGBA',(64,16));d=ImageDraw.Draw(haze)
    for x,y,r in [(4,9,8),(17,6,9),(31,10,10),(45,7,10),(60,10,8)]:d.ellipse((x-r,y-r//2,x+r,y+r//2),fill=(137,147,86,34))
    haze.resize((256,64),Image.Resampling.NEAREST).save(OUT/'gas-haze.png')
    effects.append({'id':'gas-haze','texture':uri(OUT/'gas-haze.png'),'frame_size':[256,64],'frame_count':1,'opacity':'Authored faint alpha34/255; controller owns duration/placement.'})
    icon=Image.open(ROOT/'art/ui/monsters-v1/fx/light-drained.png').convert('RGBA');pop=[]
    for i in range(6):
        im=Image.new('RGBA',(40,48))
        if i<5:
            im.alpha_composite(icon,(4,14-i*2));im.putalpha(im.getchannel('A').point(lambda a:round(a*(1-i/5))))
        pop.append(im)
    effects.append(frames('light-drained',pop,10))
    write(OUT/'catalog.json',json.dumps({'issue':141,'authoring':'Original native pixel cloud shapes and registered native SVG light mark; tools/art/build_monster_effects.py.','blend':'Normal alpha, nearest, no emission light, no additive white flash.','integration':'Presentation only. Combat decides when/where; art spends no oil/time and applies no status. Respect existing screen-flashes/settings policy.','effects':effects},indent=2)+'\n')
    print('MONSTER_FX: four-frame gas burst, static lingering haze, six-frame light-drained pop')
if __name__=='__main__':main()

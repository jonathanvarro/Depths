"""#166 wet-wall siblings and independently mounted waterworks dressing.
Preserves ImageGen masters; only resampling, periodic apron and palette export.
"""
from pathlib import Path
from PIL import Image, ImageDraw
import json, hashlib, numpy as np
ROOT=Path(__file__).resolve().parents[2]
SRC=ROOT/'art/source/waterworks-v1';TEX=ROOT/'art/textures/waterworks-v1'
PROP=ROOT/'art/dressing/waterworks-v1';REVIEW=ROOT/'art/concepts/waterworks-v1'
WALLS=['wet-plain','wet-channelled'];PROPS=['dripping-channel','broken-pipe','silted-lamp']
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def write(p,s):p.write_text(s,encoding='utf-8',newline='\n')
def uri(p):return 'res://'+p.relative_to(ROOT).as_posix()
def main():
 for p in [TEX,PROP,REVIEW]:p.mkdir(parents=True,exist_ok=True)
 prompts=json.loads((SRC/'prompts.json').read_text());manifest={'issue':166,'tool':prompts['tool'],'sources':{},'outputs':{},'reference_sha256':sha(ROOT/'art/textures/descent-walls-v1/drowned-masonry.png')}
 images={}
 for id in WALLS+PROPS:
  source=SRC/(id+'-master.png');original=Path(prompts['original_directory'])/prompts['original_filenames'][id]
  if original.exists():assert source.read_bytes()==original.read_bytes()
  im=Image.open(source).convert('RGBA')
  manifest['sources'][id]={'sha256':sha(source),'size':im.size,'original_path':str(original)}
  im=im.resize((128,128),Image.Resampling.BOX)
  if id in WALLS:
   a=np.asarray(im.convert('RGB'),dtype=float).copy()
   for axis in [0,1]:
    v=np.swapaxes(a,0,axis)
    for i in range(8):
     left=v[i].copy();right=v[-i-1].copy();mean=(left+right)/2;weight=(1-i/8)**2
     v[i]=left*(1-weight)+mean*weight;v[-i-1]=right*(1-weight)+mean*weight
   im=Image.fromarray(np.uint8(np.clip(np.rint(a),0,255))).quantize(colors=32,dither=Image.Dither.NONE).convert('RGB')
   folder=TEX
   write(TEX/(id+'.tres'),'''[gd_resource type="StandardMaterial3D" load_steps=2 format=3]
[ext_resource type="Texture2D" path="res://art/textures/waterworks-v1/ID.png" id="texture"]
[resource]
texture_filter = 0
albedo_texture = ExtResource("texture")
metallic_specular = 0.28
roughness = 0.82
'''.replace('ID',id))
   tile=Image.new('RGB',(384,384))
   for y in range(3):
    for x in range(3):tile.paste(im,(x*128,y*128))
   tile.save(REVIEW/(id+'-tiled.png'))
  else:
   alpha=im.getchannel('A').point(lambda a:255 if a>=128 else 0)
   # Palette uses visible source pixels only; transparent matte never contaminates it.
   visible=[p[:3] for p,a in zip(im.get_flattened_data(),alpha.get_flattened_data()) if a]
   strip=Image.new('RGB',(len(visible),1));strip.putdata(visible)
   pal=strip.quantize(colors=32,dither=Image.Dither.NONE)
   im=im.convert('RGB').quantize(palette=pal,dither=Image.Dither.NONE).convert('RGBA');im.putalpha(alpha)
   im.putdata([p if p[3] else (0,0,0,0) for p in im.get_flattened_data()]);folder=PROP
   width={'dripping-channel':1.8,'broken-pipe':0.8,'silted-lamp':0.65}[id];pixel=width/128
   bottom=im.getbbox()[3];y=(bottom-64)*pixel+0.008 if id=='silted-lamp' else 0
   write(PROP/(id+'.tscn'),'''[gd_scene load_steps=2 format=3]
[ext_resource type="Texture2D" path="res://art/dressing/waterworks-v1/ID.png" id="texture"]
[node name="ID" type="Node3D"]
metadata/art_issue = 166
metadata/mount = "MOUNT"
[node name="Sprite" type="Sprite3D" parent="."]
position = Vector3(0, HEIGHT, 0)
pixel_size = PIXEL
billboard = 0
shaded = true
texture_filter = 0
alpha_cut = 1
alpha_scissor_threshold = 0.5
cast_shadow = 0
texture = ExtResource("texture")
'''.replace('ID',id).replace('MOUNT','floor' if id=='silted-lamp' else 'wall-centre').replace('HEIGHT',str(y)).replace('PIXEL',str(pixel)))
  target=folder/(id+'.png');im.save(target);images[id]=im.convert('RGBA')
  manifest['outputs'][id]={'path':uri(target),'sha256':sha(target),'canvas':[128,128],'palette':len({p[:3] for p in im.convert('RGBA').get_flattened_data() if p[3]}),'bounds':im.getbbox()}
 catalog={'issue':166,'walls':{id:uri(TEX/(id+'.tres')) for id in WALLS},'props':{id:{'scene':uri(PROP/(id+'.tscn')),'mount':'floor' if id=='silted-lamp' else 'wall-centre','canvas_metres':{'dripping-channel':1.8,'broken-pipe':0.8,'silted-lamp':0.65}[id]} for id in PROPS},'integration':'Standalone library: no live theme or placement changes. Static drips, no emission, particles, collision or gameplay.'}
 write(TEX/'catalog.json',json.dumps(catalog,indent=2)+'\n');write(SRC/'generation.json',json.dumps(manifest,indent=2)+'\n')
 board=Image.new('RGB',(800,370),'#242d2d');d=ImageDraw.Draw(board)
 for i,id in enumerate(WALLS+PROPS):
  im=images[id];board.paste(im,(i*160+16,34),im);d.text((i*160+8,10),id,fill='#dfd1b5')
  small=im.resize((64,64),Image.Resampling.NEAREST);board.paste(small,(i*160+48,190),small)
 board.save(REVIEW/'overview.png')
 write(REVIEW/'assets.json',json.dumps({'catalog':catalog,'images':{id:uri((TEX if id in WALLS else PROP)/(id+'.png')) for id in WALLS+PROPS}},indent=2)+'\n')
 print('Five native128 assets exported; original walls, water, themes and dressing untouched.')
if __name__=='__main__':main()

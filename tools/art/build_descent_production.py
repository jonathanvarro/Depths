"""#166/#168: preserve old hound; add complete sibling families and stonework."""
from pathlib import Path
from PIL import Image,ImageDraw
import json,hashlib,shutil,base64
import numpy as np
ROOT=Path(__file__).resolve().parents[2];SRC=ROOT/'art/source/descent-production-v1';REVIEW=ROOT/'art/concepts/descent-production-v1'
HOUND=ROOT/'art/enemies/underhound-v2';PACK=ROOT/'art/enemies/borrowed-pack-v1';STONE=ROOT/'art/props/ancient-stonework-v1'
def write(p,s):p.write_text(s,encoding='utf-8',newline='\n')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def uri(p):return 'res://'+p.relative_to(ROOT).as_posix()
def hard(im):
 im=im.convert('RGBA');im.putalpha(im.getchannel('A').point(lambda a:255 if a>=128 else 0));return im
def quantize(im,pal):
 result=im.convert('RGB').quantize(palette=pal,dither=Image.Dither.NONE).convert('RGBA');result.putalpha(im.getchannel('A'))
 result.putdata([p if p[3] else (0,0,0,0) for p in result.get_flattened_data()]);return result
def common(raw,window):
 raw=hard(raw);pad=160;padded=Image.new('RGBA',(raw.width+pad*2,raw.height+pad*2));padded.paste(raw,(pad,pad))
 return hard(padded.resize((128,128),Image.Resampling.BOX,box=tuple(v+pad for v in window)))
def family(out,images,pixel,manifest):
 names=list(images);paths=[]
 for name,im in images.items():
  p=out/(name+'.png')
  if not p.exists() or Image.open(p).convert('RGBA').tobytes()!=im.tobytes():im.save(p)
  paths.append(uri(p));manifest[name]={'sha256':sha(p),'bounds':im.getbbox()}
 ext='\n'.join('[ext_resource type="Texture2D" path="'+path+'" id="'+name+'"]' for name,path in zip(names,paths))
 animations=',\n'.join('{"frames":[{"duration":1.0,"texture":ExtResource("'+n+'")}],"loop":'+('true' if n=='idle' else 'false')+',"name":&"'+n+'","speed":8.0}' for n in names)
 write(out/'frames.tres',f'[gd_resource type="SpriteFrames" load_steps={len(names)+1} format=3]\n'+ext+'\n[resource]\nanimations = ['+animations+']\n')
 tops=', '.join('"'+n+'": ['+str(im.getbbox()[1])+']' for n,im in images.items())
 write(out/'scene.tscn',f'''[gd_scene load_steps=3 format=3]
[ext_resource type="SpriteFrames" path="{uri(out/'frames.tres')}" id="frames"]
[ext_resource type="Script" path="res://art/enemies/underhound-v1/mount.gd" id="mount"]
[node name="DescentCreature" type="Node3D"]
script = ExtResource("mount")
pose_tops = {{{tops}}}
metadata/pivot = Vector2(64,120)
metadata/art_issue = 166
[node name="Sprite" type="AnimatedSprite3D" parent="."]
position = Vector3(0,{56*pixel},0)
pixel_size = {pixel}
billboard = 1
shaded = true
texture_filter = 0
alpha_cut = 1
alpha_scissor_threshold = 0.5
cast_shadow = 0
sprite_frames = ExtResource("frames")
animation = &"idle"
''')
def main():
 for p in [HOUND,PACK,STONE,REVIEW]:p.mkdir(parents=True,exist_ok=True)
 manifest={'issues':[166,168],'tool':'Built-in ImageGen','sources':{},'outputs':{},'preserved':{}}
 for p in SRC.glob('*master.png'):manifest['sources'][p.name]={'sha256':sha(p),'size':Image.open(p).size}
 for name in ['idle','attack','hurt']:
  p=ROOT/'art/enemies/underhound-v1'/f'{name}.png';manifest['preserved'][uri(p)]=sha(p)
 approved=json.loads((ROOT/'art/enemies/underhound-v1/approval.json').read_text(encoding='utf-8'))
 assert sha(ROOT/'art/enemies/underhound-v1/idle.png')==approved['native_png_sha256']
 assert sha(ROOT/'art/enemies/underhound-v1/hurt.png')==approved['hurt']['native_png_sha256']
 rgb=json.loads((ROOT/'art/enemies/underhound-v1/palette.json').read_text())['rgb'];pal=Image.new('P',(1,1));pal.putpalette([v for c in rgb+[rgb[-1]]*(256-len(rgb)) for v in c])
 sx,sy=112/1170,89/932;tx,ty=8-59*sx,32-236*sy;window=(-tx/sx,-ty/sy,(128-tx)/sx,(128-ty)/sy)
 hound={n:Image.open(ROOT/'art/enemies/underhound-v1'/f'{n}.png').convert('RGBA') for n in ['idle','attack','hurt']}
 for name in ['windup','lunge','defeated']:
  suffix='-registered' if name=='defeated' else ''
  raw=Image.open(SRC/f'underhound-{name}{suffix}-master.png');assert raw.size==(1254,1254)
  hound[name]=quantize(common(raw,window),pal)
 manifest['hound_registration']={'source_window':window,'per_pose_fit':False,'pivot':[64,120],'defeated_source':'underhound-defeated-registered-master.png','note':'ImageGen registration edit retained separately; source gesture has small below-pivot settling.'}
 family(HOUND,hound,0.8/89,manifest['outputs'].setdefault('underhound',{}))
 # One complete-source transform determined from idle; never fit another pose.
 raw_idle=hard(Image.open(SRC/'borrowed-pack-idle-master.png'));bottom=raw_idle.getbbox()[3]-1
 scale=120/1254;tx=4;ty=120-bottom*scale;window=(-tx/scale,-ty/scale,(128-tx)/scale,(128-ty)/scale)
 pack={}
 for name in ['idle','attack','hurt','off-balance','defeated']:
  suffix='-registered' if name=='defeated' else ''
  raw=Image.open(SRC/f'borrowed-pack-{name}{suffix}-master.png');assert raw.size==(1254,1254)
  pack[name]=common(raw,window)
 visible=[p[:3] for im in pack.values() for p in im.get_flattened_data() if p[3]];strip=Image.new('RGB',(len(visible),1));strip.putdata(visible);pal=strip.quantize(colors=32,dither=Image.Dither.NONE)
 pack={n:quantize(im,pal) for n,im in pack.items()}
 manifest['pack_registration']={'source_window':window,'scale':scale,'translate':[tx,ty],'per_pose_fit':False,'pivot':[64,120]}
 family(PACK,pack,0.95/(120-pack['hurt'].getbbox()[1]),manifest['outputs'].setdefault('borrowed-pack',{}))
 # Complete portrait-shaped source contained in a square, preserving aspect.
 raw=Image.open(SRC/'stonework-master.png').convert('RGBA');raw.thumbnail((176,176),Image.Resampling.BOX)
 stone=Image.new('RGBA',(192,192));stone.paste(raw,((192-raw.width)//2,8));stone=hard(stone)
 visible=[p[:3] for p in stone.get_flattened_data() if p[3]];strip=Image.new('RGB',(len(visible),1));strip.putdata(visible);stone=quantize(stone,strip.quantize(colors=48,dither=Image.Dither.NONE));stone.save(STONE/'stone.png')
 mask=Image.new('RGBA',(192,192));mask.putdata([(160,194,209,160) if a and b>r*1.10 and b>g*1.04 and b>45 else (0,0,0,0) for r,g,b,a in stone.get_flattened_data()]);mask.save(STONE/'pulse.png')
 manifest['outputs']['stone']={'sha256':sha(STONE/'stone.png'),'bounds':stone.getbbox(),'pulse_pixels':sum(p[3]>0 for p in mask.get_flattened_data())}
 pixel=1.75/(stone.getbbox()[3]-stone.getbbox()[1]);origin=(stone.getbbox()[3]-96)*pixel+0.02
 write(STONE/'scene.tscn',f'''[gd_scene load_steps=4 format=3]
[ext_resource type="Script" path="res://art/props/ancient-stonework-v1/pulse.gd" id="script"]
[ext_resource type="Texture2D" path="res://art/props/ancient-stonework-v1/stone.png" id="stone"]
[ext_resource type="Texture2D" path="res://art/props/ancient-stonework-v1/pulse.png" id="pulse"]
[node name="AncientStonework" type="Node3D"]
script = ExtResource("script")
metadata/art_issue = 168
[node name="Stone" type="Sprite3D" parent="."]
position = Vector3(0,{origin},0)
pixel_size = {pixel}
shaded = true
texture_filter = 0
alpha_cut = 1
alpha_scissor_threshold = 0.5
cast_shadow = 0
texture = ExtResource("stone")
[node name="Pulse" type="Sprite3D" parent="."]
position = Vector3(0,{origin},0.002)
pixel_size = {pixel}
shaded = false
texture_filter = 0
cast_shadow = 0
modulate = Color(1,1,1,0.04)
texture = ExtResource("pulse")
''')
 write(SRC/'generation.json',json.dumps(manifest,indent=2)+'\n')
 catalog={'issues':[166,168],'families':{'underhound':{'scene':uri(HOUND/'scene.tscn'),'poses':list(hound)},'borrowed-pack':{'scene':uri(PACK/'scene.tscn'),'poses':list(pack)}},'stone':uri(STONE/'scene.tscn'),'status':'Library ready for review/hookup; original scenes, definitions and rules unchanged.'}
 write(REVIEW/'catalog.json',json.dumps(catalog,indent=2)+'\n')
 for id,images in [('underhound',hound),('borrowed-pack',pack)]:
  board=Image.new('RGB',(len(images)*160,280),'#28312b');d=ImageDraw.Draw(board)
  for i,(name,im) in enumerate(images.items()):
   d.text((i*160+8,10),name,fill='#dfd3b8');board.paste(im,(i*160+16,35),im)
   small=im.resize((64,64),Image.Resampling.NEAREST);board.paste(small,(i*160+48,190),small)
  board.save(REVIEW/f'{id}-poses.png')
 assets={uri(p):'data:image/png;base64,'+base64.b64encode(p.read_bytes()).decode() for folder in [HOUND,PACK,STONE] for p in folder.glob('*.png')}
 captures=[]
 for name in ['stone-validation.json','underhound-validation.json','borrowed-pack-validation.json']:
  if (REVIEW/name).exists():captures+=json.loads((REVIEW/name).read_text(encoding='utf-8')).get('captures',[])
 if (REVIEW/'layout.html').exists():write(REVIEW/'inspector.html',(REVIEW/'layout.html').read_text(encoding='utf-8').replace('@@data@@',json.dumps({'catalog':catalog,'assets':assets})).replace('@@captures@@',json.dumps(captures)))
 print('Two complete native128 families and separate native192 stone/pulse exported; approved hound unchanged.')
if __name__=='__main__':main()

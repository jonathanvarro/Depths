"""#166/#168: fixed-family sprite export and registered flow gate."""
from pathlib import Path
from PIL import Image,ImageDraw
import json,base64,sys
sys.dont_write_bytecode=True
from build_descent_production import hard,quantize,sha,uri,write
ROOT=Path(__file__).resolve().parents[2];SRC=ROOT/'art/source/shepherd-gate-v1';REVIEW=ROOT/'art/concepts/shepherd-gate-v1'
BOSS=ROOT/'art/enemies/marrow-shepherd-v1';HOUND=ROOT/'art/enemies/unfinished-hound-v1';GATE=ROOT/'art/props/reservoir-flow-gate-v1'
POSES={'shepherd':['idle','tending','birthing','attack','hurt','defeated'],'hound':['idle','attack','hurt']}
def resize(raw,n,window):
 raw=hard(raw);pad=256;padded=Image.new('RGBA',(raw.width+512,raw.height+512));padded.paste(raw,(pad,pad))
 return hard(padded.resize((n,n),Image.Resampling.BOX,box=tuple(v+pad for v in window)))
def palette(images,n):
 visible=[v[:3] for im in images for v in im.get_flattened_data() if v[3]];strip=Image.new('RGB',(len(visible),1));strip.putdata(visible)
 return strip.quantize(colors=n,dither=Image.Dither.NONE)
def family(folder,images,n,pivot,pixel):
 for name,im in images.items():im.save(folder/(name+'.png'))
 ext='\n'.join(f'[ext_resource type="Texture2D" path="{uri(folder/(name+".png"))}" id="{name}"]' for name in images)
 anim=',\n'.join('{"frames":[{"duration":1.0,"texture":ExtResource("'+name+'")}],"loop":'+('true' if name=='idle' else 'false')+',"name":&"'+name+'","speed":8.0}' for name in images)
 write(folder/'frames.tres',f'[gd_resource type="SpriteFrames" load_steps={len(images)+1} format=3]\n'+ext+'\n[resource]\nanimations = ['+anim+']\n')
 tops=', '.join('"'+name+'": ['+str(im.getbbox()[1])+']' for name,im in images.items())
 write(folder/'scene.tscn',f'''[gd_scene load_steps=3 format=3]
[ext_resource type="SpriteFrames" path="{uri(folder/'frames.tres')}" id="frames"]
[ext_resource type="Script" path="res://art/enemies/underhound-v1/mount.gd" id="bounds"]
[node name="Creature" type="Node3D"]
script = ExtResource("bounds")
pose_tops = {{{tops}}}
metadata/pivot = Vector2({n/2},{pivot})
metadata/art_issue = 166
[node name="Sprite" type="AnimatedSprite3D" parent="."]
position = Vector3(0,{(pivot-n/2)*pixel},0)
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
 for folder in [BOSS,HOUND,GATE,REVIEW]:folder.mkdir(parents=True,exist_ok=True)
 manifest={'issues':[166,168],'tool':'Built-in ImageGen','sources':{},'references':{},'families':{},'gate':{}}
 original_dir=Path('C:/Users/jonat/.codex/generated_images/01a14858-bf41-7241-a1a3-335ffc204971')
 for source in SRC.glob('*master.png'):
  id=source.name.removesuffix('-master.png');original_name=(SRC/(id+'-original.txt')).read_text(encoding='utf-8').strip();original=original_dir/original_name
  if original.exists():assert source.read_bytes()==original.read_bytes(),id
  manifest['sources'][id]={'sha256':sha(source),'size':Image.open(source).size,'original_path':str(original),'prompt_file':id+'-prompt.txt'}
 for id,record in manifest['sources'].items():
  refs=[]
  if id=='shepherd-idle':refs=['art/concepts/descent-horror-v1/marrow-shepherd.png','art/enemies/monsters-v1/broodmother/idle.png']
  elif id.startswith('shepherd-'):refs=['art/source/shepherd-gate-v1/shepherd-idle-master.png']
  elif id=='hound-idle':refs=['art/source/shepherd-gate-v1/shepherd-idle-master.png','art/enemies/underhound-v2/idle.png']
  elif id.startswith('hound-'):refs=['art/source/shepherd-gate-v1/hound-idle-master.png']
  elif id=='gate-open':refs=['art/source/shepherd-gate-v1/gate-closed-master.png']
  elif id=='gate-open-water':refs=['art/source/shepherd-gate-v1/gate-open-master.png']
  record['references']=[{'path':ref,'sha256':sha(ROOT/ref)} for ref in refs]
 for ref in ['art/concepts/descent-horror-v1/marrow-shepherd.png','art/enemies/monsters-v1/broodmother/idle.png','art/enemies/underhound-v2/idle.png']:
  manifest['references'][ref]=sha(ROOT/ref)
 images={};meta={}
 for id,poses in POSES.items():
  n,pivot,span=(192,180,176) if id=='shepherd' else (128,120,112)
  raw=hard(Image.open(SRC/(id+'-idle-master.png')));assert raw.size==(1254,1254)
  scale=span/1254;tx=(n-span)/2;ty=pivot-(raw.getbbox()[3]-1)*scale
  window=(-tx/scale,-ty/scale,(n-tx)/scale,(n-ty)/scale)
  images[id]={pose:resize(Image.open(SRC/f'{id}-{pose}-master.png'),n,window) for pose in poses}
  meta[id]={'canvas':n,'pivot':[n//2,pivot],'source_window':window,'source_scale':scale,'source_translation':[tx,ty],'per_pose_fit':False}
 # Fixed kinship palette from the two idle drawings; no fringe colours introduced
 # by source near-transparent antialiasing are admitted into the palette.
 pal=palette([images['shepherd']['idle'],images['hound']['idle']],32)
 for id,folder,height in [('shepherd',BOSS,1.06),('hound',HOUND,0.42)]:
  images[id]={pose:quantize(im,pal) for pose,im in images[id].items()}
  pivot=meta[id]['pivot'][1];pixel=height/(pivot-images[id]['idle'].getbbox()[1]);meta[id]['pixel_size']=pixel
  family(folder,images[id],meta[id]['canvas'],pivot,pixel)
  manifest['families'][id]={**meta[id],'scene':uri(folder/'scene.tscn'),'poses':{name:{'sha256':sha(folder/(name+'.png')),'bounds':im.getbbox()} for name,im in images[id].items()}}
  board=Image.new('RGB',(len(images[id])*200,370),'#28312c');d=ImageDraw.Draw(board)
  for i,(pose,im) in enumerate(images[id].items()):
   d.text((i*200+8,10),pose,fill='#ddd0b5');board.paste(im,(i*200+(200-im.width)//2,35),im)
   small=im.resize((im.width//2,im.height//2),Image.Resampling.NEAREST);board.paste(small,(i*200+(200-small.width)//2,260),small)
  board.save(REVIEW/(id+'-poses.png'))
 gate={name:hard(Image.open(SRC/(source+'-master.png')).resize((192,192),Image.Resampling.BOX)) for name,source in [('closed','gate-closed'),('open','gate-open-water')]}
 # Reuse the closed-state frame outside the fixed aperture. All changed pixels
 # come from the generated open master, not a procedural repaint.
 aperture=(50,37,142,168);registered=gate['closed'].copy();registered.paste(gate['open'].crop(aperture),aperture[:2]);gate['open']=registered
 pal=palette(list(gate.values()),48);gate={name:quantize(im,pal) for name,im in gate.items()}
 for name,im in gate.items():im.save(GATE/(name+'.png'))
 pixel=2.0/192;origin=(gate['closed'].getbbox()[3]-96)*pixel+0.015
 write(GATE/'scene.tscn',f'''[gd_scene load_steps=4 format=3]
[ext_resource type="Script" path="res://art/props/cave-events-v1/container.gd" id="state"]
[ext_resource type="Texture2D" path="res://art/props/reservoir-flow-gate-v1/closed.png" id="closed"]
[ext_resource type="Texture2D" path="res://art/props/reservoir-flow-gate-v1/open.png" id="open"]
[node name="ReservoirFlowGate" type="Node3D"]
script = ExtResource("state")
closed_texture = ExtResource("closed")
empty_texture = ExtResource("open")
metadata/art_issue = 168
[node name="Sprite" type="Sprite3D" parent="."]
position = Vector3(0,{origin},0)
pixel_size = {pixel}
billboard = 0
shaded = true
texture_filter = 0
alpha_cut = 1
alpha_scissor_threshold = 0.5
cast_shadow = 0
texture = ExtResource("closed")
''')
 manifest['gate']={'scene':uri(GATE/'scene.tscn'),'canvas':192,'world_canvas_metres':2.0,'aperture':aperture,'pixel_size':pixel,'sprite_y':origin,'state_api':{'closed':'closed','empty':'open'},'outputs':{n:{'sha256':sha(GATE/(n+'.png')),'bounds':im.getbbox()} for n,im in gate.items()}}
 write(SRC/'generation.json',json.dumps(manifest,indent=2)+'\n')
 catalog={'issues':[166,168],'families':{id:{'scene':record['scene'],'canvas':record['canvas'],'poses':list(record['poses'])} for id,record in manifest['families'].items()},'gate':manifest['gate'],'status':'Standalone library, no live EnemyType, quest, flood rule or placement changes.'}
 write(REVIEW/'catalog.json',json.dumps(catalog,indent=2)+'\n')
 board=Image.new('RGB',(420,240),'#28312c');d=ImageDraw.Draw(board)
 for i,(name,im) in enumerate(gate.items()):d.text((i*210+8,8),name,fill='#ddd0b5');board.paste(im,(i*210+8,30),im)
 board.save(REVIEW/'gate-pair.png')
 assets={uri(p):'data:image/png;base64,'+base64.b64encode(p.read_bytes()).decode() for folder in [BOSS,HOUND,GATE] for p in folder.glob('*.png')}
 captures=[]
 for name in ['shepherd-validation.json','hound-validation.json','gate-validation.json']:
  if (REVIEW/name).exists():captures+=json.loads((REVIEW/name).read_text(encoding='utf-8')).get('captures',[])
 if (REVIEW/'layout.html').exists():write(REVIEW/'inspector.html',(REVIEW/'layout.html').read_text(encoding='utf-8').replace('@@data@@',json.dumps({'catalog':catalog,'assets':assets})).replace('@@captures@@',json.dumps(captures)))
 print('Shepherd6, hound3, registered gate2; original masters and live game resources preserved.')
if __name__=='__main__':main()

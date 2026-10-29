"""#166: preserve ImageGen masters, export periodic native surfaces/state pair."""
from pathlib import Path
from PIL import Image,ImageDraw
import hashlib,json,numpy as np
ROOT=Path(__file__).resolve().parents[2]
SOURCE=ROOT/'art/source/drowned-water-v1';TEX=ROOT/'art/textures/drowned-water-v1'
PROP=ROOT/'art/props/drowned-water-v1';REVIEW=ROOT/'art/concepts/drowned-water-v1'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def write(p,s):p.write_text(s,encoding='utf-8',newline='\n')
def uri(p):return 'res://'+p.relative_to(ROOT).as_posix()
def palette(images,n):
 colors=[p[:3] for im in images for p in im.get_flattened_data() if len(p)==3 or p[3]]
 strip=Image.new('RGB',(len(colors),1));strip.putdata(colors)
 return strip.quantize(colors=n,dither=Image.Dither.NONE)

def main():
 prompts=json.loads((SOURCE/'prompts.json').read_text(encoding='utf-8'))
 manifest={'issue':166,'tool':prompts['tool'],'prompts':'prompts.json','masters':{},'references':{},'exports':{}}
 for id,name in prompts['original_filenames'].items():
  p=SOURCE/(id+'-master.png');original=Path(prompts['original_directory'])/name
  if original.exists():assert p.read_bytes()==original.read_bytes(),id
  manifest['masters'][id]={'path':uri(p),'sha256':sha(p),'size':Image.open(p).size,'original_path':str(original)}
 for path in ['art/textures/cave-v1/floor.png','art/props/story-slice-v1/lower-water-gate.png']:
  manifest['references'][path]=sha(ROOT/path)
 images={}
 for id in ['shallow','deep']:
  im=Image.open(SOURCE/(id+'-master.png')).convert('RGB').resize((128,128),Image.Resampling.BOX)
  a=np.asarray(im,dtype=float).copy()
  # Mechanical eight-pixel edge matching, not a replacement painted surface.
  # Opposite edge samples meet exactly; the original master remains untouched.
  for axis in [0,1]:
   v=np.swapaxes(a,0,axis)
   for i in range(8):
    left=v[i].copy();right=v[-i-1].copy();mean=(left+right)/2;weight=(1-i/8)**2
    v[i]=left*(1-weight)+mean*weight;v[-i-1]=right*(1-weight)+mean*weight
  im=Image.fromarray(np.uint8(np.clip(np.rint(a),0,255)))
  im=im.quantize(colors=32,dither=Image.Dither.NONE).convert('RGB')
  im.save(TEX/(id+'.png'));images[id]=im
  array=np.asarray(im)
  assert np.array_equal(array[0],array[-1]) and np.array_equal(array[:,0],array[:,-1]),id
  tiled=Image.new('RGB',(384,384))
  for y in range(3):
   for x in range(3):tiled.paste(im,(x*128,y*128))
  tiled.save(REVIEW/(id+'-tiled.png'))
  manifest['exports'][id]={'path':uri(TEX/(id+'.png')),'sha256':sha(TEX/(id+'.png')),'size':[128,128],
   'colours':len(im.getcolors()),'opposite_edges_exact':True,'edge_blend_width':8}
 frames=[]
 for id in ['sluice-closed','sluice-open']:
  im=Image.open(SOURCE/(id+'-master.png')).convert('RGBA').resize((192,192),Image.Resampling.BOX)
  im.putalpha(im.getchannel('A').point(lambda a:255 if a>=128 else 0));frames.append(im)
 pal=palette(frames,48)
 for id,im in zip(['sluice-closed','sluice-open'],frames):
  result=im.convert('RGB').quantize(palette=pal,dither=Image.Dither.NONE).convert('RGBA');result.putalpha(im.getchannel('A'))
  result.putdata([p if p[3] else (0,0,0,0) for p in result.get_flattened_data()]);result.save(PROP/(id+'.png'));images[id]=result
  manifest['exports'][id]={'path':uri(PROP/(id+'.png')),'sha256':sha(PROP/(id+'.png')),'size':[192,192],
   'colours':len({p[:3] for p in result.get_flattened_data() if p[3]}),'bounds':result.getbbox()}
 bottom=images['sluice-closed'].getbbox()[3]-1;pixel=2.0/192;origin=(bottom-96)*pixel+.02
 scene='''[gd_scene load_steps=4 format=3]
[ext_resource type="Script" path="res://art/props/cave-events-v1/container.gd" id="state"]
[ext_resource type="Texture2D" path="res://art/props/drowned-water-v1/sluice-closed.png" id="closed"]
[ext_resource type="Texture2D" path="res://art/props/drowned-water-v1/sluice-open.png" id="open"]
[node name="SluiceWheel" type="Node3D"]
script = ExtResource("state")
closed_texture = ExtResource("closed")
empty_texture = ExtResource("open")
metadata/art_issue = 166
[node name="Sprite" type="Sprite3D" parent="."]
position = Vector3(0, ORIGIN, 0)
pixel_size = PIXEL
billboard = 0
shaded = true
texture_filter = 0
alpha_cut = 1
alpha_scissor_threshold = 0.5
cast_shadow = 0
texture = ExtResource("closed")
'''.replace('ORIGIN',str(origin)).replace('PIXEL',str(pixel))
 write(PROP/'sluice.tscn',scene)
 manifest['registration']={'common_full_square_resize':[192,192],'per_state_fitting':False,'pixel_size':pixel,'sprite_y':origin,'floor_contact_from_closed':bottom,'world_canvas_width':2.0,'state_api':{'closed':'sluice-closed','empty':'sluice-open'}}
 write(SOURCE/'generation.json',json.dumps(manifest,indent=2)+'\n')
 write(TEX/'catalog.json',json.dumps({'issue':166,'surfaces':{id:manifest['exports'][id] for id in ['shallow','deep']},
  'scene_contract':'Instantiate shallow.tscn/deep.tscn; configure(cell, cell_size, motion_enabled). Visual only; never assigns map.water.'},indent=2)+'\n')
 write(PROP/'catalog.json',json.dumps({'issue':166,'scene':uri(PROP/'sluice.tscn'),**manifest['registration']},indent=2)+'\n')
 board=Image.new('RGB',(768,440),'#252c27');d=ImageDraw.Draw(board)
 for i,id in enumerate(['shallow','deep','sluice-closed','sluice-open']):
  im=images[id].convert('RGBA');im=im.resize((192,192),Image.Resampling.NEAREST)
  board.paste(im,(i*192,36),im);d.text((i*192+8,12),id,fill='#e3d6b8')
  small=im.resize((96,96),Image.Resampling.NEAREST);board.paste(small,(i*192+48,260),small)
 board.save(REVIEW/'overview.png')
 print('Two native128 periodic water textures; registered native192 sluice pair; original masters preserved.')

if __name__=='__main__':main()

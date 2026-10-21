"""#132/#133: mechanical exports and registered art-only mount/state scenes.

Masters are immutable. Related shrine states share one crop, scale and pivot.
No live landmark/event placement, boon, inventory, collision or save changes.
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import hashlib,json,math
import numpy as np
ROOT=Path(__file__).resolve().parents[2]
SOURCE=ROOT/'art/source/landmarks-v1'
OUT=ROOT/'art/dressing/landmarks-v1'
REVIEW=ROOT/'art/concepts/landmarks-v1'
# id, mount, measured axis, metres, floors
SPECS=[
 ('root-curtain-a','ceiling','height',.65,[2,3]),
 ('root-curtain-b','ceiling','width',1.15,[2,3]),
 ('wall-roots','wall','height',1.3,[2,3]),
 ('root-foot-tangle','floor-edge','width',.7,[2,3]),
 ('floor-crossing-root','floor-decal','width',1.45,[2,3]),
 ('miners-shrine','wall','width',1.0,[1,3]),
 ('miners-shrine-used','wall','width',1.0,[1,3]),
 ('shrine-offerings','floor-edge','width',.65,[1,3]),
 ('shrine-offerings-used','floor-edge','width',.65,[1,3]),
 ('collapsed-crates','floor-edge','width',1.1,[1,2]),
 ('split-barrel','floor-edge','width',.9,[1,2]),
 ('fallen-banner','floor-decal','height',1.15,[1,2]),
 ('cache-rubble-planks','floor-decal','width',1.3,[1,2]),
 ('cache-spilled-grain','floor-decal','width',.85,[1,2]),
]
PAIRS={'miners-shrine':'miners-shrine-used','shrine-offerings':'shrine-offerings-used'}

def write(path,text):
 path.parent.mkdir(parents=True,exist_ok=True);path.write_text(text,encoding='utf-8',newline='\n')
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def uri(path):return 'res://'+path.relative_to(ROOT).as_posix()
def source(id):return SOURCE/('shrine-offerings-neutral-master.png' if id=='shrine-offerings' else id+'-master.png')
def load(id):return Image.open(source(id)).convert('RGBA')
def bounds(im):return im.getchannel('A').point(lambda a:255 if a>=128 else 0).getbbox()
def prepare(id,raw,box):
 art=raw.crop(box);scale=min(112/art.width,112/art.height)
 assert scale<=1,'No upscaling'
 size=(round(art.width*scale),round(art.height*scale))
 small=art.resize(size,Image.Resampling.BOX)
 im=Image.new('RGBA',(128,128));offset=((128-size[0])//2,(128-size[1])//2)
 im.alpha_composite(small,offset)
 data=np.array(im);data[:,:,3]=np.where(data[:,:,3]>=128,255,0);data[data[:,:,3]==0]=0
 return Image.fromarray(data),{'source_bounds':list(box),'scale':scale,'offset':list(offset)}
def mapped(im,pal):
 alpha=im.getchannel('A');im=im.convert('RGB').quantize(palette=pal,dither=Image.Dither.NONE).convert('RGBA');im.putalpha(alpha)
 data=np.array(im);data[data[:,:,3]==0]=0;return Image.fromarray(data)
def make_palette(images):
 samples=np.concatenate([np.array(i)[:,:,:3][np.array(i)[:,:,3]>0] for i in images])
 pal=Image.fromarray(samples.reshape(1,-1,3)).quantize(60,dither=Image.Dither.NONE)
 rgb=pal.getpalette();used=sorted(set(pal.get_flattened_data()))
 colours=[tuple(rgb[3*i:3*i+3]) for i in used]
 for c in [(180,148,82),(228,180,102),(164,110,56),(238,200,126)]:
  if c not in colours:colours.append(c)
 assert len(colours)<=64
 result=Image.new('P',(1,1));data=colours+[colours[-1]]*(256-len(colours));result.putpalette([v for c in data for v in c]);return result,colours
def scene(e):
 mount=e['mount'];px=e['pixel_size'];pivot=e['pivot'];x=(64-pivot[0])*px;y=(pivot[1]-64)*px
 position=f'position = Vector3({x}, {y}, {0.012 if mount=="wall" else 0})\n'
 rotation='';billboard=2 if mount in ['ceiling','floor-edge'] else 0
 if mount=='floor-decal':position='position = Vector3(0, 0.012, 0)\n';rotation='rotation_degrees = Vector3(-90,0,0)\n'
 text=f'''[gd_scene load_steps=2 format=3]

[ext_resource type="Texture2D" path="{e['texture']}" id="texture"]

[node name="{e['id']}" type="Node3D"]
metadata/asset_id = "{e['id']}"

[node name="Sprite" type="Sprite3D" parent="."]
{position}{rotation}pixel_size = {px}
billboard = {billboard}
shaded = true
texture_filter = 0
alpha_cut = 1
alpha_scissor_threshold = 0.5
cast_shadow = 0
texture = ExtResource("texture")
'''
 write(OUT/(e['id']+'.tscn'),text)

def main():
 OUT.mkdir(parents=True,exist_ok=True);write(REVIEW/'.gdignore','')
 manifest=json.loads((SOURCE/'generation.json').read_text())
 for item in manifest['assets']:
  h=sha(ROOT/item['source']);assert item.get('sha256',h)==h,item['id'];item['sha256']=h
  if item['id']=='miners-shrine-used':item['reference']='art/source/landmarks-v1/miners-shrine-master.png'
  if item['id']=='shrine-offerings-neutral':item['reference']='art/source/landmarks-v1/shrine-offerings-master.png'
 write(SOURCE/'generation.json',json.dumps(manifest,indent=2)+'\n')
 originals={id:load(id) for id,*_ in SPECS};boxes={id:bounds(im) for id,im in originals.items()}
 for fresh,used in PAIRS.items():
  assert originals[fresh].size==originals[used].size,'Changed paired master canvas'
  a,b=boxes[fresh],boxes[used];box=(min(a[0],b[0]),min(a[1],b[1]),max(a[2],b[2]),max(a[3],b[3]));boxes[fresh]=boxes[used]=box
 prepared={id:prepare(id,im,boxes[id]) for id,im in originals.items()}
 pal,colours=make_palette([im for im,meta in prepared.values()]);entries=[];exports={}
 for id,mount,axis,metres,floors in SPECS:
  image,transform=prepared[id];image=mapped(image,pal);exports[id]=image
  box=bounds(image)
  pair=next((fresh for fresh,used in PAIRS.items() if id==used),id)
  if pair in PAIRS:
   a,b=bounds(prepared[pair][0]),bounds(prepared[PAIRS[pair]][0]);measure=(max(a[2],b[2])-min(a[0],b[0]));foot=max(a[3],b[3])
  else:measure=(box[3]-box[1]) if axis=='height' else (box[2]-box[0]);foot=box[3]
  px=metres/measure
  pivot=[64,box[1]] if mount=='ceiling' else [64,foot] if mount=='floor-edge' else [64,64]
  image.save(OUT/(id+'.png'))
  e={'id':id,'mount':mount,'pivot':pivot,'canvas':[128,128],'texture':uri(OUT/(id+'.png')),'scene':uri(OUT/(id+'.tscn')),'pixel_size':px,'measured_axis':axis,'metres':metres,'floors':floors,'opacity':1,'source':uri(source(id)),'source_sha256':sha(source(id)),'export_sha256':sha(OUT/(id+'.png')),'collision':False,'interactive_candidate':id.startswith(('miners-shrine','shrine-offerings')),**transform}
  if mount=='wall':e['suggested_wall_height']=.95 if id.startswith('miners') else 1.25
  if pair in PAIRS:e['state_family']=pair
  entries.append(e);scene(e)
 # Canonical seal is a separate native layer. Source cloth remains unmodified.
 crest=Image.open(SOURCE/'native/banner-seal.png').convert('RGBA');stamp=Image.new('RGBA',(128,128));stamp.alpha_composite(crest,(48,44));stamp=mapped(stamp,pal)
 stamp.putalpha(stamp.getchannel('A').point(lambda a:round(a*.68)));stamp.save(OUT/'banner-seal.png')
 banner=next(e for e in entries if e['id']=='fallen-banner')
 text=(OUT/'fallen-banner.tscn').read_text().replace('load_steps=2','load_steps=3')
 text=text.replace('[node name="fallen-banner"','[ext_resource type="Texture2D" path="res://art/dressing/landmarks-v1/banner-seal.png" id="seal"]\n\n[node name="fallen-banner"')
 text+='\n[node name="Seal" type="Sprite3D" parent="."]\nposition = Vector3(0, 0.014, 0)\nrotation_degrees = Vector3(-90,0,0)\npixel_size = '+str(banner['pixel_size'])+'\nshaded = true\ntexture_filter = 0\nalpha_cut = 0\ncast_shadow = 0\ntexture = ExtResource("seal")\n'
 write(OUT/'fallen-banner.tscn',text)
 # Native two-frame candle accents, registered to the offerings' wick seats.
 glow=Image.new('RGBA',(256,128))
 seats=[(43,36),(58,48),(31,59)]
 for frame in range(2):
  g=Image.new('RGBA',(128,128));d=ImageDraw.Draw(g)
  for x,y in seats:
   d.ellipse((x-4,y-6,x+4,y+3),fill=(180,148,82,20+frame*6))
   d.polygon([(x,y-4-frame),(x+1,y-1),(x,y+1),(x-1,y-1)],fill=(228,180,102,170+frame*30))
   d.point((x,y-1),fill=(238,200,126,220))
  g=mapped(g,pal);glow.paste(g,(frame*128,0))
 glow.save(OUT/'shrine-candle-glow.png')
 write(OUT/'shrine-glow.tres','''[gd_resource type="SpriteFrames" load_steps=4 format=3]
[ext_resource type="Texture2D" path="res://art/dressing/landmarks-v1/shrine-candle-glow.png" id="sheet"]
[sub_resource type="AtlasTexture" id="a"]
atlas = ExtResource("sheet")
region = Rect2(0,0,128,128)
[sub_resource type="AtlasTexture" id="b"]
atlas = ExtResource("sheet")
region = Rect2(128,0,128,128)
[resource]
animations = [{"frames":[{"duration":1.0,"texture":SubResource("a")},{"duration":1.0,"texture":SubResource("b")}],"loop":true,"name":&"glow","speed":2.0}]
''')
 shrine_scene(entries)
 write(OUT/'palette.json',json.dumps(colours,indent=2)+'\n')
 write(OUT/'catalog.json',json.dumps({'issues':[132,133],'cell_metres':2,'wall_metres':2.4,'colour_limit':64,'palette':'res://art/dressing/landmarks-v1/palette.json','placement':'Art library only. Claude owns live landmark/event placement and all boon/bane rules.','assets':entries,'event_scene':'res://art/dressing/landmarks-v1/miners-shrine-event.tscn','native_layers':{'banner_seal':'res://art/dressing/landmarks-v1/banner-seal.png','shrine_glow':'res://art/dressing/landmarks-v1/shrine-glow.tres','wick_seats':seats},'map_glyph':'res://art/ui/backlog96-v1/map/landmark.png'},indent=2)+'\n')
 motif=ROOT/'art/symbols/crest-v1/forked-seal.svg'
 write(SOURCE/'native-inputs.json',json.dumps({'canonical_seal':{'path':str(motif.relative_to(ROOT)).replace('\\','/'),'sha256':sha(motif)},'map_source':'art/source/landmarks-v1/landmark.svg'},indent=2)+'\n')
 board=Image.new('RGB',(960,680),'#202823');d=ImageDraw.Draw(board)
 for i,e in enumerate(entries):
  x=(i%5)*192;y=(i//5)*210
  image=exports[e['id']].copy()
  if e['id']=='fallen-banner':image.alpha_composite(stamp)
  board.paste(image,(x+32,y+22),image);d.text((x+8,y+158),e['id'],fill='#e4d7b8');d.text((x+8,y+179),e['mount'],fill='#acb5a5')
 d.text((16,650),'Miners shrine is an EVENT candidate; roots/cache are scenery. All pieces: native128, shared64 colours.',fill='#e4d7b8');board.save(REVIEW/'overview.png')
 print('LANDMARK_EXPORT: 14 native128 pieces; shared64 palette; registered pairs; native seal/glow; event scene.')

def shrine_scene(entries):
 wall=next(e for e in entries if e['id']=='miners-shrine');floor=next(e for e in entries if e['id']=='shrine-offerings')
 text='[gd_scene load_steps=7 format=3]\n\n[ext_resource type="Script" path="res://art/dressing/landmarks-v1/shrine.gd" id="script"]\n'
 for i,id in enumerate(['miners-shrine','miners-shrine-used','shrine-offerings','shrine-offerings-used']):text+=f'[ext_resource type="Texture2D" path="res://art/dressing/landmarks-v1/{id}.png" id="t{i}"]\n'
 text+='[ext_resource type="SpriteFrames" path="res://art/dressing/landmarks-v1/shrine-glow.tres" id="glow"]\n\n[node name="MinersShrine" type="Node3D"]\nscript = ExtResource("script")\nclosed_texture = ExtResource("t0")\nempty_texture = ExtResource("t1")\nofferings_texture = ExtResource("t2")\nspent_offerings_texture = ExtResource("t3")\n'
 for node,e,z,height in [('Sprite',wall,.012,.95),('Offerings',floor,.16,0)]:
  y=(e['pivot'][1]-64)*e['pixel_size']+height
  text+=f'\n[node name="{node}" type="Sprite3D" parent="."]\nposition = Vector3(0,{y},{z})\npixel_size = {e["pixel_size"]}\nbillboard = {0 if node=="Sprite" else 2}\nshaded = true\ntexture_filter = 0\nalpha_cut = 1\ncast_shadow = 0\ntexture = ExtResource("t{0 if node=="Sprite" else 2}")\n'
 y=(floor['pivot'][1]-64)*floor['pixel_size']
 text+=f'\n[node name="Glow" type="AnimatedSprite3D" parent="."]\nposition = Vector3(0,{y},0.162)\npixel_size = {floor["pixel_size"]}\nbillboard = 2\nshaded = false\ntexture_filter = 0\ncast_shadow = 0\nsprite_frames = ExtResource("glow")\nanimation = &"glow"\nautoplay = "glow"\n'
 write(OUT/'miners-shrine-event.tscn',text)

if __name__=='__main__':main()

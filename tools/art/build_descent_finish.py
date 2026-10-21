"""#139: mechanical surface/cutout exports and original native marking/FX art.

No generated subject is repainted. Existing walls, themes and placement code
are read-only inputs. Floor/ceiling pixels use their wall's exact 32 colours.
"""
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
import hashlib,json,math,sys
sys.dont_write_bytecode=True
import numpy as np
from build_descent_walls import wrap_apron

ROOT=Path(__file__).resolve().parents[2]
SS=ROOT/'art/source/descent-surfaces-v1'
DS=ROOT/'art/source/cave-dressing-v2'
SURF=ROOT/'art/textures/descent-surfaces-v1'
OUT=ROOT/'art/dressing/cave-v2'
REVIEW=ROOT/'art/concepts/descent-finish-v1'
FAMILIES=['worked-cave','goblin-hold','drowned-masonry','fungal-stone','buried-city','sealed-temple']
# id, mount, visible axis, metres, existing/proposed inclusive floors, family
SPECS=[
 ('moss-curtain','ceiling','width',1.1,[2,3],'fungal-stone'),
 ('old-remains','floor-edge','width',.85,[1,4],'worked-cave'),
 ('mine-ring-chain','wall','height',.6,[1,1],'worked-cave'),
 ('broken-rail-end','wall','height',.55,[1,1],'worked-cave'),
 ('lantern-hook','wall','height',.35,[1,1],'worked-cave'),
 ('goblin-hide','wall','height',.8,[3,4],'goblin-hold'),
 ('goblin-banner','wall','height',.95,[3,4],'goblin-hold'),
 ('wall-spikes','wall','width',.85,[4,4],'goblin-hold'),
 ('chained-cage','ceiling','height',.65,[4,4],'goblin-hold'),
 ('overhead-walkway','ceiling-plane','width',1.6,[4,4],'goblin-hold'),
 ('waterline-stain','wall','width',1.6,[5,6],'drowned-masonry'),
 ('mineral-crust','wall','width',1.1,[5,6],'drowned-masonry'),
 ('relief-fragment','wall','width',1.0,[9,10],'buried-city'),
 ('empty-lamp-niche','wall','height',.5,[9,10],'buried-city'),
 ('ward-niche','wall','height',.65,[11,12],'sealed-temple'),
 ('stranger-mark','wall','width',.32,[1,1],'worked-cave'),
 ('inscription-band','wall','width',.8,[9,10],'buried-city'),
 ('seal-ornament','wall','width',.35,[11,12],'sealed-temple'),
]
HEIGHTS={'mine-ring-chain':1.4,'broken-rail-end':.6,'lantern-hook':1.5,'goblin-hide':1.25,'goblin-banner':1.4,'wall-spikes':1.15,'waterline-stain':.7,'mineral-crust':1.4,'relief-fragment':1.3,'empty-lamp-niche':1.2,'ward-niche':1.25,'stranger-mark':1.0,'inscription-band':1.45,'seal-ornament':1.25}

def write(p,t):p.parent.mkdir(parents=True,exist_ok=True);p.write_text(t,encoding='utf-8',newline='\n')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def uri(p):return 'res://'+p.relative_to(ROOT).as_posix()
def font(n):return ImageFont.truetype(str(next((ROOT/'art/fonts/source-sans-3').glob('*.ttf'))),n)
def provenance(folder):
 m=json.loads((folder/'generation.json').read_text(encoding='utf-8'))
 for a in m['assets']:
  h=sha(ROOT/a['source']);assert a.get('sha256',h)==h,a['id'];a['sha256']=h
 write(folder/'generation.json',json.dumps(m,indent=2)+'\n')
 return m
def native_sources():
 drawings={
  'stranger-mark':'M40 42 78 49 48 81M37 64l30 6',
  'inscription-band':'M13 54l4 17m4-19-1 12m5-10 6 11m3-14 1 20m9-16 6 3-5 9m11-17-2 19m8-14 7 5-4 10m9-20 2 15m9-14-3 18m9-17 5 4-2 10',
  'seal-ornament':'M64 23 99 43v40L64 103 29 83V43ZM43 51l21-12 21 12v24L64 87 43 75ZM48 64h32M64 45v38'}
 for id,path in drawings.items():
  svg=f'<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128"><title>{id}: provisional ornamental marks; no assigned language or lore</title><g fill="none" stroke-linecap="round" stroke-linejoin="round"><path d="{path}" stroke="#302c25" stroke-width="5"/><path d="{path}" stroke="#afa98e" stroke-width="2" transform="translate(1,1)"/></g></svg>\n'
  write(DS/'native'/(id+'.svg'),svg)
 path=drawings['stranger-mark']
 write(DS/'native/stranger-mark-ink.svg',f'<svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="30 30 60 60"><title>Same scratch motif, ink form for a future route-map clue</title><path d="{path}" fill="none" stroke="#362b20" stroke-width="6" stroke-linecap="round" stroke-linejoin="round"/></svg>\n')

def palette(colours):
 p=Image.new('P',(1,1));data=list(colours)+[colours[-1]]*(256-len(colours));p.putpalette([int(v) for c in data for v in c]);return p
def surfaces():
 report=[];families=[]
 overview=Image.new('RGB',(1152,464),'#202823');d=ImageDraw.Draw(overview)
 for i,family in enumerate(FAMILIES):
  wall=ROOT/'art/textures/descent-walls-v1'/(family+'.png');w=Image.open(wall).convert('RGB');colours=sorted(set(w.get_flattened_data()));pal=palette(colours)
  binding={'id':family,'wall_texture':uri(wall),'wall_material':uri(wall.with_suffix('.tres')),'wall_sha256':sha(wall),'palette':[list(c) for c in colours]}
  ox=i%3*384;oy=i//3*232;d.text((ox+8,oy+6),family,font=font(17),fill='#e6dac1')
  overview.paste(w,(ox,oy+38));d.text((ox+8,oy+174),'wall · unchanged',font=font(14),fill='#b7beac')
  for j,role in enumerate(['floor','ceiling']):
   id=family+'-'+role;source=SS/(id+'-master.png');raw=Image.open(source).convert('RGB')
   im=wrap_apron(raw.resize((128,128),Image.Resampling.BOX)).quantize(palette=pal,dither=Image.Dither.NONE).convert('RGB')
   dest=SURF/(id+'.png');im.save(dest);mat=dest.with_suffix('.tres')
   write(mat,f'[gd_resource type="StandardMaterial3D" load_steps=2 format=3]\n\n[ext_resource type="Texture2D" path="{uri(dest)}" id="surface"]\n\n[resource]\nresource_name = "{id}"\ntexture_filter = 0\ntexture_repeat = true\nalbedo_texture = ExtResource("surface")\nroughness = 1.0\n')
   binding[role+'_material']=uri(mat);binding[role+'_texture']=uri(dest)
   report.append({'id':id,'family':family,'role':role,'texture':uri(dest),'material':uri(mat),'canvas':[128,128],'palette_source':uri(wall),'colours':len(set(im.get_flattened_data())),'source':uri(source),'source_sha256':sha(source),'sha256':sha(dest)})
   overview.paste(im,(ox+(j+1)*128,oy+38));d.text((ox+(j+1)*128+8,oy+174),role,font=font(14),fill='#b7beac')
   repeat=Image.new('RGB',(512,512))
   for x in range(4):
    for y in range(4):repeat.paste(im,(128*x,128*y))
   repeat.save(REVIEW/(id+'-repeat.png'))
  families.append(binding)
 overview.save(REVIEW/'surface-overview.png')
 write(SURF/'catalog.json',json.dumps({'issue':139,'size':128,'colour_limit':32,'families':families,'assets':report,'assignment':'Material library only. Existing wall files and live themes are unchanged. Family/floor lore remains proposed.'},indent=2)+'\n')

def hard_image(im):
 a=np.array(im.convert('RGBA'));a[:,:,3]=np.where(a[:,:,3]>=128,255,0);a[a[:,:,3]==0]=0
 return Image.fromarray(a)
def fit(source,native=False):
 raw=Image.open(source).convert('RGBA')
 if native:
  im=hard_image(raw);alpha=im.getchannel('A');im=im.convert('RGB').quantize(32,dither=Image.Dither.NONE).convert('RGBA');im.putalpha(alpha)
  return hard_image(im),{'source_bounds':[0,0,128,128],'scale':1.0,'offset':[0,0]}
 b=raw.getchannel('A').point(lambda a:255 if a>=128 else 0).getbbox();part=raw.crop(b);scale=min(112/part.width,112/part.height);assert scale<1
 small=part.resize((round(part.width*scale),round(part.height*scale)),Image.Resampling.BOX);im=Image.new('RGBA',(128,128));offset=((128-small.width)//2,(128-small.height)//2);im.alpha_composite(small,offset)
 im=hard_image(im);a=np.array(im);samples=a[:,:,:3][a[:,:,3]>0];pal=Image.fromarray(samples.reshape(1,-1,3)).quantize(64,dither=Image.Dither.NONE)
 alpha=im.getchannel('A');im=im.convert('RGB').quantize(palette=pal,dither=Image.Dither.NONE).convert('RGBA');im.putalpha(alpha)
 return hard_image(im),{'source_bounds':list(b),'scale':scale,'offset':list(offset)}
def scene(e):
 mount=e['mount'];px=e['pixel_size'];pivot=e['pivot'];pos=f'position = Vector3({(64-pivot[0])*px}, {(pivot[1]-64)*px}, {0.012 if mount=="wall" else 0})\n';rotation=''
 if mount=='ceiling-plane':pos='position = Vector3(0, -0.012, 0)\n';rotation='rotation_degrees = Vector3(90, 0, 0)\n'
 text=f'[gd_scene load_steps=2 format=3]\n\n[ext_resource type="Texture2D" path="{e["texture"]}" id="texture"]\n\n[node name="{e["id"]}" type="Node3D"]\nmetadata/dressing_id = "{e["id"]}"\n\n[node name="Sprite" type="Sprite3D" parent="."]\n{pos}{rotation}pixel_size = {px}\nbillboard = {2 if mount in ["ceiling","floor-edge"] else 0}\nshaded = true\ntexture_filter = 0\nalpha_cut = {0 if e["opacity"]<1 else 1}\nalpha_scissor_threshold = 0.5\ncast_shadow = 0\nmodulate = Color(1, 1, 1, {e["opacity"]})\ntexture = ExtResource("texture")\n'
 write(OUT/(e['id']+'.tscn'),text)
def frames(id,mask):
 atlas=Image.new('RGBA',(512,256))
 for i in range(8):
  frame=mask.copy();frame.putalpha(mask.getchannel('A').point(lambda a:round(a*(.65+.18*math.sin(2*math.pi*i/8)))))
  atlas.paste(frame,((i%4)*128,(i//4)*128))
 atlas.save(OUT/(id+'-pulse.png'));mask.save(OUT/(id+'-emission.png'))
 text=f'[gd_resource type="SpriteFrames" load_steps=10 format=3]\n[ext_resource type="Texture2D" path="{uri(OUT/(id+"-pulse.png"))}" id="sheet"]\n'
 for i in range(8):text+=f'\n[sub_resource type="AtlasTexture" id="f{i}"]\natlas = ExtResource("sheet")\nregion = Rect2({i%4*128}, {i//4*128}, 128, 128)\n'
 text+='\n[resource]\nanimations = [{"frames":['+','.join('{"duration":1.0,"texture":SubResource("f'+str(i)+'")}' for i in range(8))+'],"loop":true,"name":&"loop","speed":4.0}]\n'
 write(OUT/(id+'-pulse.tres'),text)
def glow_scene(e):
 id=e['id'];base=(OUT/(id+'.tscn')).read_text();text=base.replace('load_steps=2','load_steps=3')
 text=text.replace('[node name="'+id+'"',f'[ext_resource type="SpriteFrames" path="{uri(OUT/(id+"-pulse.tres"))}" id="glow"]\n\n[node name="'+id+'"',1)
 px=e['pixel_size'];pivot=e['pivot'];y=(pivot[1]-64)*px
 text+=f'\n[node name="Glow" type="AnimatedSprite3D" parent="."]\nposition = Vector3(0, {y}, 0.016)\npixel_size = {px}\nbillboard = 2\nshaded = false\ntexture_filter = 0\ncast_shadow = 0\nsprite_frames = ExtResource("glow")\nanimation = &"loop"\nautoplay = "loop"\n'
 write(OUT/(id+'-lit.tscn'),text);e['glow_scene']=uri(OUT/(id+'-lit.tscn'));e['glow_frames']=uri(OUT/(id+'-pulse.tres'));e['emission_mask']=uri(OUT/(id+'-emission.png'))
def dressing():
 entries=[]
 (OUT/'stranger-mark-ink.png').write_bytes((DS/'native/stranger-mark-ink.png').read_bytes())
 for id,mount,axis,metres,floors,family in SPECS:
  native=id in ['stranger-mark','inscription-band','seal-ornament']
  source=DS/'native'/(id+'.png') if native else DS/(('wall-spikes-pointed' if id=='wall-spikes' else id)+'-master.png')
  im,transform=fit(source,native);dest=OUT/(id+'.png');im.save(dest);b=im.getbbox();measure=b[3]-b[1] if axis=='height' else b[2]-b[0];px=metres/measure
  pivot=[64,b[1]] if mount=='ceiling' else [64,b[3]] if mount=='floor-edge' else [64,64]
  e={'id':id,'mount':mount,'measured_axis':axis,'metres':metres,'canvas':[128,128],'pivot':pivot,'pixel_size':px,'floors':floors,'floor_status':'proposed layer range only' if floors[0]>4 else 'existing floor range','family':family,'source':uri(source),'source_sha256':sha(source),'texture':uri(dest),'sha256':sha(dest),'scene':uri(OUT/(id+'.tscn')),'opacity':.65 if id=='waterline-stain' else .8 if id=='mineral-crust' else 1,'collision':False,'interactive':False,**transform}
  if mount=='wall':e['suggested_wall_height']=HEIGHTS[id]
  entries.append(e);scene(e)
 # Existing neutral mushroom drawing remains byte-for-byte; only FX is new.
 old=json.loads((ROOT/'art/dressing/cave-v1/catalog.json').read_text());old=next(a for a in old['assets'] if a['id']=='pale-mushrooms')
 source=ROOT/old['texture'].removeprefix('res://');(OUT/'floor-fungus.png').write_bytes(source.read_bytes())
 e={**old,'id':'floor-fungus','source':uri(source),'source_sha256':sha(source),'texture':uri(OUT/'floor-fungus.png'),'scene':uri(OUT/'floor-fungus.tscn'),'sha256':sha(OUT/'floor-fungus.png'),'interactive':False,'family':'fungal-stone','source_kind':'unchanged existing neutral art','opacity':1}
 entries.append(e);scene(e)
 # Registered native emission contributions: no resampling/shift of the base.
 for id in ['moss-curtain','floor-fungus']:
  im=Image.open(OUT/(id+'.png')).convert('RGBA');a=np.array(im);mask=np.zeros_like(a);y,x=np.indices((128,128))
  if id=='moss-curtain':
   gate=(a[:,:,3]>0)&(a[:,:,1]>=a[:,:,0]*.94)&(a[:,:,1]>a[:,:,2]*1.1)&(y>52)&(((x//7+y//5)%3)==0)
   mask[gate]=[114,146,104,65]
  else:
   # Broad cap-only regions fitted to the unchanged pale-mushrooms drawing.
   gate=np.zeros((128,128),dtype=bool)
   for cx,cy,rx,ry in [(49,38,21,10),(84,48,18,10),(18,64,12,8),(41,74,9,6),(64,73,10,7),(106,68,14,8),(87,81,9,5)]:gate|=((x-cx)/rx)**2+((y-cy)/ry)**2<=1
   gate&=(a[:,:,3]>0)&(a[:,:,:3].mean(axis=2)>100)
   mask[gate]=[130,158,122,68]
  frames(id,Image.fromarray(mask));entry=next(e for e in entries if e['id']==id);glow_scene(entry)
 # Registered mineral/drip assembly. Put its root at 1.4m so the last splash
 # reaches floor height. Existing drip animation remains unchanged.
 crust=next(e for e in entries if e['id']=='mineral-crust');text=(OUT/'mineral-crust.tscn').read_text().replace('load_steps=2','load_steps=3')
 text=text.replace('[node name="mineral-crust"','[ext_resource type="SpriteFrames" path="res://art/effects/ambient-v1/drip.tres" id="drip"]\n\n[node name="drip-curtain"',1)
 text=text.replace('metadata/dressing_id = "mineral-crust"','metadata/dressing_id = "drip-curtain"')
 for i,x in enumerate([-.25,.25]):text+=f'\n[node name="Drip{i}" type="AnimatedSprite3D" parent="."]\nposition = Vector3({x}, -0.85, 0.04)\npixel_size = 0.008\nshaded = true\ntexture_filter = 0\ncast_shadow = 0\nsprite_frames = ExtResource("drip")\nanimation = &"loop"\nframe = {i*4}\nautoplay = "loop"\n'
 write(OUT/'drip-curtain.tscn',text);entries.append({**crust,'id':'drip-curtain','scene':uri(OUT/'drip-curtain.tscn'),'source_kind':'composite of mineral-crust and unchanged ambient drip','suggested_wall_height':1.4})
 write(OUT/'catalog.json',json.dumps({'issue':139,'cell_metres':2,'wall_metres':2.4,'colour_limit_per_piece':64,'placement':'Library only; live themes, placement, events, collisions, saves and light/nerves rules unchanged. Later floor ranges are proposals.','reuses':['art/dressing/landmarks-v1 roots','art/dressing/cave-v1/wall-fungus and ambient-v1 pulse'],'clue_ink':uri(OUT/'stranger-mark-ink.png'),'assets':entries},indent=2)+'\n')
 board=Image.new('RGB',(960,820),'#202823');d=ImageDraw.Draw(board)
 for i,e in enumerate(entries):
  x=i%5*192;y=i//5*200;im=Image.open(ROOT/e['texture'].removeprefix('res://')).convert('RGBA');board.paste(im,(x+32,y+12),im);d.text((x+8,y+144),e['id'],font=font(15),fill='#e6dac1');d.text((x+8,y+166),e['mount'],font=font(14),fill='#b3bca9')
 board.save(REVIEW/'dressing-overview.png')

def main():
 for p in [SURF,OUT,REVIEW,DS/'native']:p.mkdir(parents=True,exist_ok=True)
 write(REVIEW/'.gdignore','');provenance(SS);provenance(DS);native_sources()
 # First pass writes native sources/surfaces; rasterize, then run again.
 surfaces()
 if not (DS/'native/stranger-mark.png').exists():print('DESCENT_FINISH: surfaces exported; raster native drawings, then rerun');return
 dressing()
 preserved=[*(ROOT/'art/textures/descent-walls-v1').glob('*.png'),*(ROOT/'art/textures/descent-walls-v1').glob('*.tres'),*(ROOT/'themes').glob('*.tres'),ROOT/'scripts/level_builder.gd',ROOT/'scripts/dressing.gd',ROOT/'art/dressing/cave-v1/pale-mushrooms.png',ROOT/'art/dressing/cave-v1/wall-fungus.png',ROOT/'art/effects/ambient-v1/drip.tres']
 p=DS/'reused-inputs.json';baseline=json.loads(p.read_text()) if p.exists() else {uri(x):sha(x) for x in preserved}
 for path,h in baseline.items():assert sha(ROOT/path.removeprefix('res://'))==h,'Preserved input changed: '+path
 write(p,json.dumps(baseline,indent=2)+'\n');print('DESCENT_FINISH: 12 matching surfaces, 20 mounted pieces/assemblies, registered mood glow; existing content unchanged')
if __name__=='__main__':main()

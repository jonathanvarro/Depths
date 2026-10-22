"""#131 normal elves: immutable masters, fitted native rigs and three poses.

Reuses the accepted #124 drawing algorithms, never another head's drawings.
Existing portrait/sprite exporters and catalogues remain untouched.
"""
from pathlib import Path
import hashlib,json,sys,math
sys.dont_write_bytecode=True
from PIL import Image,ImageDraw
import numpy as np
import build_portrait_components as C
import refine_portrait_drawings as D
ROOT=Path(__file__).resolve().parents[2]
SOURCE=ROOT/'art/source/elves-v1';OUT=ROOT/'art/portraits/elves-v1'
ENEMY=ROOT/'art/enemies/elves-v1/swordswoman';REVIEW=ROOT/'art/concepts/elves-v1'
FACES={
 'elf-man':{
  'eyes':[
   ([(83,50),(88,49),(96,49),(102,51),(103,54),(99,58),(89,58),(84,55)],[(85,52),(89,54),(94,55),(99,54),(102,53)]),
   ([(109,52),(113,51),(121,52),(125,54),(125,57),(120,60),(112,59),(109,56)],[(111,54),(115,56),(119,57),(123,55)])],
  'mouth':[(90,77),(98,74),(106,74),(113,77),(115,80),(110,84),(99,85),(90,81)],
  'lip':[(93,78),(98,77),(103,77),(108,78),(112,79)]},
 'elf-woman':{
  'eyes':[
   ([(84,50),(88,49),(97,50),(103,53),(103,57),(97,60),(88,58),(84,54)],[(86,53),(91,55),(96,56),(101,55)]),
   ([(109,53),(114,52),(122,53),(126,55),(126,58),(122,62),(112,61),(109,57)],[(111,56),(115,58),(120,59),(124,57)])],
  'mouth':[(92,78),(98,75),(105,75),(112,77),(115,81),(112,85),(103,87),(95,85),(92,81)],
  'lip':[(95,80),(100,79),(104,79),(109,80),(113,82)]}}
EYES={
 'elf-man':[
  {'half':[(85,51),(90,51),(95,52),(101,52)],'lower':[(85,53),(90,55),(95,56),(101,54)]},
  {'half':[(111,53),(115,53),(120,54),(123,55)],'lower':[(111,55),(115,57),(120,58),(123,56)]}],
 'elf-woman':[
  {'half':[(86,52),(91,52),(96,53),(101,54)],'lower':[(86,54),(91,57),(96,58),(101,56)]},
  {'half':[(111,55),(115,55),(120,56),(124,56)],'lower':[(111,57),(115,59),(120,60),(124,58)]}]}
def write(p,t):p.parent.mkdir(parents=True,exist_ok=True);p.write_text(t,encoding='utf-8',newline='\n')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def uri(p):return 'res://'+p.relative_to(ROOT).as_posix()
def save(im,p):p.parent.mkdir(parents=True,exist_ok=True);im.save(p)
def hard(im):
 a=np.array(im);a[:,:,3]=np.where(a[:,:,3]>=128,255,0);a[a[:,:,3]==0]=0;return Image.fromarray(a)
def sources():
 manifest=SOURCE/'generation.json';known={a['id']:a['sha256'] for a in json.loads(manifest.read_text())['assets']} if manifest.exists() else {}
 assets=[]
 for p in sorted((SOURCE/'records').glob('*.json')):
  e=json.loads(p.read_text());path=ROOT/e['source'];origin=Path(e['original_path'])
  assert path.read_bytes()==origin.read_bytes(),e['id'];e['sha256']=sha(path)
  assert known.get(e['id']) in [None,e['sha256']],'Immutable master changed';assets.append(e)
 assert len(assets)==5
 write(manifest,json.dumps({'issue':131,'tool':'built-in image_gen','date':'2026-10-22','assets':assets},indent=2)+'\n')
def rig(ident):
 raw=Image.open(SOURCE/(ident+'-master.png')).convert('RGBA');assert raw.width==raw.height and raw.width>192
 original=raw.resize((192,192),Image.Resampling.BOX);alpha=original.getchannel('A').point(lambda a:255 if a>=128 else 0)
 original=original.convert('RGB').quantize(96,dither=Image.Dither.NONE).convert('RGBA');original.putalpha(alpha);original=hard(original)
 folder=OUT/ident;source=SOURCE/ident;save(original,folder/'resting.png')
 spec=FACES[ident];C.FACES[ident]=spec;D.EYES[ident]=EYES[ident]
 for i,eye in enumerate(D.EYES[ident]):eye['closed']=spec['eyes'][i][1]
 pal=sorted({p for p in original.get_flattened_data() if p[3]})
 eye_mask=C.merge(*[C.polygon(points) for points,_ in spec['eyes']]);mouth_mask=C.polygon(spec['mouth'])
 clean=C.clean_feature(original,eye_mask,'eye',pal);clean=C.clean_feature(clean,mouth_mask,'mouth',pal)
 save(clean,folder/'character-clean.png');save(C.full_patch(original,eye_mask),folder/'eyes-neutral.png');save(C.full_patch(original,mouth_mask),folder/'mouth-neutral.png')
 for mode in ['half','closed']:
  drawing,visible,lash=D.eyes(ident,original,clean,eye_mask,mode,pal)
  save(C.full_patch(drawing,eye_mask),folder/('eyes-'+mode+'.png'));save(visible,source/('eyes-'+mode+'-iris.png'));save(lash,source/('eyes-'+mode+'-lash.png'))
 for mode in ['small','open','round']:
  drawing,cavity,tissue=D.mouth(ident,original,mouth_mask,mode,pal)
  if mode=='round':
   # Complete replacement of the old lip corners, followed by a small native
   # ring of the original lip tissue. The resting mouth is never underneath.
   drawing=clean.copy();cavity=Image.new('L',(192,192));seam=spec['lip'];cx=round((seam[0][0]+seam[-1][0])/2);cy=C.lip_y(seam,cx)
   for y in range(cy-3,cy+5):
    for x in range(cx-5,cx+6):
     if not mouth_mask.getpixel((x,y)) or ((x-cx)/5)**2+((y-cy)/3.7)**2>1:continue
     sx=max(seam[0][0],min(seam[-1][0],round(cx+(x-cx)*1.8)));sy=cy-1 if y<cy else cy+2
     drawing.putpixel((x,y),original.getpixel((sx,sy)))
     if ((x-cx)/2.8)**2+((y-cy)/2.3)**2<1:drawing.putpixel((x,y),C.nearest(pal,(48,30,25)));cavity.putpixel((x,y),255)
  save(C.full_patch(drawing,mouth_mask),folder/('mouth-'+mode+'.png'));save(cavity,source/('mouth-'+mode+'-opening.png'))
 for kind in ['shadow','highlight']:
  layer=Image.new('RGBA',(192,192))
  for y in range(192):
   for x in range(192):
    if not original.getpixel((x,y))[3]:continue
    a=round(180*max(0,1-x/192)*max(.15,1-y/220)) if kind=='highlight' else round(190*min(1,.7*x/192+.3*y/192))
    layer.putpixel((x,y),(255,255,255,a) if kind=='highlight' else (0,0,0,a))
  save(layer,folder/(kind+'.png'))
 save(eye_mask,source/'eye-mask.png');save(mouth_mask,source/'mouth-mask.png');write(source/'contours.json',json.dumps({'features':spec,'drawings':D.EYES[ident]},indent=2)+'\n')
 reconstruction=clean.copy();reconstruction.alpha_composite(C.full_patch(original,eye_mask));reconstruction.alpha_composite(C.full_patch(original,mouth_mask));assert reconstruction.tobytes()==original.tobytes()
 names=['character-clean','eyes-neutral','mouth-neutral','eyes-half','eyes-closed','mouth-small','mouth-open','mouth-round','shadow','highlight']
 text='[gd_resource type="Resource" script_class="PortraitSet" format=3]\n\n[ext_resource type="Script" path="res://scripts/portrait_set.gd" id="script"]\n'
 for name in names:text+=f'[ext_resource type="Texture2D" path="{uri(folder/(name+".png"))}" id="{name}"]\n'
 text+='\n[resource]\nscript = ExtResource("script")\nrig_kind = "Unique"\nrig_family = &"unique-'+ident+'-v1"\nface_id = &"'+ident+'"\nhead = ExtResource("character-clean")\neyes = ExtResource("eyes-neutral")\nmouth = ExtResource("mouth-neutral")\nblink_frames = Array[Texture2D]([ExtResource("eyes-half"),ExtResource("eyes-closed")])\ntalk_frames = Array[Texture2D]([ExtResource("mouth-small"),ExtResource("mouth-open"),ExtResource("mouth-round")])\nlight_shadow = ExtResource("shadow")\nlight_highlight = ExtResource("highlight")\n'
 resource=ROOT/'data/portraits/elves-v1'/(ident+'.tres');write(resource,text)
 return {'id':ident,'rig_kind':'Unique','rig_family':'unique-'+ident+'-v1','canvas':[192,192],'resource':uri(resource),'fallback':uri(folder/'resting.png'),'features':spec}
def enemy():
 ENEMY.mkdir(parents=True,exist_ok=True);poses=['idle','attack','hurt'];images=[];entries=[]
 for pose in poses:
  p=SOURCE/('elf-'+pose+'-master.png');raw=Image.open(p).convert('RGBA');assert raw.width==raw.height
  reduced=hard(raw.resize((112,112),Image.Resampling.BOX));box=reduced.getbbox();dy=121-box[3]
  out=Image.new('RGBA',(128,128));out.paste(reduced,(8,dy));assert np.count_nonzero(np.array(out)[:,:,3])==np.count_nonzero(np.array(reduced)[:,:,3])
  images.append(out);entries.append({'pose':pose,'source':uri(p),'reduced_canvas':[112,112],'translation':[8,dy]})
 samples=np.concatenate([np.array(i)[:,:,:3][np.array(i)[:,:,3]>0] for i in images]);pal=Image.fromarray(samples.reshape(1,-1,3)).quantize(32,dither=Image.Dither.NONE)
 board=Image.new('RGB',(768,290),'#202623');draw=ImageDraw.Draw(board);colours=set()
 for i,(pose,im,e) in enumerate(zip(poses,images,entries)):
  a=im.getchannel('A');im=im.convert('RGB').quantize(palette=pal,dither=Image.Dither.NONE).convert('RGBA');im.putalpha(a);im=hard(im);save(im,ENEMY/(pose+'.png'))
  colours.update(p[:3] for p in im.get_flattened_data() if p[3]);e['bounds']=list(im.getbbox());e['sha256']=sha(ENEMY/(pose+'.png'))
  large=im.resize((256,256),Image.Resampling.NEAREST);board.paste(large,(256*i,25),large);draw.text((256*i+8,8),pose,fill='#e6dac1')
 save(board,REVIEW/'combat-poses.png');assert len(colours)<=32
 frames='[gd_resource type="SpriteFrames" load_steps=4 format=3]\n'
 for i,p in enumerate(poses):frames+=f'[ext_resource type="Texture2D" path="{uri(ENEMY/(p+".png"))}" id="{i}"]\n'
 frames+='[resource]\nanimations = ['+','.join('{"frames":[{"duration":1.0,"texture":ExtResource("%d")}],"loop":false,"name":&"%s","speed":6.0}'%(i,p) for i,p in enumerate(poses))+']\n';write(ENEMY/'frames.tres',frames)
 idle_height=121-entries[0]['bounds'][1];px=1.95/idle_height
 write(ENEMY/'scene.tscn',f'[gd_scene load_steps=2 format=3]\n[ext_resource type="SpriteFrames" path="{uri(ENEMY/"frames.tres")}" id="frames"]\n[node name="ElfSwordswoman" type="Node3D"]\nmetadata/visual_height = 1.95\n[node name="Sprite" type="AnimatedSprite3D" parent="."]\nposition = Vector3(0,{56*px},0)\npixel_size = {px}\nbillboard = 1\nshaded = true\ntexture_filter = 0\nalpha_cut = 1\nalpha_scissor_threshold = 0.5\ncast_shadow = 0\nsprite_frames = ExtResource("frames")\nanimation = &"idle"\n')
 write(ENEMY/'registration.json',json.dumps({'canvas':[128,128],'pivot':[64,120],'common_reduced_canvas':[112,112],'pixel_size':px,'metres':1.95,'palette':sorted(colours),'poses':entries},indent=2)+'\n')
def main():
 write(REVIEW/'.gdignore','');sources()
 helpers={str(p.relative_to(ROOT)).replace('\\','/'):sha(p) for p in [ROOT/'tools/art/build_portrait_components.py',ROOT/'tools/art/refine_portrait_drawings.py']}
 hp=SOURCE/'authoring-helpers.json'
 if hp.exists():assert json.loads(hp.read_text())==helpers,'Review changed native helper before export'
 else:write(hp,json.dumps(helpers,indent=2)+'\n')
 preserve=SOURCE/'preserved-art.json'
 if not preserve.exists():
  files={}
  for folder in ['art/portraits/dark-elves-v1','data/portraits/dark-elves-v1','art/enemies/dark-elves-v1','art/portraits/mara-layered-v1']:
   for p in (ROOT/folder).rglob('*'):
    if p.is_file() and p.suffix!='.import':files[str(p.relative_to(ROOT)).replace('\\','/')]=sha(p)
  write(preserve,json.dumps(files,indent=2)+'\n')
 entries=[rig(i) for i in FACES];enemy()
 write(OUT/'catalog.json',json.dumps({'issue':131,'portraits':entries,'enemy':uri(ENEMY/'scene.tscn'),'assignment':'Art only: no names, identity, dialogue, recruits, hostility, stats or encounters assigned.'},indent=2)+'\n')
 board=Image.new('RGB',(1152,432),'#202623');draw=ImageDraw.Draw(board)
 zoom=Image.new('RGB',(1536,560),'#202623');zd=ImageDraw.Draw(zoom)
 for row,e in enumerate(entries):
  base=Image.open(ROOT/e['fallback'][6:]).convert('RGBA')
  for col,state in enumerate(['rest','half','closed','small','open','round']):
   im=base.copy()
   if state!='rest':
    im=Image.open(OUT/e['id']/'character-clean.png').convert('RGBA')
    im.alpha_composite(Image.open(OUT/e['id']/('eyes-'+state+'.png' if state in ['half','closed'] else 'eyes-neutral.png')))
    im.alpha_composite(Image.open(OUT/e['id']/('mouth-'+state+'.png' if state in ['small','open','round'] else 'mouth-neutral.png')))
   board.paste(im,(col*192,row*216+24),im);draw.text((col*192+4,row*216+6),e['id']+' '+state,fill='#e6dac1')
   crop=im.crop((79,46,129,89)).resize((250,215),Image.Resampling.NEAREST);zoom.paste(crop,(col*256,row*280+30));zd.text((col*256+4,row*280+6),e['id']+' '+state,fill='#e6dac1')
 save(board,REVIEW/'held-frames.png');save(zoom,REVIEW/'features-enlarged.png')
 print('ELF_EXPORT: two fitted native192 rigs, two blink/three talk frames each; three native128/32-colour combat poses')
if __name__=='__main__':main()

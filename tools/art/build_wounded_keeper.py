"""#166: unique keeper expressions, complete fitted animation and static map pose.

No existing character is replaced. Generated expression edits contribute only
facial regions; hair, ears, garments, silhouette and wound stay byte-stable.
"""
from pathlib import Path
from PIL import Image,ImageChops,ImageDraw
import hashlib,json,sys,base64
sys.dont_write_bytecode=True
import build_portrait_components as C
import refine_portrait_drawings as D
import build_recruit_portraits as kit
ROOT=Path(__file__).resolve().parents[2]
SOURCE=ROOT/'art/source/wounded-keeper-v1';OUT=ROOT/'art/portraits/wounded-keeper-v1'
DATA=ROOT/'data/portraits/wounded-keeper-v1';REVIEW=ROOT/'art/concepts/wounded-keeper-v1'
EMOTIONS=['neutral','pained','defiant']
ORIGINALS={'neutral':'exec-4b2f1cca-5301-4c59-812e-44444b3d7637.png','pained':'exec-d0fe3039-3d83-4af6-b0dc-84c70129738e.png',
 'defiant':'exec-50a2bb68-4681-4a8e-b798-a20ed1b13993.png','map-reading':'exec-7f49db02-9e39-4ac8-b106-117b8d84b2a0.png'}
ORIGINAL_DIR=Path('C:/Users/jonat/.codex/generated_images/01a14858-bf41-7241-a1a3-335ffc204971')
EYE_FOOTPRINTS=[[(79,48),(82,46),(89,46),(94,48),(94,51),(90,53),(82,53),(79,51)],
 [(101,48),(105,46),(113,46),(118,48),(117,52),(112,54),(104,53),(101,51)]]
LIDS=[{'half':[(81,49),(85,49),(89,50),(93,50)],'lower':[(81,50),(85,52),(89,52),(93,50)],'closed':[(81,49),(85,51),(89,52),(93,50)]},
 {'half':[(103,49),(107,50),(112,51),(116,50)],'lower':[(103,51),(107,53),(112,53),(116,51)],'closed':[(103,50),(107,52),(112,53),(116,51)]}]
MOUTH=[(86,68),(90,65),(97,65),(103,67),(106,70),(103,74),(96,75),(89,73),(86,71)]
LIPS={'neutral':[(88,69),(93,68),(97,69),(102,70)],'pained':[(88,69),(93,68),(97,69),(102,70)],'defiant':[(88,69),(93,69),(97,69),(102,70)]}

def write(p,s):p.parent.mkdir(parents=True,exist_ok=True);p.write_text(s,encoding='utf-8',newline='\n')
def uri(p):return 'res://'+p.relative_to(ROOT).as_posix()
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def blank():return Image.new('RGBA',(192,192))
def load(p):return Image.open(p).convert('RGBA')
def save(im,p):
 im=im.copy();im.putdata([v if v[3] else (0,0,0,0) for v in im.get_flattened_data()]);p.parent.mkdir(parents=True,exist_ok=True);im.save(p);return im
def composite(*images):
 result=blank()
 for im in images:result.alpha_composite(im)
 return result
def registered(p):
 raw=load(p);assert raw.width==raw.height
 im=blank();im.alpha_composite(raw.resize((184,184),Image.Resampling.NEAREST),(4,4))
 im.putalpha(im.getchannel('A').point(lambda a:255 if a>=128 else 0));return im
def quantize(im,pal):
 result=im.convert('RGB').quantize(palette=pal,dither=Image.Dither.NONE).convert('RGBA');result.putalpha(im.getchannel('A'));return result

def register_expression(candidate,base):
 anchors=[(92,56,102,64),(62,45,72,59),(125,48,132,58),(88,80,99,88)]
 best=None
 for dy in range(-2,3):
  for dx in range(-2,3):
   moved=blank();moved.paste(candidate,(dx,dy))
   score=sum(sum(abs(a-b) for p,q in zip(base.crop(box).get_flattened_data(),moved.crop(box).get_flattened_data()) for a,b in zip(p[:3],q[:3])) for box in anchors)
   key=(score,abs(dx)+abs(dy),dx,dy)
   if best is None or key<best[0]:best=(key,moved)
 return best[1],list(best[0][2:])

def light_masks(original,folder):
 for kind in ['shadow','highlight']:
  layer=blank()
  for y in range(192):
   for x in range(192):
    if not original.getpixel((x,y))[3]:continue
    a=round(190*min(1,.7*x/192+.3*y/192)) if kind=='shadow' else round(180*max(0,1-x/192)*max(.15,1-y/220))
    c=0 if kind=='shadow' else 255;layer.putpixel((x,y),(c,c,c,a))
  save(layer,folder/(kind+'.png'))

def resource(emotion,animated=True):
 folder=OUT/emotion
 names=['character-clean','eyes-neutral','mouth-neutral','eyes-half','eyes-closed','mouth-small','mouth-open','shadow','highlight'] if animated else ['resting','shadow','highlight']
 text='[gd_resource type="Resource" script_class="PortraitSet" format=3]\n\n[ext_resource type="Script" path="res://scripts/portrait_set.gd" id="script"]\n'
 for n in names:text+='[ext_resource type="Texture2D" path="'+uri(folder/(n+'.png'))+'" id="'+n+'"]\n'
 family='unique-wounded-keeper-v1' if animated else 'unique-wounded-keeper-map-reading-v1'
 text+='\n[resource]\nscript = ExtResource("script")\nrig_kind = "Unique"\nrig_family = &"'+family+'"\nface_id = &"wounded-keeper"\n'
 text+='head = ExtResource("'+('character-clean' if animated else 'resting')+'")\n'
 if animated:text+='eyes = ExtResource("eyes-neutral")\nmouth = ExtResource("mouth-neutral")\nblink_frames = Array[Texture2D]([ExtResource("eyes-half"),ExtResource("eyes-closed")])\ntalk_frames = Array[Texture2D]([ExtResource("mouth-small"),ExtResource("mouth-open")])\n'
 text+='light_shadow = ExtResource("shadow")\nlight_highlight = ExtResource("highlight")\n'
 write(DATA/(emotion+'.tres'),text)

def main():
 for folder in [SOURCE,OUT,DATA,REVIEW]:folder.mkdir(parents=True,exist_ok=True)
 write(SOURCE/'.gdignore','');write(REVIEW/'.gdignore','')
 raw={id:registered(SOURCE/(id+'-master.png')) for id in ORIGINALS}
 pal=kit.make_palette(list(raw.values()),64)
 images={id:quantize(im,pal) for id,im in raw.items()}
 base=save(images['neutral'],OUT/'neutral/resting.png')
 expression_mask=C.merge(C.polygon([(78,41),(88,41),(96,44),(95,54),(90,56),(79,55)]),
  C.polygon([(100,43),(111,40),(120,41),(121,54),(112,57),(100,55)]))
 expression_mask=C.merge(expression_mask,C.polygon(MOUTH))
 expression_mask=ImageChops.multiply(expression_mask,base.getchannel('A'));expression_mask.save(SOURCE/'expression-mask.png')
 manifest={'issue':166,'tool':'image_gen.imagegen (built-in)','prompts':'prompts.json','canvas':[192,192],
  'registration':{'resize_complete_square':[184,184],'inset':[4,4],'palette_colours':64,'expression_changes':'only the pinned brow/eye/lip regions; all other pixels copied from neutral'},'masters':{},'expressions':[],
  'references':{'art/portraits/dark-elves-v1/dark-elf-woman/resting.png':sha(ROOT/'art/portraits/dark-elves-v1/dark-elf-woman/resting.png')}}
 for id,filename in ORIGINALS.items():
  path=SOURCE/(id+'-master.png');original=ORIGINAL_DIR/filename
  if original.exists():assert path.read_bytes()==original.read_bytes(),id
  manifest['masters'][id]={'file':uri(path),'sha256':sha(path),'size':load(path).size,'original_path':str(original),'input':'existing dark-elf-woman style/anatomy reference' if id=='neutral' else 'neutral-master.png edit target'}
 profiles=[]
 for emotion in EMOTIONS:
  folder=OUT/emotion;source=SOURCE/emotion
  folder.mkdir(exist_ok=True);source.mkdir(exist_ok=True)
  shift=[0,0];resting=base.copy()
  if emotion!='neutral':
   candidate,shift=register_expression(images[emotion],base)
   resting.paste(candidate,(0,0),expression_mask)
  resting=save(resting,folder/'resting.png')
  palette=sorted({p for p in resting.get_flattened_data() if p[3]})
  em=C.merge(*[C.polygon(points) for points in EYE_FOOTPRINTS]);em=ImageChops.multiply(em,base.getchannel('A'))
  mm=ImageChops.multiply(C.polygon(MOUTH),base.getchannel('A'))
  clean=C.clean_feature(resting,em,'eye',palette);clean=C.clean_feature(clean,mm,'mouth',palette)
  clean=save(clean,folder/'character-clean.png')
  save(C.full_patch(resting,em),folder/'eyes-neutral.png');save(C.full_patch(resting,mm),folder/'mouth-neutral.png')
  ident='wounded-keeper-'+emotion
  # Same character/anatomical placement; each expression samples its OWN source
  # pixels and owns all blink/talk textures. No neutral expression restoration.
  D.EYES[ident]=json.loads(json.dumps(LIDS));D.FACES[ident]={'lip':LIPS[emotion]}
  for mode in ['half','closed']:
   drawing,iris,lash=D.eyes(ident,resting,clean,em,mode,palette)
   save(C.full_patch(drawing,em),folder/('eyes-'+mode+'.png'))
   iris.save(source/('eyes-'+mode+'-iris.png'));lash.save(source/('eyes-'+mode+'-lash.png'))
  for mode in ['small','open']:
   drawing,cavity,tissue=D.mouth(ident,resting,mm,mode,palette)
   save(C.full_patch(drawing,mm),folder/('mouth-'+mode+'.png'));cavity.save(source/('mouth-'+mode+'-opening.png'))
  em.save(source/'eye-mask.png');mm.save(source/'mouth-mask.png')
  write(source/'contours.json',json.dumps({'eye_footprints':EYE_FOOTPRINTS,'lids':D.EYES[ident],'mouth':MOUTH,'lip':LIPS[emotion]},indent=2)+'\n')
  light_masks(resting,folder);resource(emotion)
  assert composite(clean,load(folder/'eyes-neutral.png'),load(folder/'mouth-neutral.png')).tobytes()==resting.tobytes(),emotion
  paths=list(folder.glob('*.png'))
  manifest['expressions'].append({'id':emotion,'source_shift':shift,'neutral_reconstruction_exact':True,'outputs':{p.name:sha(p) for p in paths}})
  profiles.append({'id':emotion,'kind':'animated-expression','portrait_set':uri(DATA/(emotion+'.tres')),'fallback':uri(folder/'resting.png'),'frames':['rest','half','closed','small','open']})
  kit.SOURCE=SOURCE
  ora=[(n,folder/(n+'.png'),n in ['character-clean','eyes-neutral','mouth-neutral']) for n in ['character-clean','eyes-neutral','mouth-neutral','eyes-half','eyes-closed','mouth-small','mouth-open','shadow','highlight']]
  kit.save_ora(emotion,ora,folder/'resting.png')
 folder=OUT/'map-reading';folder.mkdir(exist_ok=True)
 static=save(images['map-reading'],folder/'resting.png');light_masks(static,folder);resource('map-reading',False)
 kit.SOURCE=SOURCE
 kit.save_ora('map-reading',[(n,folder/(n+'.png'),n=='resting') for n in ['resting','shadow','highlight']],folder/'resting.png')
 profiles.append({'id':'map-reading','kind':'static-pose','portrait_set':uri(DATA/'map-reading.tres'),'fallback':uri(folder/'resting.png'),'frames':['rest']})
 catalog={'issue':166,'identity':'wounded-keeper','rig_kind':'Unique','rig_family':'unique-wounded-keeper-v1','canvas':[192,192],
  'assignment':'Wounded keeper visual identity; no proper name, stats, recruit eligibility or dialogue rewrite assigned. Existing room/conversation hookup remains Claude work.','portraits':profiles}
 write(OUT/'catalog.json',json.dumps(catalog,indent=2)+'\n');write(SOURCE/'generation.json',json.dumps(manifest,indent=2)+'\n')
 board=Image.new('RGB',(768,230),'#252d28');d=ImageDraw.Draw(board)
 for col,profile in enumerate(profiles):
  im=load(ROOT/profile['fallback'].removeprefix('res://'));board.paste(im,(col*192,28),im);d.text((col*192+8,8),profile['id'],fill='#e3d6b8')
 board.save(REVIEW/'overview.png')
 held=Image.new('RGB',(960,648),'#252d28');hd=ImageDraw.Draw(held)
 for row,emotion in enumerate(EMOTIONS):
  folder=OUT/emotion
  for col,state in enumerate(['rest','half','closed','small','open']):
   e='eyes-'+state if state in ['half','closed'] else 'eyes-neutral';m='mouth-'+state if state in ['small','open'] else 'mouth-neutral'
   im=composite(load(folder/'character-clean.png'),load(folder/(e+'.png')),load(folder/(m+'.png')))
   held.paste(im,(col*192,row*216+24),im);hd.text((col*192+5,row*216+5),emotion+' '+state,fill='#e3d6b8')
 held.save(REVIEW/'held-frames.png')
 assets={uri(p):'data:image/png;base64,'+base64.b64encode(p.read_bytes()).decode() for p in OUT.rglob('*.png')}
 if (REVIEW/'layout.html').exists():write(REVIEW/'inspector.html',(REVIEW/'layout.html').read_text(encoding='utf-8').replace('@@data@@',json.dumps({'catalog':catalog,'assets':assets})))
 print('Keeper: three expression-specific animated192 rigs and one static map-reading pose; existing elf art untouched.')

if __name__=='__main__':main()

"""#163: concept-faithful Fixer busts with fitted native face components.

Reuses the accepted #124 texture-preserving lid/lip authoring functions. The
owner's supplied red-coat concepts replace the rejected plain-template drafts.
Preserves each complete generated bust; never substitutes the older jerkin.
"""
from pathlib import Path
from PIL import Image, ImageChops, ImageDraw
import base64, hashlib, json, sys
sys.dont_write_bytecode = True
import build_recruit_portraits as kit
import build_portrait_components as components
import refine_portrait_drawings as drawings

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT/'art/source/fixer-v1'
OUT = ROOT/'art/portraits/fixer-v1'
DATA = ROOT/'data/portraits/fixer-v1'
REVIEW = ROOT/'art/concepts/fixer-v1'
SHARED = ROOT/'art/portraits/recruit-kit-v1/shared'
IDS = ['fixer-a', 'fixer-b', 'fixer-c']
# Complete ocular/lip footprints include the original corners and lashes.
RECIPES = {
 'fixer-a': {'eyes': [(106,56,9,4),(128,63,6,4)],
  'lip': [(99,78),(105,79),(111,81),(117,82),(121,83)],
  'ocular': [
   {'footprint':[(97,53),(101,51),(108,53),(115,56),(117,59),(114,62),(109,62),(101,58),(97,56)],
    'half':[(98,53),(103,55),(109,57),(114,59)],'lower':[(98,55),(103,58),(109,60),(114,60)],'closed':[(98,54),(103,57),(109,59),(114,59)]},
   {'footprint':[(122,59),(125,58),(131,60),(135,63),(134,67),(129,68),(123,65),(121,62)],
    'half':[(123,60),(126,61),(130,63),(133,65)],'lower':[(123,62),(127,65),(131,66),(133,65)],'closed':[(123,61),(126,64),(130,65),(133,65)]}]},
 'fixer-b': {'eyes': [(107,60,9,4),(129,66,6,4)],
  'lip': [(102,82),(108,83),(115,85),(120,86),(124,86)],
  'ocular': [
   {'footprint':[(97,57),(101,54),(108,55),(115,59),(117,62),(112,66),(105,66),(99,62)],
    'half':[(99,57),(104,58),(110,60),(115,61)],'lower':[(99,58),(104,62),(110,64),(115,62)],'closed':[(99,58),(104,61),(110,63),(115,62)]},
   {'footprint':[(121,63),(124,60),(130,61),(135,64),(135,68),(130,71),(124,69),(121,66)],
    'half':[(123,63),(126,63),(131,65),(134,66)],'lower':[(123,65),(127,68),(131,69),(134,67)],'closed':[(123,64),(127,67),(131,68),(134,67)]}]},
 'fixer-c': {'eyes': [(108,56,9,4),(131,64,6,4)],
  'lip': [(101,78),(107,79),(114,81),(120,83),(124,84)],
  'ocular': [
   {'footprint':[(98,52),(103,51),(110,53),(117,57),(117,61),(110,63),(103,60),(98,56)],
    'half':[(99,53),(104,54),(111,57),(116,59)],'lower':[(99,55),(104,58),(111,60),(116,60)],'closed':[(99,54),(104,57),(111,59),(116,59)]},
   {'footprint':[(123,60),(127,59),(133,61),(137,64),(136,68),(131,70),(125,67),(123,63)],
    'half':[(125,61),(128,63),(132,65),(135,66)],'lower':[(125,63),(129,66),(133,68),(135,66)],'closed':[(125,63),(129,66),(133,67),(135,66)]}]},
}

def write(path, text):
 path.parent.mkdir(parents=True, exist_ok=True)
 path.write_text(text, encoding='utf-8', newline='\n')

def uri(path): return 'res://'+path.relative_to(ROOT).as_posix()
def sha(path): return hashlib.sha256(path.read_bytes()).hexdigest()
def load(path): return Image.open(path).convert('RGBA')
def save(im, path):
 # Invisible RGB must not leak when tools ignore alpha in a preview.
 im=im.copy(); im.putdata([p if p[3] else (0,0,0,0) for p in im.get_flattened_data()])
 path.parent.mkdir(parents=True,exist_ok=True); im.save(path)
 return im

def register(path):
 im=kit.register(load(path))
 result=kit.quantize(im,kit.make_palette([im],48))
 result.putdata([p if p[3] else (0,0,0,0) for p in result.get_flattened_data()])
 return result

def feature_recipe(id):
 recipe=RECIPES[id]; masks=[]; eyes=[]
 for cx,cy,rx,ry in recipe['eyes']:
  masks.append(components.polygon([(cx-rx-1,cy),(cx-rx+3,cy-3),
   (cx+rx-3,cy-3),(cx+rx+1,cy-1),(cx+rx+1,cy+2),
   (cx+rx-2,cy+ry+1),(cx-rx+2,cy+ry+1),(cx-rx-1,cy+2)]))
  eyes.append({'half':[(cx-rx,cy-1),(cx-rx//2,cy),(cx+1,cy),(cx+rx-1,cy-1)],
   'lower':[(cx-rx,cy),(cx-rx//2,cy+2),(cx+2,cy+3),(cx+rx-1,cy)],
   'closed':[(cx-rx,cy),(cx-rx//2,cy+2),(cx+1,cy+2),(cx+rx-1,cy)]})
 if 'ocular' in recipe:
  masks=[components.polygon(e['footprint']) for e in recipe['ocular']]
  eyes=[{name:e[name] for name in ['half','lower','closed']} for e in recipe['ocular']]
 em=ImageChops.lighter(*masks)
 seam=recipe['lip']; left=seam[0][0]-3; right=seam[-1][0]+3
 top=min(y for x,y in seam)-4; bottom=max(y for x,y in seam)+6
 mm=components.polygon([(left,top+2),(left+4,top),(right-4,top),
  (right,top+3),(right,bottom-2),(right-4,bottom),(left+4,bottom),(left,bottom-2)])
 drawings.EYES[id]=eyes
 drawings.FACES[id]={'lip':seam}
 return em,mm

def resource(id):
 folder=OUT/id
 names={'body':folder/'body.png','head':folder/'head-clean.png',
  'eyes':folder/'eyes-neutral.png','mouth':folder/'mouth-neutral.png'}
 names.update({n:folder/(n+'.png') for n in ['eyes-half','eyes-closed','mouth-small','mouth-open',
  'blood','dirt','bandage','pallor','shadow-left','highlight-left']})
 lines=['[gd_resource type="Resource" script_class="PortraitSet" format=3]','',
  '[ext_resource type="Script" path="res://scripts/portrait_set.gd" id="script"]']
 lines += ['[ext_resource type="Texture2D" path="'+uri(p)+'" id="'+n+'"]' for n,p in names.items()]
 lines += ['','[resource]','script = ExtResource("script")','rig_kind = "Unique"',
  'rig_family = &"unique-'+id+'-v1"','face_id = &"'+id+'"']
 lines += [n+' = ExtResource("'+n+'")' for n in ['body','head','eyes','mouth']]
 lines += ['conditions = {'+', '.join('"'+n+'": ExtResource("'+n+'")' for n in kit.CONDITIONS)+'}',
  'blink_frames = Array[Texture2D]([ExtResource("eyes-half"), ExtResource("eyes-closed")])',
  'talk_frames = Array[Texture2D]([ExtResource("mouth-small"), ExtResource("mouth-open")])',
  'light_shadow = ExtResource("shadow-left")','light_highlight = ExtResource("highlight-left")']
 write(DATA/(id+'.tres'),'\n'.join(lines)+'\n')

def gallery(profiles):
 assets={}
 for p in OUT.rglob('*.png'):
  assets[uri(p)]='data:image/png;base64,'+base64.b64encode(p.read_bytes()).decode()
 payload={'portraits':profiles,'assets':assets,'out':uri(OUT)}
 html=(REVIEW/'layout.html').read_text(encoding='utf-8').replace('@@data@@',json.dumps(payload))
 write(REVIEW/'inspector.html',html)

def main():
 for p in [OUT,DATA,REVIEW]: p.mkdir(parents=True,exist_ok=True)
 write(SOURCE/'.gdignore','');write(REVIEW/'.gdignore','')
 masters={id:register(SOURCE/(id+'-master.png')) for id in IDS}
 profiles=[]; report={'issue':163,'canvas':[192,192],'method':'Generated masters; full-square 184px resize with 4px inset; native face-specific v4 lid/lip fitting.',
  'masters':{},'faces':[],'failures':[]}
 report['shared_inputs']={uri(p):sha(p) for p in [SHARED/'body.png',SHARED/'jerkin.png']}
 source_paths={'a':'exec-00bdb431-5077-4a1c-9d44-e2bf59b20cb0.png',
  'b':'exec-3b469114-6671-4711-8f62-7e578aa9a88e.png','c':'exec-b452fe25-dea1-4801-a435-9e3e3497df7a.png'}
 for id,base in masters.items():
  folder=OUT/id; folder.mkdir(exist_ok=True)
  raw=SOURCE/(id+'-master.png')
  report['masters'][id]={'file':uri(raw),'sha256':sha(raw),'size':load(raw).size,
   'original_path':'C:/Users/jonat/.codex/generated_images/01a14858-bf41-7241-a1a3-335ffc204971/'+source_paths[id[-1]]}
  # Lossless integer split of the registered master. This is a layer boundary,
  # not an anatomical socket: both parts are unique to this exact drawing.
  body=kit.blank();body.paste(base.crop((0,135,192,192)),(0,135));body=save(body,folder/'body.png')
  head=base.copy(); alpha=head.getchannel('A')
  ImageDraw.Draw(alpha).rectangle((0,135,191,191),fill=0)
  head.putalpha(alpha); head=save(head,folder/'head.png')
  palette=sorted({p for p in head.get_flattened_data() if p[3]})
  em,mm=feature_recipe(id)
  em=ImageChops.multiply(em,alpha);mm=ImageChops.multiply(mm,alpha)
  assert not ImageChops.multiply(em,mm).getbbox()
  clean=components.clean_feature(head,em,'eyes',palette)
  clean=components.clean_feature(clean,mm,'mouth',palette)
  clean=save(clean,folder/'head-clean.png')
  em.save(SOURCE/(id+'-eye-matte.png'));mm.save(SOURCE/(id+'-mouth-matte.png'))
  layers={'eyes-neutral':components.full_patch(head,em),'mouth-neutral':components.full_patch(head,mm)}
  for mode in ['half','closed']:
   full,iris,lash=drawings.eyes(id,head,clean,em,mode,palette)
   layers['eyes-'+mode]=components.full_patch(full,em)
   iris.save(SOURCE/(id+'-'+mode+'-iris.png'));lash.save(SOURCE/(id+'-'+mode+'-lash.png'))
  for mode in ['small','open']:
   full,cavity,tissue=drawings.mouth(id,head,mm,mode,palette)
   layers['mouth-'+mode]=components.full_patch(full,mm)
   cavity.save(SOURCE/(id+'-'+mode+'-cavity.png'))
  for name,im in layers.items(): layers[name]=save(im,folder/(name+'.png'))
  restored=kit.composite([clean,layers['eyes-neutral'],layers['mouth-neutral']])
  assert restored.tobytes()==head.tobytes(),id+' neutral must reconstruct exactly'
  neutral=kit.composite([body,restored]);neutral=save(neutral,folder/'preview.png')
  assert neutral.tobytes()==base.tobytes(),id+' complete registered concept is preserved'
  clip=neutral.getchannel('A')
  for name in ['blood','dirt','bandage']:
   overlay=load(ROOT/'art/portraits/recruit-roster-v1/warden-b'/(name+'.png'))
   shifted=kit.blank()
   if name=='bandage':
    mark=overlay.crop(overlay.getchannel('A').getbbox());mark.thumbnail((20,6),Image.Resampling.NEAREST)
    shifted.paste(mark,(112,43 if id=='fixer-b' else 39))
   else:shifted.paste(overlay,(0,-8))
   overlay=shifted
   overlay.putalpha(ImageChops.multiply(overlay.getchannel('A'),clip))
   save(overlay,folder/(name+'.png'))
  pallor=kit.blank(); skin=Image.new('L',(192,192))
  for y in range(22,min(135,max(y for x,y in RECIPES[id]['lip'])+20)):
   for x in range(48,139):
    p=head.getpixel((x,y))
    if p[3] and p[0]-p[2]>20 and 1.08<p[0]/max(1,p[1])<1.9 and p[0]>65:
     pallor.putpixel((x,y),(168,178,153,65));skin.putpixel((x,y),255)
  save(pallor,folder/'pallor.png')
  for name in ['shadow-left','highlight-left']:
   light=kit.blank()
   for y in range(192):
    for x in range(192):
     if not clip.getpixel((x,y)):continue
     # Low frequency image-left coverage; no material colour baked into masks.
     t=max(0,min(1,(x/192*.8+y/192*.2)))
     a=round(180*t) if name=='shadow-left' else round(190*(1-t))
     c=0 if name=='shadow-left' else 255
     light.putpixel((x,y),(c,c,c,a))
   save(light,folder/(name+'.png'))
  resource(id)
  profiles.append({'id':id,'role':'Fixer','portrait':uri(folder/'preview.png'),
   'portrait_set':uri(DATA/(id+'.tres')),'expressions':['neutral'],
   'shadow':uri(folder/'shadow-left.png'),'highlight':uri(folder/'highlight-left.png')})
  report['faces'].append({'id':id,'recipe':RECIPES[id],'neutral_reconstruction_exact':True,
   'feature_pixels':{'eyes':sum(v>0 for v in em.get_flattened_data()),'mouth':sum(v>0 for v in mm.get_flattened_data())},
   'outputs':{p.name:{'sha256':sha(p),'size':load(p).size,'colours':len({v[:3] for v in load(p).get_flattened_data() if v[3]})} for p in folder.glob('*.png')}})
  kit.SOURCE=SOURCE
  ora=[('Own clothed lower bust',folder/'body.png',True),('Clean upper character',folder/'head-clean.png',True),
   ('Eyes neutral',folder/'eyes-neutral.png',True),('Mouth neutral',folder/'mouth-neutral.png',True),
   ]
  ora += [(n,folder/(n+'.png'),False) for n in ['eyes-half','eyes-closed','mouth-small','mouth-open']+kit.CONDITIONS+['shadow-left','highlight-left']]
  kit.save_ora(id,ora,folder/'preview.png')
 catalog_path=ROOT/'art/portraits/recruit-roster-v1/catalog.json'
 catalog=json.loads(catalog_path.read_text(encoding='utf-8'))
 catalog['portraits']=[p for p in catalog['portraits'] if p['id'] not in IDS]+profiles
 catalog['by_role']['Fixer']=IDS
 write(catalog_path,json.dumps(catalog,indent=2)+'\n')
 write(OUT/'catalog.json',json.dumps({'canvas':[192,192],'issue':163,'portraits':profiles},indent=2)+'\n')
 write(SOURCE/'generation.json',json.dumps({'tool':'image_gen.imagegen (built-in)',
  'prompt_file':'prompts.json','masters':report['masters'],
  'references':{uri(p):sha(p) for p in [SOURCE/'references/male-concept.png',SOURCE/'references/female-concept.png']},
  'c_additional_reference':{'file':uri(SOURCE/'fixer-a-master.png'),'sha256':sha(SOURCE/'fixer-a-master.png'),'role':'Costume, scale and pixel style; not identity'},
  'owner_reference_provenance':{'supplied':'2026-10-27','description':'Owner identified these as previously generated Fixer concepts; original generation prompts were not supplied.',
   'male_clipboard_original':'C:/Users/jonat/AppData/Local/Temp/codex-clipboard-fa76d361-a1be-42db-9789-b31e94c73c49.png',
   'female_clipboard_original':'C:/Users/jonat/AppData/Local/Temp/codex-clipboard-88ce502b-0401-4d20-aabd-1c1309b1b376.png'},
  'export_method':report['method'],'recipes':RECIPES},indent=2)+'\n')
 write(REVIEW/'asset-validation.json',json.dumps(report,indent=2)+'\n')
 states=['neutral','eyes-half','eyes-closed','mouth-small','mouth-open']
 board=Image.new('RGBA',(192*5,216*3),'#202821');card=Image.new('RGBA',(96*5,120*3),'#202821')
 for row,id in enumerate(IDS):
  folder=OUT/id
  for col,state in enumerate(states):
   e=state if state.startswith('eyes-') else 'eyes-neutral'
   m=state if state.startswith('mouth-') else 'mouth-neutral'
   im=kit.composite([load(folder/'body.png'),load(folder/'head-clean.png'),load(folder/(e+'.png')),load(folder/(m+'.png'))])
   save(im,REVIEW/(id+'-'+state+'.png'))
   board.alpha_composite(im,(col*192,row*216+24))
   ImageDraw.Draw(board).text((col*192+4,row*216+4),id+' '+state,fill='#dfd4bc')
   card.alpha_composite(im.resize((96,96),Image.Resampling.NEAREST),(col*96,row*120+24))
   ImageDraw.Draw(card).text((col*96+3,row*120+4),id,fill='#dfd4bc')
 board.convert('RGB').save(REVIEW/'all-frames.png');card.convert('RGB').save(REVIEW/'cards-96.png')
 overview=Image.new('RGBA',(192*3,216),'#202821')
 for i,id in enumerate(IDS):
  overview.alpha_composite(load(OUT/id/'preview.png'),(i*192,24))
  ImageDraw.Draw(overview).text((i*192+8,6),id,fill='#dfd4bc')
 overview.convert('RGB').save(REVIEW/'overview.png')
 # Art-derived silhouette, visibly carrying the same ledger and purse.
 silhouette=Image.new('RGBA',(192,192),(14,13,12,0));silhouette.putalpha(load(OUT/'fixer-a/preview.png').getchannel('A'))
 # Retain low-contrast coat lapels/strap in the fallback, keeping its role read.
 muted=load(OUT/'fixer-a/preview.png')
 for y in range(192):
  for x in range(192):
   p=muted.getpixel((x,y));muted.putpixel((x,y),(round(p[0]*.32),round(p[1]*.32),round(p[2]*.32),p[3] if y>=105 else 0))
 silhouette.alpha_composite(muted)
 silhouette=Image.alpha_composite(Image.new('RGBA',(192,192),'#302b23'),silhouette)
 save(silhouette,ROOT/'art/portraits/recruit-silhouettes-v1/fixer.png')
 gallery(profiles)
 print('Three concept-faithful Fixer busts; native face-specific masks and exact registered-master reconstruction.')

if __name__=='__main__':main()

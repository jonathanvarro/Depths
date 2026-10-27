"""#163: register three generated Fixer masters; fit native face components.

Reuses the accepted #124 texture-preserving lid/lip authoring functions. Never
rewrites old faces or the shared body. All coordinates are native 192px.
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
 'fixer-a': {'eyes': [(100,69,9,4), (123,70,6,4)],
             'lip': [(104,95),(110,94),(117,95),(124,96)]},
 'fixer-b': {'eyes': [(100,68,9,4), (123,69,6,4)],
             'lip': [(104,94),(111,93),(118,94),(124,95)]},
 'fixer-c': {'eyes': [(100,67,9,4), (123,68,6,4)],
             'lip': [(102,94),(110,93),(117,94),(123,95)]},
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
 return kit.quantize(im,kit.make_palette([im],48))

def feature_recipe(id):
 recipe=RECIPES[id]; masks=[]; eyes=[]
 for cx,cy,rx,ry in recipe['eyes']:
  masks.append(components.polygon([(cx-rx-1,cy),(cx-rx+3,cy-3),
   (cx+rx-3,cy-3),(cx+rx+1,cy-1),(cx+rx+1,cy+2),
   (cx+rx-2,cy+ry+1),(cx-rx+2,cy+ry+1),(cx-rx-1,cy+2)]))
  eyes.append({'half':[(cx-rx,cy-1),(cx-rx//2,cy),(cx+1,cy),(cx+rx-1,cy-1)],
   'lower':[(cx-rx,cy),(cx-rx//2,cy+2),(cx+2,cy+3),(cx+rx-1,cy)],
   'closed':[(cx-rx,cy),(cx-rx//2,cy+2),(cx+1,cy+2),(cx+rx-1,cy)]})
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
 names={'body':SHARED/'body.png','head':folder/'head-clean.png',
  'eyes':folder/'eyes-neutral.png','mouth':folder/'mouth-neutral.png',
  'jerkin':SHARED/'jerkin.png','trade':OUT/'shared/trade-kit.png'}
 names.update({n:folder/(n+'.png') for n in ['eyes-half','eyes-closed','mouth-small','mouth-open',
  'blood','dirt','bandage','pallor','shadow-left','highlight-left']})
 lines=['[gd_resource type="Resource" script_class="PortraitSet" format=3]','',
  '[ext_resource type="Script" path="res://scripts/portrait_set.gd" id="script"]']
 lines += ['[ext_resource type="Texture2D" path="'+uri(p)+'" id="'+n+'"]' for n,p in names.items()]
 lines += ['','[resource]','script = ExtResource("script")','rig_kind = "Reusable"',
  'rig_family = &"average-covered-adult-v1"','face_id = &"'+id+'"']
 lines += [n+' = ExtResource("'+n+'")' for n in ['body','head','eyes','mouth']]
 lines += ['clothing = Array[Texture2D]([ExtResource("jerkin")])',
  'front = Array[Texture2D]([ExtResource("trade")])',
  'conditions = {'+', '.join('"'+n+'": ExtResource("'+n+'")' for n in kit.CONDITIONS)+'}',
  'blink_frames = Array[Texture2D]([ExtResource("eyes-half"), ExtResource("eyes-closed")])',
  'talk_frames = Array[Texture2D]([ExtResource("mouth-small"), ExtResource("mouth-open")])',
  'light_shadow = ExtResource("shadow-left")','light_highlight = ExtResource("highlight-left")']
 write(DATA/(id+'.tres'),'\n'.join(lines)+'\n')

def gallery(profiles):
 assets={}
 for p in list(OUT.rglob('*.png'))+[SHARED/'body.png',SHARED/'jerkin.png']:
  assets[uri(p)]='data:image/png;base64,'+base64.b64encode(p.read_bytes()).decode()
 payload={'portraits':profiles,'assets':assets,'shared':uri(SHARED), 'out':uri(OUT)}
 html=(REVIEW/'layout.html').read_text(encoding='utf-8').replace('@@data@@',json.dumps(payload))
 write(REVIEW/'inspector.html',html)

def main():
 for p in [OUT,DATA,REVIEW]: p.mkdir(parents=True,exist_ok=True)
 write(SOURCE/'.gdignore','');write(REVIEW/'.gdignore','')
 body=load(SHARED/'body.png'); outfit=load(SHARED/'jerkin.png')
 template=kit.register(load(ROOT/'art/source/recruit-kit-v1/master-a.png'))
 socket=ImageChops.subtract(kit.alpha(template),body.getchannel('A'))
 masters={id:register(SOURCE/(id+'-master.png')) for id in IDS}
 # Same generated trade accessories on the existing covered body, not three
 # almost-identical generated torsos. No changes to the older clothing pixels.
 accessory_mask=components.polygon([(34,130),(44,128),(96,177),(100,188),(80,188),(30,140)])
 for polygon in [[(45,155),(55,157),(76,170),(79,188),(43,188)],
                 [(88,174),(100,173),(109,188),(85,188)]]:
  accessory_mask=ImageChops.lighter(accessory_mask,components.polygon(polygon))
 trade=components.full_patch(masters['fixer-a'],accessory_mask)
 trade=save(trade,OUT/'shared/trade-kit.png')
 profiles=[]; report={'issue':163,'canvas':[192,192],'method':'Generated masters; full-square 184px resize with 4px inset; native face-specific v4 lid/lip fitting.',
  'masters':{},'faces':[],'failures':[]}
 report['shared_inputs']={uri(p):sha(p) for p in [SHARED/'body.png',SHARED/'jerkin.png']}
 source_paths={'a':'exec-6edf7b86-fad4-4c6c-90c5-7bc60033f547.png',
  'b':'exec-b4da4e9e-0457-4179-80f0-e47c66faa59d.png','c':'exec-7369935c-85f1-4b06-9464-4c056455df72.png'}
 for id,base in masters.items():
  folder=OUT/id; folder.mkdir(exist_ok=True)
  raw=SOURCE/(id+'-master.png')
  report['masters'][id]={'file':uri(raw),'sha256':sha(raw),'size':load(raw).size,
   'original_path':'C:/Users/jonat/.codex/generated_images/01a14858-bf41-7241-a1a3-335ffc204971/'+source_paths[id[-1]]}
  head=base.copy(); alpha=head.getchannel('A')
  for y in range(113,192):
   for x in range(192): alpha.putpixel((x,y),min(alpha.getpixel((x,y)),socket.getpixel((x,y))))
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
  neutral=kit.composite([body,restored,outfit,trade]);neutral=save(neutral,folder/'preview.png')
  clip=neutral.getchannel('A')
  for name in ['blood','dirt','bandage']:
   overlay=load(ROOT/'art/portraits/recruit-roster-v1/warden-b'/(name+'.png'))
   overlay.putalpha(ImageChops.multiply(overlay.getchannel('A'),clip))
   save(overlay,folder/(name+'.png'))
  pallor=kit.blank(); skin=Image.new('L',(192,192))
  for y in range(32,139):
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
  ora=[('Shared body',SHARED/'body.png',True),('Clean head',folder/'head-clean.png',True),
   ('Eyes neutral',folder/'eyes-neutral.png',True),('Mouth neutral',folder/'mouth-neutral.png',True),
   ('Shared jerkin',SHARED/'jerkin.png',True),('Shared trader kit',OUT/'shared/trade-kit.png',True)]
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
  'references':{uri(p):sha(p) for p in [ROOT/'art/portraits/recruit-roster-v1/warden-b/preview.png',ROOT/'art/portraits/recruit-kit-v1/scout-a/preview.png']},
  'b_c_additional_reference':{'file':uri(SOURCE/'fixer-a-master.png'),'sha256':sha(SOURCE/'fixer-a-master.png'),'role':'Shared garment/registration, not identity'},
  'export_method':report['method'],'recipes':RECIPES},indent=2)+'\n')
 write(REVIEW/'asset-validation.json',json.dumps(report,indent=2)+'\n')
 states=['neutral','eyes-half','eyes-closed','mouth-small','mouth-open']
 board=Image.new('RGBA',(192*5,216*3),'#202821');card=Image.new('RGBA',(96*5,120*3),'#202821')
 for row,id in enumerate(IDS):
  folder=OUT/id
  for col,state in enumerate(states):
   e=state if state.startswith('eyes-') else 'eyes-neutral'
   m=state if state.startswith('mouth-') else 'mouth-neutral'
   im=kit.composite([body,load(folder/'head-clean.png'),load(folder/(e+'.png')),load(folder/(m+'.png')),outfit,trade])
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
 muted=trade.copy()
 muted.putdata([(min(105,round(p[0]*.52)),min(91,round(p[1]*.52)),min(70,round(p[2]*.52)),p[3]) for p in muted.get_flattened_data()])
 silhouette.alpha_composite(muted)
 silhouette=Image.alpha_composite(Image.new('RGBA',(192,192),'#302b23'),silhouette)
 save(silhouette,ROOT/'art/portraits/recruit-silhouettes-v1/fixer.png')
 gallery(profiles)
 print('Three Fixer portraits exported; native face-specific masks, exact resting reconstruction and shared trade kit.')

if __name__=='__main__':main()

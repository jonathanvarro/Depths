"""#124: fitted native texture/lip edits inside the accepted v3 component mattes.

Original resting faces, clean plates, neutral components and timing are read-only.
Mouth tissue comes from the original lips, with a small locally fitted opening;
half lids retain the original lower iris. No generated face or atlas is used.
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageChops, ImageFilter
import argparse, copy, hashlib, json, math, sys
sys.dont_write_bytecode=True
from build_portrait_components import FACES, nearest, polygon, full_patch, lip_y

ROOT=Path(__file__).resolve().parents[2]
REVIEW=ROOT/'art/concepts/portrait-drawings-v4'
SOURCE=ROOT/'art/source/portrait-drawings-v4'
V3=ROOT/'art/concepts/portrait-components-v3/components.json'

# Each eye has a lowered lid, its actual lower globe boundary, and a closed arc.
# Corin's far eye ends at x128, before the profile turns onto the side cheek.
EYES={
 'mara':[
  {'half':[(87,69),(92,69),(98,70),(104,70),(106,70)],'lower':[(87,70),(92,73),(98,74),(104,73),(106,70)],'closed':[(87,69),(92,71),(98,72),(104,71),(106,70)]},
  {'half':[(115,70),(120,70),(126,71),(132,70),(134,70)],'lower':[(115,71),(120,74),(126,75),(132,73),(134,70)],'closed':[(115,70),(120,71),(126,72),(132,71),(134,70)]}],
 'corin':[
  {'half':[(87,66),(92,66),(97,67),(102,68)],'lower':[(87,67),(92,69),(97,70),(102,68)],'closed':[(87,66),(92,68),(98,69),(103,68)]},
  {'half':[(114,68),(118,69),(123,70),(128,70)],'lower':[(114,69),(119,72),(124,73),(128,71)],'closed':[(114,69),(119,71),(124,72),(128,71)]}],
 'alwen':[
  {'half':[(93,68),(97,69),(102,69),(107,69)],'lower':[(93,69),(98,72),(104,73),(108,70)],'closed':[(93,69),(97,71),(102,72),(107,70)]},
  {'half':[(116,68),(121,69),(126,69),(132,69)],'lower':[(116,69),(121,72),(127,73),(133,70)],'closed':[(116,69),(121,71),(127,72),(132,70)]}]
}
for face,spec in FACES.items():
 if face in EYES:continue
 EYES[face]=[]
 for footprint,old in spec['eyes']:
  cx=round((old[0][0]+old[-1][0])/2);cy=old[0][1]+1
  EYES[face].append({'half':[(cx-10,cy-1),(cx-5,cy-1),(cx+1,cy),(cx+7,cy),(cx+10,cy-1)],
   'lower':[(cx-10,cy),(cx-5,cy+3),(cx+2,cy+4),(cx+7,cy+2),(cx+10,cy)],
   'closed':[(cx-10,cy),(cx-5,cy+2),(cx+1,cy+3),(cx+7,cy+1),(cx+10,cy)]})

# The halfway drawing leaves two to three native rows of the lower iris.
for eye_pair in EYES.values():
 for eye in eye_pair:eye['half']=[(x,y-1) for x,y in eye['half']]

def local(uri):return ROOT/uri.removeprefix('res://')
def uri(path):return 'res://'+path.relative_to(ROOT).as_posix()
def load(path):return Image.open(local(path)).convert('RGBA')
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def write(path,text):
 path.parent.mkdir(parents=True,exist_ok=True);path.write_text(text,encoding='utf-8',newline='\n')
def line_points(path):
 return [(x,lip_y(path,x)) for x in range(path[0][0],path[-1][0]+1)]

def eyes(face,original,clean,mask,mode,palette):
 result=clean.copy();visible=Image.new('L',(192,192));lashes=Image.new('L',(192,192))
 smooth=original.filter(ImageFilter.GaussianBlur(1))
 for eye in EYES[face]:
  path=eye[mode];cx=(path[0][0]+path[-1][0])/2;rx=(path[-1][0]-path[0][0])/2
  for y in range(mask.getbbox()[1],mask.getbbox()[3]):
   for x in range(max(0,path[0][0]-2),min(192,path[-1][0]+3)):
    if not mask.getpixel((x,y)):continue
    edge=lip_y(path,max(path[0][0],min(path[-1][0],x)))
    lower=lip_y(eye['lower'],max(eye['lower'][0][0],min(eye['lower'][-1][0],x)))
    if y>lower+1:
     result.putpixel((x,y),original.getpixel((x,y)));continue
    if not edge-5<=y<=edge+2:continue
    c=clean.getpixel((x,y));donor=(x,min(191,mask.getbbox()[3]+1+(y%3)))
    a=original.getpixel(donor);b=smooth.getpixel(donor)
    dome=max(0,1-((x-cx)/(rx+2))**2)
    shade=7*dome*math.exp(-((y-edge+2)/1.7)**2)-3*math.exp(-((y-edge)/.8)**2)
    lift=.65*dome*math.exp(-((y-edge+1.7)/2)**2)
    result.putpixel((x,y),nearest(palette,[c[i]*(1-lift)+.83*a[i]*lift+shade+.45*(a[i]-b[i]) for i in range(3)]))
  if mode=='half':
   slit=ImageChops.multiply(polygon(eye['half']+list(reversed(eye['lower']))),mask)
   result.paste(original,(0,0),slit);visible=ImageChops.lighter(visible,slit)
  # The crease uses native skin shadows, separated from a tapered lash arc.
  for x,y in line_points(path):
   if not mask.getpixel((x,y)):continue
   u=abs((x-cx)/(rx or 1));skin=result.getpixel((x,y))
   amount=.48 if u<.8 else .28
   ink=nearest(palette,[skin[i]*(1-amount)+(42,28,23)[i]*amount for i in range(3)])
   result.putpixel((x,y),ink);lashes.putpixel((x,y),255)
   if mode=='closed' and u<.65 and mask.getpixel((x,y-3)):
    skin=result.getpixel((x,y-3));result.putpixel((x,y-3),nearest(palette,[v*.94 for v in skin[:3]]))
 visible=ImageChops.subtract(visible,lashes)
 return result,visible,lashes

def mouth(face,original,mask,mode,palette):
 # Inverse-map the original upper/lower lip tissue around a modest opening.
 # Sampling remains at native pixels; no blur is applied to skin or beard.
 result=original.copy();cavity=Image.new('L',(192,192));tissue=Image.new('L',(192,192))
 seam=FACES[face]['lip'];left,right=seam[0][0],seam[-1][0];cx=(left+right)/2;cy=lip_y(seam,round(cx));width=(right-left)/2
 scale={'small':.98,'open':.94,'round':.72}[mode]
 depth={'small':1.0,'open':2.4,'round':1.6}[mode]
 radius=width*{'small':.38,'open':.63,'round':.44}[mode]
 bounds=mask.getbbox()
 for x in range(bounds[0],bounds[2]):
  ys=[y for y in range(bounds[1],bounds[3]) if mask.getpixel((x,y))]
  if not ys:continue
  for y in ys:
   # Horizontal contraction fades into the existing moustache/cheek texture.
   fall=max(0,1-abs(y-cy)/5)
   sx=round(cx+(x-cx)/(1-(1-scale)*fall));sx=max(0,min(191,sx))
   line=lip_y(seam,max(left,min(right,sx)))
   dx=(x-cx)/(radius or 1);gap=depth*math.sqrt(max(0,1-dx*dx))
   target_line=lip_y(seam,max(left,min(right,sx)))
   if y>=target_line:
    fade=max(0,min(1,(max(ys)-y)/max(1,max(ys)-target_line-gap)))
    sy=round(y-gap*fade)
   else:sy=y
   sy=max(0,min(191,sy));sample=original.getpixel((sx,sy))
   result.putpixel((x,y),sample if sample[3] else original.getpixel((x,y)))
   if (sx,sy)!=(x,y):tissue.putpixel((x,y),255)
   if abs(dx)<1 and target_line<=y<target_line+gap:
    # Warm shaded cavity, brightest at the lower inner lip; no flat black bar.
    t=(y-target_line)/max(1,gap)
    texture=original.getpixel((sx,max(0,target_line-1)))
    rgb=[(47,29,24)[i]*(1-t)+(88,47,37)[i]*t+.08*(texture[i]-(132,88,62)[i]) for i in range(3)]
    result.putpixel((x,y),nearest(palette,rgb));cavity.putpixel((x,y),255)
 # A short, subdued tooth hint. Corin's front gap is explicitly kept dark.
 if mode=='open':
  teeth=[round(cx)-3,round(cx)-2,round(cx)+2,round(cx)+3] if face=='corin' else [round(cx)-2,round(cx)-1,round(cx)+1]
  for x in teeth:
   sx=round(cx+(x-cx)/scale);y=lip_y(seam,max(left,min(right,sx)))
   if cavity.getpixel((x,y)):
    result.putpixel((x,y),nearest(palette,(174,143,110)))
 # Reapply the fixed matte; skin boundaries and original silhouette stay exact.
 return result,cavity,tissue

def main():
 parser=argparse.ArgumentParser();parser.add_argument('--wire',action='store_true');args=parser.parse_args()
 original_manifest=json.loads(V3.read_text(encoding='utf-8'));manifest=copy.deepcopy(original_manifest)
 manifest.update({'issue':124,'revision':'textured-drawings-v4','status':'live' if args.wire else 'candidate',
  'v3_manifest_sha256':sha(V3),'method':'Native resting lip tissue around fitted openings; curved textured eyelids with original lower iris retained.'})
 write(SOURCE/'.gdignore','');write(REVIEW/'.gdignore','')
 board=Image.new('RGB',(192*6,216*12),'#202821');bd=ImageDraw.Draw(board)
 card=Image.new('RGB',(96*6,120*12),'#202821');cd=ImageDraw.Draw(card)
 enlarged=Image.new('RGB',(384*6,248*12),'#202821');ed=ImageDraw.Draw(enlarged)
 for row,face in enumerate(manifest['faces']):
  name=face['face'];original=load(face['original']);clean=load(face['clean']);palette=sorted({p for p in original.get_flattened_data() if p[3]})
  for path,h in face['input_layers'].items():assert sha(local(path))==h,(name,'Original artwork changed',path)
  eye_mask=Image.open(local(face['eye_mask'])).convert('L');mouth_mask=Image.open(local(face['mouth_mask'])).convert('L')
  old_outputs={p['name']:p for p in face['outputs']};parent=local(old_outputs['eyes-half']['texture']).parent.parent
  dest=parent/'frames-pixel-v4';dest.mkdir(exist_ok=True);source=SOURCE/name;source.mkdir(parents=True,exist_ok=True)
  displays={'neutral':original};new_outputs=[];bindings=face['bindings']
  for part in face['outputs']:
   kind=part['name']
   if kind in ['clean-character','eyes-neutral','mouth-neutral']:
    new_outputs.append(part);continue
   if kind.startswith('eyes-'):
    image,visible,stroke=eyes(name,original,clean,eye_mask,kind.split('-')[1],palette);mask=eye_mask
    visible.save(source/(kind+'-iris.png'));stroke.save(source/(kind+'-lash.png'))
    extra={'iris':uri(source/(kind+'-iris.png')),'lash':uri(source/(kind+'-lash.png'))}
   else:
    image,opening,moved=mouth(name,original,mouth_mask,kind.split('-')[1],palette);mask=mouth_mask
    opening.save(source/(kind+'-opening.png'));moved.save(source/(kind+'-tissue.png'))
    extra={'opening':uri(source/(kind+'-opening.png')),'tissue':uri(source/(kind+'-tissue.png'))}
   path=dest/(kind+'.png');full_patch(image,mask).save(path)
   new_outputs.append({'name':kind,'texture':uri(path),'sha256':sha(path),**extra})
   for old,new in list(bindings.items()):
    if new==part['texture']:bindings[old]=uri(path)
   bindings[part['texture']]=uri(path)
   display=original.copy();display.paste(image,(0,0),mask);displays[kind]=display
  face['outputs']=new_outputs;face['drawing_recipe']={'eyes':EYES[name],'lip':FACES[name]['lip'],'talk_shapes':3 if name in ['mara','corin','alwen'] else 2}
  write(source/'recipe.json',json.dumps(face['drawing_recipe'],indent=2)+'\n')
  if name=='mara':
   compare=Image.new('RGB',(800,390),'#202821');draw=ImageDraw.Draw(compare)
   for col,title in enumerate(['Previous v3 drawings','Refined v4 lip texture and lids']):
    draw.text((col*400+16,12),title,fill='#dfd4bc')
    for kind,box,y in [('eyes-closed',(80,55,141,85),42),('mouth-open',(92,93,128,112),250)]:
     image=original.copy()
     if col==0:image.alpha_composite(load(old_outputs[kind]['texture']))
     else:image=displays[kind]
     crop=image.crop(box);compare.paste(crop.resize((crop.width*6,crop.height*6),Image.Resampling.NEAREST),(col*400+16,y))
   compare.save(REVIEW/'mara-before-after.png')
  for col,kind in enumerate(['neutral','eyes-half','eyes-closed','mouth-small','mouth-open','mouth-round']):
   if kind not in displays:
    for canvas,draw,w,h in [(board,bd,192,216),(card,cd,96,120),(enlarged,ed,384,248)]:draw.text((col*w+4,row*h+4),'Not authored: 2 talk shapes',fill='#b7aa94')
    continue
   display=displays[kind]
   board.paste(display,(col*192,row*216+24),display);bd.text((col*192+4,row*216+4),name+' '+kind,fill='#dfd4bc')
   small=display.resize((96,96),Image.Resampling.NEAREST);card.paste(small,(col*96,row*120+24),small);cd.text((col*96+2,row*120+3),name,fill='#dfd4bc')
   # A separate eye and mouth crop fits a compact enlarged inspection row.
   enlarged.paste(display.crop((80,58,142,81)).resize((372,138),Image.Resampling.NEAREST),(col*384+4,row*248+22))
   enlarged.paste(display.crop((87,84,130,110)).resize((172,104),Image.Resampling.NEAREST),(col*384+100,row*248+141));ed.text((col*384+4,row*248+3),name+' '+kind,fill='#dfd4bc')
  if args.wire:
   for resource in face['resources']:
    path=local(resource);text=path.read_text(encoding='utf-8')
    for old,new in bindings.items():text=text.replace('path="'+old+'"','path="'+new+'"')
    write(path,text)
 board.save(REVIEW/'all-faces.png');card.save(REVIEW/'card-size.png');enlarged.save(REVIEW/'features-enlarged.png')
 write(REVIEW/'components.json',json.dumps(manifest,indent=2)+'\n')
 print('Refined 51 animation drawings; v3 neutral/clean/mattes unchanged; '+('live bindings updated.' if args.wire else 'candidates only.'))

if __name__=='__main__':main()

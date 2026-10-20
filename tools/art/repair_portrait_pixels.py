"""#121: owner-authorized native pixel edits, derived from each resting face.

No generation, resampling, deformation, skin recolouring or atlas fitting.
Coordinates below are hand-fitted at the existing 192px native resolution.
Only lids/lip openings change. Body/head/resting layers are read-only.
"""
from pathlib import Path
from PIL import Image,ImageDraw
import argparse,hashlib,json,re,math
import sys
sys.dont_write_bytecode=True

ROOT=Path(__file__).resolve().parents[2]
REVIEW=ROOT/'art/concepts/portrait-pixel-repair-v1'
SOURCE=ROOT/'art/source/portrait-pixel-repair-v1'
BASELINE='3d1ee08'

# Per-face ocular centres and lip seam anchors, inspected on the neutral pixels.
# Near/far eyes have separate geometry; these are not reusable expression parts.
FACES={
 'corin':{'eyes':[(95,66,7,3),(122,69,6,3)],'lip':[(94,90),(100,91),(106,93),(111,94),(116,94)],'missing_tooth':True},
 'alwen':{'eyes':[(100,68,6,3),(123,68,6,3)],'lip':[(104,96),(110,95),(117,95),(122,96)]},
 'mara':{'eyes':[(97,70,7,4),(123,71,6,4)],'lip':[(98,101),(105,100),(113,100),(121,101)]},
 'warden-a':{'eyes':[(96,71,7,4),(122,71,6,4)],'lip':[(96,100),(102,99),(110,99),(118,100)]},
 'scout-a':{'eyes':[(96,70,7,4),(122,70,6,4)],'lip':[(97,98),(104,97),(111,98),(118,98)]},
 'brawler-a':{'eyes':[(96,70,7,4),(122,70,6,4)],'lip':[(96,99),(103,98),(110,98),(117,98)]},
 'brawler-b':{'eyes':[(96,69,7,4),(122,69,6,4)],'lip':[(98,98),(105,96),(111,97),(118,98)]},
 'brawler-c':{'eyes':[(96,68,7,4),(122,69,6,4)],'lip':[(96,98),(103,97),(111,97),(119,98)]},
 'warden-b':{'eyes':[(96,68,7,4),(122,69,6,4)],'lip':[(97,97),(103,96),(110,96),(118,97)]},
 'warden-c':{'eyes':[(96,71,7,4),(122,71,6,4)],'lip':[(95,100),(102,99),(111,99),(119,100)]},
 'scout-b':{'eyes':[(96,70,7,4),(122,70,6,4)],'lip':[(97,99),(104,98),(111,99),(118,99)]},
 'scout-c':{'eyes':[(96,68,7,4),(122,69,6,4)],'lip':[(96,98),(103,98),(111,98),(118,98)]},
}

def write(path,text):
 path.parent.mkdir(parents=True,exist_ok=True);path.write_text(text,encoding='utf-8',newline='\n')
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def local(uri):return ROOT/uri.removeprefix('res://')
def uri(path):return 'res://'+path.relative_to(ROOT).as_posix()
def blank():return Image.new('RGBA',(192,192))
def lightness(c):return .2126*c[0]+.7152*c[1]+.0722*c[2]
def pixel_near(base,target):
 palette={c for c in base.get_flattened_data() if c[3]}
 return min(palette,key=lambda c:sum((a-b)**2 for a,b in zip(c[:3],target)))
def compose(entry):
 image=blank()
 for source in entry['layers']:
  if source.endswith('/background.png'):continue
  image.alpha_composite(Image.open(local(source)).convert('RGBA'))
 return image
def clipped_layer(image,box):
 result=blank();result.paste(image.crop(box),box[:2]);return result
def mask_polygon(points):
 result=Image.new('L',(192,192));ImageDraw.Draw(result).polygon(points,fill=255);return result

def eye_edit(base,spec,closed):
 image=base.copy();mask=Image.new('L',(192,192));d=ImageDraw.Draw(image)
 for cx,cy,rx,ry in spec['eyes']:
  # Socket interior only: preserve the original brow and fixed corner pixels.
  top=max(cy-ry+1,65) if spec.get('missing_tooth') else cy-ry+1
  points=[(cx-rx,cy),(cx-rx+3,top),(cx+rx-3,top),(cx+rx,cy),
          (cx+rx-1,cy+ry-2),(cx+1,cy+ry-1),(cx-rx+2,cy+ry-2)]
  ocular=mask_polygon(points)
  # Native material colours sampled just under this eye, never from another face.
  dark=pixel_near(base,(57,39,29))
  # Clone native cheek texture into the lid, shaded to the eye-socket plane.
  # Palette snapping retains the original character's existing material colours.
  lid_samples={}
  for x in range(cx-rx,cx+rx+1):
   for sy in range(3):
    c=base.getpixel((x,cy+ry+1+sy))
    lid_samples[x,sy]=pixel_near(base,tuple(round(v*.73) for v in c[:3]))
  bounds=ocular.getbbox()
  for y in range(bounds[1],bounds[3]):
   for x in range(bounds[0],bounds[2]):
    if not ocular.getpixel((x,y)):continue
    if closed or y<=cy:
     image.putpixel((x,y),lid_samples[x,(y-top)%3])
     mask.putpixel((x,y),255)
  if closed:
   line=[(cx-rx+1,cy),(cx-rx+3,cy+1),(cx,cy+1),(cx+rx-2,cy),(cx+rx,cy-1)]
  else:
   line=[(cx-rx+1,cy),(cx-rx+3,cy),(cx+rx-2,cy),(cx+rx,cy)]
  d.line(line,fill=dark,width=1);ImageDraw.Draw(mask).line(line,fill=255,width=1)
 return image,mask

def lip_y(path,x):
 for a,b in zip(path,path[1:]):
  if a[0]<=x<=b[0]:return round(a[1]+(b[1]-a[1])*(x-a[0])/(b[0]-a[0]))
 return path[-1][1]

def mouth_edit(base,spec,mode):
 image=base.copy();mask=Image.new('L',(192,192));d=ImageDraw.Draw(image);md=ImageDraw.Draw(mask)
 path=spec['lip'];left,right=path[0][0],path[-1][0];centre=(left+right)//2;cy=lip_y(path,centre)
 dark=pixel_near(base,(44,29,23));lip=pixel_near(base,(146,98,71));tooth=pixel_near(base,(201,181,149))
 if mode=='round':
  # A small central gesture. Existing corners, smile creases and stubble stay fixed.
  points=[(centre-2,cy-1),(centre+1,cy-1),(centre+3,cy+1),(centre+2,cy+3),(centre-1,cy+4),(centre-3,cy+2)]
  d.polygon(points,fill=lip);md.polygon(points,fill=255)
  cavity=[(centre-1,cy),(centre+1,cy),(centre+1,cy+2),(centre-1,cy+2)]
  d.polygon(cavity,fill=dark)
 else:
  depth=1 if mode=='small' else 3
  for x in range(left+1,right):
   y=lip_y(path,x)
   # Both mouth corners retain exactly their original pixels.
   amount=max(0,round(depth*math.sin(math.pi*(x-left)/(right-left))))
   for yy in range(y,y+amount+1):image.putpixel((x,yy),dark);mask.putpixel((x,yy),255)
   if mode=='open' and centre-4<=x<=centre+4 and amount>=2:
    # A subdued narrow upper tooth row; Corin retains his missing front tooth.
    if not spec.get('missing_tooth') or x not in [centre,centre+1]:image.putpixel((x,y+1),tooth)
   if amount>0 and centre-4<=x<=centre+4:
    image.putpixel((x,y+amount+1),lip);mask.putpixel((x,y+amount+1),255)
 return image,mask

def main():
 parser=argparse.ArgumentParser();parser.add_argument('--wire',action='store_true');args=parser.parse_args()
 registry=json.loads((ROOT/'data/portraits/catalog.json').read_text(encoding='utf-8'))
 entries=[e for e in registry['portraits'] if e['id']==e['face_id']]
 REVIEW.mkdir(parents=True,exist_ok=True);write(REVIEW/'.gdignore','');write(SOURCE/'.gdignore','')
 report={'issue':121,'method':'Owner-authorized precise native pixel edits of each existing resting face; no generated atlas fitting.',
         'baseline':BASELINE,'canvas':[192,192],'faces':[],'failures':[]}
 board=Image.new('RGB',(192*6,216*len(entries)),'#1b2420');bd=ImageDraw.Draw(board)
 comparison=Image.new('RGB',(192*6,216*3),'#1b2420');cd=ImageDraw.Draw(comparison)
 for row,entry in enumerate(entries):
  face=entry['id'];spec=FACES[face];base=compose(entry);parent=local(entry['neutral_eyes']).parent;dest=parent/'frames-pixel-v2';dest.mkdir(exist_ok=True)
  names=['eyes-half','eyes-closed','mouth-small','mouth-open']+(['mouth-round'] if len(entry['frames'])==6 else [])
  source=SOURCE/face;source.mkdir(parents=True,exist_ok=True);base.save(source/'resting-reference.png')
  record={'face':face,'family':entry['family'],'resource':entry['resource'],'base_sha256':hashlib.sha256(base.tobytes()).hexdigest(),'recipe':spec,'frames':[]}
  board.paste(base,(0,row*216+24),base);bd.text((4,row*216+4),face,fill='#dfd4bb')
  bindings={}
  for col,name in enumerate(names,1):
   if name.startswith('eyes'):image,mask=eye_edit(base,spec,name=='eyes-closed');box=entry['eye_box']
   else:image,mask=mouth_edit(base,spec,name.removeprefix('mouth-'));box=entry['mouth_box']
   layer=clipped_layer(image,tuple(box));path=dest/(name+'.png');layer.save(path)
   allowed=mask.getbbox();assert allowed and box[0]<=allowed[0] and box[1]<=allowed[1] and box[2]>=allowed[2] and box[3]>=allowed[3],(face,name,allowed,box)
   mask_path=source/(name+'-edit-mask.png');mask.save(mask_path)
   changed=[(x,y) for y in range(192) for x in range(192) if image.getpixel((x,y))!=base.getpixel((x,y))]
   assert changed and all(mask.getpixel(point)>0 for point in changed)
   composed=base.copy();composed.alpha_composite(layer);assert composed.tobytes()==image.tobytes(),(face,name,'patch compose differs')
   record['frames'].append({'name':name,'texture':uri(path),'mask':uri(mask_path),'changed_pixels':len(changed),'change_bounds':[min(x for x,y in changed),min(y for x,y in changed),max(x for x,y in changed)+1,max(y for x,y in changed)+1],'sha256':sha(path)})
   bindings[name]=uri(path);board.paste(image,(col*192,row*216+24),image)
  record['input_layers']={p:sha(local(p)) for p in entry['layers']}
  write(source/'recipe.json',json.dumps(record,indent=2)+'\n')
  if row<3:
   for col,name in enumerate(['neutral','old-eyes-closed','new-eyes-closed','neutral','old-mouth-open','new-mouth-open']):
    image=base.copy()
    if name!='neutral':
     version,feature=name.split('-',1);texture=(parent if version=='old' else dest)/(feature+'.png');image.alpha_composite(Image.open(texture).convert('RGBA'))
    comparison.paste(image,(col*192,row*216+24),image);cd.text((col*192+4,row*216+4),face+' '+name,fill='#dfd4bb')
  report['faces'].append(record)
  if args.wire:
   targets=[local(entry['resource'])]+([ROOT/'art/portraits/mara-neutral-v1/underlayer.tres'] if face=='mara' else [])
   for target in targets:
    text=target.read_text(encoding='utf-8')
    for name,path in bindings.items():
     pattern=r'(\[ext_resource type="Texture2D" path=")[^"]*/'+re.escape(name)+r'\.png(" id="[^"]+"\])'
     text,count=re.subn(pattern,lambda m:m[1]+path+m[2],text);assert count==1,(target,name,count)
    write(target,text)
 board.save(REVIEW/'all-frames-native.png')
 comparison.save(REVIEW/'heroes-before-after.png')
 write(REVIEW/'pixel-validation.json',json.dumps(report,indent=2)+'\n')
 print(f'Authored {sum(len(f["frames"]) for f in report["faces"])} face-matched native frames for {len(entries)} faces; '+('live bindings updated.' if args.wire else 'candidate exports only.'))

if __name__=='__main__':main()

"""#121: separate complete facial components from the original native artwork.

Owner-authorized pixel edits. Immutable original composites and source textures
are retained; no generation, scaling, atlas registration or new portrait design.
The neutral components reconstruct the original face exactly. Animated parts
start on a clean surface, never on the old eye or lip line.
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageChops, ImageFilter
import numpy as np
import argparse, hashlib, json, re, sys
sys.dont_write_bytecode = True

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / 'art/source/portrait-components-v3'
REVIEW = ROOT / 'art/concepts/portrait-components-v3'
ORIGINALS = ROOT / 'art/concepts/portrait-pixel-repair-v1/pixel-validation.json'

# Full feature footprints, including outer lashes and resting lip corners.
# Lid paths and lip seams are individually fitted, in the original 192px space.
FACES = {
 'mara': {
  'eyes': [([(84,68),(89,65),(99,65),(106,67),(109,70),(107,74),(102,77),(91,77),(85,73)], [(86,69),(91,72),(99,73),(105,71),(107,70)]),
           ([(113,68),(119,65),(131,65),(137,68),(139,72),(135,76),(124,78),(116,75),(113,72)], [(115,70),(120,73),(128,73),(135,71),(137,70)])],
  'mouth': [(94,100),(99,96),(105,95),(113,95),(121,98),(125,101),(122,105),(112,106),(101,105),(94,103)],
  'lip': [(97,101),(103,100),(111,100),(118,101),(122,102)]},
 'corin': {
  'eyes': [([(84,65),(90,63),(99,63),(105,65),(107,69),(104,72),(95,73),(87,70),(84,68)], [(86,66),(91,68),(98,69),(103,68),(105,67)]),
           ([(112,67),(117,65),(127,65),(133,67),(135,71),(132,75),(123,76),(116,73),(112,71)], [(114,69),(119,72),(127,73),(132,72),(133,71)])],
  'mouth': [(88,87),(94,86),(103,88),(110,90),(119,91),(123,94),(120,98),(110,98),(102,95),(95,93),(88,91)],
  'lip': [(90,89),(97,90),(104,92),(111,94),(119,94)], 'missing_tooth': True},
 'alwen': {
  'eyes': [([(90,67),(95,64),(103,64),(109,66),(111,69),(108,73),(102,76),(94,75),(90,71)], [(92,68),(97,71),(103,72),(108,70),(109,69)]),
           ([(114,67),(119,64),(129,64),(134,66),(136,69),(134,73),(128,76),(119,74),(114,71)], [(116,68),(121,71),(128,72),(133,70),(134,69)])],
  'mouth': [(100,94),(105,91),(111,91),(119,92),(124,94),(127,97),(123,101),(113,102),(103,100),(100,98)],
  'lip': [(102,96),(108,95),(115,95),(121,96),(124,97)]},
}

# Reusable socket does not imply reusable eyes: contours are face-local.
RECRUITS = {
 'warden-a': (71,71,[(95,100),(102,99),(110,99),(119,100)]),
 'scout-a': (70,70,[(96,98),(103,97),(111,98),(119,98)]),
 'brawler-a': (70,70,[(95,99),(102,98),(110,98),(118,99)]),
 'brawler-b': (69,69,[(97,98),(104,96),(111,97),(119,98)]),
 'brawler-c': (68,69,[(95,98),(102,97),(111,97),(120,98)]),
 'warden-b': (68,69,[(96,97),(103,96),(110,96),(119,97)]),
 'warden-c': (71,71,[(94,100),(102,99),(111,99),(120,100)]),
 'scout-b': (70,70,[(96,99),(103,98),(111,99),(119,99)]),
 'scout-c': (68,69,[(95,98),(102,98),(111,98),(119,98)]),
}
for face, (near_y, far_y, lip) in RECRUITS.items():
 eyes = []
 for cx, cy in [(96,near_y),(122,far_y)]:
  eyes.append(([(cx-13,cy-2),(cx-9,cy-6),(cx+1,cy-6),(cx+9,cy-3),
                 (cx+13,cy),(cx+10,cy+5),(cx+2,cy+7),(cx-7,cy+6),(cx-13,cy+2)],
                [(cx-11,cy-1),(cx-6,cy+2),(cx+1,cy+3),(cx+8,cy+1),(cx+11,cy)]))
 left, top = lip[0]; right = lip[-1][0]; bottom = max(y for x,y in lip)
 FACES[face] = {'eyes':eyes, 'lip':lip,
  'mouth':[(left-3,top-1),(left+3,min(y for x,y in lip)-4),
           (right-6,min(y for x,y in lip)-4),(right+3,bottom-1),
           (right+3,bottom+3),(right-3,bottom+5),(left+4,bottom+5),(left-3,top+3)]}

def local(uri): return ROOT / uri.removeprefix('res://')
def uri(path): return 'res://' + path.relative_to(ROOT).as_posix()
def write(path, text):
 path.parent.mkdir(parents=True, exist_ok=True)
 path.write_text(text, encoding='utf-8', newline='\n')
def sha(path): return hashlib.sha256(path.read_bytes()).hexdigest()
def blank(): return Image.new('RGBA', (192,192))
def polygon(points):
 image = Image.new('L',(192,192)); ImageDraw.Draw(image).polygon(points,fill=255)
 return image
def merge(a,b): return ImageChops.lighter(a,b)
def nearest(palette, rgb):
 return min(palette, key=lambda p:sum((p[i]-rgb[i])**2 for i in range(3)))

def clean_feature(original, mask, feature, palette):
 """Fill from unmasked native skin boundaries, then reuse local skin texture.

 The erased opening contributes no source colours. A harmonic skin fill avoids
 dragging individual brow/lip columns through the face. Snapping the result to
 the original palette retains the character's hard pixel edges and materials.
 """
 result=original.copy();bounds=mask.getbbox();active=np.asarray(mask)>0
 data=np.asarray(original,dtype=float)[:,:,:3].copy()
 # A fixed unmasked cheek sample initializes the solve; all erased source
 # pixels are discarded before interpolation begins.
 data[active]=np.mean(data[bounds[3]+1:bounds[3]+4,bounds[0]:bounds[2]],axis=(0,1))
 for _ in range(300):
  average=(np.roll(data,1,0)+np.roll(data,-1,0)+np.roll(data,1,1)+np.roll(data,-1,1))/4
  data[active]=average[active]
 smooth=original.filter(ImageFilter.GaussianBlur(1))
 for y in range(bounds[1],bounds[3]):
  for x in range(bounds[0],bounds[2]):
   if not active[y,x]:continue
   donor=(x,bounds[3]+1+(y-bounds[1])%3)
   sample=original.getpixel(donor);mean=smooth.getpixel(donor)
   rgb=[round(data[y,x,i]+.35*(sample[i]-mean[i])) for i in range(3)]
   result.putpixel((x,y),nearest(palette,rgb))
 return result

def eye_component(clean, original, spec, closed, palette):
 result = clean.copy(); ink = Image.new('L',(192,192)); d=ImageDraw.Draw(result); md=ImageDraw.Draw(ink)
 dark=nearest(palette,(53,35,27)); edge=nearest(palette,(100,65,46))
 for footprint,path in spec['eyes']:
  if not closed:
   # Only this narrow visible slit can contain any of the original open eye.
   upper=[(x,y-3) for x,y in path]; lower=[(x,y-1) for x,y in path]
   slit=polygon(upper+list(reversed(lower)))
   result.paste(original,(0,0),slit); ink=merge(ink,slit);md=ImageDraw.Draw(ink)
   line=upper
  else: line=path
  # One connected eyelid/lash stroke; no independent outer lash fragments.
  d.line([(x,y-1) for x,y in line],fill=edge,width=1)
  d.line(line,fill=dark,width=1)
  md.line([(x,y-1) for x,y in line],fill=255,width=1);md.line(line,fill=255,width=1)
 return result,ink

def lip_y(points,x):
 for a,b in zip(points,points[1:]):
  if a[0]<=x<=b[0]: return round(a[1]+(b[1]-a[1])*(x-a[0])/(b[0]-a[0]))
 return points[-1][1]

def mouth_component(clean, spec, mode, palette):
 result=clean.copy();ink=Image.new('L',(192,192));d=ImageDraw.Draw(result);md=ImageDraw.Draw(ink)
 dark=nearest(palette,(45,29,23));lip=nearest(palette,(135,85,62));lit=nearest(palette,(170,113,78));tooth=nearest(palette,(199,178,145))
 points=spec['lip'];left,right=points[0][0],points[-1][0];cx=(left+right)//2;cy=lip_y(points,cx)
 if mode=='round':
  # Full lip replacement: resting corners are absent, not drawn behind a ring.
  outer=[(cx-2,cy-3),(cx+2,cy-3),(cx+5,cy),(cx+4,cy+4),(cx+1,cy+6),(cx-3,cy+5),(cx-5,cy+1)]
  cavity=[(cx-1,cy-1),(cx+1,cy-1),(cx+3,cy+1),(cx+2,cy+3),(cx,cy+4),(cx-2,cy+3),(cx-3,cy+1)]
 else:
  depth=2 if mode=='small' else 4
  # Corner positions and slope are fitted per face; the whole contour is new.
  upper=[(left,points[0][1])]+[(x,y-1) for x,y in points[1:-1]]+[(right,points[-1][1])]
  lower=[(left,points[0][1])]+[(x,y+depth) for x,y in points[1:-1]]+[(right,points[-1][1])]
  cavity=upper+list(reversed(lower));outer=[(x,y-1) for x,y in upper]+[(x,y+1) for x,y in reversed(lower)]
 d.polygon(outer,fill=lip);d.polygon(cavity,fill=dark);md.polygon(outer,fill=255)
 if mode=='open':
  for x in range(cx-5,cx+5):
   if spec.get('missing_tooth') and x in [cx,cx+1]: continue
   y=lip_y(points,x);d.point((x,y),fill=tooth)
  d.line([(cx-3,cy+4),(cx+2,cy+4)],fill=lit,width=1)
 elif mode=='round':d.line([(cx-2,cy+5),(cx+1,cy+5)],fill=lit,width=1)
 return result,ink

def full_patch(image,mask):
 result=blank();result.paste(image,(0,0),mask);return result

def main():
 parser=argparse.ArgumentParser();parser.add_argument('--wire',action='store_true');args=parser.parse_args()
 refined=ROOT/'art/concepts/portrait-drawings-v4/components.json'
 if refined.exists() and json.loads(refined.read_text(encoding='utf-8')).get('status')=='live':
  parser.error('V3 clean/neutral components are frozen beneath the v4 drawings. Use refine_portrait_drawings.py --wire.')
 records=json.loads(ORIGINALS.read_text(encoding='utf-8'))['faces']
 write(SOURCE/'.gdignore','');write(REVIEW/'.gdignore','');write(REVIEW/'.gitignore','motion-*.png\n')
 report={'issue':121,'revision':'complete-components-v3','canvas':[192,192],
         'method':'Full original eye/lip removal, exact neutral reconstruction, native per-face replacement drawings.', 'faces':[]}
 board=Image.new('RGB',(192*7,216*len(records)),'#202821');bd=ImageDraw.Draw(board)
 details=Image.new('RGB',(384*4,300*len(records)),'#202821');dd=ImageDraw.Draw(details)
 for row,record in enumerate(records):
  face=record['face'];spec=FACES[face];source=SOURCE/face;source.mkdir(parents=True,exist_ok=True)
  for p,h in record['input_layers'].items(): assert sha(local(p))==h,(face,'Original source changed',p)
  original=Image.open(ROOT/'art/source/portrait-pixel-repair-v1'/face/'resting-reference.png').convert('RGBA')
  palette=sorted({p for p in original.get_flattened_data() if p[3]==255})
  eye_mask=merge(*[polygon(p) for p,line in spec['eyes']]);mouth_mask=polygon(spec['mouth'])
  for closed in [False,True]:
   trial,ink=eye_component(original,original,spec,closed,palette);eye_mask=merge(eye_mask,ink)
  # Include all drawings inside the erasure area, including open/round lip edges.
  trial,ink=mouth_component(original,spec,'round',palette);mouth_mask=merge(mouth_mask,ink)
  for mode in ['small','open']:
   trial,ink=mouth_component(original,spec,mode,palette);mouth_mask=merge(mouth_mask,ink)
  # Some profiles end inside these generous feature footprints. Never paint
  # skin, lashes or opacity beyond the original character silhouette.
  eye_mask=ImageChops.multiply(eye_mask,original.getchannel('A'))
  mouth_mask=ImageChops.multiply(mouth_mask,original.getchannel('A'))
  clean=clean_feature(original,eye_mask,'eye',palette)
  clean=clean_feature(clean,mouth_mask,'mouth',palette)
  all_mask=merge(eye_mask,mouth_mask)
  inputs=record['input_layers'];head_uri=next(p for p in inputs if p.endswith('/base.png') or p.endswith('/head.png'))
  parent=local(head_uri).parent;dest=parent/'frames-pixel-v3';dest.mkdir(exist_ok=True)
  head=Image.open(local(head_uri)).convert('RGBA');head.paste(clean,(0,0),all_mask)
  head_path=dest/('base-clean.png' if face=='mara' else 'head-clean.png');head.save(head_path)
  original.save(source/'resting-reference.png');clean.save(source/'clean-reference.png')
  eye_mask.save(source/'eyes-erasure.png');mouth_mask.save(source/'mouth-erasure.png')
  bindings={head_uri:uri(head_path)};outputs=[{'name':'clean-character','texture':uri(head_path),'sha256':sha(head_path)}]
  frames={};inks={}
  for name,mask in [('eyes-neutral',eye_mask),('mouth-neutral',mouth_mask)]:
   path=dest/(name+'.png');full_patch(original,mask).save(path)
   canonical=uri(parent/(name+'.png'));bindings[canonical]=uri(path)
   outputs.append({'name':name,'texture':uri(path),'sha256':sha(path)});frames[name]=original
  names=['eyes-half','eyes-closed','mouth-small','mouth-open']+(['mouth-round'] if len(record['frames'])==5 else [])
  for name in names:
   if name.startswith('eyes'):frame,ink=eye_component(clean,original,spec,name=='eyes-closed',palette);mask=eye_mask
   else:frame,ink=mouth_component(clean,spec,name.removeprefix('mouth-'),palette);mask=mouth_mask
   ink=ImageChops.multiply(ink,original.getchannel('A'))
   assert ImageChops.subtract(ink,mask).getbbox() is None,(face,name,'Drawing outside complete component')
   path=dest/(name+'.png');full_patch(frame,mask).save(path)
   ink_path=source/(name+'-ink.png');ink.save(ink_path)
   canonical=uri(parent/(name+'.png'));bindings[canonical]=uri(path);bindings[uri(parent/'frames-pixel-v2'/(name+'.png'))]=uri(path)
   outputs.append({'name':name,'texture':uri(path),'sha256':sha(path),'ink':uri(ink_path)})
   # The untouched opposite feature is shown in overview/review.
   visible=original.copy();visible.paste(frame,(0,0),mask);frames[name]=visible;inks[name]=ink
  targets=[record['resource']]+(['res://art/portraits/mara-neutral-v1/underlayer.tres'] if face=='mara' else [])
  result={'face':face,'family':record['family'],'resources':targets,'input_layers':inputs,'bindings':bindings,
          'eye_mask':uri(source/'eyes-erasure.png'),'mouth_mask':uri(source/'mouth-erasure.png'),
          'original':uri(source/'resting-reference.png'),'clean':uri(source/'clean-reference.png'),
          'recipe':spec,'outputs':outputs}
  report['faces'].append(result);write(source/'recipe.json',json.dumps(result,indent=2)+'\n')
  for col,name in enumerate(['neutral','clean','eyes-half','eyes-closed','mouth-small','mouth-open','mouth-round']):
   image=original if name=='neutral' else clean if name=='clean' else frames.get(name,original)
   board.paste(image,(col*192,row*216+24),image);bd.text((col*192+4,row*216+5),face+' '+name,fill='#e0d4bc')
  # Large unfiltered crops explicitly show removed outer eyes and lip corners.
  eye_box=(80,58,142,81);mouth_box=(86,83,131,110)
  for col,name in enumerate(['neutral','clean','eyes-closed','mouth-round' if 'mouth-round' in frames else 'mouth-open']):
   image=original if name=='neutral' else clean if name=='clean' else frames[name]
   dd.text((col*384+8,row*300+5),face+' '+name,fill='#e0d4bc')
   details.paste(image.crop(eye_box).resize((372,138),Image.Resampling.NEAREST),(col*384+6,row*300+28))
   details.paste(image.crop(mouth_box).resize((270,162),Image.Resampling.NEAREST),(col*384+40,row*300+140))
  if face=='mara':
   comparison=Image.new('RGB',(800,390),'#202821');cd=ImageDraw.Draw(comparison)
   for col,label in enumerate(['Previous v2: resting features remain','Corrected v3: complete replacement']):
    cd.text((col*400+16,12),label,fill='#e0d4bc')
    for name,box,y in [('eyes-closed',(80,55,141,85),42),('mouth-round',(92,93,128,112),250)]:
     image=original.copy()
     if col==0:image.alpha_composite(Image.open(parent/'frames-pixel-v2'/(name+'.png')).convert('RGBA'))
     else:image=frames[name]
     crop=image.crop(box);crop=crop.resize((crop.width*6,crop.height*6),Image.Resampling.NEAREST)
     comparison.paste(crop,(col*400+16,y))
   comparison.save(REVIEW/'mara-before-after.png')
  if args.wire:
   for target in targets:
    path=local(target);text=path.read_text(encoding='utf-8')
    for old,new in bindings.items():text=text.replace('path="'+old+'"','path="'+new+'"')
    write(path,text)
 board.save(REVIEW/'all-faces.png');details.save(REVIEW/'feature-removal-enlarged.png')
 write(REVIEW/'components.json',json.dumps(report,indent=2)+'\n')
 print(f'Built complete components for {len(records)} faces; '+('wired 13 resources.' if args.wire else 'candidate exports only.'))

if __name__=='__main__':main()

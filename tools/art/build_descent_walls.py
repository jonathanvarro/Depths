"""#126: six generated wall masters -> small reusable Godot materials/reviews.

Export only: downsample to128, gently reconcile a six-pixel wrapping apron,
quantize32 without dithering. Original generated masters are preserved exactly.
This adds no floor/theme assignment or story content.
"""
from pathlib import Path
from PIL import Image,ImageDraw
import hashlib,json
import numpy as np

ROOT=Path(__file__).resolve().parents[2]
SOURCE=ROOT/'art/source/cave-walls-v1'
OUT=ROOT/'art/textures/descent-walls-v1'
REVIEW=ROOT/'art/concepts/descent-walls-v1'
FAMILIES=[('worked-cave','Worked cave',[1,2]),('goblin-hold','Goblin hold',[3,4]),
 ('drowned-masonry','Drowned masonry',[5,6]),('fungal-stone','Fungal stone',[7,8]),
 ('buried-city','Buried city',[9,10]),('sealed-temple','Sealed temple',[11,12])]

def write(path,text):
 path.parent.mkdir(parents=True,exist_ok=True);path.write_text(text,encoding='utf-8',newline='\n')
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def uri(path):return 'res://'+path.relative_to(ROOT).as_posix()
def wrap_apron(image,width=6):
 data=np.asarray(image,dtype=float).copy()
 for axis in [1,0]:
  old=data.copy()
  for inset in range(width):
   weight=.5*(1-inset/width)**2
   if axis==1:
    a=old[:,inset,:];b=old[:,-1-inset,:]
    data[:,inset,:]=a*(1-weight)+b*weight;data[:,-1-inset,:]=b*(1-weight)+a*weight
   else:
    a=old[inset,:,:];b=old[-1-inset,:,:]
    data[inset,:,:]=a*(1-weight)+b*weight;data[-1-inset,:,:]=b*(1-weight)+a*weight
 return Image.fromarray(np.clip(np.rint(data),0,255).astype('uint8'))

def main():
 OUT.mkdir(parents=True,exist_ok=True);write(REVIEW/'.gdignore','')
 provenance=json.loads((SOURCE/'generation.json').read_text(encoding='utf-8'))
 report={'issue':126,'native_size':[128,128],'palette_limit':32,'method':'BOX downsample; six-pixel symmetric wrap apron;32-colour median cut, no dithering.',
  'assignment':'Library only; proposed floor pairs are suggestions from #125, not implemented floors.','assets':[]}
 overview=Image.new('RGB',(960,784),'#1c2420');draw=ImageDraw.Draw(overview)
 repeats=Image.new('RGB',(128*4*3,552*2),'#1c2420');rd=ImageDraw.Draw(repeats)
 for index,(key,label,floors) in enumerate(FAMILIES):
  master=SOURCE/(key+'-master.png');original=Image.open(master).convert('RGB')
  source_record=next(p for p in provenance['assets'] if p['id']==key)
  assert sha(master)==source_record['sha256'],key+' generated source changed'
  export=wrap_apron(original.resize((128,128),Image.Resampling.BOX))
  export=export.quantize(colors=32,method=Image.Quantize.MEDIANCUT,dither=Image.Dither.NONE).convert('RGB')
  path=OUT/(key+'.png');export.save(path)
  material=OUT/(key+'.tres')
  write(material,'[gd_resource type="StandardMaterial3D" load_steps=2 format=3]\n\n'
   f'[ext_resource type="Texture2D" path="{uri(path)}" id="wall"]\n\n'
   '[resource]\n'+f'resource_name = "Descent walls v1 - {label}"\n'
   'texture_filter = 0\ntexture_repeat = true\nalbedo_texture = ExtResource("wall")\nroughness = 1.0\n')
  a=np.asarray(export);assert np.array_equal(a[:,0],a[:,-1]) and np.array_equal(a[0],a[-1]),key
  report['assets'].append({'id':key,'label':label,'suggested_floor_pair':floors,'source':uri(master),
   'source_sha256':sha(master),'source_size':list(original.size),'texture':uri(path),'sha256':sha(path),
   'material':uri(material),'colours':len(export.getcolors(16384)),'opposite_edge_pixels_identical':True,
   'generation_tool':source_record['tool']})
  x=(index%3)*320;y=(index//3)*392
  draw.text((x+16,y+10),label,fill='#dfd3b9')
  overview.paste(export.resize((256,256),Image.Resampling.NEAREST),(x+16,y+36))
  overview.paste(export.resize((64,64),Image.Resampling.NEAREST),(x+16,y+308))
  draw.text((x+88,y+334),'64px check',fill='#b0aa98')
  x=(index%3)*512;y=(index//3)*552;rd.text((x+8,y+8),label+' / 4x4 repeat',fill='#dfd3b9')
  for tx in range(4):
   for ty in range(4):repeats.paste(export,(x+tx*128,y+28+ty*128))
 overview.save(REVIEW/'wall-families.png');repeats.save(REVIEW/'repeat-4x4.png')
 write(OUT/'catalog.json',json.dumps(report,indent=2)+'\n')
 write(REVIEW/'export-validation.json',json.dumps({'assets':6,'native_size':[128,128],'all_opaque':True,'palette_limit':32,'exact_wrapping_edge_pixels':True,'texture_bytes_rgba':6*128*128*4,
  'limitation':'Identical border pixels prevent a colour jump; they do not prove every stone course or crack joins geometrically. Inspect repeated sheets and corridors.','failures':[]},indent=2)+'\n')
 print('Exported six128px /32-colour wall textures, six standalone Godot materials and native/repeat reviews.')

if __name__=='__main__':main()

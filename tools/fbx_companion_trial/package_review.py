"""Local-only review of actual Godot outputs; never uploads source or derived assets."""
from pathlib import Path
import hashlib,json,shutil
from PIL import Image,ImageDraw,ImageFont
ROOT=Path(__file__).resolve().parents[2]
LOCAL=ROOT/'build/local-fbx-trial'
OUT=LOCAL/'review'
OUT.mkdir(parents=True,exist_ok=True)
shutil.copyfile(Path(__file__).with_name('inspector.template.html'),OUT/'inspector.html')
frames=[]
for path in sorted((OUT/'frames').glob('*.png')):
    image=Image.open(path).convert('RGB')
    image.thumbnail((840,440),Image.Resampling.LANCZOS)
    frames.append(image)
assert len(frames)==66
frames[0].save(OUT/'seated-motion.gif',save_all=True,append_images=frames[1:],duration=50,loop=0,optimize=False)
sheet=Image.new('RGB',(1440,1090),'#111b21')
draw=ImageDraw.Draw(sheet)
font=ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf',28)
small=ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf',20)
draw.text((24,18),'DEPTHS / SUPPLIED FBX EXPEDITION TRIAL',font=font,fill='#e4dfce')
draw.text((24,60),'One body and outfit · two appearances · new sit-down / seated idle / stand-up clips',font=small,fill='#b5c4c8')
def tile(name,crop,x,y,w,h,label):
    image=Image.open(OUT/name).convert('RGB').crop(crop)
    image.thumbnail((w,h),Image.Resampling.LANCZOS)
    sheet.paste(image,(x+(w-image.width)//2,y))
    draw.text((x+8,y+h+8),label,font=small,fill='#c9d0c8')
tile('standing.png',(285,0,1060,710),20,115,690,630,'Shared expedition tunic, trousers, boots and field kit')
tile('portrait.png',(150,70,1230,700),730,115,690,400,'Copper hair / silver crop & slate band')
tile('seated.png',(250,100,1070,715),730,580,690,420,'Same weighted outfit through the seated animation')
draw.text((24,1035),'Actual model renders. Appearance variations share one face/body shape. Source and derived art remain local.',font=small,fill='#b5c4c8')
sheet.save(OUT/'overview.png')
files={}
for path in sorted(OUT.rglob('*')):
    if path.is_file() and path.name not in {'manifest.json','browser-report.json'}:
        files[str(path.relative_to(OUT)).replace('\\','/')]={'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'bytes':path.stat().st_size}
manifest={
 'source_fbx_sha256':hashlib.sha256((LOCAL/'source/character.fbx').read_bytes()).hexdigest(),
 'source_texture_sha256':hashlib.sha256((LOCAL/'body-texture.png').read_bytes()).hexdigest(),
 'source_authoring':'Supplied FBX/PNG; original source kept separately. Clothing/kit, hair edits, facial details and seated clips are trial additions.',
 'renderer':'Godot 4.7.2 Mobile / D3D12 / AMD Radeon RX 9070 XT',
 'files':files,
 'source_code_sha256':{p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in Path(__file__).parent.glob('*.gd')},
 'privacy':'Source files, intermediate scenes, derived models and renders are local in git-ignored build/local-fbx-trial.',
 'limits':['One source body and face shape; two appearance variants, not independently sculpted characters','Shell-derived fitted clothing, no cloth simulation or arbitrary equipment coverage','Simple eyes/mouth, no face animation','Authored transition with sampled sole clearance, no foot IK','No live game binding or physical iPhone profile'],
 'environment_warning':'Restricted user://vulkan shader cache unavailable; renderer continued without cache, exit 0.',
 'motion':'66 direct renderer samples at 50ms/frame, down/up cycle. Resized and GIF encoded; no synthesized frames.'
}
(OUT/'manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
print(f'Local gallery ready: {len(files)} captured/review files; 66 real motion frames')

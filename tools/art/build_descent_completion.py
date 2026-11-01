"""#166/#167/#168/#178/#190: export new art and author native interface glyphs.

Source drawings are ImageGen masters; only mechanical exports/composition happen
here. Native SVG extends the existing interface system. No live bindings.
"""
from pathlib import Path
import json, hashlib, sys
sys.dont_write_bytecode = True
import numpy as np
from PIL import Image, ImageDraw
from build_field_kit_art import fitted

ROOT=Path(__file__).resolve().parents[2]
SRC=ROOT/'art/source/descent-completion-v1'
OUT=ROOT/'art/concepts/descent-completion-v1'
TEX=ROOT/'art/textures/reservoir-v1'
PROP=ROOT/'art/props/reservoir-finish-v1'
BREW=ROOT/'art/items/brews-v1'
UI=ROOT/'art/ui/expedition-v1'
ILL=ROOT/'art/illustrations/descent-v1'

def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def write(p,s):p.parent.mkdir(parents=True,exist_ok=True);p.write_text(s,encoding='utf-8')
def js(p,v):write(p,json.dumps(v,indent=2)+'\n')
def uri(p):return 'res://'+p.relative_to(ROOT).as_posix()
def path(d):return f'<path d="{d}"/>'
def svg(body,size=32):return f'<svg xmlns="http://www.w3.org/2000/svg" width="{size}" height="{size}" viewBox="0 0 32 32"><g fill="none" stroke="#e6dac1" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">{body}</g></svg>\n'

def glyphs():
    eye=path('M5 16Q16 4 27 16 16 28 5 16ZM16 12v8')
    fire=path('M16 3C20 12 28 12 25 22Q22 31 11 27C2 23 6 15 11 10L12 18Q18 15 16 3Z')
    defs={
      'marks/eye':eye,'marks/tooth':path('M8 6Q16 2 24 6L22 19 18 28 16 19 12 28 9 19Z'),
      'marks/spiral':path('M27 15C26 1 6 1 5 15S25 32 25 18 10 7 10 16 20 23 20 17 15 14 15 18'),
      'marks/hand':path('M10 27 5 17Q4 13 8 15L11 18V7Q13 3 14 7V15 4Q17 1 18 5V15 7Q21 4 22 8V17 12Q25 9 26 13V23L22 28Z'),
      'marks/moon':path('M22 4A12 12 0 1 0 26 23Q10 26 13 10Q15 5 22 4Z'),
      'marks/cross':path('M13 4H19V13H28V19H19V28H13V19H4V13H13Z'),
      'journal/fire':fire,'journal/flare':path('M16 4V9M16 23V28M4 16H9M23 16H28M6 6L10 10M22 22L26 26M6 26L10 22M22 10L26 6M16 10 22 16 16 22 10 16Z'),
      'journal/reach':path('M4 27 24 7M21 4 28 4 28 11M5 21 11 27'),
      'journal/thrown-torch':path('M7 28 19 16M13 15 21 23M19 15Q14 7 22 3L22 10 27 7Q30 15 23 18M4 10Q8 3 14 5'),
      'journal/brace':path('M7 5H25V17Q24 24 16 29Q8 24 7 17ZM16 8V24'),
      'journal/poison':path('M16 3Q5 16 7 22Q10 31 22 27Q31 22 16 3ZM12 21h1M19 21h1M13 25h6'),
      'journal/immune':path('M4 10V4H10M22 4H28V10M28 22V28H22M10 28H4V22M5 27 27 5'),
      'journal/weak-to':path('M3 10V3H10M22 3H29V10M29 22V29H22M10 29H3V22M12 5 16 10 20 5M12 27 16 22 20 27'),
      'mastery/one':path('M8 25 15 8'),
      'mastery/two':path('M6 25 13 8M17 25 24 8'),
      'mastery/full':path('M5 24 10 8 16 19 22 8 27 24M8 27H24'),
      'mastery/improve':path('M7 24H26M10 24V18H24V24M8 11 18 4 24 13 14 18ZM24 3V8M21 5H28'),
      'combat/long-lunge':path('M3 24Q13 24 20 10M16 7 27 4 24 15M4 16H10M7 10H12'),
      'combat/birthing':path('M9 4Q1 16 9 28M23 4Q31 16 23 28M13 10Q16 5 19 10L20 20 16 25 12 20ZM9 16H4M23 16H28'),
      'combat/off-balance':path('M8 4 22 7M18 7 13 18 23 28M13 18 5 25M9 13 24 18M4 30H11'),
      'combat/tastes-blood':path('M5 6 10 18 14 10 18 18 24 6M7 7H24M24 18Q17 27 23 29Q30 29 24 18Z'),
      'map/deep-water':path('M3 8Q7 4 11 8T19 8T29 8M4 16Q8 12 12 16T20 16T28 16M3 24Q7 20 11 24T19 24T29 24')}
    label_shapes={'restorative':defs['marks/cross'],'caustic':path('M8 4 20 16M18 3 28 13M6 23H26M14 14 10 21M24 17 22 21'),
                  'slumber':path('M5 15Q16 27 27 15M8 19 5 23M14 22V27M21 21 24 25'),
                  'frenzy':path('M6 26 13 17 6 13 18 4 16 14 26 15 17 27 18 19Z'),'revealing':eye}
    for name,d in label_shapes.items():defs['labels/'+name]='<path d="M3 4 28 3 29 27 5 29Z" fill="#d8c39e" stroke="#64533b"/>'+d.replace('<path','<path stroke="#302d25"')
    for name,d in defs.items():write(UI/(name+'.svg'),svg(d))
    for i in range(6):
        r=3+i*2; y=25-i
        shards=''.join(f'<path d="M{16+dx*(i+1)} {y-abs(dx)*2}l2 -3 1 4Z" fill="#e6dac1"/>' for dx in [-2,-1,1,2])
        splash=path(f'M{16-r} {y}Q16 {y-5-i} {16+r} {y}M{16-r} {y+3}Q16 {y+5} {16+r} {y+3}')
        write(UI/f'splash/frame-{i}.svg',svg(splash+shards,64))
    return list(defs)

def scene(texture,name,width,height,bottom=0):
    return f'''[gd_scene load_steps=2 format=3]
[ext_resource type="Texture2D" path="{texture}" id="art"]
[node name="{name}" type="Node3D"]
metadata/art_issue = 168
metadata/mount = "fixed wall, caller supplies real wall anchor"
[node name="Sprite" type="Sprite3D" parent="."]
position = Vector3(0,{height/2-bottom},0)
pixel_size = {width/(256 if name=='WaterEdge' else 192)}
billboard = 0
shaded = true
texture_filter = 0
alpha_cut = 1
cast_shadow = 0
texture = ExtResource("art")
'''

def main():
    for p in [TEX,PROP,BREW,UI,ILL,OUT]:p.mkdir(parents=True,exist_ok=True)
    manifest=json.loads((SRC/'generation.json').read_text())
    catalogue=[]; checks=0
    surfaces=[e for e in manifest['assets'] if e['group']=='textures']
    pool=np.concatenate([np.array(Image.open(ROOT/e['source']).convert('RGB').resize((128,128))).reshape(-1,3) for e in surfaces])
    palette=Image.fromarray(pool.reshape(1,-1,3)).quantize(32,dither=Image.Dither.NONE)
    for e in manifest['assets']:
        raw=Image.open(ROOT/e['source']).convert('RGBA');id=e['id'];registration=None
        source=ROOT/e['source'];checksum=sha(source)
        assert not e.get('sha256') or e['sha256']==checksum
        e.update(sha256=checksum,source_canvas=list(raw.size))
        if e['group']=='textures':
            im=raw.convert('RGB').resize((128,128),Image.Resampling.LANCZOS)
            a=np.array(im).astype(float)
            # Mechanical periodic registration at export size. Wall waterlines
            # repeat horizontally; floors/ceilings wrap in both directions.
            for axis in ([1] if id=='reservoir-wall' else [1,0]):
                for i in range(4):
                    l=[slice(None)]*3;r=[slice(None)]*3;l[axis]=i;r[axis]=-1-i
                    left=a[tuple(l)].copy();right=a[tuple(r)].copy();w=(1-i/4)*.5
                    a[tuple(l)]=left*(1-w)+right*w;a[tuple(r)]=right*(1-w)+left*w
            im=Image.fromarray(a.round().astype('uint8')).quantize(palette=palette,dither=Image.Dither.NONE).convert('RGB');dest=TEX/(id+'.png');im.save(dest)
            a=np.array(im);assert np.array_equal(a[:,0],a[:,-1]);checks+=1
            if id!='reservoir-wall':assert np.array_equal(a[0],a[-1]);checks+=1
            write(TEX/(id+'.tres'),f'[gd_resource type="StandardMaterial3D" load_steps=2 format=3]\n[ext_resource type="Texture2D" path="{uri(dest)}" id="art"]\n[resource]\ntexture_filter = 0\ntexture_repeat = true\nalbedo_texture = ExtResource("art")\nroughness = 1.0\n')
            tile=Image.new('RGB',(384,384))
            for x in range(3):
                for y in range(3):tile.paste(im,(x*128,y*128))
            tile.save(OUT/(id+'-tile-review.png'))
            assert len(im.getcolors(16384))<=32 and im.size==(128,128);checks+=2
        elif e['group']=='brews':
            im,registration=fitted(raw,64,12);dest=BREW/(id+'.png');im.save(dest)
            a=np.array(im);mask=Image.new('RGBA',(64,64));d=ImageDraw.Draw(mask)
            b=im.getchannel('A').getbbox()
            for y in range(round(b[1]+(b[3]-b[1])*.5),b[3]-2):
                xs=np.where(a[y,:,3]>=128)[0]
                if len(xs)>3:d.line((int(xs[0])+1,y,int(xs[-1])-1,y),fill='white')
            mask.save(BREW/(id+'-liquid-mask.png'))
            e['stamp_center']=[32,b[1]+min(5,round((b[3]-b[1])*.1))]
            e['label_side']=max(8,min(16,max(b[2]-b[0],11)-2))
            assert min(b[0],b[1],64-b[2],64-b[3])>=4 and set(np.unique(a[:,:,3]))<={0,255};checks+=2
        elif id=='reservoir-stairs':
            # Full canvas is fixed to 2m; bottom opaque bounds register to floor.
            im=raw.resize((192,192),Image.Resampling.LANCZOS)
            arr=np.array(im);arr[:,:,3]=np.where(arr[:,:,3]>=128,255,0);arr[arr[:,:,3]==0]=0
            im=Image.fromarray(arr).quantize(32,method=Image.Quantize.FASTOCTREE,dither=Image.Dither.NONE).convert('RGBA')
            dest=PROP/'stairs.png';im.save(dest)
            bottom=(192-im.getchannel('A').getbbox()[3])/96
            write(PROP/'stairs.tscn',scene(uri(dest),'ReservoirStairs',2,2,bottom))
            assert im.getpixel((96,75))[3]==255;checks+=1
        elif id=='reservoir-edge':
            im=raw.convert('RGB').resize((256,128),Image.Resampling.LANCZOS).quantize(32,dither=Image.Dither.NONE).convert('RGB');dest=PROP/'water-edge.png';im.save(dest)
            write(PROP/'water-edge.tscn',scene(uri(dest),'WaterEdge',2,1))
        elif e['group']=='camp':
            dest=OUT/'overlook-concept.png';im=raw.convert('RGB').resize((1600,900),Image.Resampling.LANCZOS);im.save(dest)
        else:
            size=(1280,720) if id=='vision' else (640,360)
            im=raw.convert('RGB').resize(size,Image.Resampling.LANCZOS);dest=ILL/(id+'.png');im.save(dest)
        assert dest.exists();checks+=1
        e.update(export=uri(dest),export_sha256=sha(dest),registration=registration)
        catalogue.append(e)
    names=glyphs()
    for name in names:
        assert (UI/(name+'.svg')).exists();checks+=1
    js(SRC/'generation.json',manifest)
    js(BREW/'catalog.json',{'canvas':[64,64],'glass_palette_limit':12,'layer_order':['glass','liquid mask applied as tint/filled cavity','stopper stamp','identified label only when known'],'shapes':[{k:e[k] for k in ['id','export','stamp_center','registration','label_side']} for e in catalogue if e['group']=='brews'],'colours':['#a54b43','#b58b3d','#75895b','#557f94','#8773a5','#b4a887'],'marks':['eye','tooth','spiral','hand','moon','cross']})
    js(UI/'catalog.json',{'glyphs':names,'splash_frames':6,'native_glyph_canvas':[32,32],'display_px':20,'brews_have_no_effect_mapping':True})
    js(OUT/'catalog.json',{'assets':catalogue,'named_portraits_excluded':True,'live_bindings_changed':False})
    js(OUT/'source-validation.json',{'checks':checks,'failures':[],'imagegen_masters':len(catalogue),'native_glyphs':len(names),'splash_frames':6})
    print(f'DESCENT_EXPORT: {checks} checks; {len(catalogue)} masters; {len(names)} native glyphs')

if __name__=='__main__':main()

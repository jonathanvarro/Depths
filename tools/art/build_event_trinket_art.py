"""#142: immutable-source exports, shared prop registration and visual bindings.

Only reduction/registration/quantization and native seal compositing happen
here. Generated subjects are never repainted. Existing artwork stays intact.
"""
from pathlib import Path
import argparse,hashlib,json,re,sys
sys.dont_write_bytecode=True
from PIL import Image,ImageDraw,ImageFont
import numpy as np
from build_field_kit_art import fitted
ROOT=Path(__file__).resolve().parents[2]
SOURCE=ROOT/'art/source/events-trinkets-v1'
ICONS=ROOT/'art/items/trinkets-v1'
PROPS=ROOT/'art/props/shrine-events-v1'
REVIEW=ROOT/'art/concepts/events-trinkets-v1'
ITEMS=[
 ('bloodstone','Bloodstone','Rough red charm in blackened silver and cord','bloodstone'),
 ('moth-wing-brooch','Moth-wing brooch','Broad pewter wings and pale inlay','moth_wing_brooch'),
 ('slingers-thumb-ring',"Slinger’s thumb-ring",'Flared horn guard with a large thumb hole','slingers_thumb_ring'),
 ('ember-ring','Ember ring','Thick coal-black iron band with a rust-red seam','ember_ring'),
 ('gamblers-knucklebone',"Gambler’s knucklebone",'Rubbed ivory gaming bone and three pips','gamblers_knucklebone'),
 ('shield-bearers-token',"Shield-bearer’s token",'Dented tin badge and the established forked seal','shield_bearers_token'),
 ('black-pearl-ring','Black pearl ring','Thin tarnished silver band and one dark pearl','black_pearl_ring'),
 ('bone-white-charm','Bone-white charm','Notched carved bone and frayed cord','bone_charm'),
 ('goblin-gold-torc','Goblin gold torc','Heavy open gold collar with blunt terminals','goblin_torc')]
EVENTS=[
 ('defiled-shrine','A defiled shrine','wall',1.0,'object_defiled_shrine',True),
 ('fouled-well','A fouled well','floor',1.15,'object_fouled_well',True),
 ('buried-cache','A buried cache','floor',1.25,'chest_buried_cache',True)]

def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def uri(p):return 'res://'+p.relative_to(ROOT).as_posix()
def write(p,t):p.parent.mkdir(parents=True,exist_ok=True);p.write_text(t,encoding='utf-8',newline='\n')
def bounds(im):return im.getchannel('A').point(lambda a:255 if a>=128 else 0).getbbox()
def normalize(text,kind):
    typ='Texture2D' if kind=='item' else 'PackedScene'
    return re.sub(r'(\[ext_resource type="'+typ+r'" path=")[^"]+',r'\1<visual>',text)
def palette(images,n=64):
    samples=np.concatenate([np.array(i)[:,:,:3][np.array(i)[:,:,3]>0] for i in images])
    return Image.fromarray(samples.reshape(1,-1,3)).quantize(n,dither=Image.Dither.NONE)
def quant(im,pal):
    a=im.getchannel('A').point(lambda a:255 if a>=128 else 0)
    im=im.convert('RGB').quantize(palette=pal,dither=Image.Dither.NONE).convert('RGBA');im.putalpha(a)
    ar=np.array(im);ar[ar[:,:,3]==0]=0;return Image.fromarray(ar)
def bind(path,old,new,kind):
    text=path.read_text();baseline=normalize(text,kind)
    if new in text:return
    assert old in text,(path,old)
    updated=text.replace(old,new)
    assert normalize(updated,kind)==baseline,'Gameplay field changed'
    write(path,updated)

def baseline():
    p=SOURCE/'bindings-before.json'
    if p.exists():return json.loads(p.read_text())
    files={}
    for id,name,design,stem in ITEMS:
        for suffix in ['', '_cursed']:
            resource=ROOT/'data/trinkets'/(stem+suffix+'.tres')
            if resource.exists():files[resource.relative_to(ROOT).as_posix()]={'kind':'item','text':resource.read_text()}
    for id,name,mount,width,event,live in EVENTS:
        resource=ROOT/'data/events'/(event+'.tres');files[resource.relative_to(ROOT).as_posix()]={'kind':'prop','text':resource.read_text()}
    for rel in ['tools/story/build_trinkets.gd','tools/story/build_shrines.gd']:
        files[rel]={'kind':'builder','text':(ROOT/rel).read_text()}
    write(p,json.dumps(files,indent=2)+'\n');return files

def preserve():
    p=SOURCE/'preserved-art.json'
    if p.exists():return
    files={}
    for rel in ['art/items/refined-v2','art/items/field-kit-v1','art/props/room-states-v1','art/dressing/landmarks-v1','art/symbols/crest-v1']:
        for f in (ROOT/rel).rglob('*'):
            if f.is_file() and f.suffix in ['.png','.svg','.tscn','.gd','.tres','.json']:files[f.relative_to(ROOT).as_posix()]=sha(f)
    write(p,json.dumps(files,indent=2)+'\n')

def prop_scene(e):
    wall=e['mount']=='wall';px=e['pixel_size'];foot=e['pivot'][1]
    pos=f'Vector3(0, {0.95 if wall else (foot-64)*px}, {0.012 if wall else 0})'
    text=f'''[gd_scene load_steps=4 format=3]
[ext_resource type="Texture2D" path="{e['textures'][0]}" id="fresh"]
[ext_resource type="Texture2D" path="{e['textures'][1]}" id="used"]
[ext_resource type="Script" path="res://art/props/cave-events-v1/container.gd" id="state"]
[node name="{e['id']}" type="Node3D"]
script = ExtResource("state")
closed_texture = ExtResource("fresh")
empty_texture = ExtResource("used")
metadata/prop_mount = "{e['mount']}"
metadata/wall_height = 0.95
[node name="Sprite" type="Sprite3D" parent="."]
position = {pos}
pixel_size = {px}
billboard = {0 if wall else 2}
shaded = true
texture_filter = 0
alpha_cut = 1
alpha_scissor_threshold = 0.5
cast_shadow = 0
texture = ExtResource("fresh")
'''
    write(PROPS/(e['id']+'.tscn'),text)

def main():
    args=argparse.ArgumentParser();args.add_argument('--wire',action='store_true');args=args.parse_args()
    for p in [ICONS,ICONS/'compact64',PROPS,REVIEW]:p.mkdir(parents=True,exist_ok=True)
    write(REVIEW/'.gdignore','');old=baseline();preserve()
    sources=json.loads((SOURCE/'generation.json').read_text())
    assert len(sources['assets'])==15
    for e in sources['assets']:assert sha(ROOT/e['source'])==e['sha256'],e['id']
    items=[]
    for ident,name,design,stem in ITEMS:
        source=SOURCE/(ident+'-master.png');raw=Image.open(source).convert('RGBA')
        im,transform=fitted(raw,128,64);compact,_=fitted(raw,64,32)
        seal=SOURCE/'native/token-seal.png'
        if ident=='shield-bearers-token' and seal.exists():
            layer=Image.open(seal).convert('RGBA');im.alpha_composite(layer)
            compact.alpha_composite(layer.resize((64,64),Image.Resampling.BOX))
            im=quant(im,palette([im]));compact=quant(compact,palette([compact],32))
        im.save(ICONS/(ident+'.png'));compact.save(ICONS/'compact64'/(ident+'.png'))
        resources=[]
        for suffix in ['', '_cursed']:
            path=ROOT/'data/trinkets'/(stem+suffix+'.tres')
            if not path.exists():continue
            resources.append(uri(path))
            before=old[path.relative_to(ROOT).as_posix()]['text']
            previous=re.search(r'\[ext_resource type="Texture2D" path="([^"]+)',before)[1]
            if args.wire:bind(path,previous,uri(ICONS/(ident+'.png')),'item')
        items.append({'id':ident,'name':name,'design':design,'icon':uri(ICONS/(ident+'.png')),'compact_icon':uri(ICONS/'compact64'/(ident+'.png')),'resources':resources,'source':uri(source),'source_sha256':sha(source),'canvas':[128,128],'colour_limit':64,**transform})
    props=[]
    for ident,name,mount,width,event,live in EVENTS:
        images=[Image.open(SOURCE/(ident+suffix+'-master.png')).convert('RGBA') for suffix in ['', '-used']]
        assert images[0].size==images[1].size,'Paired sources must keep one canvas'
        boxes=[bounds(i) for i in images]
        box=[min(b[0] for b in boxes),min(b[1] for b in boxes),max(b[2] for b in boxes),max(b[3] for b in boxes)]
        scale=min(112/(box[2]-box[0]),112/(box[3]-box[1]));size=(round((box[2]-box[0])*scale),round((box[3]-box[1])*scale))
        offset=[(128-size[0])//2,(128-size[1])//2];exports=[]
        for raw in images:
            im=Image.new('RGBA',(128,128));im.alpha_composite(raw.crop(box).resize(size,Image.Resampling.BOX),offset)
            exports.append(im)
        if ident=='buried-cache':
            for i,suffix in enumerate(['','-used']):
                seal=SOURCE/'native'/('cache-seal'+suffix+'.png')
                if seal.exists():exports[i].alpha_composite(Image.open(seal).convert('RGBA'))
        pal=palette(exports);exports=[quant(i,pal) for i in exports]
        bb=[bounds(i) for i in exports];visible_width=max(b[2] for b in bb)-min(b[0] for b in bb)
        pivot=[64,64 if mount=='wall' else max(b[3] for b in bb)]
        textures=[]
        for suffix,im in zip(['','-used'],exports):im.save(PROPS/(ident+suffix+'.png'));textures.append(uri(PROPS/(ident+suffix+'.png')))
        entry={'id':ident,'name':name,'mount':mount,'metres_wide':width,'pixel_size':width/visible_width,'pivot':pivot,'textures':textures,'scene':uri(PROPS/(ident+'.tscn')),'event':'res://data/events/'+event+'.tres','connected':live,'source_bounds':box,'shared_scale':scale,'offset':offset,'source_canvas':list(images[0].size),'canvas':[128,128],'colour_limit':64}
        props.append(entry);prop_scene(entry)
        if args.wire and live:
            path=ROOT/'data/events'/(event+'.tres');previous=re.search(r'\[ext_resource type="PackedScene" path="([^"]+)',old[path.relative_to(ROOT).as_posix()]['text'])[1]
            bind(path,previous,entry['scene'],'prop')
    if args.wire:
        path=ROOT/'tools/story/build_trinkets.gd';text=path.read_text()
        if 'res://art/items/trinkets-v1/' not in text:
            text=text.replace('Icons borrow the jewellery art until ChatGPT\'s land.','Unique and curse-pair icons use #142; other jewellery reuses its treasure art.')
            text=text.replace('\tt.icon = _icon(icon)','\tvar art_id: String = id.trim_suffix("_cursed").replace("_", "-")\n\tart_id = {"bone-charm": "bone-white-charm", "goblin-torc": "goblin-gold-torc"}.get(art_id, art_id)\n\tvar art_path := "res://art/items/trinkets-v1/%s.png" % art_id\n\tt.icon = load(art_path) if ResourceLoader.exists(art_path) else _icon(icon)')
            write(path,text)
        path=ROOT/'tools/story/build_shrines.gd';text=path.read_text()
        # Claude added prop_on_wall in 639d014 during source generation.
        # Retain the miners' shrine and use the new art only for its defiled variant.
        if 'const DEFILED_SHRINE' not in text:
            text=text.replace('const POOL :=','const DEFILED_SHRINE := "res://art/props/shrine-events-v1/defiled-shrine.tscn"\nconst POOL :=')
            text=text.replace('], OBJECT, Vector2i(2, 4), SHRINE, 2, true)','], OBJECT, Vector2i(2, 4), DEFILED_SHRINE, 2, true)')
        text=text.replace('res://art/props/room-states-v1/still-pool.tscn','res://art/props/shrine-events-v1/fouled-well.tscn').replace('res://art/props/room-states-v1/old-workings.tscn','res://art/props/shrine-events-v1/buried-cache.tscn')
        write(path,text)
    cat={'issue':142,'items':items,'props':props,'native_seal_source':'res://art/symbols/crest-v1/forked-seal.svg','contract':'Props share paired crop/scale/pivot and 64 colours; icons 128/64px; cursed/cleansed pairs share one image. All props/trinkets are connected; shrine retains existing prop_on_wall placement from 639d014.'}
    write(ICONS/'catalog.json',json.dumps(cat,indent=2)+'\n');write(PROPS/'catalog.json',json.dumps({'issue':142,'props':props},indent=2)+'\n')
    font=ImageFont.truetype(str(next((ROOT/'art/fonts/source-sans-3').glob('*.ttf'))),18)
    board=Image.new('RGB',(1000,920),'#1c2420');d=ImageDraw.Draw(board)
    for i,e in enumerate(items):
        x=(i%3)*330;y=(i//3)*205;im=Image.open(ROOT/e['icon'][6:]);board.paste(im,(x+12,y+5),im)
        for size,dx,dy in [(64,170,12),(40,184,90)]:
            tiny=Image.open(ROOT/e['compact_icon'][6:]) if size==64 else im.resize((size,size),Image.Resampling.NEAREST)
            board.paste(tiny,(x+dx,y+dy),tiny)
        d.text((x+12,y+145),e['name'],font=font,fill='#e6dac1')
        d.text((x+12,y+170),'128 / 64 / 40 px',font=font,fill='#a6b29e')
    for i,e in enumerate(props):
        x=i*330;y=640
        d.text((x+12,y),e['name'],font=font,fill='#e6dac1')
        for j,t in enumerate(e['textures']):
            im=Image.open(ROOT/t[6:]);board.paste(im,(x+12+j*150,y+34),im)
        d.text((x+12,y+180),'Fresh                         Resolved',font=font,fill='#a6b29e')
    board.save(REVIEW/'overview.png')
    print('EVENT_TRINKET_EXPORT: 9 icons (128/64), 3 registered prop pairs; '+('wired 12 trinkets and 3 events' if args.wire else 'export only'))
if __name__=='__main__':main()

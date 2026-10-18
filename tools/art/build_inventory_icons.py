"""Export approved item art to a common native inventory size; optional icon wiring."""
from pathlib import Path
from PIL import Image,ImageDraw
import argparse,hashlib,importlib.util,json,re,sys
sys.dont_write_bytecode=True
ROOT=Path(__file__).resolve().parents[2]
spec=importlib.util.spec_from_file_location('treasure_export',ROOT/'tools/art/build_treasure_art.py')
base=importlib.util.module_from_spec(spec);spec.loader.exec_module(base)
OUT=ROOT/'art/items/inventory-64-v1'
SOURCE=ROOT/'art/source/inventory-64-v1'
REVIEW=ROOT/'art/concepts/inventory-64-v1'
NAMES=['plain-knife','wooden-club','simple-spear','woodcutters-axe','plain-staff','iron-sword','wooden-shield',
    'padded-coat','oil-flask','party-ration','clean-dressing','restorative-draught','antivenom']
WIRE={'plain-knife':'data/gear/plain_knife.tres','wooden-club':'data/gear/wooden_club.tres',
    'simple-spear':'data/gear/simple_spear.tres','woodcutters-axe':'data/gear/woodcutters_axe.tres',
    'iron-sword':'data/gear/iron_sword.tres','clean-dressing':'data/items/dressing.tres','copper-ore':'data/items/copper_ore.tres'}

def wire(path,texture):
    text=path.read_text(encoding='utf-8');match=re.search(r'^icon = ExtResource\("([^"]+)"\)',text,re.M)
    if match:
        id=match[1]
        pattern=r'(\[ext_resource type="Texture2D" path=")[^"]+(" id="'+re.escape(id)+r'"\])'
        text,count=re.subn(pattern,lambda m:m[1]+texture+m[2],text);assert count==1,path
    else:
        text=text.replace('[resource]','[ext_resource type="Texture2D" path="'+texture+'" id="art_icon"]\n\n[resource]',1)
        text=re.sub(r'(^script = ExtResource\([^\n]+\)\n)',r'\1icon = ExtResource("art_icon")\n',text,count=1,flags=re.M)
    # Godot attaches the script before applying its exported properties.
    text=re.sub(r'(\[resource\]\n)(icon = [^\n]+\n)(script = [^\n]+\n)',r'\1\3\2',text)
    path.write_text(text,encoding='utf-8',newline='\n')

def main():
    parser=argparse.ArgumentParser();parser.add_argument('--wire',action='store_true');args=parser.parse_args()
    for d in [OUT,REVIEW]:d.mkdir(parents=True,exist_ok=True)
    catalog={'issue':92,'canvas':[64,64],'padding':4,'assets':[]}
    report={'issue':92,'assets':{},'source_sha256':{},'failures':[]}
    for id in NAMES+['copper-ore','lantern','lantern-unlit']:
        source=ROOT/'art/items/starter-v1'/(id+'.png') if id in NAMES else SOURCE/(id+'.png')
        im=base.fit_icon(Image.open(source).convert('RGBA'))
        im=base.quantize(im,base.palette([im],32))
        dest=OUT/(id+'.png');im.save(dest)
        report['assets'][id]=base.verify(im,(64,64),32)
        report['source_sha256'][source.relative_to(ROOT).as_posix()]=hashlib.sha256(source.read_bytes()).hexdigest()
        entry={'id':id,'icon':base.uri(dest)}
        if id in WIRE:
            entry['resource']='res://'+WIRE[id]
            if args.wire:wire(ROOT/WIRE[id],entry['icon'])
        catalog['assets'].append(entry)
    (OUT/'catalog.json').write_text(json.dumps(catalog,indent=2)+'\n',encoding='utf-8',newline='\n')
    for bg,colour in [('dark','#1b2420'),('light','#d6cbb4')]:
        board=Image.new('RGBA',(768,600),colour);draw=ImageDraw.Draw(board)
        for i,entry in enumerate(catalog['assets']):
            im=Image.open(ROOT/entry['icon'].replace('res://','')).convert('RGBA');x=(i%4)*192;y=(i//4)*150
            board.alpha_composite(im,(x+28,y+10));board.alpha_composite(im.resize((40,40),Image.Resampling.NEAREST),(x+114,y+22))
            draw.text((x+96,y+82),entry['id'],font=base.font(17),fill='#e6dac1' if bg=='dark' else '#262b27',anchor='mt')
        board.convert('RGB').save(REVIEW/('overview-'+bg+'.png'))
    report['sha256']={p.relative_to(ROOT).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in OUT.glob('*.png')}
    live=[]
    for p in sorted(list((ROOT/'data/gear').glob('*.tres'))+list((ROOT/'data/items').glob('*.tres'))):
        text=p.read_text();binding=re.search(r'^icon = ExtResource\("([^"]+)"\)',text,re.M)
        assert binding,p
        texture=re.search(r'\[ext_resource type="Texture2D" path="([^"]+)" id="'+re.escape(binding[1])+r'"\]',text)[1]
        im=Image.open(ROOT/texture.replace('res://','')).convert('RGBA');assert im.size==(64,64),(p,im.size)
        live.append((p.stem,im))
    report['live_resource_count']=len(live)
    for bg,colour in [('dark','#1b2420'),('light','#d6cbb4')]:
        board=Image.new('RGBA',(768,((len(live)+5)//6)*120),colour);draw=ImageDraw.Draw(board)
        for i,(name,im) in enumerate(live):
            x=(i%6)*128;y=(i//6)*120
            board.alpha_composite(im,(x+10,y+8));board.alpha_composite(im.resize((40,40),Image.Resampling.NEAREST),(x+82,y+20))
            draw.text((x+64,y+80),name.replace('_',' '),font=base.font(12),fill='#e6dac1' if bg=='dark' else '#262b27',anchor='mt')
        board.convert('RGB').save(REVIEW/('live-library-'+bg+'.png'))
    (REVIEW/'asset-validation.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8',newline='\n')
    print('Sixteen 64px icons exported; seven live resources wired.' if args.wire else 'Sixteen 64px icons exported.')

if __name__=='__main__':main()

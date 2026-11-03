"""#196: map seven base IDs to distinct source-derived 128/64 icons.

All source masters remain immutable; only optional icon paths and obsolete
placeholder prose change in the bases table. No numeric/RNG fields change.
"""
from pathlib import Path
import sys,json,hashlib,re
sys.dont_write_bytecode=True
from PIL import Image,ImageDraw,ImageFont
import numpy as np
from build_field_kit_art import fitted
ROOT=Path(__file__).resolve().parents[2]
SRC=ROOT/'art/source/equipment-live-v1';OUT=ROOT/'art/items/equipment-live-v1';REVIEW=ROOT/'art/concepts/equipment-live-v1'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def write_json(p,a):p.write_text(json.dumps(a,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
def main():
    manifest=json.loads((SRC/'generation.json').read_text(encoding='utf-8'));entries=manifest['assets']
    for ident,path,why in [('goblin_cleaver','art/source/early-equipment-v1/notched-falchion-master.png','Retained broad chipped single-edged chopper; no new generation.'),('buckler','art/items/starter-v1/wooden-shield.png','Retained round timber shield with iron rim/boss; source is a large original, not an upscaled runtime icon.'),('shadow_cape','art/source/early-equipment-v1/raiders-mantle-master.png','Retained short dark mantle with split uneven hem and oxblood underside.')]:
        if not any(e['id']==ident for e in entries):entries.append({'id':ident,'source':path,'reuse':why})
    before=json.loads((SRC/'bases-before.json').read_text(encoding='utf-8'));current=json.loads((ROOT/'data/equipment/bases.json').read_text(encoding='utf-8'));checks=0
    (OUT/'compact64').mkdir(parents=True,exist_ok=True)
    font=ImageFont.truetype(str(ROOT/'art/fonts/source-sans-3/SourceSans3-Variable.ttf'),15)
    board=Image.new('RGBA',(1190,340),'#10140f');d=ImageDraw.Draw(board)
    for i,e in enumerate(entries):
        p=ROOT/e['source'];im=Image.open(p).convert('RGBA');assert im.getchannel('A').getextrema()[0]==0
        if 'sha256' in e:assert sha(p)==e['sha256']
        e['sha256']=sha(p)
        if e.get('reference'):e['reference_sha256']=sha(ROOT/e['reference'])
        e['source_canvas']=list(im.size);e['registration']={}
        b=next(b for b in current['bases'] if b['id']==e['id']);e['name']=b['name'];checks+=2
        for size in [128,64]:
            small,reg=fitted(im,size,64);dest=OUT/(e['id']+'.png') if size==128 else OUT/'compact64'/(e['id']+'.png');small.save(dest)
            e['registration'][str(size)]=reg;a=np.array(small);box=small.getchannel('A').getbbox();pad=size//16
            assert min(box[0],box[1],size-box[2],size-box[3])>=pad
            assert set(np.unique(a[:,:,3]))=={0,255} and not a[a[:,:,3]==0,:3].any()
            assert len(np.unique(a[a[:,:,3]>0,:3],axis=0))<=64;checks+=3
        e['export']='res://'+(OUT/(e['id']+'.png')).relative_to(ROOT).as_posix();e['compact']='res://'+(OUT/'compact64'/(e['id']+'.png')).relative_to(ROOT).as_posix()
        b['icon']=e['export'];b['description']=b['description'].replace(' Placeholder picture.','');e['description']=b['description']
        for row,bg,fg in [(0,'#1b2420','#e6dac1'),(1,'#d7c5a3','#302d25')]:
            x=i*170;y=row*165;d.rectangle((x+4,y+4,x+166,y+160),fill=bg);d.text((x+10,y+12),e['name'],font=font,fill=fg)
            icon=Image.open(OUT/(e['id']+'.png'));board.alpha_composite(icon.resize((64,64),Image.Resampling.NEAREST),(x+12,y+55));board.alpha_composite(icon.resize((40,40),Image.Resampling.NEAREST),(x+110,y+69))
    clean=json.loads(json.dumps(current))
    for b in clean['bases']:
        if any(e['id']==b['id'] for e in entries):b.pop('icon',None)
        if b['id'] in ['buckler','goblin_shield']:b['description']+=' Placeholder picture.'
    assert clean==before,'Nonvisual equipment fields changed';checks+=1
    write_json(ROOT/'data/equipment/bases.json',current);write_json(SRC/'generation.json',manifest)
    write_json(OUT/'catalog.json',{'items':entries,'checks':checks,'nonvisual_fields_unchanged':True})
    board.convert('RGB').save(REVIEW/'library.png')
    cards=''.join(f'<article><h2>{e["name"]}</h2><img src="../../../{e["export"][6:]}" width="128" height="128"><img src="../../../{e["compact"][6:]}" width="64" height="64"><p>{e["description"]}</p><small>{e.get("reuse","New ImageGen variant; exact prompt retained.")}</small></article>' for e in entries)
    (REVIEW/'inspector.html').write_text('<!doctype html><meta charset="utf-8"><meta name="viewport" content="width=device-width"><title>Equipment base icons</title><style>body{background:#10140f;color:#e6dac1;font:18px Georgia;margin:30px}main{display:grid;grid-template-columns:repeat(auto-fit,minmax(240px,1fr));gap:20px}article{background:#1b2420;border:1px solid #706147;padding:16px}img{image-rendering:pixelated;vertical-align:middle}p{line-height:1.5}a{color:#d9b374}small{display:block;line-height:1.4}</style><h1>Worn, individual equipment</h1><p>Seven real base IDs, native128 and direct-source64. Four new variants and three retained designs. Existing item rolls, stats and shared template art preserved.</p><p><a href="../../../art/source/equipment-live-v1/generation.json">Exact prompts and reuse record</a> · <a href="library.png">Dark / parchment, 64px / 40px</a></p><main>'+cards+'</main>',encoding='utf-8')
    gallery=REVIEW/'inspector.html'
    gallery.write_text(gallery.read_text(encoding='utf-8')+'<h2>Actual game screens</h2>'+''.join('<p><a href="'+x.name+'">'+x.stem+'</a></p>' for x in sorted(REVIEW.glob('*-*-*.png'))),encoding='utf-8')
    print('EQUIPMENT_ICONS:',checks,'checks, seven distinct base mappings')
if __name__=='__main__':main()

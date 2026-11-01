"""#196/#202: mechanical exports/bindings for seven prepared trade materials.

ImageGen originals are retained; this reuses the established field-kit exporter.
Only the item icon URI and obsolete placeholder-picture sentence may change.
"""
from pathlib import Path
import argparse,hashlib,json,re,sys
sys.dont_write_bytecode=True
import numpy as np
from PIL import Image,ImageDraw,ImageFont
from build_field_kit_art import fitted

ROOT=Path(__file__).resolve().parents[2]
SRC=ROOT/'art/source/salvage-v1'
OUT=ROOT/'art/items/salvage-v1'
REVIEW=ROOT/'art/concepts/salvage-v1'

def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def write(p,s):p.parent.mkdir(parents=True,exist_ok=True);p.write_text(s,encoding='utf-8',newline='\n')
def js(p,data):write(p,json.dumps(data,indent=2)+'\n')
def invariant(text):
    return re.sub(r'(type="Texture2D" path=")[^"]+',r'\1<ICON>',text).replace(' Placeholder picture.','')

def board(entries,grey=False):
    font=ImageFont.truetype(str(ROOT/'art/fonts/source-sans-3/SourceSans3-Variable.ttf'),16)
    title=ImageFont.truetype(str(ROOT/'art/fonts/source-sans-3/SourceSans3-Variable.ttf'),22)
    im=Image.new('RGBA',(1190,310),'#10140f');d=ImageDraw.Draw(im)
    d.text((18,8),'Salvage and smith materials · 64px / 40px',font=title,fill='#e6dac1')
    for n,e in enumerate(entries):
        x=n*170;icon=Image.open(ROOT/e['export'].removeprefix('res://')).convert('RGBA')
        if grey:
            a=icon.getchannel('A');icon=icon.convert('L').convert('RGBA');icon.putalpha(a)
        for y,paper in [(48,False),(178,True)]:
            d.rectangle((x+6,y,x+164,y+121),fill='#d7c5a3' if paper else '#1b2420')
            d.text((x+10,y+6),e['name'],font=font,fill='#302d25' if paper else '#e6dac1')
            im.alpha_composite(icon.resize((64,64),Image.Resampling.NEAREST),(x+16,y+39))
            im.alpha_composite(icon.resize((40,40),Image.Resampling.NEAREST),(x+107,y+53))
    im.convert('RGB').save(REVIEW/('library-greyscale.png' if grey else 'library-colour.png'))

def main():
    parser=argparse.ArgumentParser();parser.add_argument('--wire',action='store_true');args=parser.parse_args()
    OUT.mkdir(parents=True,exist_ok=True);(OUT/'compact64').mkdir(exist_ok=True)
    manifest=json.loads((SRC/'generation.json').read_text(encoding='utf-8'))
    baseline=json.loads((SRC/'bindings-before.json').read_text(encoding='utf-8'))
    entries=[];checks=0;signatures=set()
    for e in manifest['assets']:
        source=ROOT/e['source'];raw=Image.open(source)
        assert raw.mode=='RGBA' and raw.getchannel('A').getextrema()[0]==0,e['id']+' needs genuine source alpha'
        assert not e.get('sha256') or e['sha256']==sha(source)
        e['sha256']=sha(source);e['source_canvas']=list(raw.size);checks+=2
        registration={}
        for size,padding in [(128,8),(64,4)]:
            im,reg=fitted(raw,size,64)
            dest=OUT/(e['id']+'.png') if size==128 else OUT/'compact64'/(e['id']+'.png')
            im.save(dest);a=np.array(im);box=im.getchannel('A').getbbox()
            assert min(box[0],box[1],size-box[2],size-box[3])>=padding
            assert set(np.unique(a[:,:,3]))=={0,255}
            assert len(np.unique(a[a[:,:,3]>0,:3],axis=0))<=64
            assert not np.any(a[a[:,:,3]==0,:3])
            assert not np.any(a[:padding,:,3]) and not np.any(a[-padding:,:,3])
            checks+=5;registration[str(size)]=reg
            if size==128:e['export']='res://'+dest.relative_to(ROOT).as_posix()
            else:e['compact']='res://'+dest.relative_to(ROOT).as_posix()
        e['registration']=registration;e['export_sha256']=sha(ROOT/e['export'].removeprefix('res://'))
        signatures.add(e['export_sha256'])
        before=next(b for b in baseline['items'] if b['resource']==e['resource'])
        path=ROOT/e['resource'];current=path.read_text(encoding='utf-8')
        assert invariant(current)==invariant(before['text']), 'Unrelated resource change: '+e['resource']
        old_icon=re.search(r'type="Texture2D" path="([^"]+)"',current)[1]
        assert old_icon in [before['old_icon'],e['export']], 'Another icon binding appeared'
        if args.wire:
            current=current.replace(old_icon,e['export']).replace(' Placeholder picture.','')
            assert invariant(current)==invariant(before['text'])
            write(path,current)
        e['old_icon']=before['old_icon'];e['description']=re.search(r'^description = "(.*)"$',current,re.M)[1]
        e['bound']=e['export'] in current
        checks+=2;entries.append(e)
    assert len(signatures)==len(entries)==7;checks+=1
    for uri,checksum in baseline['shared_art'].items():
        assert sha(ROOT/uri.removeprefix('res://'))==checksum,'Shared original changed: '+uri
        checks+=1
    js(SRC/'generation.json',manifest);js(OUT/'catalog.json',{'items':entries,'runtime_canvas':[128,128],'compact_canvas':[64,64],'visible_colours':64,'gameplay_unchanged':True})
    js(REVIEW/'export-validation.json',{'checks':checks,'failures':[],'items':7,'runtime_and_compact_exports':14,'all_bound':all(e['bound'] for e in entries),'shared_originals_unchanged':True,'nonvisual_resource_text_unchanged':True,'rgba_bytes':7*(128*128+64*64)*4})
    board(entries);board(entries,True)
    print(f'SALVAGE_EXPORT: {checks} checks, seven distinct icons, bound={all(e["bound"] for e in entries)}')

if __name__=='__main__':main()
